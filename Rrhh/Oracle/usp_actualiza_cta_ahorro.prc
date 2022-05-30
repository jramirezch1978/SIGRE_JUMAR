create or replace procedure usp_actualiza_cta_ahorro is

--  Lee maestro de trabajadores
Cursor c_maestro is
  Select m.nro_cnta_ahorro, m.nro_cnta_cts
  from maestro m ;

begin

For rc_mae in c_maestro Loop

  If rc_mae.nro_cnta_ahorro is null or trim(rc_mae.nro_cnta_ahorro) = '' then
    Update maestro
      Set nro_cnta_ahorro = ' ' ;
  End if ;
  
  If rc_mae.nro_cnta_cts is null or trim(rc_mae.nro_cnta_cts) = '' then
    Update maestro
      Set nro_cnta_cts = ' ' ;
  End if ;
  
End Loop ;

end usp_actualiza_cta_ahorro ;
/
