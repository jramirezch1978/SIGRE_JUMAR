create or replace procedure usp_rh_liq_rpt_asiento (
  as_cod_trabajador in char, as_nombres in char ) is

ls_cuenta_deb          char(10) ;
ls_cuenta_hab          char(10) ;
ls_flag_cc             char(1) ;
ls_flag_td             char(1) ;

ls_nro_liquidacion     char(10) ;
ld_fec_liquidacion     date ;
ls_cencos              char(10) ;
ls_cencos_rrhh         char(10) ;
ls_tiptra              char(3) ;
ls_tipo_doc            char(4) ;

ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_grp_fdoret          char(6) ;
ls_grp_cts             char(6) ;
ls_grp_comp            char(6) ;
ls_grp_dsctos          char(6) ;
ls_grp_remun           char(6) ;
ls_grp_leyes           char(6) ;
ls_grp_dscto_remun     char(6) ;
ls_grp_aportes         char(6) ;

ls_grp_asivac          char(6) ;
ls_grp_gradev          char(6) ;
ls_grp_gratru          char(6) ;
ls_grp_racazu          char(6) ;
ls_grp_remdev          char(6) ;
ls_grp_vacaci          char(6) ;
ls_grp_vactru          char(6) ;
ls_grp_indvac          char(6) ;

ls_concepto            char(4) ;
ls_cncp_fdoret         char(4) ;
ls_cncp_cts            char(4) ;
ls_cncp_intcts         char(4) ;
ls_cncp_comp           char(4) ;

ls_cncp_asivac         char(4) ;
ls_cncp_vacaci         char(4) ;
ls_cncp_gradev         char(4) ;
ls_cncp_remdev         char(4) ;
ls_cncp_racazu         char(4) ;
ls_cncp_gratif         char(4) ;
ls_cncp_indvac         char(4) ;
ls_cncp_lcl            char(4) ;
ls_cncp_vactru         char(4) ;

ls_cen                 char(10) ;
ls_cod                 char(8) ;
ls_tip                 char(4) ;
ls_nro                 char(10) ;
ls_nom                 varchar2(60) ;

ln_verifica            integer ;
ln_item                number(3) ;
ln_importe             number(13,2) ;
ln_imp_liquidacion     number(13,2) ;

--  Lectura de los grupos que forman parte de la liquidacion
cursor c_grupos is
  select d.cod_grupo, d.cod_sub_grupo
  from rh_liq_grupo c, rh_liq_grupo_det d
  where c.cod_grupo = d.cod_grupo and nvl(c.flag_estado,'0') = '1' and
        nvl(d.flag_estado,'0') = '1'
  order by c.secuencia, d.cod_sub_grupo ;

--  Lectura del grupo de pagos por remuneraciones
cursor c_remuneraciones is
  select distinct(r.cod_sub_grupo)
  from rh_liq_remuneracion r
  where r.cod_trabajador = as_cod_trabajador and r.cod_grupo = ls_grp_remun and
        r.cod_sub_grupo = ls_sub_grupo ;
  
--  Lectura del grupo de informacion con conceptos
cursor c_conceptos is
  select l.concep, l.importe
  from rh_liq_dscto_leyes_aportes l
  where l.cod_trabajador = as_cod_trabajador and l.cod_grupo = ls_grupo and
        l.cod_sub_grupo = ls_sub_grupo
  order by l.cod_trabajador, l.concep ;

--  Lectura del archivo temporal para emitir reporte
cursor c_movimiento is
  select a.cod_trabajador, a.item, a.concepto, a.importe, c.desc_concep
  from tt_liq_asiento a, concepto c
  where a.concepto = c.concep and nvl(a.importe,0) <> 0
  order by a.cod_trabajador, a.item ;
    
begin

--  **************************************************************
--  ***   GENERA REPORTE DE ASIENTO CONTABLE POR LIQUIDACION   ***
--  **************************************************************

select p.cencos_liq into ls_cencos_rrhh from rh_liqparam p
  where p.reckey = '1' ;
  
delete from tt_liq_asiento ;
delete from tt_liq_rpt_asiento ;

--  Verifica que la liquidacion haya sido aprobada
ln_verifica := 0 ;
select count(*) into ln_verifica from rh_liq_credito_laboral l, maestro m
  where l.cod_trabajador = m.cod_trabajador and l.cod_trabajador = as_cod_trabajador and
        nvl(l.flag_estado,'0') = '2' ;
