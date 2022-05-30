SELECT distinct(m.cod_trabajador), 
       TRIM(m.apel_paterno) ||' '||TRIM(m.apel_materno)||', '|| trim(m.nombre1)||' '||TRIM(NVL(m.nombre2,' ')) as nombre, 
       m.fec_ingreso, m.fec_cese 
  FROM maestro m, historico_calculo hc 
 WHERE m.cod_trabajador = hc.cod_trabajador and 
       to_char(hc.fec_calc_plan,'yyyy') = '2007' AND
       ( ( m.fec_ingreso > hc.fec_calc_plan ) OR ( NVL(m.fec_cese, to_date('31/12/2007','dd/mm/yyyy')) < hc.fec_calc_plan ) )
order by m.cod_trabajador 