create or replace procedure usp_jub_actualiza_saldos
   ( ad_fec_proceso   in date
   ) is

ls_codigo              detalle_deuda_jubilado.cod_jubilado%type ;
ln_secuencia           detalle_deuda_jubilado.sec_herederos%type ;
ls_concepto            detalle_deuda_jubilado.concep%type ;
ld_fecha_pago          detalle_deuda_jubilado.fec_pago%type ;
ln_factor_emplear      detalle_deuda_jubilado.factor_emplear%type ;
ln_saldo_capital_ant   detalle_deuda_jubilado.sldo_capital_mes_ant%type ;
ln_saldo_interes_ant   detalle_deuda_jubilado.sldo_interes_mes_ant%type ;
ln_interes_mes         detalle_deuda_jubilado.int_mes%type ;
ln_adelanto_mes        detalle_deuda_jubilado.dscto_adel_mes%type ;
ln_interes_fijo_ant    detalle_deuda_jubilado.dscto_int_mes_ant%type ;

ld_fecha_mes_ant       sldo_deuda_jubilado.fec_actual%type ;

ls_flag_estado         sldo_deuda_jubilado.flag_estado%type ;
ln_importe_original    sldo_deuda_jubilado.imp_original%type ;
ln_interes_original    sldo_deuda_jubilado.imp_acum_interes%type ;
ln_acumulado_capital   sldo_deuda_jubilado.imp_acum_adel_capital%type ;
ln_acumulado_interes   sldo_deuda_jubilado.imp_acum_adel_interes%type ;
ln_saldo_capital       sldo_deuda_jubilado.imp_sldo_capital%type ;
ln_saldo_interes       sldo_deuda_jubilado.imp_sldo_interes%type ;

--  Cursor para hallar fecha del mes anterior
Cursor c_detalle is
  Select ddj.cod_jubilado, ddj.sec_herederos, ddj.concep,
         ddj.fec_pago, ddj.factor_emplear, ddj.sldo_capital_mes_ant,
         ddj.sldo_interes_mes_ant, ddj.int_mes,
         ddj.dscto_adel_mes, ddj.dscto_int_mes_ant
  from detalle_deuda_jubilado ddj
  where ddj.fec_pago = ad_fec_proceso
  order by ddj.cod_jubilado, ddj.sec_herederos, ddj.concep ;

begin

--  Borra registros del mes de proceso para volver a actualizar
DELETE FROM sldo_deuda_jubilado bs
  WHERE bs.fec_actual = ad_fec_proceso ;

--  Realiza lectura para actualizacion de saldos
For rc_det in c_detalle Loop

  ls_codigo            := rc_det.cod_jubilado ;
  ln_secuencia         := rc_det.sec_herederos ;
  ls_concepto          := rc_det.concep ;
  ld_fecha_pago        := rc_det.fec_pago ;
  ln_factor_emplear    := rc_det.factor_emplear ;
  ln_saldo_capital_ant := rc_det.sldo_capital_mes_ant ;
  ln_saldo_interes_ant := rc_det.sldo_interes_mes_ant ;
  ln_interes_mes       := rc_det.int_mes ;
  ln_adelanto_mes      := rc_det.dscto_adel_mes ;
  ln_interes_fijo_ant  := rc_det.dscto_int_mes_ant ;

  ln_saldo_capital_ant := nvl(ln_saldo_capital_ant,0) ;
  ln_saldo_interes_ant := nvl(ln_saldo_interes_ant,0) ;
  ln_interes_mes       := nvl(ln_interes_mes,0) ;
  ln_adelanto_mes      := nvl(ln_adelanto_mes,0) ;
  ln_interes_fijo_ant  := nvl(ln_interes_fijo_ant,0) ;

  ld_fecha_mes_ant := add_months(ad_fec_proceso, - 1) ;

  Select sdj.flag_estado, sdj.imp_original, sdj.imp_acum_interes,
         sdj.imp_acum_adel_capital, sdj.imp_acum_adel_interes,
         sdj.imp_sldo_capital, sdj.imp_sldo_interes
    into ls_flag_estado, ln_importe_original, ln_interes_original,
         ln_acumulado_capital, ln_acumulado_interes,
         ln_saldo_capital, ln_saldo_interes
    from sldo_deuda_jubilado sdj
    where sdj.fec_actual    = ld_fecha_mes_ant and
          sdj.cod_jubilado  = ls_codigo and
          sdj.sec_herederos = ln_secuencia and
          sdj.concep        = ls_concepto ;

  ls_flag_estado       := nvl(ls_flag_estado,'0') ;
  ln_importe_original  := nvl(ln_importe_original,0) ;
  ln_interes_original  := nvl(ln_interes_original,0) ;
  ln_acumulado_capital := nvl(ln_acumulado_capital,0) ;
  ln_acumulado_interes := nvl(ln_acumulado_interes,0) ;
  ln_saldo_capital     := nvl(ln_saldo_capital,0) ;
  ln_saldo_interes     := nvl(ln_saldo_interes,0) ;

  --  Actualizacion de saldos al mes de proceso
  ln_acumulado_capital := ln_acumulado_capital + ln_adelanto_mes ;
  ln_acumulado_interes := ln_acumulado_interes + ln_interes_mes ;
  
  ln_saldo_capital := ln_saldo_capital - ln_adelanto_mes ;
  If ln_saldo_capital < 0 then
    ln_saldo_capital := ln_saldo_capital * (-1) ;
    ln_saldo_interes := ln_saldo_interes - ln_saldo_capital ;
    ln_saldo_capital := 0 ;
  End if ;
  ln_saldo_interes := ln_saldo_interes + ln_interes_mes ;
  
  If (ln_saldo_capital + ln_saldo_interes) = 0 then
    ls_flag_estado := '0' ;
  End if ;

  --  Adiciona registro de saldos a deuda de jubilado
  Insert into sldo_deuda_jubilado
    ( cod_jubilado, sec_herederos, concep, fec_actual,
      flag_estado, imp_original, imp_acum_interes,
      imp_acum_adel_capital, imp_acum_adel_interes,
      imp_sldo_capital, imp_sldo_interes )
  Values     
    ( ls_codigo, ln_secuencia, ls_concepto, ad_fec_proceso,
      ls_flag_estado, ln_importe_original, ln_interes_original,
      ln_acumulado_capital, ln_acumulado_interes,
      ln_saldo_capital, ln_saldo_interes ) ;
  
End Loop ;

End usp_jub_actualiza_saldos ;
/
