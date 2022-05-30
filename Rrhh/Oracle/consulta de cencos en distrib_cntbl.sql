select hc.cod_trabajador,
       m.apel_paterno || ' ' || m.apel_materno || ', ' || m.nombre1 as nom_trabajador, m.tipo_trabajador,
       sum(hc.nro_horas) as nro_horas
from historico_distrib_cntble hc,
     maestro                  m
where m.cod_trabajador = hc.cod_trabajador
  and to_char(hc.fec_movimiento, 'mmyyyy') = '012010'
  and hc.cencos = 'ADCAMPR'
group by hc.cod_trabajador,
       m.apel_paterno || ' ' || m.apel_materno || ', ' || m.nombre1,
        m.tipo_trabajador
