create or replace procedure usp_rpt_jub_mov_variable is

ls_codigo              mov_variable_jubilado.cod_jubilado%type ;
ln_secuencia           mov_variable_jubilado.nro_secuencial%type ;
ls_flag_estado         mov_variable_jubilado.flag_estado%type ;
ld_fecha_proceso       mov_variable_jubilado.fecha_proceso%type ;
ln_fijo                mov_variable_jubilado.imp_fijo%type ;
ln_interes             mov_variable_jubilado.imp_interes%type ;
ln_variable            mov_variable_jubilado.imp_variable%type ;
ln_caja                mov_variable_jubilado.imp_adelanto_caja%type ;

ln_adelanto_mes        number(13,2) ;
ln_saldo_capital       number(13,2) ;
ln_saldo_interes       number(13,2) ;
ln_capital_interes     number(13,2) ;
ln_diferencia          number(13,2) ;

ld_fecha_mes_ant       sldo_deuda_jubilado.fec_actual%type ;
ls_flag_juicio         char(1) ;
ls_nombres             varchar2(120) ;
ls_nombres_apoderados  varchar2(120) ;
ln_registros           number(13,0) ;

--  Cursor para pagos de adelantos de jubilados
cursor c_movimiento is 
  Select mvj.cod_jubilado, mvj.nro_secuencial, mvj.flag_estado,
         mvj.fecha_proceso, mvj.imp_fijo, mvj.imp_interes,
         mvj.imp_variable, mvj.imp_adelanto_caja
  from mov_variable_jubilado mvj
  where mvj.flag_estado = '1' ;

begin

delete from tt_rpt_jub_mov_variable ;

For rc_mov in c_movimiento Loop  

  ls_codigo        := rc_mov.cod_jubilado ;
  ln_secuencia     := rc_mov.nro_secuencial ;
  ls_flag_estado   := rc_mov.flag_estado ;
  ld_fecha_proceso := rc_mov.fecha_proceso ;
  ln_fijo          := rc_mov.imp_fijo ;
  ln_interes       := rc_mov.imp_interes ;
  ln_variable      := rc_mov.imp_variable ;
  ln_caja          := rc_mov.imp_adelanto_caja ;

  ln_fijo     := nvl(ln_fijo,0) ;
  ln_interes  := nvl(ln_interes,0) ;
  ln_variable := nvl(ln_variable,0) ;
  ln_caja     := nvl(ln_caja,0) ;

  ld_fecha_mes_ant := add_months(ld_fecha_proceso, - 1) ;
  ln_adelanto_mes := ln_fijo + ln_interes +
                     ln_variable + ln_caja ;
                     
  Select rtrim(hj.apel_paterno)||' '||rtrim(hj.apel_materno)||' '||
         nvl(rtrim(hj.nombre1),' ')||' '||nvl(rtrim(hj.nombre2),' ')
    into ls_nombres
    from herederos_jubilados hj
    where hj.cod_jubilado  = ls_codigo and
          hj.sec_herederos = ln_secuencia ;
  ls_nombres := nvl(ls_nombres,' ') ;

  Select m.flag_juicio
    into ls_flag_juicio
    from maestro m
    where m.cod_trabajador = ls_codigo ;
  ls_flag_juicio := nvl(ls_flag_juicio,'0') ;
    
  Select sum(sdj.imp_sldo_capital), sum(sdj.imp_sldo_interes)
    into ln_saldo_capital, ln_saldo_interes
    from sldo_deuda_jubilado sdj
    where sdj.cod_jubilado = ls_codigo and
          sdj.sec_herederos = ln_secuencia and
          sdj.fec_actual = ld_fecha_mes_ant and
          sdj.flag_estado = '1' ;
          
  ln_saldo_capital := nvl(ln_saldo_capital,0) ;
  ln_saldo_interes := nvl(ln_saldo_interes,0) ;

  ln_capital_interes := ln_saldo_capital + ln_saldo_interes ;
  If ln_adelanto_mes > ln_capital_interes then
    ln_diferencia := ln_adelanto_mes - ln_capital_interes ;
  Else
    ln_diferencia := 0 ;
  End if ;

  If ls_flag_juicio = '1' then
    ln_adelanto_mes := 0 ;
    ln_diferencia   := 0 ;
  End if ;

  ln_registros := 0 ;
  Select count(*)
    into ln_registros
    from apoderado_jubilado ap
    where ap.cod_jubilado = ls_codigo ;
  ln_registros := nvl(ln_registros,0) ;
       
  If ln_registros > 0 then
    Select rtrim(ap.apel_paterno_apod)||' '||rtrim(ap.apel_materno_apod)||' '||
           nvl(rtrim(ap.nombre1_apod),' ')||' '||nvl(rtrim(ap.nombre2_apod),' ')
      into ls_nombres_apoderados
      from apoderado_jubilado ap
      where ap.cod_jubilado  = ls_codigo ;
    ls_nombres_apoderados := nvl(ls_nombres_apoderados,' ') ;
  End if ;
                           
  ln_registros := 0 ;
  Select count(*)
    into ln_registros
    from herederos_jubilados hj
    where hj.cod_jubilado  = ls_codigo and
          hj.sec_herederos = ln_secuencia ;
  ln_registros := nvl(ln_registros,0) ;
       
  If ln_registros > 0 then
    Select hj.nom_apoderado
      into ls_nombres_apoderados
      from herederos_jubilados hj
      where hj.cod_jubilado  = ls_codigo and
            hj.sec_herederos = ln_secuencia ;
    ls_nombres_apoderados := nvl(ls_nombres_apoderados,' ') ;
  End if ;

  --  Insertar los Registro en la tabla tt_rpt_jub_mov_variable
  Insert into tt_rpt_jub_mov_variable
    (codigo, secuencia, nombres, nombres_apoderados,
     importe_fijo, importe_interes, importe_variable, importe_caja,
     importe_total, importe_saldo, importe_diferencia, fecha_proceso)
  Values
    (ls_codigo, ln_secuencia, ls_nombres, ls_nombres_apoderados,
     ln_fijo, ln_interes, ln_variable, ln_caja,
     ln_adelanto_mes, ln_capital_interes, ln_diferencia, ld_fecha_proceso ) ;

End loop ;
                     
End usp_rpt_jub_mov_variable ;
/
