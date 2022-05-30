create or replace procedure usp_rh_cts_add_du_acumulado (
  as_codtra in char, ad_fec_proceso in date ) is

ln_contador          integer ;
ld_fec_deposito      date ;
ln_liquidacion       cts_decreto_urgencia.liquidacion%type ;

begin

--  ************************************************************
--  ***   ADICIONA C.T.S. DECRETO DE URGENCIA AL ACUMULADO   ***
--  ************************************************************

ln_contador := 0 ;
select count(*) into ln_contador from cts_decreto_urgencia cdu
  where cdu.cod_trabajador = as_codtra and cdu.fec_proceso = ad_fec_proceso ;

if ln_contador > 0 then

  select cdu.fec_proceso, nvl(cdu.liquidacion,0)
    into ld_fec_deposito, ln_liquidacion from cts_decreto_urgencia cdu
    where cdu.cod_trabajador = as_codtra and cdu.fec_proceso = ad_fec_proceso ;

  ld_fec_deposito := ad_fec_proceso + 1 ;

  insert into cnta_crrte_cts (
    fec_prdo_dpsto, fec_calc_int, cod_trabajador, tasa_interes,
    imp_prdo_dpsto, cts_dispon_ant, int_legales, a_cnta_cts, flag_control, flag_replicacion )
  values (
    ld_fec_deposito, ad_fec_proceso, as_codtra, 0,
    ln_liquidacion, 0, 0, 0, '0', '1' ) ;

end if ;

end usp_rh_cts_add_du_acumulado ;
/
