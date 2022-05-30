create or replace procedure usp_rh_liq_reporte_trabajador (
  as_cod_trabajador in char, as_nombres in char ) is

begin

--  *************************************************************************
--  ***   GENERACION DE ARCHIVOS TEMPORALES PARA EMISION DE LIQUIDACION   ***
--  *************************************************************************

--  Informacion de cabecera de la liquidacion
usp_rh_liq_rpt_cabecera
  ( as_cod_trabajador, as_nombres ) ;

--  Detalle de liquidacion por fondo de retiro
usp_rh_liq_rpt_fondo_retiro
  ( as_cod_trabajador ) ;

--  Detalle de liquidacion por C.T.S.
usp_rh_liq_rpt_cts
  ( as_cod_trabajador ) ;

--  Detalle de liquidacion por compensacion adicional
usp_rh_liq_rpt_comp_adicional
  ( as_cod_trabajador ) ;

--  Detalle de liquidacion por descuento de beneficios sociales
usp_rh_liq_rpt_dscto_bensoc
  ( as_cod_trabajador ) ;

--  Detalle de liquidacion por pago de remuneraciones pendientes
usp_rh_liq_rpt_pago_remune
  ( as_cod_trabajador ) ;

--  Detalle de liquidacion por descuentos de leyes sociales
usp_rh_liq_rpt_dscto_leysoc
  ( as_cod_trabajador ) ;

--  Detalle de liquidacion por retencion judicial
usp_rh_liq_rpt_ret_judicial
  ( as_cod_trabajador ) ;

--  Detalle de liquidacion por aportaciones patronales
usp_rh_liq_rpt_aportaciones
  ( as_cod_trabajador ) ;

--  Determina importe bruto de la liquidacion
usp_rh_liq_rpt_importe_bruto
  ( as_cod_trabajador ) ;

end usp_rh_liq_reporte_trabajador ;
/
