create or replace procedure usp_flujo_caja_real
  ( as_tipo_moneda       in maestro.flag_estado%type,
    ad_fec_proceso       in calculo.fec_proceso%type
  ) is

--  Variables
ls_concepto         concepto.concep%type ;
ln_tipo_cambio      calendario.cmp_dol_prom%type ;
ln_periodo          number(4) ;
ln_mes              number(2) ;
ln_impsol           number(13,2) ;
ln_impdol           number(13,2) ;
ls_cod_flujo        char(10) ;
ls_des_gasper       char(10) ;
ls_des_gasgra       char(10) ;
ls_des_gascts       char(10) ;
ln_gasper_s         number(13,2) ;
ln_gratif_s         number(13,2) ;
ln_impcts_s         number(13,2) ;
ln_gasper_d         number(13,2) ;
ln_gratif_d         number(13,2) ;
ln_impcts_d         number(13,2) ;
ln_contador         number(15) ;

--  Registros calculados en la planilla mensual
Cursor c_calculo is
  Select c.concep, c.imp_soles, c.imp_dolar
  from calculo c
  where c.fec_proceso = ad_fec_proceso and
        (substr(c.concep,1,1) = '1' or substr(c.concep,1,1) = '3')
  order by c.cod_trabajador, c.concep ;

begin

--  Elimina registros de la planilla mensual
delete from flujo_caja fc
  where (fc.cod_flujo_caja = 'GASPER    ' or
         fc.cod_flujo_caja = 'GASGRA    ' or
         fc.cod_flujo_caja = 'GASCTS    ') and
         fc.periodo = to_number(to_char(ad_fec_proceso,'YYYY')) and
         fc.mes = to_number(to_char(ad_fec_proceso,'MM')) and
         fc.flag_flujo = 'R' ;

ln_periodo := to_number(to_char(ad_fec_proceso,'YYYY')) ;
ln_mes     := to_number(to_char(ad_fec_proceso,'MM')) ;

ln_contador := 0 ; ln_tipo_cambio := 1 ;
Select count(*)
  into ln_contador
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_contador := nvl(ln_contador,0) ;

If ln_contador > 0 then  
  Select tc.vta_dol_prom
    into ln_tipo_cambio
    from calendario tc
    where tc.fecha= ad_fec_proceso ;
  ln_tipo_cambio := nvl(ln_tipo_cambio,1) ;
End if ;

ln_gasper_s := 0 ; ln_gasper_d := 0 ;
ln_gratif_s := 0 ; ln_gratif_d := 0 ;
ln_impcts_s := 0 ; ln_impcts_d := 0 ;

For rc_cal in c_calculo loop

  ls_concepto := rc_cal.concep ;
  ln_impsol   := rc_cal.imp_soles ;
  ln_impdol   := rc_cal.imp_dolar ;
  ln_impsol   := nvl(ln_impsol,0) ;
  ln_impdol   := nvl(ln_impdol,0) ;

  If ls_concepto <> '1450' and ls_concepto <> '3050' then

    Select con.cod_flujo_caja
      into ls_cod_flujo
      from concepto con
      where con.concep = ls_concepto ;
    ls_cod_flujo := nvl(ls_cod_flujo,' ') ;

    If ls_cod_flujo = 'GASPER    ' then
      ln_gasper_s   := ln_gasper_s + ln_impsol ;
      ln_gasper_d   := ln_gasper_d + ln_impdol ;
      ls_des_gasper := 'GASPER    ' ;
    Elsif ls_cod_flujo = 'GASGRA    ' then
      ln_gratif_s   := ln_gratif_s + ln_impsol ;
      ln_gratif_d   := ln_gratif_d + ln_impdol ;
      ls_des_gasgra := 'GASGRA    ' ;
    Elsif ls_cod_flujo = 'GASCTS    ' then
      ln_impcts_s   := ln_impcts_s + ln_impsol ;
      ln_impcts_d   := ln_impcts_d + ln_impdol ;
      ls_des_gascts := 'GASCTS    ' ;
    End if ;

  End if ;

End Loop ;

If as_tipo_moneda = 'S' then      --  Graba en Soles

  If ln_gasper_s > 0 then
    Insert into flujo_caja
      ( cod_flujo_caja, periodo, mes, flag_flujo,
        cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
    Values
      ( ls_des_gasper, ln_periodo, ln_mes, 'R',
        ln_gasper_s, '1', 'S/.', 0 ) ;
  End if ;
  If ln_gratif_s > 0 then
    Insert into flujo_caja
      ( cod_flujo_caja, periodo, mes, flag_flujo,
        cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
    Values
      ( ls_des_gasgra, ln_periodo, ln_mes, 'R',
        ln_gratif_s, '1', 'S/.', 0 ) ;
  End if ;
  If ln_impcts_s > 0 then
    Insert into flujo_caja
      ( cod_flujo_caja, periodo, mes, flag_flujo,
        cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
    Values
      ( ls_des_gascts, ln_periodo, ln_mes, 'R',
        ln_impcts_s, '1', 'S/.', 0 ) ;
  End if ;

Elsif as_tipo_moneda = 'D' then   --  Graba en Dolares

  If ln_gasper_d > 0 then
    Insert into flujo_caja
      ( cod_flujo_caja, periodo, mes, flag_flujo,
        cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
    Values
      ( ls_des_gasper, ln_periodo, ln_mes, 'R',
        ln_gasper_d, '1', 'US$', ln_tipo_cambio ) ;
  End if ;
  If ln_gratif_d > 0 then
    Insert into flujo_caja
      ( cod_flujo_caja, periodo, mes, flag_flujo,
        cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
    Values
      ( ls_des_gasgra, ln_periodo, ln_mes, 'R',
        ln_gratif_d, '1', 'US$', ln_tipo_cambio ) ;
  End if ;
  If ln_impcts_d > 0 then
    Insert into flujo_caja
      ( cod_flujo_caja, periodo, mes, flag_flujo,
        cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
    Values
      ( ls_des_gascts, ln_periodo, ln_mes, 'R',
        ln_impcts_d, '1', 'US$', ln_tipo_cambio ) ;
  End if ;

End if ;
       
End usp_flujo_caja_real ;
/
