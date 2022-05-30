create or replace procedure usp_rh_asiento_planilla (
  as_tipo_trabajador in char,
  as_origen          in char,
  as_usuario         in char,
  ad_fec_proceso     in date
) is

lk_empleado         constant char(3)   := 'EMP' ;
lk_obrero           constant char(3)   := 'OBR' ;
lk_nro_horas        constant number(3) := 240 ;

--ld_fec_inicio       date ;
ld_fec_desde        date ;
ld_fec_hasta        date ;
ls_concepto_ing     char(4) ;
ls_concepto_des     char(4) ;
ls_concepto_pag     char(4) ;
ls_concepto_apo     char(4) ;
ln_contador         integer ;
ln_distribucion     integer ;
ln_sw               integer ;
ln_verifica         integer ;
ln_item             number(6) ;
ln_nro_libro        number(3) ;
ls_desc_libro       varchar2(60) ;
ln_provisional      number(10) ;
ln_tipo_cambio      number(7,3) ;
ls_tipo_doc         char(4) ;
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

--  Personal activo para generacion de asientos
cursor c_maestro is
  select m.cod_trabajador, m.cencos, m.cod_seccion
  from maestro m
  where m.tipo_trabajador = as_tipo_trabajador
    and m.cod_origen      = as_origen
  order by m.cod_seccion, m.cencos, m.cod_trabajador ;

rc_mae c_maestro%rowtype ;

--  Lectura del calculo de la planilla por trabajador
cursor c_calculo is
  select c.concep, c.imp_soles, c.imp_dolar
  from calculo c
  where c.cod_trabajador = ls_codigo
    and trunc(c.fec_proceso) = trunc(ad_fec_proceso)
    and nvl(c.imp_soles,0) <> 0
    and c.concep <> ls_concepto_ing
    and c.concep <> ls_concepto_des
    and c.concep <> ls_concepto_apo
  order by c.cod_trabajador, c.concep ;

--  Lectura del Historio de calculo de la planilla por trabajador
cursor c_hist_calculo is
  select c.concep, c.imp_soles, c.imp_dolar
  from historico_calculo c
  where c.cod_trabajador = ls_codigo
    and trunc(c.FEC_CALC_PLAN) = trunc(ad_fec_proceso)
    and nvl(c.imp_soles,0) <> 0
    and c.concep <> ls_concepto_ing
    and c.concep <> ls_concepto_des
    and c.concep <> ls_concepto_apo
  order by c.cod_trabajador, c.concep ;

--  Lectura para generar asientos de la distribucion contable
cursor c_distribucion is
  select d.cod_trabajador, d.cencos, d.cod_labor, d.nro_horas
  from distribucion_cntble d
  where d.cod_trabajador = ls_codigo
    and trunc(d.fec_movimiento) between trunc(ld_fec_desde) and trunc(ld_fec_hasta)
  order by d.cod_trabajador, d.cencos, d.cod_labor ;

rc_dis c_distribucion%rowtype ;

begin

--  ***************************************************************
--  ***   GENERA ASIENTO CONTABLES POR PAGOS DE REMUNERACIONES  ***
--  ***************************************************************

select p.fec_inicio, p.fec_final
  into ld_fec_desde, ld_fec_hasta
  from rrhh_param_org p
  where p.origen = as_origen ;
  
select p.cnc_total_ing, p.cnc_total_dsct,
       p.cnc_total_pgd, p.cnc_total_aport
  into ls_concepto_ing, ls_concepto_des,
       ls_concepto_pag, ls_concepto_apo
  from rrhhparam p
 where p.reckey = '1' ;

--  Determina numero y descripcion del libro contable
if as_tipo_trabajador = lk_empleado then
   select t.libro_planilla
     into ln_nro_libro
     from tipo_trabajador t
    where t.tipo_trabajador = lk_empleado ;
elsif as_tipo_trabajador = lk_obrero then
   select t.libro_planilla
     into ln_nro_libro
     from tipo_trabajador t
    where t.tipo_trabajador = lk_obrero ;
end if ;

select cl.desc_libro
  into ls_desc_libro
  from cntbl_libro cl
 where cl.nro_libro = ln_nro_libro ;

/*ld_fec_inicio := to_date('01'||'/'||to_char(ad_fec_proceso,'MM')||'/'||
                 to_char(ad_fec_proceso,'YYYY'),'DD/MM/YYYY') ;
*/
--  Elimina movimiento de asiento contable generado
usp_cnt_borrar_pre_asiento( as_origen, ln_nro_libro, ad_fec_proceso, ad_fec_proceso ) ;

--  Determina tipo de cambio a la fecha de proceso
ln_contador    := 0 ;
ln_tipo_cambio := 1 ;
select count(*)
  into ln_contador
  from calendario cal
 where trunc(cal.fecha) = trunc(ad_fec_proceso);

if ln_contador > 0 then
   select nvl(cal.vta_dol_prom,1)
     into ln_tipo_cambio
     from calendario cal
    where trunc(cal.fecha) = trunc(ad_fec_proceso);
end if ;

