create or replace procedure usp_rh_calculo_devengados (
  as_codtra in char, ad_fec_proceso in date, ad_fec_anterior in date ) is

begin

  --  ********************************************************
  --  ***   REALIZA CALCULO DE REMUNERACIONES DEVENGADAS   ***
  --  ********************************************************

  usp_rh_dev_borrar            ( as_codtra, ad_fec_proceso ) ;
  usp_rh_dev_adiciona          ( as_codtra, ad_fec_proceso ) ;
  usp_rh_dev_adiciona_variable ( as_codtra, ad_fec_proceso ) ;
  usp_rh_dev_calculo_gra       ( as_codtra, ad_fec_proceso, ad_fec_anterior ) ;
  usp_rh_dev_calculo_rem       ( as_codtra, ad_fec_proceso, ad_fec_anterior ) ;
  usp_rh_dev_calculo_rac       ( as_codtra, ad_fec_proceso, ad_fec_anterior ) ;

end usp_rh_calculo_devengados ;
/
