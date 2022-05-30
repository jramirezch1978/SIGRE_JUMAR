create or replace procedure usp_gen_asi_plla (
  as_tipo_trabajador in char, as_origen in char, as_usuario in char ) is

lk_libro_emp        constant number(3) := 020 ;
lk_libro_obr        constant number(3) := 021 ;
lk_nro_horas        constant number(3) := 240 ;
lk_tipo_doc         constant char(4)   := 'PLAN' ;

ld_fec_inicio       date ;
ld_fec_proceso      date ;
ld_fec_desde        date ;
ld_fec_hasta        date ;
ln_contador         integer ;
ln_distribucion     integer ;
ln_sw               integer ;
ln_item             number(6) ;
ln_nro_libro        number(3) ;
ls_desc_libro       varchar2(60) ;
ln_provisional      number(10) ;
ln_tipo_cambio      number(7,3) ;
ls_nro_doc          char(15) ;
ls_seccion          char(3) ;
ls_codigo           char(8) ;
ls_codtra           char(8) ;
ls_cencos           char(10) ;
ls_cencos_dis       char(10) ;
ls_labor_dis        char(8) ;
ls_cnta_prsp        char(10) ;
ls_concepto         char(4) ;
ls_grupo            char(2) ;
ls_flag_cp          char(1) ;
ls_flag_cc          char(1) ;
ls_flag_cr          char(1) ;
ls_ind_cencos       char(10) ;
ls_ind_codigo       char(8) ;
ln_imp_soles        number(13,2) ;
ln_imp_dolar        number(13,2) ;
ln_imp_dis_sol      number(13,2) ;
ln_imp_dis_dol      number(13,2) ;
ln_tot_dis_sol      number(13,2) ;
ln_tot_dis_dol      number(13,2) ;
ln_nro_horas        number(13,2) ;
ls_flag_dh          char(1) ;
ls_cuenta_debe      char(10) ;
ls_cuenta_haber     char(10) ;
ln_total_soldeb     number(13,2) ;
ln_total_solhab     number(13,2) ;
ln_total_doldeb     number(13,2) ;
ln_total_dolhab     number(13,2) ;
ln_count            number(2) ;
ln_verifica         integer ;

--  Personal activo para generacion de asientos
cursor c_maestro is
  select m.cod_trabajador, m.cencos, m.cod_seccion
  from maestro m
  where m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_seccion, m.cencos, m.cod_trabajador ;
rc_mae c_maestro%rowtype ;
  
--  Lectura del calculo de la planilla por trabajador
cursor c_calculo is
  select c.concep, c.imp_soles, c.imp_dolar
  from calculo c
  where c.cod_trabajador = ls_codigo and c.imp_soles <> 0 and
        c.concep <> '1450' and c.concep <> '2351' and
        c.concep <> '2352' and c.concep <> '3050'
  order by c.cod_trabajador, c.concep ;

