create or replace procedure usp_actualiza_cta is

ls_nro_afp        char(12) ;
ls_codigo         char(8) ;
ln_contador       number(15) ;

--  Lee maestro de trabajadores
Cursor c_maestro is
  Select m.cod_trabajador
  from maestro m 
  where m.flag_estado = '1' ;

begin

For rc_mae in c_maestro Loop

  ls_codigo := rc_mae.cod_trabajador ;
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from nroafp n
    where n.codnue = ls_codigo ;
  ln_contador := nvl(ln_contador,0) ;
  
  If ln_contador > 0 then
    Select n.nroafp
      into ls_nro_afp
      from nroafp n
      where n.codnue = ls_codigo ;
    
    Update maestro
      Set nro_afp_trabaj = ls_nro_afp
      where cod_trabajador = ls_codigo ;

  End if ;
  
End Loop ;

end usp_actualiza_cta ;
/
