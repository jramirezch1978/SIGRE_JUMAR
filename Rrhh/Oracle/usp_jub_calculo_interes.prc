create or replace procedure usp_jub_calculo_interes
   ( ad_fec_proceso   in date
   ) is

ls_codigo              sldo_deuda_jubilado.cod_jubilado%type ;
ln_secuencia           sldo_deuda_jubilado.sec_herederos%type ;
ls_concepto            sldo_deuda_jubilado.concep%type ;
ln_saldo_capital       sldo_deuda_jubilado.imp_sldo_capital%type ;
ln_saldo_interes       sldo_deuda_jubilado.imp_sldo_interes%type ;
ld_fecha_mes_ant       factor_planilla.fec_calc_int%type ;

ln_fac_pago_ant        factor_planilla.fact_interes%type ;
ln_fac_pago_act        factor_planilla.fact_interes%type ;
ln_factor_emplear      detalle_deuda_jubilado.factor_emplear%type ;
ln_interes_mes         detalle_deuda_jubilado.int_mes%type ;

ln_adelanto_mes        detalle_deuda_jubilado.dscto_adel_mes%type ;
ln_tope_adelanto       detalle_deuda_jubilado.dscto_adel_mes%type ;
ln_importe_fijo        detalle_deuda_jubilado.dscto_int_mes_ant%type ;
ln_interes_fijo        detalle_deuda_jubilado.dscto_int_mes_ant%type ;
ln_importe_variable    detalle_deuda_jubilado.dscto_int_mes_ant%type ;
ln_adelanto_caja       detalle_deuda_jubilado.dscto_int_mes_ant%type ;

ls_flag_juicio         maestro.flag_juicio%type ;

ls_cod_jubilado        detalle_deuda_jubilado.cod_jubilado%type ;
ln_sec_herederos       detalle_deuda_jubilado.sec_herederos%type ;
ls_concep              detalle_deuda_jubilado.concep%type ;

--  Cursor para determinar el adelanto del mes
Cursor c_movimiento is
  Select mvj.cod_jubilado, mvj.nro_secuencial, mvj.flag_estado,
         mvj.fecha_proceso, mvj.imp_fijo, mvj.imp_interes,
         mvj.imp_variable, mvj.imp_adelanto_caja
  from mov_variable_jubilado mvj
  where mvj.flag_estado = '1' ;

--  Cursor para hallar fecha del mes anterior
Cursor c_detalle is
  Select ddj.cod_jubilado, ddj.sec_herederos, ddj.concep,
         ddj.fec_pago, ddj.factor_emplear, ddj.sldo_capital_mes_ant,
         ddj.sldo_interes_mes_ant, ddj.int_mes,
         ddj.dscto_adel_mes, ddj.dscto_int_mes_ant
  from detalle_deuda_jubilado ddj
  order by ddj.fec_pago ;

--  Cursor para actualizar adelantos del mes
Cursor c_detalle_deuda is
  Select dda.cod_jubilado, dda.sec_herederos, dda.concep,
         dda.fec_pago, dda.factor_emplear, dda.sldo_capital_mes_ant,
         dda.sldo_interes_mes_ant, dda.int_mes,
         dda.dscto_adel_mes, dda.dscto_int_mes_ant
  from detalle_deuda_jubilado dda
  where dda.cod_jubilado = ls_codigo and
            dda.sec_herederos = ln_secuencia and
            dda.fec_pago = ad_fec_proceso
  order by dda.cod_jubilado, dda.sec_herederos, dda.concep
  for update ;

--  Saldo de jubilados por conceptos
Cursor c_saldos is
  Select sdj.cod_jubilado, sdj.sec_herederos, sdj.concep,
         sdj.fec_actual, sdj.flag_estado, sdj.imp_original,
         sdj.imp_acum_interes, sdj.imp_acum_adel_capital,
         sdj.imp_acum_adel_interes, sdj.imp_sldo_capital,
         sdj.imp_sldo_interes
  from sldo_deuda_jubilado sdj
  where sdj.fec_actual = ld_fecha_mes_ant 
        order by sdj.cod_jubilado, sdj.sec_herederos, sdj.concep ;
        
begin

--  Borra registros del mes de proceso para volver a calcular
DELETE FROM detalle_deuda_jubilado bd
  WHERE bd.fec_pago = ad_fec_proceso ;

--  Realiza lectura para hallar ultima fecha de proceso
For rc_det in c_detalle Loop
  ld_fecha_mes_ant := rc_det.fec_pago ;
End Loop ;
ld_fecha_mes_ant := nvl(ld_fecha_mes_ant,ad_fec_proceso) ;
If ld_fecha_mes_ant = ad_fec_proceso then
  ld_fecha_mes_ant := add_months(ad_fec_proceso, - 1) ;
End if ;

--  Halla factor a emplear para calculo de intereses
Select fp.fact_interes
  into ln_fac_pago_ant
  from factor_planilla fp
  where fp.fec_calc_int = ld_fecha_mes_ant ;
ln_fac_pago_ant := nvl(ln_fac_pago_ant,0) ;

Select fp.fact_interes
  into ln_fac_pago_act
  from factor_planilla fp
  where fp.fec_calc_int = ad_fec_proceso ;
ln_fac_pago_act := nvl(ln_fac_pago_act,0) ;
        
