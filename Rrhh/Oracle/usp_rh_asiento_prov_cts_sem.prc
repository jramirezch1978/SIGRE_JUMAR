create or replace procedure usp_rh_asiento_prov_cts_sem (
  as_origen in char, as_usuario in char, ad_fec_proceso in date,
  ad_fec_desde in date, ad_fec_hasta in date ) is

lk_nro_horas        constant number(3)    := 240 ;
lk_tipo_doc         constant char(4)      := 'PLAN' ;
lk_desc_libro       constant varchar2(60) := 'ASIENTO DE PROVISION DE C.T.S.' ;
lk_empleado         constant char(3)      := 'EMP' ;
lk_obrero           constant char(3)      := 'OBR' ;

ln_libro_cts        number(3) ;
ld_fec_inicio       date ;
ln_contador         integer ;
ln_distribucion     integer ;
ln_item             number(6) ;
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
ls_cuenta_debe      char(10) ;
ls_cuenta_haber     char(10) ;
ln_total_soldeb     number(13,2) ;
ln_total_solhab     number(13,2) ;
ln_total_doldeb     number(13,2) ;
ln_total_dolhab     number(13,2) ;

--  Personal activo para generacion de asientos
cursor c_maestro is
  select m.cod_trabajador, m.tipo_trabajador, m.cencos, m.cod_seccion
  from maestro m, prov_cts_gratif g
  where m.cod_trabajador = g.cod_trabajador and m.cod_origen = as_origen and
        nvl(m.flag_cal_plnlla,'0') = '1' and nvl(m.flag_estado,'0') = '1'
  order by m.cod_seccion, m.cencos, m.cod_trabajador ;
rc_mae c_maestro%rowtype ;

--  Lectura del calculo de provision de C.T.S.
cursor c_provision is
  select p.cod_trabajador, p.prov_cts_01, p.prov_cts_02, p.prov_cts_03,
         p.prov_cts_04, p.prov_cts_05, p.prov_cts_06
  from prov_cts_gratif p
  where p.cod_trabajador = ls_codigo
  order by p.cod_trabajador ;
  
--  Lectura para generar asientos de la distribucion contable
cursor c_distribucion is
  select d.cod_trabajador, d.cencos, d.cod_labor, d.nro_horas
  from distribucion_cntble d
  where d.cod_trabajador = ls_codigo and
        trunc(d.fec_movimiento) between ad_fec_desde and ad_fec_hasta
  order by d.cod_trabajador, d.cencos, d.cod_labor ;
rc_dis c_distribucion%rowtype ;

begin

--  **************************************************************
--  ***   GENERA ASIENTOS CONTABLES DE PROVISIONES DE C.T.S.   ***
--  **************************************************************

select t.libro_prov_cts into ln_libro_cts from tipo_trabajador t
  where t.tipo_trabajador = lk_empleado ;

ld_fec_inicio := to_date('01'||'/'||to_char(ad_fec_proceso,'mm')||'/'||
                 to_char(ad_fec_proceso,'yyyy'),'dd/mm/yyyy') ;

--  Elimina movimiento de asiento contable generado
usp_cnt_borrar_pre_asiento( as_origen, ln_libro_cts, ld_fec_inicio, ad_fec_proceso ) ;

--  Determina tipo de cambio a la fecha de proceso
ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*) into ln_contador from calendario cal
  where trunc(cal.fecha) = trunc(ad_fec_proceso) ;
if ln_contador > 0 then
  select nvl(cal.vta_dol_prom,1) into ln_tipo_cambio from calendario cal
    where trunc(cal.fecha) = trunc(ad_fec_proceso) ;
end if ;

ls_nro_doc := lk_tipo_doc||to_char(ad_fec_proceso,'mmyyyy') ;

