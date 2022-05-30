create or replace procedure usp_gen_asi_prov_gra (
  as_origen in char, as_usuario in char,
  ad_fec_proceso in date, ad_fec_desde in date, ad_fec_hasta in date ) is

lk_libro_gra        constant number(3) := 047 ;
lk_nro_horas        constant number(3) := 240 ;
lk_tipo_doc         constant char(4)   := 'PLAN' ;
lk_desc_libro       constant varchar2(60) := 'ASIENTO DE PROVISION DE GRATIFICACION' ;

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
  from maestro m, prov_cts_gratif p
  where m.cod_trabajador = p.cod_trabajador and m.cencos is not null and
        m.flag_estado = '1'
  order by m.cod_seccion, m.cencos, m.cod_trabajador ;
rc_mae c_maestro%rowtype ;
  
--  Lectura del calculo de provision de gratificaciones
cursor c_provision is
  select p.cod_trabajador,
         p.prov_gratif_01, p.prov_gratif_02, p.prov_gratif_03,
         p.prov_gratif_04, p.prov_gratif_05, p.prov_gratif_06,
         p.prov_gratif_07, p.prov_gratif_08, p.prov_gratif_09,
         p.prov_gratif_10, p.prov_gratif_11, p.prov_gratif_12
  from prov_cts_gratif p
  where p.cod_trabajador = ls_codigo
  order by p.cod_trabajador ;

--  Lectura para generar asientos de la distribucion contable  
cursor c_distribucion is
  select d.cod_trabajador, d.cencos, d.cod_labor, d.nro_horas
  from distribucion_cntble d
  where d.cod_trabajador = ls_codigo and
        to_date(to_char(d.fec_movimiento,'DD/MM/YYYY'),'DD/MM/YYYY') between
        to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')
  order by d.cod_trabajador, d.cencos, d.cod_labor ;
rc_dis c_distribucion%rowtype ;

begin

ld_fec_inicio := to_date('01'||'/'||to_char(ad_fec_proceso,'MM')||'/'||
                 to_char(ad_fec_proceso,'YYYY'),'DD/MM/YYYY') ;

--  Elimina movimiento de asiento contable generado
usp_cnt_borrar_pre_asiento( as_origen, lk_libro_gra, ld_fec_inicio, ad_fec_proceso ) ;