if ln_verifica > 0 then  
  select l.nro_liquidacion, l.fec_liquidacion, (nvl(l.imp_liq_befef_soc,0) +
         nvl(l.imp_liq_remun,0)), m.cencos, m.tipo_trabajador
    into ls_nro_liquidacion, ld_fec_liquidacion, ln_imp_liquidacion, ls_cencos, ls_tiptra
    from rh_liq_credito_laboral l, maestro m
    where l.cod_trabajador = m.cod_trabajador and l.cod_trabajador = as_cod_trabajador and
          nvl(l.flag_estado,'0') = '2' ;
else
  raise_application_error
    ( -20000, 'La liquidación no existe o no ha sido aprobada. Por favor verificar') ;
end if ;

--  Determina datos del archivo de parametros
select p.tipo_doc, p.grp_fondo_retiro, p.grp_cts, p.grp_indemnizacion, p.grp_dscto_cta_cte,
       p.grp_remuneracion, p.grp_dscto_leyes, p.grp_dscto_remun, p.grp_aportacion,
       p.cncp_fondo_ret, p.cncp_cts, p.cncp_int_cts_abn, p.cncp_comp_dic,
       p.sgrp_asig_vac, p.sgrp_grat_dev, p.sgrp_grat_trunc, p.sgrp_racion_azucar,
       p.sgrp_remun_dev, p.sgrp_vacaciones, p.sgrp_vac_truncas, p.sgrp_indem_vac,
       p.cncp_asig_vac, p.cncp_vacaciones, p.cncp_grat_dev, p.cncp_remun_dev,
       p.cncp_racion_azucar, p.cncp_gratificacion, p.cncp_indem_vac, p.cncp_liq_cred_lab, p.cncp_vac_trunc
  into ls_tipo_doc, ls_grp_fdoret, ls_grp_cts, ls_grp_comp, ls_grp_dsctos,
       ls_grp_remun, ls_grp_leyes, ls_grp_dscto_remun, ls_grp_aportes,
       ls_cncp_fdoret, ls_cncp_cts, ls_cncp_intcts, ls_cncp_comp,
       ls_grp_asivac, ls_grp_gradev, ls_grp_gratru, ls_grp_racazu,
       ls_grp_remdev, ls_grp_vacaci, ls_grp_vactru, ls_grp_indvac,
       ls_cncp_asivac, ls_cncp_vacaci, ls_cncp_gradev, ls_cncp_remdev,
       ls_cncp_racazu, ls_cncp_gratif, ls_cncp_indvac, ls_cncp_lcl, ls_cncp_vactru
  from rh_liqparam p
  where p.reckey = '1' ;

