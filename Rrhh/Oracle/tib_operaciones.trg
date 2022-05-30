create or replace trigger tib_operaciones
  before insert on operaciones
  for each row

declare
  -- local variables here
begin
  SELECT Seq_operaciones.NEXTVAL
         INTO :new.oper_sec 
         FROM dual;
end tib_operaciones;
/
