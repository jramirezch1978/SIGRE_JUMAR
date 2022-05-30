create or replace procedure usp_rh_cts_add_acumulado (
  asi_codtra      in maestro.cod_trabajador%TYPE, 
  adi_fec_proceso in date 
) is

ld_fec_deposito      date ;
ls_mes_proceso       char(2) ;
ls_flag_estado       char(1) ;
ln_dias              number(2) ;
ln_prov_cts_01       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_02       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_03       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_04       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_05       prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_06       prov_cts_gratif.prov_cts_01%type ;
ln_imp_tot_cts       cnta_crrte_cts.imp_prdo_dpsto%type ;

begin

--  **********************************************************************
--  ***   ADICIONA C.T.S. SEMESTRAL AL ACUMULADO DE CUENTA CORRIENTE   ***
--  **********************************************************************

select pcg.flag_estado, nvl(pcg.prov_cts_01,0), nvl(pcg.prov_cts_02,0),
       nvl(pcg.prov_cts_03,0), nvl(pcg.prov_cts_04,0), nvl(pcg.prov_cts_05,0),
       nvl(pcg.prov_cts_06,0)
  into ls_flag_estado, ln_prov_cts_01, ln_prov_cts_02, ln_prov_cts_03,
       ln_prov_cts_04, ln_prov_cts_05, ln_prov_cts_06
  from prov_cts_gratif pcg where pcg.cod_trabajador = asi_codtra ;

select p.dias_interes_cts
  into ln_dias
  from rh_liqparam p
  where p.reckey = '1' ;

if ls_flag_estado = '1' then

  ln_imp_tot_cts := ln_prov_cts_01 + ln_prov_cts_02 + ln_prov_cts_03 +
                    ln_prov_cts_04 + ln_prov_cts_05 + ln_prov_cts_06 ;

  ls_mes_proceso := to_char(adi_fec_proceso,'mm') ;
  if ls_mes_proceso = '04' or ls_mes_proceso = '10' then
    ld_fec_deposito := adi_fec_proceso + ln_dias ;
  end if ;

  insert into cnta_crrte_cts (
    fec_prdo_dpsto, fec_calc_int, cod_trabajador, tasa_interes,
    imp_prdo_dpsto, cts_dispon_ant, int_legales, a_cnta_cts, flag_control, flag_replicacion )
  values (
    ld_fec_deposito, adi_fec_proceso, asi_codtra, 0,
    ln_imp_tot_cts, 0, 0, 0, '0', '1' ) ;

end if ;

end usp_rh_cts_add_acumulado ;
/
