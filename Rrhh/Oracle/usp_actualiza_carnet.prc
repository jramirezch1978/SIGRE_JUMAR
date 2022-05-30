create or replace procedure usp_actualiza_carnet is

ls_carnet      char(10) ;           
ls_codigo      char(08) ;
ls_estado      char(01) ;
ld_fecha       date ;
ln_registro    number(15) ;

--  Lee maestro de trabajadores
Cursor c_maestro is
  Select m.cod_trabajador, m.carnet_trabaj
  from maestro m
  where m.flag_estado = '1' and
        m.flag_marca_reloj = '1' and
        m.carnet_trabaj <> ' ' ;

begin

delete from carnet_trabajador ;
      
For rc_mae in c_maestro Loop

  ls_codigo := rc_mae.cod_trabajador ;
  ls_carnet := rc_mae.carnet_trabaj ;
  ls_estado := '1' ;
  ld_fecha  := to_date('01/01/2001','DD/MM/YYYY') ;

  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from carnet_trabajador ct
    where ct.carnet_trabajador = ls_carnet and
          ct.cod_trabajador = ls_codigo ;
  ln_registro := nvl(ln_registro,0) ;
    
  If ln_registro > 0 then
    Update carnet_trabajador
      Set flag_estado = ls_estado ,
          fecha_asignacion = ld_fecha
      where carnet_trabajador = ls_carnet and
            cod_trabajador = ls_codigo ;
  Else    
    Insert into carnet_trabajador (
      carnet_trabajador, cod_trabajador,
      flag_estado, fecha_asignacion )
    Values (
      ls_carnet, ls_codigo,
      ls_estado, ld_fecha ) ;
  End if ;
  
End Loop ;

end usp_actualiza_carnet ;
/
