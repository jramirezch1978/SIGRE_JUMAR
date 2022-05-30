create or replace procedure usp_rpt_jub_adelantos ( as_nada in string )is

ln_orden               number(3,0) ;     
ls_codigo              detalle_deuda_jubilado.cod_jubilado%type ;
ln_secuencia           detalle_deuda_jubilado.sec_herederos%type ;
ls_concepto            detalle_deuda_jubilado.concep%type ;
ld_fecha_proceso       detalle_deuda_jubilado.fec_pago%type ;
ln_adelant_mes         detalle_deuda_jubilado.dscto_adel_mes%type ;

ls_cod_jubilado        mov_variable_jubilado.cod_jubilado%type ;
ln_nro_secuencia       mov_variable_jubilado.nro_secuencial%type ;

ls_nombres             varchar2(120) ;
ld_fec_proceso         date ;
ls_origen              char(2) ;

ln_adelant_01          number(13,2) ;
ln_adelant_02          number(13,2) ;
ln_adelant_03          number(13,2) ;
ln_adelant_04          number(13,2) ;
ln_adelant_05          number(13,2) ;
ln_adelant_06          number(13,2) ;
ln_adelant_07          number(13,2) ;
ln_adelant_08          number(13,2) ;
ln_adelant_09          number(13,2) ;
ln_adelant_10          number(13,2) ;
ln_adelant_11          number(13,2) ;
ln_adelant_12          number(13,2) ;
ln_adelant_13          number(13,2) ;
ln_adelant_total       number(13,2) ;

--  Cursor para seleccion de jubilados
cursor c_movimiento is 
  Select mvj.cod_jubilado, mvj.nro_secuencial
  from mov_variable_jubilado mvj
  where mvj.flag_estado = '1' 
  order by mvj.cod_jubilado, mvj.nro_secuencial ;

--  Cursor para hallar adelantos mensuales
cursor c_adelantos is 
  Select ddj.cod_jubilado, ddj.sec_herederos, ddj.concep,
         ddj.fec_pago, ddj.factor_emplear, ddj.sldo_capital_mes_ant,
         ddj.sldo_interes_mes_ant, ddj.int_mes, ddj.dscto_adel_mes,
         ddj.dscto_int_mes_ant
  from detalle_deuda_jubilado ddj
  where ddj.cod_jubilado  = ls_cod_jubilado and
        ddj.sec_herederos = ln_nro_secuencia and
        ddj.fec_pago      = ld_fec_proceso 
  order by ddj.fec_pago, ddj.cod_jubilado, ddj.sec_herederos,
           ddj.concep ;

begin

delete from tt_rpt_jub_adelantos ;

--  Selecciona fecha de proceso
select p.cod_origen
  into ls_origen
  from genparam p
  where p.reckey = '1' ;
  
select p.fec_proceso
  into ld_fec_proceso
  from rrhh_param_org p
  where p.origen = ls_origen ;
  
--Select rh.fec_proceso
--  into ld_fec_proceso
--  from rrhhparam rh where rh.reckey = '1' ;
  
ln_orden := 0 ;  

For rc_mov in c_movimiento Loop  

  ls_cod_jubilado  := rc_mov.cod_jubilado ;
  ln_nro_secuencia := rc_mov.nro_secuencial ;

  Select rtrim(hj.apel_paterno)||' '||rtrim(hj.apel_materno)||' '||
         nvl(rtrim(hj.nombre1),' ')||' '||nvl(rtrim(hj.nombre2),' ')
    into ls_nombres
    from herederos_jubilados hj
    where hj.cod_jubilado  = ls_cod_jubilado and
          hj.sec_herederos = ln_nro_secuencia ;
  ls_nombres := nvl(ls_nombres,' ') ;

  ln_adelant_01 := 0 ;  ln_adelant_02 := 0 ;  ln_adelant_03 := 0 ;
  ln_adelant_04 := 0 ;  ln_adelant_05 := 0 ;  ln_adelant_06 := 0 ;
  ln_adelant_07 := 0 ;  ln_adelant_08 := 0 ;  ln_adelant_09 := 0 ;
  ln_adelant_10 := 0 ;  ln_adelant_11 := 0 ;  ln_adelant_12 := 0 ;
  ln_adelant_13 := 0 ;

  For rc_ade in c_adelantos Loop  

    ls_concepto    := rc_ade.concep ;
    ln_adelant_mes := rc_ade.dscto_adel_mes ;
    ln_adelant_mes := nvl(ln_adelant_mes,0) ;
  
    If ls_concepto = '5001' Then 
      ln_adelant_01 := ln_adelant_mes ;
    ElsIF ls_concepto = '5002' Then
      ln_adelant_02 := ln_adelant_mes ;
    ElsIF ls_concepto = '5003' Then
      ln_adelant_03 := ln_adelant_mes ;
    ElsIF ls_concepto = '5004' Then
      ln_adelant_04 := ln_adelant_mes ;
    ElsIF ls_concepto = '5005' Then
      ln_adelant_05 := ln_adelant_mes ;
    ElsIF ls_concepto = '5006' Then
      ln_adelant_06 := ln_adelant_mes ;
    ElsIF ls_concepto = '5007' Then
      ln_adelant_07 := ln_adelant_mes ;
    ElsIF ls_concepto = '5008' Then
      ln_adelant_08 := ln_adelant_mes ;
    ElsIF ls_concepto = '5009' Then
      ln_adelant_09 := ln_adelant_mes ;
    ElsIF ls_concepto = '5010' Then
      ln_adelant_10 := ln_adelant_mes ;
    ElsIF ls_concepto = '5011' Then
      ln_adelant_11 := ln_adelant_mes ;
    ElsIF ls_concepto = '5012' Then
      ln_adelant_12 := ln_adelant_mes ;
    ElsIF ls_concepto = '5013' Then
      ln_adelant_13 := ln_adelant_mes ;
    End If ;

  End loop ;
                      
  ln_adelant_total := ln_adelant_01 + ln_adelant_02 + ln_adelant_03 + ln_adelant_04 +
                      ln_adelant_05 + ln_adelant_06 + ln_adelant_07 + ln_adelant_08 +
                      ln_adelant_09 + ln_adelant_10 + ln_adelant_11 + ln_adelant_12 +
                      ln_adelant_13 ;
                    
  --  Insertar los Registro en la tabla tt_rpt_jub_adelantos
  If ln_adelant_total > 0 then

    ln_orden := ln_orden + 1 ;
    Insert into tt_rpt_jub_adelantos
      (orden, codigo, secuencia, nombres, 
       adelant_01, adelant_02, adelant_03, adelant_04,
       adelant_05, adelant_06, adelant_07, adelant_08,
       adelant_09, adelant_10, adelant_11, adelant_12,
       adelant_13, adelant_total, fecha_proceso)
    Values
      (ln_orden, ls_cod_jubilado, ln_nro_secuencia, ls_nombres,
       ln_adelant_01, ln_adelant_02, ln_adelant_03, ln_adelant_04,
       ln_adelant_05, ln_adelant_06, ln_adelant_07, ln_adelant_08,
       ln_adelant_09, ln_adelant_10, ln_adelant_11, ln_adelant_12,
       ln_adelant_13, ln_adelant_total, ld_fec_proceso ) ;

  End if ;
     
End loop ;
                     
End usp_rpt_jub_adelantos ;
/
