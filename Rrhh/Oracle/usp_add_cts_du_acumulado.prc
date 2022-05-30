create or replace procedure usp_add_cts_du_acumulado
 ( as_codtra        in maestro.cod_trabajador%type , 
   ad_fec_proceso   date ) is
   
ld_fec_deposito      date ;
ln_liquidacion       cts_decreto_urgencia.liquidacion%type ;

begin

--  Determina que registros van a ser adicionados
Select cdu.fec_proceso, cdu.liquidacion
  into ld_fec_deposito, ln_liquidacion
  from cts_decreto_urgencia cdu
  where cdu.cod_trabajador = as_codtra and
        cdu.fec_proceso = ad_fec_proceso ;
  ln_liquidacion := nvl(ln_liquidacion,0) ;

  ld_fec_deposito := ad_fec_proceso + 1 ;

  Insert into cnta_crrte_cts
    ( fec_prdo_dpsto, fec_calc_int, cod_trabajador, tasa_interes,
      imp_prdo_dpsto, cts_dispon_ant, int_legales,    a_cnta_cts,
      flag_control )
  Values
    ( ld_fec_deposito, ad_fec_proceso, as_codtra, 0,
      ln_liquidacion, 0, 0, 0,
      '0' ) ;
       
end usp_add_cts_du_acumulado ;
/
