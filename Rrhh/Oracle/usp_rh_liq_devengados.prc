create or replace procedure usp_rh_liq_devengados (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_verifica            integer ;
ls_gratif              char(3) ;
ls_remune              char(3) ;
ls_racion              char(3) ;

ls_grupo               char(6) ;
ls_sub_grp_gratif      char(6) ;
ls_sub_grp_racion      char(6) ;
ls_sub_grp_remune      char(6) ;
ls_concepto            char(4) ;

ld_fec_saldo           date ;
ld_fec_ingreso         date ;

ln_imp_gratif          number(13,2) ;
ln_imp_remune          number(13,2) ;
ln_imp_racion          number(13,2) ;

begin

--  **************************************************************
--  ***   LIQUIDACION DE PAGOS POR REMUNERACIONES DEVENGADAS   ***
--  **************************************************************

select p.grp_remuneracion, p.sgrp_grat_dev, p.sgrp_racion_azucar, p.sgrp_remun_dev
  into ls_grupo, ls_sub_grp_gratif, ls_sub_grp_racion, ls_sub_grp_remune
  from rh_liqparam p where p.reckey = '1' ;
    
select g.gratific_deveng, g.remun_deveng, g.rac_azucar_deveng
  into ls_gratif, ls_remune, ls_racion
  from rrhhparam_cconcep g where g.reckey = '1' ;
  
ln_verifica := 0 ;
select count(*) into ln_verifica from sldo_deveng s
  where s.cod_trabajador = as_cod_trabajador ;
  
if ln_verifica > 0 then

  select m.fec_ingreso into ld_fec_ingreso from maestro m
    where m.cod_trabajador = as_cod_trabajador ;
    
  ld_fec_saldo := null ;
  select max(s.fec_proceso) into ld_fec_saldo from sldo_deveng s
    where s.cod_trabajador = as_cod_trabajador ;
    
  ln_imp_gratif := 0 ; ln_imp_remune := 0 ; ln_imp_racion := 0 ;
  select nvl(s.sldo_gratif_dev,0), nvl(s.sldo_rem_dev,0), nvl(s.sldo_racion,0)
    into ln_imp_gratif, ln_imp_remune, ln_imp_racion
    from sldo_deveng s
    where s.cod_trabajador = as_cod_trabajador and trunc(s.fec_proceso) = ld_fec_saldo ;
    
  --  Inserta registros por gratificaciones devengadas
  if nvl(ln_imp_gratif,0) > 0 then
    ls_concepto := null ;
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = ls_gratif ;
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_gratif, ld_fec_ingreso, ad_fec_liquidacion,
      0, 0, 0 ) ;
    insert into rh_liq_remuneracion (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
      fec_hasta, tm_ef_liq_anos )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_gratif, ld_fec_ingreso,
      ad_fec_liquidacion, nvl(ln_imp_gratif,0) ) ;
  end if ;
  
  --  Inserta registros por remuneraciones devengadas
  if nvl(ln_imp_remune,0) > 0 then
    ls_concepto := null ;
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = ls_remune ;
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_remune, ld_fec_ingreso, ad_fec_liquidacion,
      0, 0, 0 ) ;
    insert into rh_liq_remuneracion (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
      fec_hasta, tm_ef_liq_anos )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_remune, ld_fec_ingreso,
      ad_fec_liquidacion, nvl(ln_imp_remune,0) ) ;
  end if ;
  
  --  Inserta registros por raciones de azucar devengadas
  if nvl(ln_imp_racion,0) > 0 then
    ls_concepto := null ;
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = ls_racion ;
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_racion, ld_fec_ingreso, ad_fec_liquidacion,
      0, 0, 0 ) ;
    insert into rh_liq_remuneracion (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
      fec_hasta, tm_ef_liq_anos )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_racion, ld_fec_ingreso,
      ad_fec_liquidacion, nvl(ln_imp_racion,0) ) ;
  end if ;
  
end if ;
  
end usp_rh_liq_devengados ;
/
