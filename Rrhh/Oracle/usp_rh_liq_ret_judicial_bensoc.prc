create or replace procedure usp_rh_liq_ret_judicial_bensoc (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_verifica            integer ;
ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_grp_comadi          char(6) ;
ls_grp_calculo         char(3) ;
ls_concepto            char(4) ;
ln_retencion           number(5,2) ;
ln_importe             number(13,2) ;
ln_imp_judicial        number(13,2) ;

begin

--  ********************************************************************
--  ***   DESCUENTOS POR RETENCION JUDICIAL DE BENEFICIOS SOCIALES   ***
--  ********************************************************************

select p.grp_dscto_cta_cte, p.sgrp_reten_jud, p.grp_indemnizacion
  into ls_grupo, ls_sub_grupo, ls_grp_comadi
  from rh_liqparam p where p.reckey = '1' ;

select c.calc_judic into ls_grp_calculo from rrhhparam_cconcep c
  where c.reckey = '1' ;
  
ln_verifica := 0 ; ln_retencion := 0 ;
select count(*) into ln_verifica from rh_liq_retencion_judicial j
  where j.cod_trabajador = as_cod_trabajador and
        ( nvl(j.flag_reten_jud,'0') = '1' or nvl(j.flag_reten_jud,'0') = '3' ) ;
if ln_verifica > 0 then
  select nvl(j.reten_jud,0) into ln_retencion from rh_liq_retencion_judicial j
    where j.cod_trabajador = as_cod_trabajador and 
          ( nvl(j.flag_reten_jud,'0') = '1' or nvl(j.flag_reten_jud,'0') = '3' ) ;
end if ;

if nvl(ln_retencion,0) > 0 then

  select c.concepto_gen into ls_concepto from grupo_calculo c
    where c.grupo_calculo = ls_grp_calculo ;

  --  Determina monto para realizar retencion judicial

  ln_verifica := 0 ; ln_imp_judicial := 0 ; ln_importe := 0 ;
  select count(*) into ln_verifica from rh_liq_fondo_retiro f
    where f.cod_trabajador = as_cod_trabajador ;
  if ln_verifica > 0 then
    select sum(nvl(f.imp_x_liq_anos,0) + nvl(f.imp_x_liq_meses,0) + nvl(f.imp_x_liq_dias,0))
      into ln_importe
      from rh_liq_fondo_retiro f
      where f.cod_trabajador = as_cod_trabajador ;
    ln_imp_judicial := ln_imp_judicial + ln_importe ;
  end if ;
    
  ln_verifica := 0 ; ln_importe := 0 ;
  select count(*) into ln_verifica from rh_liq_cts c
    where c.cod_trabajador = as_cod_trabajador ;
  if ln_verifica > 0 then
    select sum(nvl(c.deposito,0) + nvl(c.interes,0))
      into ln_importe
      from rh_liq_cts c
      where c.cod_trabajador = as_cod_trabajador ;
    ln_imp_judicial := ln_imp_judicial + ln_importe ;
  end if ;
    
  ln_verifica := 0 ; ln_importe := 0 ;
  select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_comadi ;
  if ln_verifica > 0 then
    select sum(nvl(d.importe,0)) into ln_importe from rh_liq_dscto_leyes_aportes d
      where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_comadi ;
    ln_imp_judicial := ln_imp_judicial + ln_importe ;
  end if ;    

  ln_imp_judicial := nvl(ln_imp_judicial,0) * nvl(ln_retencion,0) / 100 ;
  
  --  Graba movimiento por retencion judicial
  if nvl(ln_imp_judicial,0) > 0 then
  
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo, ad_fec_liquidacion, ad_fec_liquidacion,
      0, 0, 0 ) ;

    insert into rh_liq_dscto_leyes_aportes (
      cod_trabajador, cod_grupo, cod_sub_grupo,
      concep, importe )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo,
      ls_concepto, nvl(ln_imp_judicial,0) ) ;
    
  end if ;

end if ;
  
end usp_rh_liq_ret_judicial_bensoc ;
/