--  Lectura para generar asientos de la distribucion contable  
cursor c_distribucion is
  select d.cod_trabajador, d.cencos, d.cod_labor, d.nro_horas
  from distribucion_cntble d
  where d.cod_trabajador = ls_codigo and
        to_date(to_char(d.fec_movimiento,'DD/MM/YYYY'),'DD/MM/YYYY') between
        to_date(to_char(ld_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
        to_date(to_char(ld_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')
  order by d.cod_trabajador, d.cencos, d.cod_labor ;
rc_dis c_distribucion%rowtype ;

begin

--  Determina numero de libro contable
if as_tipo_trabajador = 'EMP' then
  ln_nro_libro  := lk_libro_emp ;
  ls_desc_libro := 'ASIENTO DE PLANILLA EMPLEADOS' ;
elsif as_tipo_trabajador = 'OBR' then
  ln_nro_libro  := lk_libro_obr ;
  ls_desc_libro := 'ASIENTO DE PLANILLA OBREROS' ;
end if ;

--  Determina fechas del registro de parametros
select rh.fec_proceso, rh.fec_desde, rh.fec_hasta
  into ld_fec_proceso, ld_fec_desde, ld_fec_hasta
  from rrhhparam rh
  where rh.reckey = '1' ;

ld_fec_inicio := to_date('01'||'/'||to_char(ld_fec_proceso,'MM')||'/'||
                 to_char(ld_fec_proceso,'YYYY'),'DD/MM/YYYY') ;

--  Elimina movimiento de asiento contable generado
usp_cnt_borrar_pre_asiento( as_origen, ln_nro_libro, ld_fec_inicio, ld_fec_proceso ) ;

--  Determina tipo de cambio a la fecha de proceso
ln_contador := 0 ; ln_tipo_cambio := 0 ;
select count(*)
  into ln_contador from calendario cal
  where to_char(cal.fecha,'DD/MM/YYYY') = to_char(ld_fec_proceso,'DD/MM/YYYY') ;
if ln_contador > 0 then
  select nvl(cal.vta_dol_prom,1)
    into ln_tipo_cambio from calendario cal
    where to_char(cal.fecha,'DD/MM/YYYY') = to_char(ld_fec_proceso,'DD/MM/YYYY') ;
end if ;

ls_nro_doc := lk_tipo_doc||to_char(ld_fec_proceso,'MMYYYY') ;

--  ******************************************************************
--  ***   LECTURA DE TRABAJADORES PARA LA GENERACION DEL ASIENTO   ***
--  ******************************************************************
open c_maestro ;
fetch c_maestro into rc_mae ;
while c_maestro%found loop

  --  Determina numero provisional
  ln_contador := 0 ;
  select count(*)
    into ln_contador from cntbl_libro l
    where l.nro_libro = ln_nro_libro ;
  if ln_contador = 0 then
    ln_provisional := 1 ;
    insert into cntbl_libro ( nro_libro, desc_libro, num_provisional )
    values ( ln_nro_libro, substr(ls_desc_libro,1,40), ln_provisional ) ;
  else
    select nvl(l.num_provisional,0)
      into ln_provisional from cntbl_libro l
      where l.nro_libro = ln_nro_libro ;
    ln_provisional := ln_provisional + 1 ;
  end if ;

  --  Adiciona registro de cabecera del pre asiento
  insert into cntbl_pre_asiento (
    origen, nro_libro, nro_provisional, cod_moneda, tasa_cambio,
    desc_glosa, fec_cntbl, fec_registro, cod_usr, flag_estado,
    tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab )
  values (
    as_origen, ln_nro_libro, ln_provisional, 'S/.', ln_tipo_cambio,
    ls_desc_libro, ld_fec_proceso, ld_fec_proceso, as_usuario, '1',
    0, 0, 0, 0 ) ;

  ln_item := 0 ; ls_seccion := rc_mae.cod_seccion ;
  while rc_mae.cod_seccion = ls_seccion and c_maestro%found loop

    ls_codigo := rc_mae.cod_trabajador ;
    ls_cencos := rc_mae.cencos ;

    --  Verifica que existan horas distribuidas por trabajador
    ln_contador := 0 ; ln_distribucion := 0 ;
--    if as_tipo_trabajador = 'OBR' and (substr(ls_cencos,1,2) = '31' or
--       substr(ls_cencos,1,2) = '32' or substr(ls_cencos,1,5) = '84111') then
    if as_tipo_trabajador = 'OBR' and (substr(ls_cencos,1,1) = '3' or
       substr(ls_cencos,1,5) = '84111') then
      select count(*)
        into ln_contador from distribucion_cntble dc
        where dc.cod_trabajador = ls_codigo and
              to_date(to_char(dc.fec_movimiento,'DD/MM/YYYY'),'DD/MM/YYYY') between
              to_date(to_char(ld_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
              to_date(to_char(ld_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY') ;
      if ln_contador > 0 then
        ln_distribucion := 1 ;
      end if ;
    end if ;

    --  *************************************************************
    --  ***   LECTURA DEL CALCULO DE LA PLANILLA POR TRABAJADOR   ***
    --  *************************************************************
    for rc_cal in c_calculo loop

      ls_concepto  := rc_cal.concep ;
      ln_imp_soles := nvl(rc_cal.imp_soles,0) ;
      ln_imp_dolar := nvl(rc_cal.imp_dolar,0) ;

      ln_sw := 0 ;
      if ln_imp_soles < 0 and ln_imp_dolar < 0 then
        ln_imp_soles := ln_imp_soles * -1 ;
        ln_imp_dolar := ln_imp_dolar * -1 ;
        ln_sw        := 1 ;
      end if ;

      --  Genera asientos sin distribucion de horas trabajadas
      if ln_distribucion = 0 then

        if as_tipo_trabajador = 'EMP' then
          select nvl(con.cta_haber_emp,' '), nvl(con.cta_debe_emp,' ')
            into ls_cuenta_haber, ls_cuenta_debe
            from concepto con where con.concep = ls_concepto ;
        elsif as_tipo_trabajador = 'OBR' then
          select nvl(con.cta_haber_obr,' '), nvl(con.cta_debe_obr,' ')
            into ls_cuenta_haber, ls_cuenta_debe
            from concepto con where con.concep = ls_concepto ;
        end if ;

        if ls_cuenta_debe <> ' ' then
          if substr(ls_cuenta_debe,1,1) = '9' then
            ln_contador := 0 ;
            select count(*)
              into ln_contador from centros_costo c
              where c.cencos = ls_cencos ;
            if ln_contador > 0 then
              select nvl(c.grp_cntbl,' ')
                into ls_grupo from centros_costo c
                where c.cencos = ls_cencos ;
              ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
            end if ;
          end if ;
          ln_verifica := 0 ;
          select count(*) into ln_verifica from cntbl_cnta cta
            where cta.cnta_ctbl = ls_cuenta_debe ;
          if ln_verifica > 0 then
            select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
              into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
              where cta.cnta_ctbl = ls_cuenta_debe ;
          else
            raise_application_error(-20000, 'Cencos  '||ls_cencos||
            '  Cuenta  '||ls_cuenta_debe||'  NO EXISTE') ;
          end if ;
          if ls_flag_cc <> '1' then ls_ind_cencos := null ;
          else ls_ind_cencos := ls_cencos ; end if ;
          if ls_flag_cr <> '1' then ls_ind_codigo := null ;
          else ls_ind_codigo := ls_codigo ; end if ;
          ls_flag_dh := 'D' ;
          if ln_sw = 1 then ls_flag_dh := 'H' ; end if ;
          ln_item := ln_item + 1 ;
          insert into cntbl_pre_asiento_det (
            origen, nro_libro, nro_provisional, item,
            cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
            tipo_docref, nro_docref1, cencos, cod_relacion,
            imp_movsol, imp_movdol )
          values (
            as_origen, ln_nro_libro, ln_provisional, ln_item,
            ls_cuenta_debe, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_imp_soles, ln_imp_dolar ) ;
        end if ;

        if ls_cuenta_haber <> ' ' then
          if substr(ls_cuenta_haber,1,1) = '9' then
            ln_contador := 0 ;
            select count(*)
              into ln_contador from centros_costo c
              where c.cencos = ls_cencos ;
            if ln_contador > 0 then
              select nvl(c.grp_cntbl,' ')
                into ls_grupo from centros_costo c
                where c.cencos = ls_cencos ;
              ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
            end if ;
          end if ;
          ln_verifica := 0 ;
          select count(*) into ln_verifica from cntbl_cnta cta
            where cta.cnta_ctbl = ls_cuenta_haber ;
          if ln_verifica > 0 then
            select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
              into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
              where cta.cnta_ctbl = ls_cuenta_haber ;
          else
            raise_application_error(-20001, 'Cencos  '||ls_cencos||
            '  Cuenta  '||ls_cuenta_haber||'  NO EXISTE') ;
          end if ;
          if ls_flag_cc <> '1' then ls_ind_cencos := null ;
          else ls_ind_cencos := ls_cencos ; end if ;
          if ls_flag_cr <> '1' then ls_ind_codigo := null ;
          else ls_ind_codigo := ls_codigo ; end if ;
          ls_flag_dh := 'H' ;
          if ln_sw = 1 then ls_flag_dh := 'D' ; end if ;
          ln_item := ln_item + 1 ;
          insert into cntbl_pre_asiento_det (
            origen, nro_libro, nro_provisional, item,
            cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
            tipo_docref, nro_docref1, cencos, cod_relacion,
            imp_movsol, imp_movdol, imp_movaju )
          values (
            as_origen, ln_nro_libro, ln_provisional, ln_item,
            ls_cuenta_haber, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_imp_soles, ln_imp_dolar, 0 ) ;
        end if ;

      end if ;

      --  Genera asiento con distribucion de horas trabajadas
      if ln_distribucion = 1 then
        select nvl(con.cta_haber_obr,' '), nvl(con.cta_debe_obr,' ')
          into ls_cuenta_haber, ls_cuenta_debe
          from concepto con where con.concep = ls_concepto ;
        if ls_cuenta_debe <> ' ' then
          ls_flag_dh := 'D' ;
          if ln_sw = 1 then ls_flag_dh := 'H' ; end if ;
          if substr(ls_cuenta_debe,1,1) <> '9' then
            select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
              into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
              where cta.cnta_ctbl = ls_cuenta_debe ;
            if ls_flag_cc <> '1' then ls_ind_cencos := null ;
            else ls_ind_cencos := ls_cencos ; end if ;
            if ls_flag_cr <> '1' then ls_ind_codigo := null ;
            else ls_ind_codigo := ls_codigo ; end if ;
            ln_item := ln_item + 1 ;
            insert into cntbl_pre_asiento_det (
              origen, nro_libro, nro_provisional, item,
              cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
              tipo_docref, nro_docref1, cencos, cod_relacion,
              imp_movsol, imp_movdol )
            values (
              as_origen, ln_nro_libro, ln_provisional, ln_item,
              ls_cuenta_debe, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
              lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
              ln_imp_soles, ln_imp_dolar ) ;
          else
            --  Distribuye gastos por centros de costos
            ln_tot_dis_sol := 0 ; ln_tot_dis_dol := 0 ;
            open c_distribucion ;
            fetch c_distribucion into rc_dis ;
            while c_distribucion%found loop
              ln_nro_horas  := 0 ;
              ls_codtra     := rc_dis.cod_trabajador ;
              ls_labor_dis  := rc_dis.cod_labor ;
              ls_cencos_dis := rc_dis.cencos ;
              while rc_dis.cod_trabajador = ls_codtra and rc_dis.cencos = ls_cencos_dis and
                    rc_dis.cod_labor = ls_labor_dis and c_distribucion%found loop
                ln_nro_horas := ln_nro_horas + nvl(rc_dis.nro_horas,0) ;
                fetch c_distribucion into rc_dis ;
              end loop ;
              ln_imp_dis_sol := (ln_imp_soles / lk_nro_horas) * ln_nro_horas ;
              ln_imp_dis_dol := ln_imp_dis_sol / ln_tipo_cambio ;
              ln_tot_dis_sol := ln_tot_dis_sol + ln_imp_dis_sol ;
              ln_tot_dis_dol := ln_tot_dis_dol + ln_imp_dis_dol ;
              ln_item := ln_item + 1 ;
              ln_contador := 0 ; ls_flag_cp := ' ' ;
              select count(*)
                into ln_contador from centros_costo c
                where c.cencos = ls_cencos_dis ;
              if ln_contador > 0 then
                select nvl(c.flag_cta_presup,' '), nvl(c.grp_cntbl,' ')
                  into ls_flag_cp, ls_grupo from centros_costo c
                  where c.cencos = ls_cencos_dis ;
                ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
              end if ;
              ln_verifica := 0 ;
              select count(*) into ln_verifica from cntbl_cnta cta
                where cta.cnta_ctbl = ls_cuenta_debe ;
              if ln_verifica > 0 then
                select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
                  into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
                  where cta.cnta_ctbl = ls_cuenta_debe ;
              else
                raise_application_error(-20002, 'Cencos  '||ls_cencos_dis||
                '  Cuenta  '||ls_cuenta_debe||'  NO EXISTE') ;
              end if ;
              if ls_flag_cc <> '1' then ls_ind_cencos := null ;
              else ls_ind_cencos := ls_cencos_dis ; end if ;
              if ls_flag_cr <> '1' then ls_ind_codigo := null ;
              else ls_ind_codigo := ls_codigo ; end if ;
              insert into cntbl_pre_asiento_det (
                origen, nro_libro, nro_provisional, item,
                cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                tipo_docref, nro_docref1, cencos, cod_relacion,
                imp_movsol, imp_movdol )
              values (
                as_origen, ln_nro_libro, ln_provisional, ln_item,
                ls_cuenta_debe, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
                lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                ln_imp_dis_sol, ln_imp_dis_dol ) ;
              if ls_flag_cp = '1' then
                select nvl(l.cnta_prsp,' ') into ls_cnta_prsp
                  from labor l where l.cod_labor = ls_labor_dis ;
                if ls_cnta_prsp <> ' ' then
                  insert into cntbl_pre_asiento_det_aux (
                    origen, nro_libro, nro_provisional, item, cnta_prsp )
                  values (
                    as_origen, ln_nro_libro, ln_provisional, ln_item, ls_cnta_prsp ) ;
                else
                  raise_application_error(-20006, 'Labor  '||ls_labor_dis||
                  '  NO tiene cuenta presupuestal') ;
                end if ;
              end if ;
            end loop ;
            close c_distribucion ;
            --  Ajusta importe de distribucion
            ln_tot_dis_sol := ln_imp_soles - ln_tot_dis_sol ;
            ln_tot_dis_dol := ln_imp_dolar - ln_tot_dis_dol ;
            if ln_tot_dis_sol <> 0 then
              if ln_tot_dis_sol < 0 then
                ln_tot_dis_sol := ln_tot_dis_sol * -1 ;
                ln_tot_dis_dol := ln_tot_dis_dol * -1 ;
                if ls_flag_dh = 'D' then
                  ls_flag_dh := 'H' ;
                else
                  ls_flag_dh := 'D' ;
                end if ;
              end if ;
              ln_item := ln_item + 1 ;
              ln_contador := 0 ; ls_flag_cp := ' ' ;
              select count(*)
                into ln_contador from centros_costo c
                where c.cencos = ls_cencos ;
              if ln_contador > 0 then
                select nvl(c.flag_cta_presup,' '), nvl(c.grp_cntbl,' ')
                  into ls_flag_cp, ls_grupo from centros_costo c
                  where c.cencos = ls_cencos ;
                ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
              end if ;
              ln_verifica := 0 ;
              select count(*) into ln_verifica from cntbl_cnta cta
                where cta.cnta_ctbl = ls_cuenta_debe ;
              if ln_verifica > 0 then
                select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
                  into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
                  where cta.cnta_ctbl = ls_cuenta_debe ;
              else
                raise_application_error(-20003, 'Cencos  '||ls_cencos||
                '  Cuenta  '||ls_cuenta_debe||'  NO EXISTE') ;
              end if ;
              if ls_flag_cc <> '1' then ls_ind_cencos := null ;
              else ls_ind_cencos := ls_cencos ; end if ;
              if ls_flag_cr <> '1' then ls_ind_codigo := null ;
              else ls_ind_codigo := ls_codigo ; end if ;
              insert into cntbl_pre_asiento_det (
                origen, nro_libro, nro_provisional, item,
                cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                tipo_docref, nro_docref1, cencos, cod_relacion,
                imp_movsol, imp_movdol )
              values (
                as_origen, ln_nro_libro, ln_provisional, ln_item,
                ls_cuenta_debe, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
                lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                ln_tot_dis_sol, ln_tot_dis_dol ) ;
            end if ;
          end if ;
        end if ;

        if ls_cuenta_haber <> ' ' then
          ls_flag_dh := 'H' ;
          if ln_sw = 1 then ls_flag_dh := 'D' ; end if ;
          if substr(ls_cuenta_haber,1,1) <> '9' then
            select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
              into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
              where cta.cnta_ctbl = ls_cuenta_haber ;
            if ls_flag_cc <> '1' then ls_ind_cencos := null ;
            else ls_ind_cencos := ls_cencos ; end if ;
            if ls_flag_cr <> '1' then ls_ind_codigo := null ;
            else ls_ind_codigo := ls_codigo ; end if ;
            ln_item := ln_item + 1 ;
            insert into cntbl_pre_asiento_det (
              origen, nro_libro, nro_provisional, item,
              cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
              tipo_docref, nro_docref1, cencos, cod_relacion,
              imp_movsol, imp_movdol, imp_movaju )
            values (
              as_origen, ln_nro_libro, ln_provisional, ln_item,
              ls_cuenta_haber, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
              lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
              ln_imp_soles, ln_imp_dolar, 0 ) ;
          else
            --  Distribuye gastos por centros de costos
            ln_tot_dis_sol := 0 ; ln_tot_dis_dol := 0 ;
            open c_distribucion ;
            fetch c_distribucion into rc_dis ;
            while c_distribucion%found loop
              ln_nro_horas  := 0 ;
              ls_codtra     := rc_dis.cod_trabajador ;
              ls_labor_dis  := rc_dis.cod_labor ;
              ls_cencos_dis := rc_dis.cencos ;
              while rc_dis.cod_trabajador = ls_codtra and rc_dis.cencos = ls_cencos_dis and
                    rc_dis.cod_labor = ls_labor_dis and c_distribucion%found loop
                ln_nro_horas := ln_nro_horas + nvl(rc_dis.nro_horas,0) ;
                fetch c_distribucion into rc_dis ;
              end loop ;
              ln_imp_dis_sol := (ln_imp_soles / lk_nro_horas) * ln_nro_horas ;
              ln_imp_dis_dol := ln_imp_dis_sol / ln_tipo_cambio ;
              ln_tot_dis_sol := ln_tot_dis_sol + ln_imp_dis_sol ;
              ln_tot_dis_dol := ln_tot_dis_dol + ln_imp_dis_dol ;
              ln_item := ln_item + 1 ;
              ln_contador := 0 ; ls_flag_cp := ' ' ;
              select count(*)
                into ln_contador from centros_costo c
                where c.cencos = ls_cencos_dis ;
              if ln_contador > 0 then
                select nvl(c.flag_cta_presup,' '), nvl(c.grp_cntbl,' ')
                  into ls_flag_cp, ls_grupo from centros_costo c
                  where c.cencos = ls_cencos_dis ;
                ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
              end if ;
              ln_verifica := 0 ;
              select count(*) into ln_verifica from cntbl_cnta cta
                where cta.cnta_ctbl = ls_cuenta_haber ;
              if ln_verifica > 0 then
                select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
                  into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
                  where cta.cnta_ctbl = ls_cuenta_haber ;
              else
                raise_application_error(-20004, 'Cencos  '||ls_cencos_dis||
                '  Cuenta  '||ls_cuenta_haber||'  NO EXISTE') ;
              end if ;
              if ls_flag_cc <> '1' then ls_ind_cencos := null ;
              else ls_ind_cencos := ls_cencos_dis ; end if ;
              if ls_flag_cr <> '1' then ls_ind_codigo := null ;
              else ls_ind_codigo := ls_codigo ; end if ;
              insert into cntbl_pre_asiento_det (
                origen, nro_libro, nro_provisional, item,
                cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                tipo_docref, nro_docref1, cencos, cod_relacion,
                imp_movsol, imp_movdol )
              values (
                as_origen, ln_nro_libro, ln_provisional, ln_item,
                ls_cuenta_haber, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
                lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                ln_imp_dis_sol, ln_imp_dis_dol ) ;
              if ls_flag_cp = '1' then
                select nvl(l.cnta_prsp,' ') into ls_cnta_prsp
                  from labor l where l.cod_labor = ls_labor_dis ;
                if ls_cnta_prsp <> ' ' then
                  insert into cntbl_pre_asiento_det_aux (
                    origen, nro_libro, nro_provisional, item, cnta_prsp )
                  values (
                    as_origen, ln_nro_libro, ln_provisional, ln_item, ls_cnta_prsp ) ;
                else
                  raise_application_error(-20007, 'Labor  '||ls_labor_dis||
                  '  NO tiene cuenta presupuestal') ;
                end if ;
              end if ;
            end loop ;
            close c_distribucion ;
            --  Ajusta importe de distribucion
            ln_tot_dis_sol := ln_imp_soles - ln_tot_dis_sol ;
            ln_tot_dis_dol := ln_imp_dolar - ln_tot_dis_dol ;
            if ln_tot_dis_sol <> 0 then
              if ln_tot_dis_sol < 0 then
                ln_tot_dis_sol := ln_tot_dis_sol * -1 ;
                ln_tot_dis_dol := ln_tot_dis_dol * -1 ;
                if ls_flag_dh = 'D' then
                  ls_flag_dh := 'H' ;
                else
                  ls_flag_dh := 'D' ;
                end if ;
              end if ;
              ln_contador := 0 ; ls_flag_cp := ' ' ;
              select count(*)
                into ln_contador from centros_costo c
                where c.cencos = ls_cencos ;
              if ln_contador > 0 then
                select nvl(c.flag_cta_presup,' '), nvl(c.grp_cntbl,' ')
                  into ls_flag_cp, ls_grupo from centros_costo c
                  where c.cencos = ls_cencos ;
                ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
              end if ;
              ln_verifica := 0 ;
              select count(*) into ln_verifica from cntbl_cnta cta
                where cta.cnta_ctbl = ls_cuenta_haber ;
              if ln_verifica > 0 then
                select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
                  into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
                  where cta.cnta_ctbl = ls_cuenta_haber ;
              else
                raise_application_error(-20005, 'Cencos  '||ls_cencos||
                '  Cuenta  '||ls_cuenta_haber||'  NO EXISTE') ;
              end if ;
              if ls_flag_cc <> '1' then ls_ind_cencos := null ;
              else ls_ind_cencos := ls_cencos ; end if ;
              if ls_flag_cr <> '1' then ls_ind_codigo := null ;
              else ls_ind_codigo := ls_codigo ; end if ;
              ln_item := ln_item + 1 ;
              insert into cntbl_pre_asiento_det (
                origen, nro_libro, nro_provisional, item,
                cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                tipo_docref, nro_docref1, cencos, cod_relacion,
                imp_movsol, imp_movdol )
              values (
                as_origen, ln_nro_libro, ln_provisional, ln_item,
                ls_cuenta_haber, ld_fec_proceso, ls_desc_libro, ls_flag_dh,
                lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                ln_tot_dis_sol, ln_tot_dis_dol ) ;
            end if ;
          end if ;
        end if ;

      end if ;
    
    end loop ;
  
    fetch c_maestro into rc_mae ;
  
  end loop ;

  --  Actualiza nuevo numero provisional
  update cntbl_libro
    set num_provisional = ln_provisional
    where nro_libro = ln_nro_libro ;

  --  Actualiza importes del registro de cabebcera
  ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
  ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_soldeb, ln_total_doldeb
    from cntbl_pre_asiento_det d
    where d.origen = as_origen and d.nro_libro = ln_nro_libro and
          d.nro_provisional = ln_provisional and d.fec_cntbl = ld_fec_proceso and
          d.flag_debhab = 'D' ;
  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_solhab, ln_total_dolhab
    from cntbl_pre_asiento_det d
    where d.origen = as_origen and d.nro_libro = ln_nro_libro and
          d.nro_provisional = ln_provisional and d.fec_cntbl = ld_fec_proceso and
          d.flag_debhab = 'H' ;
  
  update cntbl_pre_asiento
    set tot_soldeb = ln_total_soldeb ,
        tot_solhab = ln_total_solhab ,
        tot_doldeb = ln_total_doldeb ,
        tot_dolhab = ln_total_dolhab
    where origen = as_origen and nro_libro = ln_nro_libro and
          nro_provisional = ln_provisional and fec_cntbl = ld_fec_proceso ;

end loop ;

end usp_gen_asi_plla ;
/
