create or replace procedure usp_rpt_jub_saldos
  ( as_nada in string ) is

ln_orden               number(3,0) ;     
ls_codigo              sldo_deuda_jubilado.cod_jubilado%type ;
ln_secuencia           sldo_deuda_jubilado.sec_herederos%type ;
ls_concepto            sldo_deuda_jubilado.concep%type ;
ld_fecha_proceso       sldo_deuda_jubilado.fec_actual%type ;
ls_flag_estado         sldo_deuda_jubilado.flag_estado%type ;
ln_saldo_capital       sldo_deuda_jubilado.imp_sldo_capital%type ;
ln_saldo_interes       sldo_deuda_jubilado.imp_sldo_interes%type ;

ls_cod_jubilado        mov_variable_jubilado.cod_jubilado%type ;
ln_nro_secuencia       mov_variable_jubilado.nro_secuencial%type ;

ln_capital_interes     sldo_deuda_jubilado.imp_sldo_interes%type ;
ls_nombres             varchar2(120) ;
ld_fec_proceso         date ;
ls_origen              char(2) ;

ln_saldo_01            number(13,2) ;
ln_saldo_02            number(13,2) ;
ln_saldo_03            number(13,2) ;
ln_saldo_04            number(13,2) ;
ln_saldo_05            number(13,2) ;
ln_saldo_06            number(13,2) ;
ln_saldo_07            number(13,2) ;
ln_saldo_08            number(13,2) ;
ln_saldo_09            number(13,2) ;
ln_saldo_10            number(13,2) ;
ln_saldo_11            number(13,2) ;
ln_saldo_12            number(13,2) ;
ln_saldo_13            number(13,2) ;
ln_saldo_total         number(13,2) ;

--  Cursor para seleccion de jubilados
cursor c_movimiento is 
  Select mvj.cod_jubilado, mvj.nro_secuencial
  from mov_variable_jubilado mvj
  where mvj.flag_estado = '1' 
  order by mvj.cod_jubilado, mvj.nro_secuencial ;

--  Cursor para hallar saldos por capital e interes
cursor c_saldos is 
  Select sdj.cod_jubilado, sdj.sec_herederos, sdj.concep,
         sdj.fec_actual, sdj.flag_estado, sdj.imp_sldo_capital,
         sdj.imp_sldo_interes
  from sldo_deuda_jubilado sdj
  where sdj.cod_jubilado = ls_cod_jubilado and
        sdj.sec_herederos = ln_nro_secuencia and
        sdj.fec_actual  = ld_fec_proceso and
        sdj.flag_estado = '1' 
  order by sdj.fec_actual, sdj.cod_jubilado, sdj.sec_herederos,
           sdj.concep ;

begin

delete from tt_rpt_jub_saldos ;

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
--  from rrhhparam rh
--  where rh.reckey = '1' ;
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

  ln_saldo_01 := 0 ;  ln_saldo_02 := 0 ;  ln_saldo_03 := 0 ;
  ln_saldo_04 := 0 ;  ln_saldo_05 := 0 ;  ln_saldo_06 := 0 ;
  ln_saldo_07 := 0 ;  ln_saldo_08 := 0 ;  ln_saldo_09 := 0 ;
  ln_saldo_10 := 0 ;  ln_saldo_11 := 0 ;  ln_saldo_12 := 0 ;
  ln_saldo_13 := 0 ;

  For rc_sal in c_saldos Loop  

    ls_concepto      := rc_sal.concep ;
    ln_saldo_capital := rc_sal.imp_sldo_capital ;
    ln_saldo_interes := rc_sal.imp_sldo_interes ;

    ln_saldo_capital := nvl(ln_saldo_capital,0) ;
    ln_saldo_interes := nvl(ln_saldo_interes,0) ;
  
    ln_capital_interes := ln_saldo_capital + ln_saldo_interes ;

    If ls_concepto = '5001' Then 
      ln_saldo_01 := ln_capital_interes ;
    ElsIF ls_concepto = '5002' Then
      ln_saldo_02 := ln_capital_interes ;
    ElsIF ls_concepto = '5003' Then
      ln_saldo_03 := ln_capital_interes ;
    ElsIF ls_concepto = '5004' Then
      ln_saldo_04 := ln_capital_interes ;
    ElsIF ls_concepto = '5005' Then
      ln_saldo_05 := ln_capital_interes ;
    ElsIF ls_concepto = '5006' Then
      ln_saldo_06 := ln_capital_interes ;
    ElsIF ls_concepto = '5007' Then
      ln_saldo_07 := ln_capital_interes ;
    ElsIF ls_concepto = '5008' Then
      ln_saldo_08 := ln_capital_interes ;
    ElsIF ls_concepto = '5009' Then
      ln_saldo_09 := ln_capital_interes ;
    ElsIF ls_concepto = '5010' Then
      ln_saldo_10 := ln_capital_interes ;
    ElsIF ls_concepto = '5011' Then
      ln_saldo_11 := ln_capital_interes ;
    ElsIF ls_concepto = '5012' Then
      ln_saldo_12 := ln_capital_interes ;
    ElsIF ls_concepto = '5013' Then
      ln_saldo_13 := ln_capital_interes ;
    End If ;

  End loop ;
                      
  ln_saldo_total := ln_saldo_01 + ln_saldo_02 + ln_saldo_03 + ln_saldo_04 +
                    ln_saldo_05 + ln_saldo_06 + ln_saldo_07 + ln_saldo_08 +
                    ln_saldo_09 + ln_saldo_10 + ln_saldo_11 + ln_saldo_12 +
                    ln_saldo_13 ;
                    
  --  Insertar los Registro en la tabla tt_rpt_jub_saldos
  If ln_saldo_total > 0 then

    ln_orden := ln_orden + 1 ;
    Insert into tt_rpt_jub_saldos
      (orden, codigo, secuencia, nombres, 
       saldo_01, saldo_02, saldo_03, saldo_04,
       saldo_05, saldo_06, saldo_07, saldo_08,
       saldo_09, saldo_10, saldo_11, saldo_12,
       saldo_13, saldo_total, fecha_proceso)
    Values
      (ln_orden, ls_cod_jubilado, ln_nro_secuencia, ls_nombres,
       ln_saldo_01, ln_saldo_02, ln_saldo_03, ln_saldo_04,
       ln_saldo_05, ln_saldo_06, ln_saldo_07, ln_saldo_08,
       ln_saldo_09, ln_saldo_10, ln_saldo_11, ln_saldo_12,
       ln_saldo_13, ln_saldo_total, ld_fec_proceso ) ;

  End if ;
     
End loop ;
                     
End usp_rpt_jub_saldos ;
/
