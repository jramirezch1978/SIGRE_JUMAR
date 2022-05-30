create or replace procedure usp_add_cts_acumulado
 ( as_codtra        in maestro.cod_trabajador%type , 
   ad_fec_proceso   date
 ) is
   
ld_fec_deposito      date ;
ls_mes_proceso       char(2) ;
ls_flag_estado       char(1) ;
ln_prov_cts_01       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_02       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_03       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_04       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_05       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_06       prov_cts_gratif.prov_cts_01%type ;
ln_imp_tot_cts       cnta_crrte_cts.imp_prdo_dpsto%type ;

begin

--  Determina que registros van a ser adicionados
Select pcg.flag_estado, pcg.prov_cts_01, pcg.prov_cts_02, pcg.prov_cts_03,
       pcg.prov_cts_04, pcg.prov_cts_05, pcg.prov_cts_06
  into ls_flag_estado, ln_prov_cts_01, ln_prov_cts_02, ln_prov_cts_03,
       ln_prov_cts_04, ln_prov_cts_05, ln_prov_cts_06
  from prov_cts_gratif pcg
  where pcg.cod_trabajador = as_codtra ;
  ln_prov_cts_01 := nvl(ln_prov_cts_01,0) ;
  ln_prov_cts_02 := nvl(ln_prov_cts_02,0) ;
  ln_prov_cts_03 := nvl(ln_prov_cts_03,0) ;
  ln_prov_cts_04 := nvl(ln_prov_cts_04,0) ;
  ln_prov_cts_05 := nvl(ln_prov_cts_05,0) ;
  ln_prov_cts_06 := nvl(ln_prov_cts_06,0) ;

If ls_flag_estado = '1' then

  ln_imp_tot_cts := ln_prov_cts_01 + ln_prov_cts_02 + ln_prov_cts_03 +
                    ln_prov_cts_04 + ln_prov_cts_05 + ln_prov_cts_06 ;

  ls_mes_proceso := to_char(ad_fec_proceso,'MM') ;
  If ls_mes_proceso = '04' or ls_mes_proceso = '10' then
    ld_fec_deposito := ad_fec_proceso + 16 ;
  End if ;

  Insert into cnta_crrte_cts
    ( fec_prdo_dpsto, fec_calc_int, cod_trabajador, tasa_interes,
      imp_prdo_dpsto, cts_dispon_ant, int_legales,    a_cnta_cts,
      flag_control )
  Values
    ( ld_fec_deposito, ad_fec_proceso, as_codtra, 0,
      ln_imp_tot_cts, 0, 0, 0,
      '0' ) ;
       
End if ;
  
end usp_add_cts_acumulado ;
/
