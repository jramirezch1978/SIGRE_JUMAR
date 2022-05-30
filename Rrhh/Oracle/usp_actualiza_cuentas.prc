create or replace procedure usp_actualiza_cuentas is

ls_codigo      char(08) ;
ln_registro    number(15) ;
ls_ctacte      char(16) ;
ls_ctacts      char(16) ;
ls_libele      char(8) ;

--  Lee maestro de trabajadores
Cursor c_maestro is
  Select m.cod_trabajador, m.nro_cnta_ahorro, m.nro_cnta_cts
  from maestro m
  where m.flag_estado = '1' ;

begin

For rc_mae in c_maestro Loop

  ls_codigo  := rc_mae.cod_trabajador ;

  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from cuentas c
    where c.codigo = ls_codigo ;
  ln_registro := nvl(ln_registro,0) ;
    
  If ln_registro > 0 then

    Select c.ctacte, c.ctacts, c.libele
      into ls_ctacts, ls_ctacte, ls_libele 
      from cuentas c
      where c.codigo = ls_codigo ;
    ls_ctacte := nvl(ls_ctacte,' ') ;
    ls_ctacts := nvl(ls_ctacts,' ') ;
    ls_libele := nvl(ls_libele,' ') ;
      
    Update maestro
      Set dni             = ls_libele ,
          nro_cnta_ahorro = ls_ctacte ,
          nro_cnta_cts    = ls_ctacts
      where cod_trabajador = ls_codigo ;
  End if ;
  
End Loop ;

end usp_actualiza_cuentas ;
/
