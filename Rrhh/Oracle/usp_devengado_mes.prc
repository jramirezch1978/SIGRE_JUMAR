create or replace procedure usp_devengado_mes (
  as_tipo_trabajador  in maestro.tipo_trabajador%type ) is

ls_codigo          maestro.cod_trabajador%type ;
ls_nombres         varchar2(40) ;
ls_seccion         maestro.cod_seccion%type ;
ls_desc_seccion    varchar2(40) ;
ls_concepto        concepto.concep%type ;
ld_fecha           date ;
ln_importe         number(13,2) ;
ln_imp_1           number(13,2) ;
ln_imp_2           number(13,2) ;
ln_imp_3           number(13,2) ;
ln_imp_t           number(13,2) ;

--  Cursor para leer todos los trabajadores activos del maestro
Cursor c_maestro is
  Select m.cod_trabajador, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_seccion, m.cod_trabajador ;
        
--  Cursor para leer pagos por devengados
Cursor c_calculo is
  Select c.concep, c.fec_proceso, c.imp_soles
  from calculo c
  where c.cod_trabajador = ls_codigo and
        c.concep = '1301' or
        c.concep = '1302' or
        c.concep = '1303' ;
        
begin

delete from tt_devengado_mes ;
        
For rc_mae in c_maestro Loop

  ln_imp_1 := 0 ; ln_imp_2 := 0 ; 
  ln_imp_3 := 0 ; ln_imp_t := 0 ;

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_nombres := usf_nombre_trabajador(ls_codigo) ;

  If ls_seccion  is not null Then
    Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
  Else 
    ls_seccion := '340' ;
  End if ;
  ls_desc_seccion := nvl(ls_desc_seccion,' ') ;

  For rc_cal in c_calculo Loop

    ls_concepto := rc_cal.concep ;
    ld_fecha    := rc_cal.fec_proceso ;
    ln_importe  := rc_cal.imp_soles ;
    ln_importe  := nvl(ln_importe,0) ;

    If ls_concepto = '1301' then
      ln_imp_1 := ln_importe ;
    Elsif ls_concepto = '1302' then
      ln_imp_2 := ln_importe ;
    Elsif ls_concepto = '1303' then
      ln_imp_3 := ln_importe ;
    End if ;
    
  End loop ;
  
  ln_imp_t := ln_imp_1 + ln_imp_2 + ln_imp_3 ;

  --  Adiciona registros en la tabla temporal tt_devengado_mes
  If ln_imp_t <> 0 then
    Insert into tt_devengado_mes
      (cod_trabajador, nombre, cod_seccion,
       desc_seccion, fec_hasta, importe1,
       importe2, importe3, importet)
    Values     
      (ls_codigo, ls_nombres, ls_seccion,
       ls_desc_seccion, ld_fecha, ln_imp_1,
       ln_imp_2, ln_imp_3, ln_imp_t) ;
  End if ;

End loop ;

End usp_devengado_mes ;
/