--  Lectura de grupos de calculos de liquidacion
ln_item := 0 ;
for rc_grp in c_grupos loop

  ls_sub_grupo := rc_grp.cod_sub_grupo ;
  
  --  Grupo de fondo de retiro
  if rc_grp.cod_grupo = ls_grp_fdoret then

    ls_concepto := ls_cncp_fdoret ;
    ln_verifica := 0 ; ln_importe := 0 ;
    select count(*) into ln_verifica from rh_liq_fondo_retiro f
      where f.cod_trabajador = as_cod_trabajador ;
    if ln_verifica > 0 then  
      select sum(nvl(f.imp_x_liq_anos,0) + nvl(f.imp_x_liq_meses,0) + nvl(f.imp_x_liq_dias,0))
        into ln_importe from rh_liq_fondo_retiro f
        where f.cod_trabajador = as_cod_trabajador ;
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
    end if ;

  --  Grupo de C.T.S.
  elsif rc_grp.cod_grupo = ls_grp_cts then

    ls_concepto := ls_cncp_cts ;
    ln_verifica := 0 ; ln_importe:= 0 ;
    select count(*) into ln_verifica from rh_liq_cts c
      where c.cod_trabajador = as_cod_trabajador ;
    if ln_verifica > 0 then  
      select sum(nvl(c.deposito,0))
        into ln_importe from rh_liq_cts c
        where c.cod_trabajador = as_cod_trabajador ;
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
    end if ;

    ls_concepto := ls_cncp_intcts ;
    ln_verifica := 0 ; ln_importe:= 0 ;
    select count(*) into ln_verifica from rh_liq_cts c
      where c.cod_trabajador = as_cod_trabajador ;
    if ln_verifica > 0 then  
      select sum(nvl(c.interes,0))
        into ln_importe from rh_liq_cts c
        where c.cod_trabajador = as_cod_trabajador ;
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
    end if ;

  --  Grupo de compensacion adicional
  elsif rc_grp.cod_grupo = ls_grp_comp then

    ls_concepto := ls_cncp_comp ;
    ln_verifica := 0 ; ln_importe := 0 ;
    select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
      where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_comp ;
    if ln_verifica > 0 then
      select sum(nvl(d.importe,0)) into ln_importe from rh_liq_dscto_leyes_aportes d
        where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_comp ;
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
    end if ;  

  --  Grupo de descuentos de beneficios sociales
  elsif rc_grp.cod_grupo = ls_grp_dsctos then

    ls_grupo := rc_grp.cod_grupo ;
    for rc_con in c_conceptos loop
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, rc_con.concep, nvl(rc_con.importe,0) ) ;
    end loop ;
    
  --  Grupo de pagos de remuneraciones
  elsif rc_grp.cod_grupo = ls_grp_remun then

    for rc_rem in c_remuneraciones loop
    
      --  Sub grupo para asignacion vacacional
      if rc_rem.cod_sub_grupo = ls_grp_asivac then

        ls_concepto := ls_cncp_asivac ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_asivac ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_asivac ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      --  Sub grupo para gratificaciones devengadas
      elsif rc_rem.cod_sub_grupo = ls_grp_gradev then

        ls_concepto := ls_cncp_gradev ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_gradev ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_gradev ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      --  Sub grupo para gratificaciones truncas
      elsif rc_rem.cod_sub_grupo = ls_grp_gratru then

        ls_concepto := ls_cncp_gratif ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_gratru ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_gratru ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      --  Sub grupo para raciones de azucar
      elsif rc_rem.cod_sub_grupo = ls_grp_racazu then

        ls_concepto := ls_cncp_racazu ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_racazu ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_racazu ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      --  Sub grupo para remuneraciones devengadas
      elsif rc_rem.cod_sub_grupo = ls_grp_remdev then

        ls_concepto := ls_cncp_remdev ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_remdev ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_remdev ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      --  Sub grupo para vacaciones
      elsif rc_rem.cod_sub_grupo = ls_grp_vacaci then

        ls_concepto := ls_cncp_vacaci ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_vacaci ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_vacaci ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      --  Sub grupo para vacaciones truncas
      elsif rc_rem.cod_sub_grupo = ls_grp_vactru then

        ls_concepto := ls_cncp_vactru ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_vactru ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_vactru ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      --  Sub grupo para indemnizacion vacacional
      elsif rc_rem.cod_sub_grupo = ls_grp_indvac then

        ls_concepto := ls_cncp_indvac ;
        ln_verifica := 0 ; ln_importe := 0 ;
        select count(*) into ln_verifica from rh_liq_remuneracion r
          where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_indvac ;
        if ln_verifica > 0 then
          select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
            where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo = ls_grp_indvac ;
          ln_item := ln_item + 1 ;
          insert into tt_liq_asiento (
            cod_trabajador, item, concepto, importe )
          values (
            as_cod_trabajador, ln_item, ls_concepto, ln_importe ) ;
        end if ;

      end if ;
      
    end loop ;
    
  --  Grupo de descuentos de leyes sociales
  elsif rc_grp.cod_grupo = ls_grp_leyes then

    ls_grupo := rc_grp.cod_grupo ;
    for rc_con in c_conceptos loop
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, rc_con.concep, nvl(rc_con.importe,0) ) ;
    end loop ;
    
  --  Grupo de descuentos de remuneraciones
  elsif rc_grp.cod_grupo = ls_grp_dscto_remun then

    ls_grupo := rc_grp.cod_grupo ;
    for rc_con in c_conceptos loop
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, rc_con.concep, nvl(rc_con.importe,0) ) ;
    end loop ;
    
  --  Grupo de aportaciones sociales
  elsif rc_grp.cod_grupo = ls_grp_aportes then

    ls_grupo := rc_grp.cod_grupo ;
    for rc_con in c_conceptos loop
      ln_item := ln_item + 1 ;
      insert into tt_liq_asiento (
        cod_trabajador, item, concepto, importe )
      values (
        as_cod_trabajador, ln_item, rc_con.concep, nvl(rc_con.importe,0) ) ;
    end loop ;
    
  end if ;
    
end loop ;

--  Inserta registro del neto de la liquidacion
ln_item := ln_item + 1 ;
insert into tt_liq_asiento (
  cod_trabajador, item, concepto, importe )
values (
  as_cod_trabajador, ln_item, ls_cncp_lcl, nvl(ln_imp_liquidacion,0) ) ;


--  ************************************************************
--  ***   GENERA MOVIMIENTO PARA EMITIR REPORTE DE ASIENTO   ***
--  ************************************************************

