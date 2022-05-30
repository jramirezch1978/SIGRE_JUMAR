create or replace procedure usp_rh_dev_borrar (
  as_codtra in char, ad_fec_proceso in date ) is

begin

--  ***********************************************************
--  ***  ELIMINA MOVIMIENTOS DE REMUNERACIONES DEVENGADAS   ***
--  ***********************************************************

delete from maestro_remun_gratif_dev mrg
  where to_char(mrg.fec_calc_int,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy')
        and mrg.cod_trabajador = as_codtra ;
  commit ;

delete from racion_azucar_deveng rad
  where to_char(rad.fec_proceso, 'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy')
        and rad.cod_trabajador = as_codtra ;
  commit ;

end usp_rh_dev_borrar ;
/
