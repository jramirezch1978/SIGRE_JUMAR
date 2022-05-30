create or replace trigger tdb_rrhh_hist_inasistencia
  before delete on historico_inasistencia  
  for each row
declare
  -- local variables here
  --ln_count           Number ;
begin
  raise_application_error(-20000,'NO SE DEBE ELIMINAR INFORMACION HISTORICA') ;
  --ln_count := 1;
end tdb_rrhh_hist_inasistencia;
/
