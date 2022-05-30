create or replace procedure usp_eval_psi_trabaj_delete
 (as_cod_trabaj in maestro.cod_trabajador%type,
  ad_fec_proceso  in date ,
  as_cod_plant_psi in plantilla_psicologica.cod_plant_psi%type
 ) is

begin
--Delete de la Eval Psicol Trabaj Detalle
Delete eval_psicol_trabajador_detalle eptd 
 where eptd.cod_trabajador = as_cod_trabaj and 
       eptd.fec_proceso = ad_fec_proceso and 
       eptd.cod_plant_psi = as_cod_plant_psi ;
  
--Delete de la Eval Psicol Trabaj
Delete eval_psicologica_trabajador ept
 where ept.cod_trabajador = as_cod_trabaj and 
       ept.fec_proceso = ad_fec_proceso and 
       ept.cod_plant_psi = as_cod_plant_psi; 

end usp_eval_psi_trabaj_delete ;
/