ln_factor_emplear := ln_fac_pago_act - ln_fac_pago_ant ;

--  Realiza lectura para calculo de intereses
For rc_sal in c_saldos Loop

  ls_codigo        := rc_sal.cod_jubilado ;
  ln_secuencia     := rc_sal.sec_herederos ;
  ls_concepto      := rc_sal.concep ;
  ln_saldo_capital := rc_sal.imp_sldo_capital ;
  ln_saldo_interes := rc_sal.imp_sldo_interes ;
  ln_saldo_capital := nvl(ln_saldo_capital,0) ;
  ln_saldo_interes := nvl(ln_saldo_interes,0) ;

  ln_interes_mes := 0 ;
  If ln_saldo_capital > 0 then
    ln_interes_mes := ln_saldo_capital * ln_factor_emplear ;
  Else
    If ln_saldo_interes > 0 then
      ln_interes_mes := 0 ;
    End if ;
  End if ;

  Select m.flag_juicio
    into ls_flag_juicio
    from maestro m
    where m.cod_trabajador = ls_codigo ;
  ls_flag_juicio:= nvl(ls_flag_juicio,'0') ;
    
  If ls_flag_juicio = '1' then
    ln_adelanto_mes := 0 ;
    ln_interes_mes  := 0 ;
  End if ;

  --  Adiciona registro al detalle de deuda de jubilado
  Insert into detalle_deuda_jubilado
    ( cod_jubilado, sec_herederos, concep, fec_pago,
      factor_emplear, sldo_capital_mes_ant, sldo_interes_mes_ant,
      int_mes, dscto_adel_mes, dscto_int_mes_ant )
  Values     
    ( ls_codigo, ln_secuencia, ls_concepto, ad_fec_proceso,
      ln_factor_emplear, ln_saldo_capital, ln_saldo_interes,
      ln_interes_mes, ln_adelanto_mes, ln_interes_fijo ) ;
    
End Loop ;

--  Realiza lectura para actualizar adelantos
For rc_mov in c_movimiento Loop

  ls_codigo           := rc_mov.cod_jubilado ;
  ln_secuencia        := rc_mov.nro_secuencial ;
  ln_importe_fijo     := rc_mov.imp_fijo ;
  ln_interes_fijo     := rc_mov.imp_interes ;
  ln_importe_variable := rc_mov.imp_variable ;
  ln_adelanto_caja    := rc_mov.imp_adelanto_caja ; 
  
  ln_importe_fijo     := nvl(ln_importe_fijo,0) ;
  ln_interes_fijo     := nvl(ln_interes_fijo,0) ;
  ln_importe_variable := nvl(ln_importe_variable,0) ;
  ln_adelanto_caja    := nvl(ln_adelanto_caja,0) ;
  ln_adelanto_mes     := ln_importe_fijo + ln_interes_fijo +
                         ln_importe_variable + ln_adelanto_caja ;

  Select sum(sdj.imp_sldo_capital), sum(sdj.imp_sldo_interes)
    into ln_saldo_capital, ln_saldo_interes
    from sldo_deuda_jubilado sdj
    where sdj.cod_jubilado = ls_codigo and
          sdj.sec_herederos = ln_secuencia and
          sdj.fec_actual = ld_fecha_mes_ant and
          sdj.flag_estado = '1' ;
          
  ln_saldo_capital := nvl(ln_saldo_capital,0) ;
  ln_saldo_interes := nvl(ln_saldo_interes,0) ;

  ln_tope_adelanto := ln_saldo_capital + ln_saldo_interes ;
  If ln_adelanto_mes > ln_tope_adelanto then
    ln_adelanto_mes := ln_tope_adelanto ;
  End if ;

  For rc_ade in c_detalle_deuda Loop

    ls_cod_jubilado  := rc_ade.cod_jubilado ;
    ln_sec_herederos := rc_ade.sec_herederos ;
    ls_concep        := rc_ade.concep ;
   
    Select sdj.imp_sldo_capital, sdj.imp_sldo_interes
      into ln_saldo_capital, ln_saldo_interes
      from sldo_deuda_jubilado sdj
      where sdj.cod_jubilado = ls_cod_jubilado and
            sdj.sec_herederos = ln_sec_herederos and
            sdj.concep = ls_concep and
            sdj.fec_actual = ld_fecha_mes_ant and
            sdj.flag_estado = '1' ;
          
    ln_saldo_capital := nvl(ln_saldo_capital,0) ;
    ln_saldo_interes := nvl(ln_saldo_interes,0) ;

    ln_tope_adelanto := ln_saldo_capital + ln_saldo_interes ;
    If ln_tope_adelanto >= ln_adelanto_mes then
    --  Actualiza registro
      Update detalle_deuda_jubilado
        Set dscto_adel_mes    = ln_adelanto_mes ,
            dscto_int_mes_ant = ln_interes_fijo
        where current of c_detalle_deuda ;
      Exit ;
    Else
      Update detalle_deuda_jubilado
        Set dscto_adel_mes    = ln_tope_adelanto ,
            dscto_int_mes_ant = ln_interes_fijo
        where current of c_detalle_deuda ;
      ln_adelanto_mes := ln_adelanto_mes - ln_tope_adelanto ;
    End if ;

  End loop ;

End Loop ;

End usp_jub_calculo_interes ;
/