--  ******************************************************************
--  ***   LECTURA DE TRABAJADORES PARA LA GENERACION DEL ASIENTO   ***
--  ******************************************************************
open c_maestro ;
fetch c_maestro into rc_mae ;
while c_maestro%found loop

  --  Determina numero provisional
  ln_contador := 0 ;
  select count(*) into ln_contador from cntbl_libro l
    where l.nro_libro = ln_libro_cts ;
  if ln_contador = 0 then
    ln_provisional := 1 ;
    insert into cntbl_libro ( nro_libro, desc_libro, num_provisional, flag_replicacion )
    values ( ln_libro_cts, substr(lk_desc_libro,1,40), ln_provisional, '1' ) ;
  else
    select nvl(l.num_provisional,0) into ln_provisional from cntbl_libro l
      where l.nro_libro = ln_libro_cts ;
    ln_provisional := ln_provisional + 1 ;
  end if ;

  --  Adiciona registro de cabecera del pre asiento
  insert into cntbl_pre_asiento (
    origen, nro_libro, nro_provisional, cod_moneda, tasa_cambio,
    desc_glosa, fec_cntbl, fec_registro, cod_usr, flag_estado,
    tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab, flag_replicacion )
  values (
    as_origen, ln_libro_cts, ln_provisional, 'S/.', ln_tipo_cambio,
    lk_desc_libro, ad_fec_proceso, ad_fec_proceso, as_usuario, '1',
    0, 0, 0, 0, '1' ) ;

  ln_item := 0 ; ls_seccion := rc_mae.cod_seccion ;
  while rc_mae.cod_seccion = ls_seccion and c_maestro%found loop

    ls_codigo := rc_mae.cod_trabajador ;
    ls_cencos := rc_mae.cencos ;

    --  Verifica que existan horas distribuidas por trabajador
    ln_contador := 0 ; ln_distribucion := 0 ;
    if rc_mae.tipo_trabajador = lk_obrero and (substr(ls_cencos,1,1) = '3' or
       substr(ls_cencos,1,5) = '84111') then
      select count(*) into ln_contador from distribucion_cntble dc
        where dc.cod_trabajador = ls_codigo and
              trunc(dc.fec_movimiento) between ad_fec_desde and ad_fec_hasta ;
      if ln_contador > 0 then
        ln_distribucion := 1 ;
      end if ;
    end if ;

    --  *************************************************************
    --  ***   LECTURA DEL CALCULO DE LA PLANILLA POR TRABAJADOR   ***
    --  *************************************************************
    for rc_prov in c_provision loop

      if to_char(ad_fec_proceso,'mm') = '05' or to_char(ad_fec_proceso,'mm') = '11' then
        ln_imp_soles := nvl(rc_prov.prov_cts_01,0) ;
      elsif to_char(ad_fec_proceso,'mm') = '06' or to_char(ad_fec_proceso,'mm') = '12' then
        ln_imp_soles := nvl(rc_prov.prov_cts_02,0) ;
      elsif to_char(ad_fec_proceso,'mm') = '07' or to_char(ad_fec_proceso,'mm') = '01' then
        ln_imp_soles := nvl(rc_prov.prov_cts_03,0) ;
      elsif to_char(ad_fec_proceso,'mm') = '08' or to_char(ad_fec_proceso,'mm') = '02' then
        ln_imp_soles := nvl(rc_prov.prov_cts_04,0) ;
      elsif to_char(ad_fec_proceso,'mm') = '09' or to_char(ad_fec_proceso,'mm') = '03' then
        ln_imp_soles := nvl(rc_prov.prov_cts_05,0) ;
      elsif to_char(ad_fec_proceso,'mm') = '10' or to_char(ad_fec_proceso,'mm') = '04' then
        ln_imp_soles := nvl(rc_prov.prov_cts_06,0) ;
      end if ;
      ln_imp_dolar := ln_imp_soles / ln_tipo_cambio ;

      if ln_imp_soles < 0 and ln_imp_dolar < 0 then
        ln_imp_soles := ln_imp_soles * -1 ;
        ln_imp_dolar := ln_imp_dolar * -1 ;
      end if ;

      --  Genera asientos sin distribucion de horas trabajadas
      if ln_distribucion = 0 then

        if rc_mae.tipo_trabajador = lk_empleado then
          ls_cuenta_debe  := '91861101' ;
          ls_cuenta_haber := '47100100' ;
        elsif rc_mae.tipo_trabajador = lk_obrero then
          ls_cuenta_debe  := '90861201' ;
          ls_cuenta_haber := '47100200' ;
        end if ;

        ln_contador := 0 ;
        select count(*) into ln_contador from centros_costo c
          where c.cencos = ls_cencos ;
        if ln_contador > 0 then
          select nvl(c.grp_cntbl,' ') into ls_grupo from centros_costo c
            where c.cencos = ls_cencos ;
           ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
        end if ;
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
          imp_movsol, imp_movdol, flag_replicacion )
        values (
          as_origen, ln_libro_cts, ln_provisional, ln_item,
          ls_cuenta_debe, ad_fec_proceso, lk_desc_libro, 'D',
          lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
          ln_imp_soles, ln_imp_dolar, '1' ) ;

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
          imp_movsol, imp_movdol, imp_movaju, flag_replicacion )
        values (
          as_origen, ln_libro_cts, ln_provisional, ln_item,
          ls_cuenta_haber, ad_fec_proceso, lk_desc_libro, 'H',
          lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
          ln_imp_soles, ln_imp_dolar, 0, '1' ) ;

      end if ;

      --  Genera asiento con distribucion de horas trabajadas
      if ln_distribucion = 1 then

        if rc_mae.tipo_trabajador = lk_empleado then
          ls_cuenta_debe  := '91861101' ;
          ls_cuenta_haber := '47100100' ;
        elsif rc_mae.tipo_trabajador = lk_obrero then
          ls_cuenta_debe  := '90861201' ;
          ls_cuenta_haber := '47100200' ;
        end if ;

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
          select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
            into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
            where cta.cnta_ctbl = ls_cuenta_debe ;
          if ls_flag_cc <> '1' then ls_ind_cencos := null ;
          else ls_ind_cencos := ls_cencos_dis ; end if ;
          if ls_flag_cr <> '1' then ls_ind_codigo := null ;
          else ls_ind_codigo := ls_codigo ; end if ;
          ln_item := ln_item + 1 ;
          insert into cntbl_pre_asiento_det (
            origen, nro_libro, nro_provisional, item,
            cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
            tipo_docref, nro_docref1, cencos, cod_relacion,
            imp_movsol, imp_movdol, flag_replicacion )
          values (
            as_origen, ln_libro_cts, ln_provisional, ln_item,
            ls_cuenta_debe, ad_fec_proceso, lk_desc_libro, 'D',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_imp_dis_sol, ln_imp_dis_dol, '1' ) ;
          if ls_flag_cp = '1' then
            select l.cnta_prsp
              into ls_cnta_prsp
              from labor l where l.cod_labor = ls_labor_dis ;
            insert into cntbl_pre_asiento_det_aux (
              origen, nro_libro, nro_provisional, item, cnta_prsp, flag_replicacion )
            values (
              as_origen, ln_libro_cts, ln_provisional, ln_item, ls_cnta_prsp, '1' ) ;
          end if ;
          select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
            into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
            where cta.cnta_ctbl = ls_cuenta_haber ;
          if ls_flag_cc <> '1' then ls_ind_cencos := null ;
          else ls_ind_cencos := ls_cencos_dis ; end if ;
          if ls_flag_cr <> '1' then ls_ind_codigo := null ;
          else ls_ind_codigo := ls_codigo ; end if ;
          ln_item := ln_item + 1 ;
          insert into cntbl_pre_asiento_det (
            origen, nro_libro, nro_provisional, item,
            cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
            tipo_docref, nro_docref1, cencos, cod_relacion,
            imp_movsol, imp_movdol, flag_replicacion )
          values (
            as_origen, ln_libro_cts, ln_provisional, ln_item,
            ls_cuenta_haber, ad_fec_proceso, lk_desc_libro, 'H',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_imp_dis_sol, ln_imp_dis_dol, '1' ) ;
          if ls_flag_cp = '1' then
            select l.cnta_prsp
              into ls_cnta_prsp
              from labor l where l.cod_labor = ls_labor_dis ;
            insert into cntbl_pre_asiento_det_aux (
              origen, nro_libro, nro_provisional, item, cnta_prsp, flag_replicacion )
            values (
              as_origen, ln_libro_cts, ln_provisional, ln_item, ls_cnta_prsp, '1' ) ;
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
          end if ;
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
            imp_movsol, imp_movdol, flag_replicacion )
          values (
            as_origen, ln_libro_cts, ln_provisional, ln_item,
            ls_cuenta_debe, ad_fec_proceso, lk_desc_libro, 'D',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_tot_dis_sol, ln_tot_dis_dol, '1' ) ;
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
            imp_movsol, imp_movdol, flag_replicacion )
          values (
            as_origen, ln_libro_cts, ln_provisional, ln_item,
            ls_cuenta_haber, ad_fec_proceso, lk_desc_libro, 'H',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_tot_dis_sol, ln_tot_dis_dol, '1' ) ;
        end if ;

      end if ;

    end loop ;

    fetch c_maestro into rc_mae ;

  end loop ;

  --  Actualiza nuevo numero provisional
  update cntbl_libro
    set num_provisional = ln_provisional,
         flag_replicacion = '1'
    where nro_libro = ln_libro_cts ;

  --  Actualiza importes del registro de cabebcera
  ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
  ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_soldeb, ln_total_doldeb
    from cntbl_pre_asiento_det d
    where d.origen = as_origen and d.nro_libro = ln_libro_cts and
          d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
          d.flag_debhab = 'D' ;
  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_solhab, ln_total_dolhab
    from cntbl_pre_asiento_det d
    where d.origen = as_origen and d.nro_libro = ln_libro_cts and
          d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
          d.flag_debhab = 'H' ;

  update cntbl_pre_asiento
    set tot_soldeb = ln_total_soldeb ,
        tot_solhab = ln_total_solhab ,
        tot_doldeb = ln_total_doldeb ,
        tot_dolhab = ln_total_dolhab,
         flag_replicacion = '1'
    where origen = as_origen and nro_libro = ln_libro_cts and
          nro_provisional = ln_provisional and fec_cntbl = ad_fec_proceso ;

end loop ;

end usp_rh_asiento_prov_cts_sem ;
/
