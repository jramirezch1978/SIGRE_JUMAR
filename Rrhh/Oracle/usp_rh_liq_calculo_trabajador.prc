create or replace procedure usp_rh_liq_calculo_trabajador (
  as_cod_trabajador in char, ad_fec_liquidacion in date, as_nombres in char,
  as_usuario in char ) is

--  Variables
ln_verifica             integer ;
ls_nro_liquidacion      char(10) ;

begin

--  ****************************************************
--  ***   GENERA LIQUIDACION DE CREDITOS LABORALES   ***
--  ****************************************************

--  Verifica si la liquidacion ha sido aprobada
ln_verifica := 0 ;
select count(*) into ln_verifica from rh_liq_credito_laboral l
  where l.cod_trabajador = as_cod_trabajador and l.flag_estado = '2' ;
if ln_verifica > 0 then
  select l.nro_liquidacion into ls_nro_liquidacion
    from rh_liq_credito_laboral l
    where l.cod_trabajador = as_cod_trabajador ;
  raise_application_error
    ( -20000, 'La liquidación '||ls_nro_liquidacion||' del trabajador '||as_nombres||' '||
              'con código '||as_cod_trabajador||' No puede ser procesada. Ya está aprobada') ;
end if ;

--  Elimina movimiento de liquidacion por trabajador
delete from rh_liq_remuneracion l
  where l.cod_trabajador = as_cod_trabajador ;
delete from rh_liq_dscto_leyes_aportes l
  where l.cod_trabajador = as_cod_trabajador ;
delete from rh_liq_cts l
  where l.cod_trabajador = as_cod_trabajador ;
delete from rh_liq_fondo_retiro l
  where l.cod_trabajador = as_cod_trabajador ;
delete from rh_liq_tiempo_efectivo l
  where l.cod_trabajador = as_cod_trabajador ;
delete from rh_liq_cnta_crrte_cred_lab l
  where l.cod_trabajador = as_cod_trabajador ;
delete from rh_liq_credito_laboral l
  where l.cod_trabajador = as_cod_trabajador ;

--  ********************************************************
--  ***   LIQUIDACION DE PAGOS POR BENEFICIOS SOCIALES   ***
--  ********************************************************

--  Calcula fondo de retiro
usp_rh_liq_fondo_retiro
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  Calcula compensacion por tiempo de servicio
usp_rh_liq_cts
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  Calcula compensacion adicional -  Articulo 75 D.S. 001-97-TR
usp_rh_liq_comp_adicional
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  *************************************************************
--  ***   LIQUIDACION DE DESCUENTOS POR BENEFICIOS SOCIALES   ***
--  *************************************************************

--  Descuentos de adelantos de C.T.S. y Beneficios Sociales
usp_rh_liq_adelantos
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  Descuentos de cuentas por cobrar ( Cuenta Corriente )
usp_rh_liq_cuentas_cobrar
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  Descuentos por retencion judicial de beneficios sociales
usp_rh_liq_ret_judicial_bensoc
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  **************************************************************
--  ***   LIQUIDACION DE PAGOS POR REMUNERACIONES PENDIENTES   ***
--  **************************************************************

--  Calculo de devengados ( Gratificaciones, Remuneraciones y Raciones )
usp_rh_liq_devengados
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  Calculo de vacaciones y asignacion vacacional
usp_rh_liq_vacaciones_asig
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  Calculo de remuneraciones truncas ( Gratificaciones y Vacaciones )
usp_rh_liq_remun_truncas
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  *********************************************************************
--  ***   DESCUENTOS DE LEYES SOCIALES DE REMUNERACIONES PENDIENTES   ***
--  *********************************************************************

--  Descuentos de leyes sociales de las remuneraciones
usp_rh_liq_descuento_leyes
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  Descuentos por retencion judicial de remuneraciones
usp_rh_liq_ret_judicial_remune
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  *******************************************************************
--  ***   DESCUENTOS DE APORTACIONES SOCIALES PARA LA LIQUIDACION   ***
--  *******************************************************************

--  Descuentos de aportaciones sociales
usp_rh_liq_descuento_aportes
  ( as_cod_trabajador, ad_fec_liquidacion ) ;

--  *******************************************************
--  ***   ACTUALIZACION DE DATOS DE LAS LIQUIDACIONES   ***
--  *******************************************************

--  Actualiza importes de liquidacion de creditos laborales
usp_rh_liq_actualiza_importe
  ( as_cod_trabajador ) ;

--  Calculo de diferido en caso liquidacion sea negativa
usp_rh_liq_diferido
  ( as_cod_trabajador, ad_fec_liquidacion, as_usuario ) ;

end usp_rh_liq_calculo_trabajador ;
/
