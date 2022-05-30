create or replace procedure usp_pla_cal_quincena_borrar is
  
begin

--  Elimina registros de la tabla de adelantos de quincena

  DELETE FROM adelanto_quincena ;
  COMMIT;
  
end usp_pla_cal_quincena_borrar ;
/