ln_item := 0 ;
for rc_mov in c_movimiento loop

  ln_verifica := 0 ; ls_cuenta_deb := null ; ls_cuenta_hab := null ;
  select count(*) into ln_verifica from concepto_tip_trab_cnta c
    where c.concep = rc_mov.concepto and c.tipo_trabajador = ls_tiptra ;
  if ln_verifica > 0 then
    select c.cnta_cntbl_debe, c.cnta_cntbl_haber
      into ls_cuenta_deb, ls_cuenta_hab
      from concepto_tip_trab_cnta c
      where c.concep = rc_mov.concepto and c.tipo_trabajador = ls_tiptra ;
  end if ;

  if ls_cuenta_deb is not null then

    select nvl(cc.flag_cencos,'0'), nvl(cc.flag_doc_ref,'0')
      into ls_flag_cc, ls_flag_td
      from cntbl_cnta cc where cc.cnta_ctbl = ls_cuenta_deb ;
    ls_cen := null ; ls_cod := null ; ls_nom := null ;
    ls_tip := null ; ls_nro := null ;
    if ls_flag_cc = '1' then
     ls_cen := ls_cencos ;
     if rc_mov.concepto = ls_cncp_comp then
       ls_cen := ls_cencos_rrhh ;
     end if ;
    end if ;
    if ls_flag_td = '1' then
      ls_cod := as_cod_trabajador ; ls_tip := ls_tipo_doc ;
      ls_nro := ls_nro_liquidacion ;
    end if ;
    if ls_cod is not null then
      select p.nom_proveedor into ls_nom from proveedor p
        where p.proveedor = ls_cod ;
    end if ;

    ln_item := ln_item + 1 ;
    insert into tt_liq_rpt_asiento (
      fec_liquidacion, nro_liquidacion, cod_trabajador,
      nombres, item, cuenta, flag_debhab, cencos, cod_relacion, nom_cod_relacion,
      tipo_doc, nro_doc, glosa, imp_debe, imp_haber )
    values (
      ld_fec_liquidacion, ls_nro_liquidacion, as_cod_trabajador,
      as_nombres, ln_item, ls_cuenta_deb, 'D', ls_cen, ls_cod, ls_nom,
      ls_tip, ls_nro, rc_mov.desc_concep, nvl(rc_mov.importe,0), 0 ) ;

  end if ;
  
  if ls_cuenta_hab is not null then

    select nvl(cc.flag_cencos,'0'), nvl(cc.flag_doc_ref,'0')
      into ls_flag_cc, ls_flag_td
      from cntbl_cnta cc where cc.cnta_ctbl = ls_cuenta_hab ;
    ls_cen := null ; ls_cod := null ; ls_nom := null ;
    ls_tip := null ; ls_nro := null ;
    if ls_flag_cc = '1' then ls_cen := ls_cencos ; end if ;
    if ls_flag_td = '1' then
      ls_cod := as_cod_trabajador ; ls_tip := ls_tipo_doc ;
      ls_nro := ls_nro_liquidacion ;
      ln_verifica := 0 ;
      select count(*) into ln_verifica from rh_liq_saldos_cnta_crrte s
        where s.cod_trabajador = as_cod_trabajador and s.concep = rc_mov.concepto ;
      if ln_verifica = 1 then
        select s.tipo_doc, s.nro_doc into ls_tip, ls_nro
          from rh_liq_saldos_cnta_crrte s
          where s.cod_trabajador = as_cod_trabajador and s.concep = rc_mov.concepto ;
      elsif ln_verifica > 0 then
        select max(s.tipo_doc), max(s.nro_doc) into ls_tip, ls_nro
          from rh_liq_saldos_cnta_crrte s
          where s.cod_trabajador = as_cod_trabajador and s.concep = rc_mov.concepto ;
      end if ;        
    end if ;
    if ls_cod is not null then
      select p.nom_proveedor into ls_nom from proveedor p
        where p.proveedor = ls_cod ;
    end if ;

    ln_item := ln_item + 1 ;
    insert into tt_liq_rpt_asiento (
      fec_liquidacion, nro_liquidacion, cod_trabajador,
      nombres, item, cuenta, flag_debhab, cencos, cod_relacion, nom_cod_relacion,
      tipo_doc, nro_doc, glosa, imp_debe, imp_haber )
    values (
      ld_fec_liquidacion, ls_nro_liquidacion, as_cod_trabajador,
      as_nombres, ln_item, ls_cuenta_hab, 'H', ls_cen, ls_cod, ls_nom,
      ls_tip, ls_nro, rc_mov.desc_concep, 0, nvl(rc_mov.importe,0) ) ;

  end if ;

end loop ;

end usp_rh_liq_rpt_asiento ;
/
