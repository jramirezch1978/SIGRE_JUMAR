create or replace trigger TIB_RRHH_VACACIONES_TRABAJ
  before insert on rrhh_vacaciones_trabaj
  for each row
declare
  -- local variables here
  ls_concepto_vacac           rrhhparam_vacacion.concepto_vacac%type ;
BEGIN

  SELECT r.concepto_vacac 
    INTO ls_concepto_vacac 
    FROM rrhhparam_vacacion r 
   WHERE reckey='1' ;
   
   IF :new.concep <> ls_concepto_vacac THEN
      RAISE_APPLICATION_ERROR(-20000, 'Concepto de vacaciones no es el correcto. Revisar parámetro de rrhhparam_vacacion') ;
      Return ;
   END IF ;
  
END TIB_RRHH_VACACIONES_TRABAJ ;
/