--  ******************************************************************
--  ***   LECTURA DE TRABAJADORES PARA LA GENERACION DEL ASIENTO   ***
--  ******************************************************************
open c_maestro ;
fetch c_maestro into rc_mae ;
while c_maestro%found loop

  --  Determina numero provisional
  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from cntbl_libro l
   where l.nro_libro = ln_nro_libro ;

  if ln_contador = 0 then
     ln_provisional := 1 ;
     insert into cntbl_libro ( nro_libro, desc_libro, num_provisional, flag_replicacion )
     values ( ln_nro_libro, substr(ls_desc_libro,1,40), ln_provisional, '1' ) ;
  else
     select nvl(l.num_provisional,0)
       into ln_provisional
       from cntbl_libro l
      where l.nro_libro = ln_nro_libro ;
     ln_provisional := ln_provisional + 1 ;
  end if ;

  --  Adiciona registro de cabecera del pre asiento
  insert into cntbl_pre_asiento (
    origen, nro_libro, nro_provisional, cod_moneda, tasa_cambio,
    desc_glosa, fec_cntbl, fec_registro, cod_usr, flag_estado,
    tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab, flag_replicacion )
  values (
    as_origen, ln_nro_libro, ln_provisional, 'S/.', ln_tipo_cambio,
    ls_desc_libro, ad_fec_proceso, ad_fec_proceso, as_usuario, '1',
    0, 0, 0, 0, '1' ) ;

  ln_item := 0 ; ls_seccion := rc_mae.cod_seccion ;
  -- Genera un asiento contable por seecion
  while rc_mae.cod_seccion = ls_seccion and c_maestro%found loop

    ls_codigo := rc_mae.cod_trabajador ;
    ls_cencos := rc_mae.cencos ;

    --  Verifica que existan horas distribuidas por trabajador
    ln_contador := 0 ; ln_distribucion := 0 ;
    if as_tipo_trabajador = lk_obrero and (substr(ls_cencos,1,1) = '3' or
       substr(ls_cencos,1,5) = '84111') then
       select count(*)
         into ln_contador
         from distribucion_cntble dc
        where dc.cod_trabajador = ls_codigo
          and trunc(dc.fec_movimiento) between trunc(ld_fec_desde) and trunc(ld_fec_hasta) ;

       if ln_contador > 0 then
          ln_distribucion := 1 ;
       end if ;
    end if ;

    --  *************************************************************
    --  ***   VERIFICO SI LA FECHA DE PROCESO SE ENCUENTA EN LA TABLA
    --  ***   CALCULO SINO LO BUSCO EN LA TABLA HISTORICO DE CALCULO
    --  *************************************************************
    select count(*)
      into ln_verifica
      from calculo c
     where c.cod_trabajador = ls_codigo
       and trunc(c.fec_proceso) = trunc(ad_fec_proceso)
       and nvl(c.imp_soles,0) <> 0
       and c.concep <> ls_concepto_ing
       and c.concep <> ls_concepto_des
       and c.concep <> ls_concepto_apo;

    if ln_verifica > 0 then
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
               ln_verifica := 0 ;
               select count(*)
                 into ln_verifica
                 from concepto_tip_trab_cnta c
                where c.concep = ls_concepto
                  and c.tipo_trabajador = as_tipo_trabajador ;

               if ln_verifica > 0 then
                  select nvl(c.cnta_cntbl_debe,' '), nvl(c.cnta_cntbl_haber,' ')
                    into ls_cuenta_debe, ls_cuenta_haber
                    from concepto_tip_trab_cnta c
                   where c.concep = ls_concepto
                     and c.tipo_trabajador = as_tipo_trabajador ;
               else
                  raise_application_error( -20000, 'Concepto' || ' ' ||ls_concepto || ' ' || 'No tiene Cuentas Contables') ;
               end if ;

               if ls_cuenta_debe <> ' ' then
                  if substr(ls_cuenta_debe,1,1) = '9' then
                     ln_contador := 0 ;
                     select count(*)
                       into ln_contador
                       from centros_costo c
                       where c.cencos = ls_cencos ;

                     if ln_contador > 0 then
                        select nvl(c.grp_cntbl,' ')
                          into ls_grupo
                          from centros_costo c
                         where c.cencos = ls_cencos ;

                        ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
                        ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                          from cntbl_cnta c
                         where c.cnta_ctbl = ls_cuenta_debe ;

                        if ln_verifica = 0 then
                           raise_application_error( -20002, 'Cuenta' || ' ' ||ls_cuenta_debe || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                        end if ;
                     end if ;
                  end if ;

                  select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                    into ls_flag_cc, ls_flag_cr
                    from cntbl_cnta cta
                   where cta.cnta_ctbl = ls_cuenta_debe ;

                  if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                  else ls_ind_cencos := ls_cencos ; end if ;
    --
                  if ls_flag_cr <> '1' then
                     ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                  else
                     ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                     select count(*)
                       into ln_verifica
                       from cnta_crrte cc,
                            cnta_crrte_detalle d
                      where cc.cod_trabajador = d.cod_trabajador
                        and cc.tipo_doc = d.tipo_doc
                        and cc.nro_doc = d.nro_doc
                        and cc.concep = ls_concepto
                        and cc.cod_trabajador = ls_codigo
                        and cc.flag_estado = '1'
                        and trunc(d.fec_dscto) = trunc(ad_fec_proceso);

                     if ln_verifica > 0 then
                        select cc.tipo_doc, cc.nro_doc
                          into ls_tipo_doc, ls_nro_doc
                          from cnta_crrte cc,
                               cnta_crrte_detalle d
                         where cc.cod_trabajador = d.cod_trabajador
                           and cc.tipo_doc = d.tipo_doc
                           and cc.nro_doc = d.nro_doc
                           and cc.concep = ls_concepto
                           and cc.cod_trabajador = ls_codigo
                           and cc.flag_estado = '1'
                           and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                     end if ;
                  end if ;
    --
                  ls_flag_dh := 'D' ;
                  if ln_sw = 1 then ls_flag_dh := 'H' ; end if ;
                  ln_item := ln_item + 1 ;
                  insert into cntbl_pre_asiento_det (
                         origen, nro_libro, nro_provisional, item,
                         cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                         tipo_docref, nro_docref1, cencos, cod_relacion,
                         imp_movsol, imp_movdol, flag_replicacion )
                  values (
                         as_origen, ln_nro_libro, ln_provisional, ln_item,
                         ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                         ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                         ln_imp_soles, ln_imp_dolar, '1' ) ;
               end if ;

               if ls_cuenta_haber <> ' ' then
                  if substr(ls_cuenta_haber,1,1) = '9' then
                     ln_contador := 0 ;
                     select count(*)
                       into ln_contador
                       from centros_costo c
                      where c.cencos = ls_cencos ;

                     if ln_contador > 0 then
                        select nvl(c.grp_cntbl,' ')
                          into ls_grupo
                          from centros_costo c
                         where c.cencos = ls_cencos ;

                        ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
                        ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                          from cntbl_cnta c
                         where c.cnta_ctbl = ls_cuenta_haber ;

                        if ln_verifica = 0 then
                           raise_application_error( -20003, 'Cuenta' || ' ' ||ls_cuenta_haber || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                        end if ;
                     end if ;
                  end if ;
                  select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                    into ls_flag_cc, ls_flag_cr
                    from cntbl_cnta cta
                   where cta.cnta_ctbl = ls_cuenta_haber ;

                  if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                  else ls_ind_cencos := ls_cencos ; end if ;
    --
                  if ls_flag_cr <> '1' then
                     ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                  else
                     ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                     select count(*)
                       into ln_verifica
                       from cnta_crrte cc,
                            cnta_crrte_detalle d
                      where cc.cod_trabajador = d.cod_trabajador
                        and cc.tipo_doc = d.tipo_doc
                        and cc.nro_doc = d.nro_doc
                        and cc.concep = ls_concepto
                        and cc.cod_trabajador = ls_codigo
                        and cc.flag_estado = '1'
                        and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                     if ln_verifica > 0 then
                        select cc.tipo_doc, cc.nro_doc
                          into ls_tipo_doc, ls_nro_doc
                          from cnta_crrte cc,
                               cnta_crrte_detalle d
                         where cc.cod_trabajador = d.cod_trabajador
                           and cc.tipo_doc = d.tipo_doc
                           and cc.nro_doc = d.nro_doc
                           and cc.concep = ls_concepto
                           and cc.cod_trabajador = ls_codigo
                           and cc.flag_estado = '1'
                           and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                     end if ;
                  end if ;
    --
                  ls_flag_dh := 'H' ;
                  if ln_sw = 1 then ls_flag_dh := 'D' ; end if ;
                  ln_item := ln_item + 1 ;
                  insert into cntbl_pre_asiento_det (
                         origen, nro_libro, nro_provisional, item,
                         cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                         tipo_docref, nro_docref1, cencos, cod_relacion,
                         imp_movsol, imp_movdol, imp_movaju, flag_replicacion )
                  values (
                         as_origen, ln_nro_libro, ln_provisional, ln_item,
                         ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                         ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                         ln_imp_soles, ln_imp_dolar, 0, '1' ) ;
               end if ;

            end if ;

            --  Genera asiento con distribucion de horas trabajadas
            if ln_distribucion = 1 then
               ln_verifica := 0 ;
               select count(*)
                 into ln_verifica
                 from concepto_tip_trab_cnta c
                where c.concep = ls_concepto
                  and c.tipo_trabajador = as_tipo_trabajador ;

               if ln_verifica > 0 then
                  select nvl(c.cnta_cntbl_debe,' '), nvl(c.cnta_cntbl_haber,' ')
                    into ls_cuenta_debe, ls_cuenta_haber
                    from concepto_tip_trab_cnta c
                   where c.concep = ls_concepto
                     and c.tipo_trabajador = as_tipo_trabajador ;
               else
                  raise_application_error( -20001, 'Concepto' || ' ' ||ls_concepto || ' ' || 'No tiene Cuentas Contables') ;
               end if ;
               if ls_cuenta_debe <> ' ' then
                  ls_flag_dh := 'D' ;
                  if ln_sw = 1 then ls_flag_dh := 'H' ; end if ;
                  if substr(ls_cuenta_debe,1,1) <> '9' then
                     select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                       into ls_flag_cc, ls_flag_cr
                       from cntbl_cnta cta
                      where cta.cnta_ctbl = ls_cuenta_debe ;

                     if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                     else ls_ind_cencos := ls_cencos ; end if ;
    --
                     if ls_flag_cr <> '1' then
                        ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                     else
                        ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                          from cnta_crrte cc,
                               cnta_crrte_detalle d
                         where cc.cod_trabajador = d.cod_trabajador
                           and cc.tipo_doc = d.tipo_doc
                           and cc.nro_doc = d.nro_doc
                           and cc.concep = ls_concepto
                           and cc.cod_trabajador = ls_codigo
                           and cc.flag_estado = '1'
                           and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                        if ln_verifica > 0 then
                           select cc.tipo_doc, cc.nro_doc
                             into ls_tipo_doc, ls_nro_doc
                             from cnta_crrte cc,
                                  cnta_crrte_detalle d
                            where cc.cod_trabajador = d.cod_trabajador
                              and cc.tipo_doc = d.tipo_doc
                              and cc.nro_doc = d.nro_doc
                              and cc.concep = ls_concepto
                              and cc.cod_trabajador = ls_codigo
                              and cc.flag_estado = '1'
                              and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                        end if ;
                     end if ;
    --
                     ln_item := ln_item + 1 ;
                     insert into cntbl_pre_asiento_det (
                            origen, nro_libro, nro_provisional, item,
                            cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                            tipo_docref, nro_docref1, cencos, cod_relacion,
                            imp_movsol, imp_movdol, flag_replicacion )
                     values (
                            as_origen, ln_nro_libro, ln_provisional, ln_item,
                            ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                            ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                            ln_imp_soles, ln_imp_dolar, '1' ) ;
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
                         into ln_contador
                         from centros_costo c
                        where c.cencos = ls_cencos_dis ;

                       if ln_contador > 0 then
                          select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                            into ls_flag_cp, ls_grupo
                            from centros_costo c
                           where c.cencos = ls_cencos_dis ;

                          ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
                          ln_verifica := 0 ;
                          select count(*)
                            into ln_verifica
                            from cntbl_cnta c
                           where c.cnta_ctbl = ls_cuenta_debe ;

                          if ln_verifica = 0 then
                             raise_application_error( -20004, 'Cuenta' || ' ' ||ls_cuenta_debe || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos_dis) ;
                          end if ;
                       end if ;

                       select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                         into ls_flag_cc, ls_flag_cr
                         from cntbl_cnta cta
                        where cta.cnta_ctbl = ls_cuenta_debe ;

                       if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                       else ls_ind_cencos := ls_cencos_dis ; end if ;
    --
                       if ls_flag_cr <> '1' then
                          ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                       else
                          ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                          select count(*)
                            into ln_verifica
                            from cnta_crrte cc,
                                 cnta_crrte_detalle d
                           where cc.cod_trabajador = d.cod_trabajador
                             and cc.tipo_doc = d.tipo_doc
                             and cc.nro_doc = d.nro_doc
                             and cc.concep = ls_concepto
                             and cc.cod_trabajador = ls_codigo
                             and cc.flag_estado = '1'
                             and trunc(d.fec_dscto) = trunc(ad_fec_proceso);

                          if ln_verifica > 0 then
                             select cc.tipo_doc, cc.nro_doc
                               into ls_tipo_doc, ls_nro_doc
                               from cnta_crrte cc,
                                    cnta_crrte_detalle d
                              where cc.cod_trabajador = d.cod_trabajador
                                and cc.tipo_doc = d.tipo_doc
                                and cc.nro_doc = d.nro_doc
                                and cc.concep = ls_concepto
                                and cc.cod_trabajador = ls_codigo
                                and cc.flag_estado = '1'
                                and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                          end if ;
                       end if ;
    --
                       insert into cntbl_pre_asiento_det (
                              origen, nro_libro, nro_provisional, item,
                              cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                              tipo_docref, nro_docref1, cencos, cod_relacion,
                              imp_movsol, imp_movdol, flag_replicacion )
                       values (
                              as_origen, ln_nro_libro, ln_provisional, ln_item,
                              ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                              ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                              ln_imp_dis_sol, ln_imp_dis_dol, '1' ) ;
                       if ls_flag_cp = '1' then
                          ln_verifica := 0 ;
                          select count(*)
                            into ln_verifica
                            from labor l
                           where l.cod_labor = ls_labor_dis ;

                          if ln_verifica > 0 then
                             select nvl(l.cnta_prsp,' ')
                               into ls_cnta_prsp
                               from labor l
                              where l.cod_labor = ls_labor_dis ;
                          else
                             raise_application_error( -20008, 'Labor' || ' ' ||ls_labor_dis || ' ' || 'No Tiene Cuenta Presupuestal') ;
                          end if ;
                          insert into cntbl_pre_asiento_det_aux (
                                 origen, nro_libro, nro_provisional, item, cnta_prsp, flag_replicacion )
                          values (
                                 as_origen, ln_nro_libro, ln_provisional, ln_item, ls_cnta_prsp, '1' ) ;
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
                          into ln_contador
                          from centros_costo c
                         where c.cencos = ls_cencos ;

                        if ln_contador > 0 then
                           select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                             into ls_flag_cp, ls_grupo
                             from centros_costo c
                            where c.cencos = ls_cencos ;

                           ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
                           ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from cntbl_cnta c
                            where c.cnta_ctbl = ls_cuenta_debe ;

                           if ln_verifica = 0 then
                              raise_application_error( -20005, 'Cuenta' || ' ' ||ls_cuenta_debe || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                           end if ;
                        end if ;
                        select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                          into ls_flag_cc, ls_flag_cr
                          from cntbl_cnta cta
                         where cta.cnta_ctbl = ls_cuenta_debe ;

                        if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                        else ls_ind_cencos := ls_cencos ; end if ;
    --
                        if ls_flag_cr <> '1' then
                           ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                        else
                           ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from cnta_crrte cc,
                                  cnta_crrte_detalle d
                            where cc.cod_trabajador = d.cod_trabajador
                              and cc.tipo_doc = d.tipo_doc
                              and cc.nro_doc = d.nro_doc
                              and cc.concep = ls_concepto
                              and cc.cod_trabajador = ls_codigo
                              and cc.flag_estado = '1'
                              and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                           if ln_verifica > 0 then
                              select cc.tipo_doc, cc.nro_doc
                                into ls_tipo_doc, ls_nro_doc
                                from cnta_crrte cc,
                                     cnta_crrte_detalle d
                               where cc.cod_trabajador = d.cod_trabajador
                                 and cc.tipo_doc = d.tipo_doc
                                 and cc.nro_doc = d.nro_doc
                                 and cc.concep = ls_concepto
                                 and cc.cod_trabajador = ls_codigo
                                 and cc.flag_estado = '1'
                                 and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                           end if ;
                        end if ;
    --
                        insert into cntbl_pre_asiento_det (
                               origen, nro_libro, nro_provisional, item,
                               cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                               tipo_docref, nro_docref1, cencos, cod_relacion,
                               imp_movsol, imp_movdol, flag_replicacion )
                        values (
                               as_origen, ln_nro_libro, ln_provisional, ln_item,
                               ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                               ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                               ln_tot_dis_sol, ln_tot_dis_dol, '1' ) ;
                     end if ;
                  end if ;
               end if ;

               if ls_cuenta_haber <> ' ' then
                  ls_flag_dh := 'H' ;
                  if ln_sw = 1 then ls_flag_dh := 'D' ; end if ;

                  if substr(ls_cuenta_haber,1,1) <> '9' then
                     select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                       into ls_flag_cc, ls_flag_cr
                       from cntbl_cnta cta
                      where cta.cnta_ctbl = ls_cuenta_haber ;

                     if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                     else ls_ind_cencos := ls_cencos ; end if ;
    --
                     if ls_flag_cr <> '1' then
                        ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                     else
                        ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                           from cnta_crrte cc,
                                cnta_crrte_detalle d
                          where cc.cod_trabajador = d.cod_trabajador
                            and cc.tipo_doc = d.tipo_doc
                            and cc.nro_doc = d.nro_doc
                            and cc.concep = ls_concepto
                            and cc.cod_trabajador = ls_codigo
                            and cc.flag_estado = '1'
                            and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                         if ln_verifica > 0 then
                            select cc.tipo_doc, cc.nro_doc
                              into ls_tipo_doc, ls_nro_doc
                              from cnta_crrte cc,
                                   cnta_crrte_detalle d
                             where cc.cod_trabajador = d.cod_trabajador
                               and cc.tipo_doc = d.tipo_doc
                               and cc.nro_doc = d.nro_doc
                               and cc.concep = ls_concepto
                               and cc.cod_trabajador = ls_codigo
                               and cc.flag_estado = '1'
                               and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                         end if ;
                      end if ;
    --
                      ln_item := ln_item + 1 ;
                      insert into cntbl_pre_asiento_det (
                             origen, nro_libro, nro_provisional, item,
                             cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                             tipo_docref, nro_docref1, cencos, cod_relacion,
                             imp_movsol, imp_movdol, imp_movaju, flag_replicacion )
                      values (
                             as_origen, ln_nro_libro, ln_provisional, ln_item,
                             ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                             ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                             ln_imp_soles, ln_imp_dolar, 0, '1' ) ;
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
                          into ln_contador
                          from centros_costo c
                         where c.cencos = ls_cencos_dis ;
                        if ln_contador > 0 then
                           select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                             into ls_flag_cp, ls_grupo
                             from centros_costo c
                            where c.cencos = ls_cencos_dis ;

                            ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
                            ln_verifica := 0 ;
                            select count(*)
                              into ln_verifica
                              from cntbl_cnta c
                             where c.cnta_ctbl = ls_cuenta_haber ;

                            if ln_verifica = 0 then
                               raise_application_error( -20006, 'Cuenta' || ' ' ||ls_cuenta_haber || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos_dis) ;
                            end if ;
                        end if ;

                        select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                          into ls_flag_cc, ls_flag_cr
                          from cntbl_cnta cta
                         where cta.cnta_ctbl = ls_cuenta_haber ;

                        if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                        else ls_ind_cencos := ls_cencos_dis ; end if ;
    --
                        if ls_flag_cr <> '1' then
                           ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                        else
                           ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from cnta_crrte cc,
                                  cnta_crrte_detalle d
                            where cc.cod_trabajador = d.cod_trabajador
                              and cc.tipo_doc = d.tipo_doc
                              and cc.nro_doc = d.nro_doc
                              and cc.concep = ls_concepto
                              and cc.cod_trabajador = ls_codigo
                              and cc.flag_estado = '1'
                              and trunc(d.fec_dscto) = trunc(ad_fec_proceso);

                           if ln_verifica > 0 then
                              select cc.tipo_doc, cc.nro_doc
                                into ls_tipo_doc, ls_nro_doc
                                from cnta_crrte cc,
                                     cnta_crrte_detalle d
                               where cc.cod_trabajador = d.cod_trabajador
                                 and cc.tipo_doc = d.tipo_doc
                                 and cc.nro_doc = d.nro_doc
                                 and cc.concep = ls_concepto
                                 and cc.cod_trabajador = ls_codigo
                                 and cc.flag_estado = '1'
                                 and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                           end if ;
                        end if ;
    --
                        insert into cntbl_pre_asiento_det (
                               origen, nro_libro, nro_provisional, item,
                               cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                               tipo_docref, nro_docref1, cencos, cod_relacion,
                               imp_movsol, imp_movdol, flag_replicacion )
                        values (
                               as_origen, ln_nro_libro, ln_provisional, ln_item,
                               ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                               ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                               ln_imp_dis_sol, ln_imp_dis_dol, '1' ) ;

                        if ls_flag_cp = '1' then
                           ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from labor l
                            where l.cod_labor = ls_labor_dis ;
                           if ln_verifica > 0 then
                              select nvl(l.cnta_prsp,' ')
                                into ls_cnta_prsp
                                from labor l
                               where l.cod_labor = ls_labor_dis ;
                           else
                              raise_application_error( -20009, 'Labor' || ' ' ||ls_labor_dis || ' ' || 'No Tiene Cuenta Presupuestal') ;
                           end if ;
                           insert into cntbl_pre_asiento_det_aux (
                                  origen, nro_libro, nro_provisional, item, cnta_prsp,
                                  flag_replicacion )
                           values (
                                  as_origen, ln_nro_libro, ln_provisional, ln_item, ls_cnta_prsp,
                                  '1' ) ;
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
                           into ln_contador
                           from centros_costo c
                          where c.cencos = ls_cencos ;
                         if ln_contador > 0 then
                            select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                              into ls_flag_cp, ls_grupo
                              from centros_costo c
                             where c.cencos = ls_cencos ;
                            ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
                            ln_verifica := 0 ;
                            select count(*)
                              into ln_verifica
                              from cntbl_cnta c
                             where c.cnta_ctbl = ls_cuenta_haber ;
                            if ln_verifica = 0 then
                               raise_application_error( -20007, 'Cuenta' || ' ' ||ls_cuenta_haber || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                            end if ;
                         end if ;
                         select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                          into ls_flag_cc, ls_flag_cr
                          from cntbl_cnta cta
                         where cta.cnta_ctbl = ls_cuenta_haber ;

                         if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                         else ls_ind_cencos := ls_cencos ; end if ;
    --
                         if ls_flag_cr <> '1' then
                            ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                         else
                            ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                            select count(*)
                              into ln_verifica
                              from cnta_crrte cc,
                                   cnta_crrte_detalle d
                             where cc.cod_trabajador = d.cod_trabajador
                               and cc.tipo_doc = d.tipo_doc
                               and cc.nro_doc = d.nro_doc
                               and cc.concep = ls_concepto
                               and cc.cod_trabajador = ls_codigo
                               and cc.flag_estado = '1'
                               and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                            if ln_verifica > 0 then
                               select cc.tipo_doc, cc.nro_doc
                                 into ls_tipo_doc, ls_nro_doc
                                 from cnta_crrte cc,
                                      cnta_crrte_detalle d
                                where cc.cod_trabajador = d.cod_trabajador
                                  and cc.tipo_doc = d.tipo_doc
                                  and cc.nro_doc = d.nro_doc
                                  and cc.concep = ls_concepto
                                  and cc.cod_trabajador = ls_codigo
                                  and cc.flag_estado = '1'
                                  and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                            end if ;
                         end if ;
    --
                         ln_item := ln_item + 1 ;
                         insert into cntbl_pre_asiento_det (
                                origen, nro_libro, nro_provisional, item,
                                cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                                tipo_docref, nro_docref1, cencos, cod_relacion,
                                imp_movsol, imp_movdol, flag_replicacion )
                         values (
                               as_origen, ln_nro_libro, ln_provisional, ln_item,
                               ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                               ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                               ln_tot_dis_sol, ln_tot_dis_dol, '1' ) ;
                      end if ;
                  end if ;
               end if ;
            end if ;
        end loop ;
     else
       --  *************************************************************
       --  ***   LECTURA DEL CALCULO DE LA PLANILLA POR TRABAJADOR   ***
       --  *************************************************************

        for rc_hist in c_hist_calculo loop

            ls_concepto  := rc_hist.concep ;
            ln_imp_soles := nvl(rc_hist.imp_soles,0) ;
            ln_imp_dolar := nvl(rc_hist.imp_dolar,0) ;

            ln_sw := 0 ;
            if ln_imp_soles < 0 and ln_imp_dolar < 0 then
               ln_imp_soles := ln_imp_soles * -1 ;
               ln_imp_dolar := ln_imp_dolar * -1 ;
               ln_sw        := 1 ;
            end if ;

            --  Genera asientos sin distribucion de horas trabajadas
            if ln_distribucion = 0 then
               ln_verifica := 0 ;
               select count(*)
                 into ln_verifica
                 from concepto_tip_trab_cnta c
                where c.concep = ls_concepto
                  and c.tipo_trabajador = as_tipo_trabajador ;

               if ln_verifica > 0 then
                  select nvl(c.cnta_cntbl_debe,' '), nvl(c.cnta_cntbl_haber,' ')
                    into ls_cuenta_debe, ls_cuenta_haber
                    from concepto_tip_trab_cnta c
                   where c.concep = ls_concepto
                     and c.tipo_trabajador = as_tipo_trabajador ;
               else
                  raise_application_error( -20000, 'Concepto' || ' ' ||ls_concepto || ' ' || 'No tiene Cuentas Contables') ;
               end if ;

               if ls_cuenta_debe <> ' ' then
                  if substr(ls_cuenta_debe,1,1) = '9' then
                     ln_contador := 0 ;
                     select count(*)
                       into ln_contador
                       from centros_costo c
                       where c.cencos = ls_cencos ;

                     if ln_contador > 0 then
                        select nvl(c.grp_cntbl,' ')
                          into ls_grupo
                          from centros_costo c
                         where c.cencos = ls_cencos ;

                        ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
                        ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                          from cntbl_cnta c
                         where c.cnta_ctbl = ls_cuenta_debe ;

                        if ln_verifica = 0 then
                           raise_application_error( -20002, 'Cuenta' || ' ' ||ls_cuenta_debe || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                        end if ;
                     end if ;
                  end if ;

                  select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                    into ls_flag_cc, ls_flag_cr
                    from cntbl_cnta cta
                   where cta.cnta_ctbl = ls_cuenta_debe ;

                  if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                  else ls_ind_cencos := ls_cencos ; end if ;
    --
                  if ls_flag_cr <> '1' then
                     ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                  else
                     ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                     select count(*)
                       into ln_verifica
                       from cnta_crrte cc,
                            cnta_crrte_detalle d
                      where cc.cod_trabajador = d.cod_trabajador
                        and cc.tipo_doc = d.tipo_doc
                        and cc.nro_doc = d.nro_doc
                        and cc.concep = ls_concepto
                        and cc.cod_trabajador = ls_codigo
                        and cc.flag_estado = '1'
                        and trunc(d.fec_dscto) = trunc(ad_fec_proceso);

                     if ln_verifica > 0 then
                        select cc.tipo_doc, cc.nro_doc
                          into ls_tipo_doc, ls_nro_doc
                          from cnta_crrte cc,
                               cnta_crrte_detalle d
                         where cc.cod_trabajador = d.cod_trabajador
                           and cc.tipo_doc = d.tipo_doc
                           and cc.nro_doc = d.nro_doc
                           and cc.concep = ls_concepto
                           and cc.cod_trabajador = ls_codigo
                           and cc.flag_estado = '1'
                           and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                     end if ;
                  end if ;
    --
                  ls_flag_dh := 'D' ;
                  if ln_sw = 1 then ls_flag_dh := 'H' ; end if ;
                  ln_item := ln_item + 1 ;
                  insert into cntbl_pre_asiento_det (
                         origen, nro_libro, nro_provisional, item,
                         cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                         tipo_docref, nro_docref1, cencos, cod_relacion,
                         imp_movsol, imp_movdol, flag_replicacion )
                  values (
                         as_origen, ln_nro_libro, ln_provisional, ln_item,
                         ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                         ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                         ln_imp_soles, ln_imp_dolar, '1' ) ;
               end if ;

               if ls_cuenta_haber <> ' ' then
                  if substr(ls_cuenta_haber,1,1) = '9' then
                     ln_contador := 0 ;
                     select count(*)
                       into ln_contador
                       from centros_costo c
                      where c.cencos = ls_cencos ;

                     if ln_contador > 0 then
                        select nvl(c.grp_cntbl,' ')
                          into ls_grupo
                          from centros_costo c
                         where c.cencos = ls_cencos ;

                        ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
                        ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                          from cntbl_cnta c
                         where c.cnta_ctbl = ls_cuenta_haber ;

                        if ln_verifica = 0 then
                           raise_application_error( -20003, 'Cuenta' || ' ' ||ls_cuenta_haber || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                        end if ;
                     end if ;
                  end if ;
                  select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                    into ls_flag_cc, ls_flag_cr
                    from cntbl_cnta cta
                   where cta.cnta_ctbl = ls_cuenta_haber ;

                  if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                  else ls_ind_cencos := ls_cencos ; end if ;
    --
                  if ls_flag_cr <> '1' then
                     ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                  else
                     ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                     select count(*)
                       into ln_verifica
                       from cnta_crrte cc,
                            cnta_crrte_detalle d
                      where cc.cod_trabajador = d.cod_trabajador
                        and cc.tipo_doc = d.tipo_doc
                        and cc.nro_doc = d.nro_doc
                        and cc.concep = ls_concepto
                        and cc.cod_trabajador = ls_codigo
                        and cc.flag_estado = '1'
                        and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                     if ln_verifica > 0 then
                        select cc.tipo_doc, cc.nro_doc
                          into ls_tipo_doc, ls_nro_doc
                          from cnta_crrte cc,
                               cnta_crrte_detalle d
                         where cc.cod_trabajador = d.cod_trabajador
                           and cc.tipo_doc = d.tipo_doc
                           and cc.nro_doc = d.nro_doc
                           and cc.concep = ls_concepto
                           and cc.cod_trabajador = ls_codigo
                           and cc.flag_estado = '1'
                           and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                     end if ;
                  end if ;
    --
                  ls_flag_dh := 'H' ;
                  if ln_sw = 1 then ls_flag_dh := 'D' ; end if ;
                  ln_item := ln_item + 1 ;
                  insert into cntbl_pre_asiento_det (
                         origen, nro_libro, nro_provisional, item,
                         cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                         tipo_docref, nro_docref1, cencos, cod_relacion,
                         imp_movsol, imp_movdol, imp_movaju, flag_replicacion )
                  values (
                         as_origen, ln_nro_libro, ln_provisional, ln_item,
                         ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                         ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                         ln_imp_soles, ln_imp_dolar, 0, '1' ) ;
               end if ;

            end if ;

            --  Genera asiento con distribucion de horas trabajadas
            if ln_distribucion = 1 then
               ln_verifica := 0 ;
               select count(*)
                 into ln_verifica
                 from concepto_tip_trab_cnta c
                where c.concep = ls_concepto
                  and c.tipo_trabajador = as_tipo_trabajador ;

               if ln_verifica > 0 then
                  select nvl(c.cnta_cntbl_debe,' '), nvl(c.cnta_cntbl_haber,' ')
                    into ls_cuenta_debe, ls_cuenta_haber
                    from concepto_tip_trab_cnta c
                   where c.concep = ls_concepto
                     and c.tipo_trabajador = as_tipo_trabajador ;
               else
                  raise_application_error( -20001, 'Concepto' || ' ' ||ls_concepto || ' ' || 'No tiene Cuentas Contables') ;
               end if ;

               if ls_cuenta_debe <> ' ' then
                  ls_flag_dh := 'D' ;
                  if ln_sw = 1 then ls_flag_dh := 'H' ; end if ;
                  if substr(ls_cuenta_debe,1,1) <> '9' then
                     select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                       into ls_flag_cc, ls_flag_cr
                       from cntbl_cnta cta
                      where cta.cnta_ctbl = ls_cuenta_debe ;

                     if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                     else ls_ind_cencos := ls_cencos ; end if ;
    --
                     if ls_flag_cr <> '1' then
                        ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                     else
                        ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                          from cnta_crrte cc,
                               cnta_crrte_detalle d
                         where cc.cod_trabajador = d.cod_trabajador
                           and cc.tipo_doc = d.tipo_doc
                           and cc.nro_doc = d.nro_doc
                           and cc.concep = ls_concepto
                           and cc.cod_trabajador = ls_codigo
                           and cc.flag_estado = '1'
                           and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                        if ln_verifica > 0 then
                           select cc.tipo_doc, cc.nro_doc
                             into ls_tipo_doc, ls_nro_doc
                             from cnta_crrte cc,
                                  cnta_crrte_detalle d
                            where cc.cod_trabajador = d.cod_trabajador
                              and cc.tipo_doc = d.tipo_doc
                              and cc.nro_doc = d.nro_doc
                              and cc.concep = ls_concepto
                              and cc.cod_trabajador = ls_codigo
                              and cc.flag_estado = '1'
                              and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                        end if ;
                     end if ;
    --
                     ln_item := ln_item + 1 ;
                     insert into cntbl_pre_asiento_det (
                            origen, nro_libro, nro_provisional, item,
                            cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                            tipo_docref, nro_docref1, cencos, cod_relacion,
                            imp_movsol, imp_movdol, flag_replicacion )
                     values (
                            as_origen, ln_nro_libro, ln_provisional, ln_item,
                            ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                            ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                            ln_imp_soles, ln_imp_dolar, '1' ) ;
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
                         into ln_contador
                         from centros_costo c
                        where c.cencos = ls_cencos_dis ;

                       if ln_contador > 0 then
                          select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                            into ls_flag_cp, ls_grupo
                            from centros_costo c
                           where c.cencos = ls_cencos_dis ;

                          ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
                          ln_verifica := 0 ;
                          select count(*)
                            into ln_verifica
                            from cntbl_cnta c
                           where c.cnta_ctbl = ls_cuenta_debe ;

                          if ln_verifica = 0 then
                             raise_application_error( -20004, 'Cuenta' || ' ' ||ls_cuenta_debe || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos_dis) ;
                          end if ;
                       end if ;

                       select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                         into ls_flag_cc, ls_flag_cr
                         from cntbl_cnta cta
                        where cta.cnta_ctbl = ls_cuenta_debe ;

                       if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                       else ls_ind_cencos := ls_cencos_dis ; end if ;
    --
                       if ls_flag_cr <> '1' then
                          ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                       else
                          ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                          select count(*)
                            into ln_verifica
                            from cnta_crrte cc,
                                 cnta_crrte_detalle d
                           where cc.cod_trabajador = d.cod_trabajador
                             and cc.tipo_doc = d.tipo_doc
                             and cc.nro_doc = d.nro_doc
                             and cc.concep = ls_concepto
                             and cc.cod_trabajador = ls_codigo
                             and cc.flag_estado = '1'
                             and trunc(d.fec_dscto) = trunc(ad_fec_proceso);

                          if ln_verifica > 0 then
                             select cc.tipo_doc, cc.nro_doc
                               into ls_tipo_doc, ls_nro_doc
                               from cnta_crrte cc,
                                    cnta_crrte_detalle d
                              where cc.cod_trabajador = d.cod_trabajador
                                and cc.tipo_doc = d.tipo_doc
                                and cc.nro_doc = d.nro_doc
                                and cc.concep = ls_concepto
                                and cc.cod_trabajador = ls_codigo
                                and cc.flag_estado = '1'
                                and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                          end if ;
                       end if ;
    --
                       insert into cntbl_pre_asiento_det (
                              origen, nro_libro, nro_provisional, item,
                              cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                              tipo_docref, nro_docref1, cencos, cod_relacion,
                              imp_movsol, imp_movdol, flag_replicacion )
                       values (
                              as_origen, ln_nro_libro, ln_provisional, ln_item,
                              ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                              ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                              ln_imp_dis_sol, ln_imp_dis_dol, '1' ) ;
                       if ls_flag_cp = '1' then
                          ln_verifica := 0 ;
                          select count(*)
                            into ln_verifica
                            from labor l
                           where l.cod_labor = ls_labor_dis ;

                          if ln_verifica > 0 then
                             select nvl(l.cnta_prsp,' ')
                               into ls_cnta_prsp
                               from labor l
                              where l.cod_labor = ls_labor_dis ;
                          else
                             raise_application_error( -20008, 'Labor' || ' ' ||ls_labor_dis || ' ' || 'No Tiene Cuenta Presupuestal') ;
                          end if ;
                          insert into cntbl_pre_asiento_det_aux (
                                 origen, nro_libro, nro_provisional, item, cnta_prsp, flag_replicacion )
                          values (
                                 as_origen, ln_nro_libro, ln_provisional, ln_item, ls_cnta_prsp, '1' ) ;
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
                          into ln_contador
                          from centros_costo c
                         where c.cencos = ls_cencos ;

                        if ln_contador > 0 then
                           select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                             into ls_flag_cp, ls_grupo
                             from centros_costo c
                            where c.cencos = ls_cencos ;

                           ls_cuenta_debe := ls_grupo||substr(ls_cuenta_debe,3,8) ;
                           ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from cntbl_cnta c
                            where c.cnta_ctbl = ls_cuenta_debe ;

                           if ln_verifica = 0 then
                              raise_application_error( -20005, 'Cuenta' || ' ' ||ls_cuenta_debe || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                           end if ;
                        end if ;
                        select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                          into ls_flag_cc, ls_flag_cr
                          from cntbl_cnta cta
                         where cta.cnta_ctbl = ls_cuenta_debe ;

                        if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                        else ls_ind_cencos := ls_cencos ; end if ;
    --
                        if ls_flag_cr <> '1' then
                           ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                        else
                           ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from cnta_crrte cc,
                                  cnta_crrte_detalle d
                            where cc.cod_trabajador = d.cod_trabajador
                              and cc.tipo_doc = d.tipo_doc
                              and cc.nro_doc = d.nro_doc
                              and cc.concep = ls_concepto
                              and cc.cod_trabajador = ls_codigo
                              and cc.flag_estado = '1'
                              and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                           if ln_verifica > 0 then
                              select cc.tipo_doc, cc.nro_doc
                                into ls_tipo_doc, ls_nro_doc
                                from cnta_crrte cc,
                                     cnta_crrte_detalle d
                               where cc.cod_trabajador = d.cod_trabajador
                                 and cc.tipo_doc = d.tipo_doc
                                 and cc.nro_doc = d.nro_doc
                                 and cc.concep = ls_concepto
                                 and cc.cod_trabajador = ls_codigo
                                 and cc.flag_estado = '1'
                                 and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                           end if ;
                        end if ;
    --
                        insert into cntbl_pre_asiento_det (
                               origen, nro_libro, nro_provisional, item,
                               cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                               tipo_docref, nro_docref1, cencos, cod_relacion,
                               imp_movsol, imp_movdol, flag_replicacion )
                        values (
                               as_origen, ln_nro_libro, ln_provisional, ln_item,
                               ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                               ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                               ln_tot_dis_sol, ln_tot_dis_dol, '1' ) ;
                     end if ;
                  end if ;
               end if ;

               if ls_cuenta_haber <> ' ' then
                  ls_flag_dh := 'H' ;
                  if ln_sw = 1 then ls_flag_dh := 'D' ; end if ;

                  if substr(ls_cuenta_haber,1,1) <> '9' then
                     select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                       into ls_flag_cc, ls_flag_cr
                       from cntbl_cnta cta
                      where cta.cnta_ctbl = ls_cuenta_haber ;

                     if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                     else ls_ind_cencos := ls_cencos ; end if ;
    --
                     if ls_flag_cr <> '1' then
                        ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                     else
                        ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                        select count(*)
                          into ln_verifica
                           from cnta_crrte cc,
                                cnta_crrte_detalle d
                          where cc.cod_trabajador = d.cod_trabajador
                            and cc.tipo_doc = d.tipo_doc
                            and cc.nro_doc = d.nro_doc
                            and cc.concep = ls_concepto
                            and cc.cod_trabajador = ls_codigo
                            and cc.flag_estado = '1'
                            and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;

                         if ln_verifica > 0 then
                            select cc.tipo_doc, cc.nro_doc
                              into ls_tipo_doc, ls_nro_doc
                              from cnta_crrte cc,
                                   cnta_crrte_detalle d
                             where cc.cod_trabajador = d.cod_trabajador
                               and cc.tipo_doc = d.tipo_doc
                               and cc.nro_doc = d.nro_doc
                               and cc.concep = ls_concepto
                               and cc.cod_trabajador = ls_codigo
                               and cc.flag_estado = '1'
                               and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                         end if ;
                      end if ;
    --
                      ln_item := ln_item + 1 ;
                      insert into cntbl_pre_asiento_det (
                             origen, nro_libro, nro_provisional, item,
                             cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                             tipo_docref, nro_docref1, cencos, cod_relacion,
                             imp_movsol, imp_movdol, imp_movaju, flag_replicacion )
                      values (
                             as_origen, ln_nro_libro, ln_provisional, ln_item,
                             ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                             ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                             ln_imp_soles, ln_imp_dolar, 0, '1' ) ;
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
                          into ln_contador
                          from centros_costo c
                         where c.cencos = ls_cencos_dis ;
                        if ln_contador > 0 then
                           select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                             into ls_flag_cp, ls_grupo
                             from centros_costo c
                            where c.cencos = ls_cencos_dis ;

                            ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
                            ln_verifica := 0 ;
                            select count(*)
                              into ln_verifica
                              from cntbl_cnta c
                             where c.cnta_ctbl = ls_cuenta_haber ;

                            if ln_verifica = 0 then
                               raise_application_error( -20006, 'Cuenta' || ' ' ||ls_cuenta_haber || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos_dis) ;
                            end if ;
                        end if ;

                        select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                          into ls_flag_cc, ls_flag_cr
                          from cntbl_cnta cta
                         where cta.cnta_ctbl = ls_cuenta_haber ;

                        if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                        else ls_ind_cencos := ls_cencos_dis ; end if ;
    --
                        if ls_flag_cr <> '1' then
                           ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                        else
                           ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from cnta_crrte cc,
                                  cnta_crrte_detalle d
                            where cc.cod_trabajador = d.cod_trabajador
                              and cc.tipo_doc = d.tipo_doc
                              and cc.nro_doc = d.nro_doc
                              and cc.concep = ls_concepto
                              and cc.cod_trabajador = ls_codigo
                              and cc.flag_estado = '1'
                              and trunc(d.fec_dscto) = trunc(ad_fec_proceso);

                           if ln_verifica > 0 then
                              select cc.tipo_doc, cc.nro_doc
                                into ls_tipo_doc, ls_nro_doc
                                from cnta_crrte cc,
                                     cnta_crrte_detalle d
                               where cc.cod_trabajador = d.cod_trabajador
                                 and cc.tipo_doc = d.tipo_doc
                                 and cc.nro_doc = d.nro_doc
                                 and cc.concep = ls_concepto
                                 and cc.cod_trabajador = ls_codigo
                                 and cc.flag_estado = '1'
                                 and trunc(d.fec_dscto) = trunc(ad_fec_proceso) ;
                           end if ;
                        end if ;
    --
                        insert into cntbl_pre_asiento_det (
                               origen, nro_libro, nro_provisional, item,
                               cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                               tipo_docref, nro_docref1, cencos, cod_relacion,
                               imp_movsol, imp_movdol, flag_replicacion )
                        values (
                               as_origen, ln_nro_libro, ln_provisional, ln_item,
                               ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                               ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                               ln_imp_dis_sol, ln_imp_dis_dol, '1' ) ;

                        if ls_flag_cp = '1' then
                           ln_verifica := 0 ;
                           select count(*)
                             into ln_verifica
                             from labor l
                            where l.cod_labor = ls_labor_dis ;
                           if ln_verifica > 0 then
                              select nvl(l.cnta_prsp,' ')
                                into ls_cnta_prsp
                                from labor l
                               where l.cod_labor = ls_labor_dis ;
                           else
                              raise_application_error( -20009, 'Labor' || ' ' ||ls_labor_dis || ' ' || 'No Tiene Cuenta Presupuestal') ;
                           end if ;
                           insert into cntbl_pre_asiento_det_aux (
                                  origen, nro_libro, nro_provisional, item, cnta_prsp,
                                  flag_replicacion )
                           values (
                                  as_origen, ln_nro_libro, ln_provisional, ln_item, ls_cnta_prsp,
                                  '1' ) ;
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
                           into ln_contador
                           from centros_costo c
                          where c.cencos = ls_cencos ;
                         if ln_contador > 0 then
                            select nvl(c.flag_cta_presup,'0'), nvl(c.grp_cntbl,' ')
                              into ls_flag_cp, ls_grupo
                              from centros_costo c
                             where c.cencos = ls_cencos ;
                            ls_cuenta_haber := ls_grupo||substr(ls_cuenta_haber,3,8) ;
                            ln_verifica := 0 ;
                            select count(*)
                              into ln_verifica
                              from cntbl_cnta c
                             where c.cnta_ctbl = ls_cuenta_haber ;
                            if ln_verifica = 0 then
                               raise_application_error( -20007, 'Cuenta' || ' ' ||ls_cuenta_haber || ' ' || 'No Existe por el Grupo Contable Para el Centro de Costo' || ' ' || ls_cencos) ;
                            end if ;
                         end if ;
                         select nvl(cta.flag_cencos,'0'), nvl(cta.flag_codrel,'0')
                          into ls_flag_cc, ls_flag_cr
                          from cntbl_cnta cta
                         where cta.cnta_ctbl = ls_cuenta_haber ;

                         if ls_flag_cc <> '1' then ls_ind_cencos := null ;
                         else ls_ind_cencos := ls_cencos ; end if ;
    --
                         if ls_flag_cr <> '1' then
                            ls_ind_codigo := null ; ls_tipo_doc := null ; ls_nro_doc := null ;
                         else
                            ls_ind_codigo := ls_codigo ; ln_verifica := 0 ;
                            select count(*)
                              into ln_verifica
                              from cnta_crrte cc,
                                   cnta_crrte_detalle d
                             where cc.cod_trabajador = d.cod_trabajador
                               and cc.tipo_doc = d.tipo_doc
                               and cc.nro_doc = d.nro_doc
                               and cc.concep = ls_concepto
                               and cc.cod_trabajador = ls_codigo
                               and cc.flag_estado = '1'
                               and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                            if ln_verifica > 0 then
                               select cc.tipo_doc, cc.nro_doc
                                 into ls_tipo_doc, ls_nro_doc
                                 from cnta_crrte cc,
                                      cnta_crrte_detalle d
                                where cc.cod_trabajador = d.cod_trabajador
                                  and cc.tipo_doc = d.tipo_doc
                                  and cc.nro_doc = d.nro_doc
                                  and cc.concep = ls_concepto
                                  and cc.cod_trabajador = ls_codigo
                                  and cc.flag_estado = '1'
                                  and trunc(d.fec_dscto) = trunc(ad_fec_proceso);
                            end if ;
                         end if ;
    --
                         ln_item := ln_item + 1 ;
                         insert into cntbl_pre_asiento_det (
                                origen, nro_libro, nro_provisional, item,
                                cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
                                tipo_docref, nro_docref1, cencos, cod_relacion,
                                imp_movsol, imp_movdol, flag_replicacion )
                         values (
                               as_origen, ln_nro_libro, ln_provisional, ln_item,
                               ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, ls_flag_dh,
                               ls_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
                               ln_tot_dis_sol, ln_tot_dis_dol, '1' ) ;
                      end if ;
                  end if ;
               end if ;
            end if ;
        end loop ;
     end if;
    fetch c_maestro into rc_mae ;
  end loop ;

  --  Actualiza nuevo numero provisional
  update cntbl_libro
     set num_provisional = ln_provisional,
         flag_replicacion = '1'
    where nro_libro = ln_nro_libro ;

  --  Actualiza importes del registro de cabebcera
  ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
  ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_soldeb, ln_total_doldeb
    from cntbl_pre_asiento_det d
    where d.origen = as_origen
      and d.nro_libro = ln_nro_libro
      and d.nro_provisional = ln_provisional
      and trunc(d.fec_cntbl) = trunc(ad_fec_proceso)
      and d.flag_debhab = 'D' ;

  select sum(d.imp_movsol), sum(d.imp_movdol)
    into ln_total_solhab, ln_total_dolhab
    from cntbl_pre_asiento_det d
    where d.origen = as_origen
      and d.nro_libro = ln_nro_libro
      and d.nro_provisional = ln_provisional
      and trunc(d.fec_cntbl) = trunc(ad_fec_proceso)
      and d.flag_debhab = 'H' ;

  update cntbl_pre_asiento
    set tot_soldeb = ln_total_soldeb ,
        tot_solhab = ln_total_solhab ,
        tot_doldeb = ln_total_doldeb ,
        tot_dolhab = ln_total_dolhab,
        flag_replicacion = '1'
  where origen = as_origen
    and nro_libro = ln_nro_libro
    and nro_provisional = ln_provisional
    and trunc(fec_cntbl) = trunc(ad_fec_proceso) ;

end loop ;

end usp_rh_asiento_planilla ;
/
