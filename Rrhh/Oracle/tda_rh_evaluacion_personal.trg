create or replace trigger TDA_RH_EVALUACION_PERSONAL
  after delete on rh_evaluacion_personal  
  for each row
declare
  -- local variables here
begin
  
  delete from rh_evaluacion_personal_det
  where rh_evaluacion_personal_det.cod_trabajador = :old.cod_trabajador;
   
end TDA_RH_EVALUACION_PERSONAL;
/