--  Determina tipo de cambio a la fecha de proceso
ln_contador := 0 ; ln_tipo_cambio := 0 ;
select count(*)
  into ln_contador from calendario cal
  where to_char(cal.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
if ln_contador > 0 then
  select nvl(cal.vta_dol_prom,1)
    into ln_tipo_cambio from calendario cal
    where to_char(cal.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
end if ;

ls_nro_doc := lk_tipo_doc||to_char(ad_fec_proceso,'MMYYYY') ;

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
    where l.nro_libro = lk_libro_gra ;
  if ln_contador = 0 then
    ln_provisional := 1 ;
    insert into cntbl_libro ( nro_libro, desc_libro, num_provisional )
    values ( lk_libro_gra, substr(lk_desc_libro,1,40), ln_provisional ) ;
  else
    select nvl(l.num_provisional,0)
      into ln_provisional from cntbl_libro l
      where l.nro_libro = lk_libro_gra ;
    ln_provisional := ln_provisional + 1 ;
  end if ;

  --  Adiciona registro de cabecera del pre asiento
  insert into cntbl_pre_asiento (
    origen, nro_libro, nro_provisional, cod_moneda, tasa_cambio,
    desc_glosa, fec_cntbl, fec_registro, cod_usr, flag_estado,
    tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab )
  values (
    as_origen, lk_libro_gra, ln_provisional, 'S/.', ln_tipo_cambio,
    lk_desc_libro, ad_fec_proceso, ad_fec_proceso, as_usuario, '1',
    0, 0, 0, 0 ) ;

  ln_item := 0 ; ls_seccion := rc_mae.cod_seccion ;
  while rc_mae.cod_seccion = ls_seccion and c_maestro%found loop

    ls_codigo := rc_mae.cod_trabajador ;
    ls_cencos := rc_mae.cencos ;

    --  Verifica que existan horas distribuidas por trabajador
    ln_contador := 0 ; ln_distribucion := 0 ;
    if rc_mae.tipo_trabajador = 'OBR' and (substr(ls_cencos,1,2) = '31' or
       substr(ls_cencos,1,2) = '32' or substr(ls_cencos,1,5) = '84111') then
      select count(*)
        into ln_contador from distribucion_cntble dc
        where dc.cod_trabajador = ls_codigo and
              to_date(to_char(dc.fec_movimiento,'DD/MM/YYYY'),'DD/MM/YYYY') between
              to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
              to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY') ;
      if ln_contador > 0 then
        ln_distribucion := 1 ;
      end if ;
    end if ;

    --  *************************************************************
    --  ***   LECTURA DEL CALCULO DE LA PLANILLA POR TRABAJADOR   ***
    --  *************************************************************
    for rc_prov in c_provision loop

      if to_char(ad_fec_proceso,'MM') = '01' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_01,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '02' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_02,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '03' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_03,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '04' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_04,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '05' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_05,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '06' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_06,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '07' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_07,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '08' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_08,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '09' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_09,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '10' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_10,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '11' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_11,0) ;
      elsif to_char(ad_fec_proceso,'MM') = '12' then
        ln_imp_soles := nvl(rc_prov.prov_gratif_12,0) ;
      end if ;

      ln_imp_dolar := ln_imp_soles / ln_tipo_cambio ;

      if ln_imp_soles < 0 and ln_imp_dolar < 0 then
        ln_imp_soles := ln_imp_soles * -1 ;
        ln_imp_dolar := ln_imp_dolar * -1 ;
      end if ;

      --  Genera asientos sin distribucion de horas trabajadas
      if ln_distribucion = 0 then

        if rc_mae.tipo_trabajador = 'EMP' then
          ls_cuenta_debe  := '91251101' ;
          ls_cuenta_haber := '41110100' ;
        elsif rc_mae.tipo_trabajador = 'OBR' then
          ls_cuenta_debe  := '90251201' ;
          ls_cuenta_haber := '41110200' ;
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
          imp_movsol, imp_movdol )
        values (
          as_origen, lk_libro_gra, ln_provisional, ln_item,
          ls_cuenta_debe, ad_fec_proceso, lk_desc_libro, 'D',
          lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
          ln_imp_soles, ln_imp_dolar ) ;

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
          as_origen, lk_libro_gra, ln_provisional, ln_item,
          ls_cuenta_haber, ad_fec_proceso, lk_desc_libro, 'H',
          lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
          ln_imp_soles, ln_imp_dolar, 0 ) ;

      end if ;

      --  Genera asiento con distribucion de horas trabajadas
      if ln_distribucion = 1 then

        if rc_mae.tipo_trabajador = 'EMP' then
          ls_cuenta_debe  := '91251101' ;
          ls_cuenta_haber := '41110100' ;
        elsif rc_mae.tipo_trabajador = 'OBR' then
          ls_cuenta_debe  := '90251201' ;
          ls_cuenta_haber := '41110200' ;
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
            imp_movsol, imp_movdol )
          values (
            as_origen, lk_libro_gra, ln_provisional, ln_item,
            ls_cuenta_debe, ad_fec_proceso, lk_desc_libro, 'D',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_imp_dis_sol, ln_imp_dis_dol ) ;
          if ls_flag_cp = '1' then
            select nvl(l.cnta_prsp,' ')
              into ls_cnta_prsp
              from labor l where l.cod_labor = ls_labor_dis ;
            insert into cntbl_pre_asiento_det_aux (
              origen, nro_libro, nro_provisional, item, cnta_prsp )
            values (
              as_origen, lk_libro_gra, ln_provisional, ln_item, ls_cnta_prsp ) ;
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
            imp_movsol, imp_movdol )
          values (
            as_origen, lk_libro_gra, ln_provisional, ln_item,
            ls_cuenta_haber, ad_fec_proceso, lk_desc_libro, 'H',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_imp_dis_sol, ln_imp_dis_dol ) ;
          if ls_flag_cp = '1' then
            select nvl(l.cnta_prsp,' ')
              into ls_cnta_prsp
              from labor l where l.cod_labor = ls_labor_dis ;
            insert into cntbl_pre_asiento_det_aux (
              origen, nro_libro, nro_provisional, item, cnta_prsp )
            values (
              as_origen, lk_libro_gra, ln_provisional, ln_item, ls_cnta_prsp ) ;
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
            imp_movsol, imp_movdol )
          values (
            as_origen, lk_libro_gra, ln_provisional, ln_item,
            ls_cuenta_debe, ad_fec_proceso, lk_desc_libro, 'D',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_tot_dis_sol, ln_tot_dis_dol ) ;
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
            imp_movsol, imp_movdol )
          values (
            as_origen, lk_libro_gra, ln_provisional, ln_item,
            ls_cuenta_haber, ad_fec_proceso, lk_desc_libro, 'H',
            lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
            ln_tot_dis_sol, ln_tot_dis_dol ) ;
        end if ;

      end if ;
    
    end loop ;
  
    fetch c_maestro into rc_mae ;
  
  end loop ;

  --  Actualiza nuevo numero provisional
  update cntbl_libro
    set num_provisional = ln_provisional
    where nro_libro = lk_libro_gra ;

  --  Actualiza importes del registro de cabebcera
  ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
  ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_soldeb, ln_total_doldeb
    from cntbl_pre_asiento_det d
    where d.origen = as_origen and d.nro_libro = lk_libro_gra and
          d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
          d.flag_debhab = 'D' ;
  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_solhab, ln_total_dolhab
    from cntbl_pre_asiento_det d
    where d.origen = as_origen and d.nro_libro = lk_libro_gra and
          d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
          d.flag_debhab = 'H' ;
  
  update cntbl_pre_asiento
    set tot_soldeb = ln_total_soldeb ,
        tot_solhab = ln_total_solhab ,
        tot_doldeb = ln_total_doldeb ,
        tot_dolhab = ln_total_dolhab
    where origen = as_origen and nro_libro = lk_libro_gra and
          nro_provisional = ln_provisional and fec_cntbl = ad_fec_proceso ;

end loop ;

end usp_gen_asi_prov_gra ;
/
