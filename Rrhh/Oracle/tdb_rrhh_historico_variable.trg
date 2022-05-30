create or replace trigger tdb_rrhh_historico_variable
  before delete on historico_variable 
  for each row
declare
  -- local variables here
  ln_count           Number ; 
begin
     
  ln_count := 1 ;
  --raise_application_error(-20000,'NO SE DEBE ELIMINAR INFORMACION HISTORICA') ;
end tdb_rrhh_historico_variable ;
/
