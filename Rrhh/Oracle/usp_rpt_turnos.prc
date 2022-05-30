create or replace procedure usp_rpt_turnos
  ( as_mes              char ,
    as_ano              char ,
    an_semana_d         number ,
    an_semana_h         number ) is

ls_seccion              char(3) ;
ls_desc_seccion         varchar2(40) ;
ls_codigo               char(8) ;
ls_carnet               char(10) ;
ls_nombres              varchar2(40) ;
ls_mes                  char(9) ;
ls_ano                  char(4) ;
ln_semana_1             number(2) ;
ln_semana_2             number(2) ;
ln_semana_3             number(2) ;
ln_semana_4             number(2) ;
ln_semana_5             number(2) ;
 
Cursor c_maestro is
  Select m.cod_trabajador, m.carnet_trabaj, m.cod_seccion,
         m.turno, m.flag_marca_reloj
  From maestro m
  Where m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and
        m.turno = 'TR00' and
        m.flag_marca_reloj = '1'
  Order by m.cod_seccion, m.apel_paterno, m.apel_materno,
           m.nombre1, m.nombre2 ;
                
begin

delete from tt_turnos ;

ls_mes      := as_mes ;
ls_ano      := as_ano ;
ln_semana_1 := an_semana_d ;
ln_semana_2 := an_semana_d + 1 ;
ln_semana_3 := an_semana_d + 2 ;
ln_semana_4 := an_semana_d + 3 ;
ln_semana_5 := an_semana_d + 4 ;

If an_semana_h < ln_semana_5 then
  ln_semana_5 := 0 ;
End if ;

--  Genera archivo del personal rotativo
For rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_carnet  := rc_mae.carnet_trabaj ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_nombres := usf_nombre_trabajador(ls_codigo) ;
    
  If ls_seccion  is not null Then
    Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
  End if ;
  ls_desc_seccion := nvl(ls_desc_seccion,'340') ;

  --  Inserta registros para generar turnos mensuales
  Insert into tt_turnos (
    seccion, desc_seccion, codigo,
    carnet, nombres, mes, ano, semana_1,
    semana_2, semana_3, semana_4, semana_5 )
  Values (
    ls_seccion, ls_desc_seccion, ls_codigo,
    ls_carnet, ls_nombres, ls_mes, ls_ano, ln_semana_1,
    ln_semana_2, ln_semana_3, ln_semana_4, ln_semana_5 ) ;

End Loop;

End usp_rpt_turnos ;
/
