create or replace procedure usp_rh_liq_adelantos (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_verifica            integer ;
ln_sw                  integer ;
ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_concepto_cts        char(4) ;
ls_concepto_bs         char(4) ;
ls_concepto_int        char(4) ;

ld_fecha               date ;
ln_importe             number(13,2) ;
ln_imp_adel_cts        number(13,2) ;
ln_imp_adel_bs         number(13,2) ;
ln_imp_inte_cts        number(13,2) ;

ln_fac_cese            number(9,6) ;
ln_fac_prdo            number(9,6) ;
ln_fac_emplear         number(9,6) ;

--  Lectura de adelantos a cuenta de C.T.S.
cursor c_adelantos is
  select a.fec_proceso, a.imp_a_cuenta
  from adel_cnta_cts a
  where a.cod_trabajador = as_cod_trabajador
  order by a.cod_trabajador, a.fec_proceso ;
    
begin

--  ******************************************************************
--  ***   DESCUENTOS DE ADELANTOS - C.T.S. Y BENEFICIOS SOCIALES   ***
--  ******************************************************************

select p.grp_dscto_cta_cte, p.sgrp_adelanto, p.cncp_adel_cts, p.cncp_adel_bs,
       p.cncp_int_cts
  into ls_grupo, ls_sub_grupo, ls_concepto_cts, ls_concepto_bs,
       ls_concepto_int
  from rh_liqparam p where p.reckey = '1' ;

--  Determina adelantos a cuenta de C.T.S.

ln_verifica := 0 ; ln_imp_adel_cts := 0 ;
select count(*) into ln_verifica from adel_cnta_cts a
  where a.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then  
  select sum(nvl(a.imp_a_cuenta,0)) into ln_imp_adel_cts from adel_cnta_cts a
    where a.cod_trabajador = as_cod_trabajador ;
end if ;

if nvl(ln_imp_adel_cts,0) > 0 then

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
    ls_concepto_cts, nvl(ln_imp_adel_cts,0) ) ;

  --  Calcula descuentos de intereses de adelantos a cuenta de C.T.S.
   
  select nvl(f.fact_cts,0) into ln_fac_cese from factor_planilla f
    where trunc(f.fec_calc_int) = trunc(ad_fec_liquidacion) ;

  ln_imp_inte_cts := 0 ;
  for rc_ade in c_adelantos loop
    select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
      where trunc(f.fec_calc_int) = trunc(rc_ade.fec_proceso) ;
    ln_fac_emplear  := (nvl(ln_fac_cese,0) / nvl(ln_fac_prdo,0)) - 1 ;
    ln_imp_inte_cts := ln_imp_inte_cts + (nvl(rc_ade.imp_a_cuenta,0) * nvl(ln_fac_emplear,0)) ;
  end loop ;

  insert into rh_liq_dscto_leyes_aportes (
    cod_trabajador, cod_grupo, cod_sub_grupo,
    concep, importe )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo,
    ls_concepto_int, nvl(ln_imp_inte_cts,0) ) ;

end if ;

--  Determina adelantos a cuenta de Beneficios Sociales

ln_verifica := 0 ; ln_imp_adel_bs := 0 ;
select count(*) into ln_verifica from historico_calculo h
  where h.cod_trabajador = as_cod_trabajador and h.concep = ls_concepto_bs ;
if ln_verifica > 0 then  
  select sum(nvl(h.imp_soles,0)) into ln_imp_adel_bs from historico_calculo h
    where h.cod_trabajador = as_cod_trabajador and h.concep = ls_concepto_bs ;
end if ;

ln_verifica := 0 ; ld_fecha := null ; ln_importe := 0 ;
select count(*) into ln_verifica from calculo c
  where c.cod_trabajador = as_cod_trabajador and c.concep = ls_concepto_bs ;
if ln_verifica > 0 then
  select c.fec_proceso, nvl(c.imp_soles,0) into ld_fecha, ln_importe from calculo c
    where c.cod_trabajador = as_cod_trabajador and c.concep = ls_concepto_bs ;
  ln_verifica := 0 ;
  select count(*) into ln_verifica from historico_calculo h
    where h.cod_trabajador = as_cod_trabajador and h.concep = ls_concepto_bs and
          trunc(h.fec_calc_plan) = trunc(ld_fecha) ;
  if ln_verifica = 0 then
    ln_imp_adel_bs := ln_imp_adel_bs + ln_importe ;
  end if ;
end if ;

if nvl(ln_imp_adel_bs,0) > 0 then
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rh_liq_tiempo_efectivo t
    where t.cod_trabajador = as_cod_trabajador and t.cod_grupo = ls_grupo and
          t.cod_sub_grupo = ls_sub_grupo and t.fec_desde = ad_fec_liquidacion ;
  if ln_verifica = 0 then    
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo, ad_fec_liquidacion, ad_fec_liquidacion,
      0, 0, 0 ) ;
  end if ;
  insert into rh_liq_dscto_leyes_aportes (
    cod_trabajador, cod_grupo, cod_sub_grupo,
    concep, importe )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo,
    ls_concepto_bs, nvl(ln_imp_adel_bs,0) ) ;
end if ;

end usp_rh_liq_adelantos ;
/
