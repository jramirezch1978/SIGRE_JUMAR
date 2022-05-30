create or replace function usf_rh_saldos_disponibles_cts (
  as_cod_trabajador in char ) return number is

ln_verifica          integer ;
ld_min_fecha         date ;
ld_max_fecha         date ;
ln_max_factor        number(9,6) ;
ln_fac_prdo          number(9,6) ;
ln_fac_emplear       number(9,6) ;
ln_deposito          number(13,2) ;
ln_interes           number(13,2) ;
ln_adelantos         number(13,2) ;
ln_int_adel          number(13,2) ;
ln_saldos            number(13,2) ;

--  Cursor para halar saldo disponible
cursor c_saldos is
  select c.fec_prdo_dpsto, c.imp_prdo_dpsto
  from cnta_crrte_cts c
  where c.cod_trabajador = as_cod_trabajador
  order by c.cod_trabajador, c.fec_prdo_dpsto ;
  
--  Lectura de adelantos a cuenta de C.T.S. para calculo de intereses
cursor c_adelantos is
  select a.fec_proceso, a.imp_a_cuenta
  from adel_cnta_cts a
  where a.cod_trabajador = as_cod_trabajador
  order by a.cod_trabajador, a.fec_proceso ;
    
begin

--  **********************************************************
--  ***   DETERMINA SALDO DISPONIBLE AL 50% DE LA C.T.S.   ***
--  **********************************************************

--  Determina factor de C.T.S. a la ultima fecha
ld_max_fecha := null ; ln_max_factor := 0 ;
select max(f.fec_calc_int) into ld_max_fecha from factor_planilla f ;
select nvl(f.fact_cts,0) into ln_max_factor from factor_planilla f
  where trunc(f.fec_calc_int) = trunc(ld_max_fecha) ;

--  Verifica saldos disponible del 50% del trabajador
ln_deposito := 0 ; ln_interes := 0 ;
for rc_s in c_saldos loop
  ln_verifica := 0 ;
  select count(*) into ln_verifica from factor_planilla f
    where trunc(f.fec_calc_int) = (trunc(rc_s.fec_prdo_dpsto) - 1) ;
  if ln_verifica > 0 then
    select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
      where trunc(f.fec_calc_int) = (trunc(rc_s.fec_prdo_dpsto) - 1) ;
  else
    select min(f.fec_calc_int) into ld_min_fecha from factor_planilla f ;
    select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
      where trunc(f.fec_calc_int) = trunc(ld_min_fecha) ;
  end if ;
  ln_fac_emplear := (nvl(ln_max_factor,0) / nvl(ln_fac_prdo,0)) - 1 ;
  ln_deposito    := ln_deposito + (nvl(rc_s.imp_prdo_dpsto,0) / 2 ) ;
  ln_interes     := ln_interes + (nvl(rc_s.imp_prdo_dpsto,0) / 2 * nvl(ln_fac_emplear,0)) ;
end loop ;

--  Determina adelantos a cuenta de C.T.S.
ln_adelantos := 0 ; ln_int_adel := 0 ;
for rc_ade in c_adelantos loop
  select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
    where trunc(f.fec_calc_int) = trunc(rc_ade.fec_proceso) ;
  ln_fac_emplear  := (nvl(ln_max_factor,0) / nvl(ln_fac_prdo,0)) - 1 ;
  ln_adelantos    := ln_adelantos + nvl(rc_ade.imp_a_cuenta,0) ;
  ln_int_adel     := ln_int_adel + (nvl(rc_ade.imp_a_cuenta,0) * nvl(ln_fac_emplear,0)) ;
end loop ;

ln_saldos := (ln_deposito + ln_interes) - (ln_adelantos + ln_int_adel) ;

return (ln_saldos) ;

end usf_rh_saldos_disponibles_cts ;
/
