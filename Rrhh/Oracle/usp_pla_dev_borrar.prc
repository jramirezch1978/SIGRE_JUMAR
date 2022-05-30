create or replace procedure usp_pla_dev_borrar (
  as_codtra      in maestro.cod_trabajador%type ,
  ad_fec_proceso in date ) is
  
ls_mes            char(2) ;
ls_year           char(4) ;

begin

ls_mes  := to_char(ad_fec_proceso, 'MM') ;
ls_year := to_char(ad_fec_proceso, 'YYYY') ;
 
--  Elimina registros adicionados en el mes a las tablas
--  Gratificaciones, Remuneraciones y Raciones de Azucar

DELETE FROM maestro_remun_gratif_dev mrg
  WHERE to_char(mrg.fec_calc_int, 'MM') = ls_mes
        and to_char(mrg.fec_calc_int, 'YYYY') = ls_year
        and mrg.cod_trabajador = as_codtra ;
  COMMIT;
    
DELETE FROM racion_azucar_deveng rad
  WHERE to_char(rad.fec_proceso, 'MM') = ls_mes
        and to_char(rad.fec_proceso, 'YYYY') = ls_year
        and rad.cod_trabajador = as_codtra ;
  COMMIT;

end usp_pla_dev_borrar ;
/
