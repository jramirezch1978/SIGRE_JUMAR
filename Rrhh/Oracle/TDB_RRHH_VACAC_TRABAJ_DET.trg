create or replace trigger TDB_RRHH_VACAC_TRABAJ_DET
  before delete on rrhh_vacac_trabaj_det  
  for each row
declare
  -- local variables here
begin
  
  IF :old.flag_estado='2' THEN
     RAISE_APPLICATION_ERROR (-20000, 'Registro a eliminar tiene estado cerrado, no puede eliminarlo') ;
     return ;
  END IF ;

  IF :old.flag_estado='1' THEN
     RAISE_APPLICATION_ERROR (-20001, 'Registro a eliminar tiene estado activo. Primero borre registro de movimiento de planilla') ;
     return ;
  END IF ;
  
  -- Actualiza los dias programados 
  UPDATE rrhh_vacaciones_trabaj v 
     SET v.dias_program = NVL(v.dias_program,0) - NVL(:old.nro_dias,0)
   WHERE v.cod_trabajador = :old.cod_trabajador 
     AND v.periodo_inicio = :old.periodo_inicio ;
  
end TDB_RRHH_VACAC_TRABAJ_DET;
/
