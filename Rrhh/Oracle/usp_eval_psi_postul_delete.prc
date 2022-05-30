create or replace procedure usp_eval_psi_postul_delete
 (as_cod_postul in postulante.cod_postulante%type,
  ad_fec_proceso  in date ,
  as_cod_plant_psi in plantilla_psicologica.cod_plant_psi%type
 ) is

begin
--Delete de la Eval Psicol del Postul Detalle
Delete eval_psicol_postulante_detalle eppd
 where eppd.cod_postulante = as_cod_postul and 
       eppd.fec_proceso = ad_fec_proceso and 
       eppd.cod_plant_psi = as_cod_plant_psi ;
  
--Delete de la Eval Psicol del Postul
Delete eval_psicologica_postulante epp
 where epp.cod_postulante = as_cod_postul and 
       epp.fec_proceso = ad_fec_proceso and 
       epp.cod_plant_psi = as_cod_plant_psi; 


end usp_eval_psi_postul_delete ;
/
