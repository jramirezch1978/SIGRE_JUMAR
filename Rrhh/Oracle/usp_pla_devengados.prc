create or replace procedure usp_pla_devengados (
   as_codtra             in maestro.cod_trabajador%type,
   ad_fec_proceso        in rrhhparam.fec_proceso%type
   ) is

begin

   --  Procesos de Devengados 
   usp_pla_dev_borrar            ( as_codtra, ad_fec_proceso );
   usp_pla_dev_adiciona          ( as_codtra, ad_fec_proceso );
   usp_pla_dev_adiciona_variable ( as_codtra, ad_fec_proceso );
   usp_pla_dev_calculo_gra       ( as_codtra, ad_fec_proceso );
   usp_pla_dev_calculo_rem       ( as_codtra, ad_fec_proceso );
   usp_pla_dev_calculo_rac       ( as_codtra, ad_fec_proceso );

end usp_pla_devengados ;
/
