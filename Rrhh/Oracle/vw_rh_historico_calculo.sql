create or replace view vw_rh_historico_calculo as
select c.concep as concepto,
       c.concep || '-' || c.desc_concep as desc_concepto,
       hc.imp_soles, hc.imp_dolar, hc.fec_calc_plan as fec_proceso,
       DECODE(hc.tipo_trabajador, null, m.tipo_trabajador, hc.tipo_trabajador) as tipo_trabajador,
       m.cod_trabajador,
       m.apel_paterno || ' ' || m.apel_materno || ', ' || m.nombre1 || ' ' || m.nombre2 as nombre_trabajador,
       to_char(hc.fec_calc_plan, 'yyyymm') as periodo,
       to_char(hc.fec_calc_plan, 'yyyy') as año,
       to_char(hc.fec_calc_plan, 'mm') as mes,
       m.nro_doc_ident_rtps as dni,
       s.desc_seccion,
       hc.dias_trabaj
from historico_calculo hc,
     concepto          c,
     maestro           m,
     seccion           s
where hc.concep = c.concep
  and m.cod_area = s.cod_area
  and m.cod_seccion = s.cod_seccion
  and hc.cod_trabajador = m.cod_trabajador
union
select c.concep as concepto,
       c.concep || '-' || c.desc_concep as desc_concepto,
       ca.imp_soles, ca.imp_dolar, ca.fec_proceso,
       m.tipo_trabajador,
       m.cod_trabajador,
       m.apel_paterno || ' ' || m.apel_materno || ', ' || m.nombre1 || ' ' || m.nombre2 as nombre_trabajador,
       to_char(ca.fec_proceso, 'yyyymm') as periodo,
       to_char(ca.fec_proceso, 'yyyy') as año,
       to_char(ca.fec_proceso, 'mm') as mes,
       m.nro_doc_ident_rtps as dni,
       s.desc_seccion,
       ca.dias_trabaj
from calculo           ca,
     concepto          c,
     maestro           m,
     seccion           s
where ca.concep = c.concep
  and m.cod_area = s.cod_area
  and m.cod_seccion = s.cod_seccion
  and ca.cod_trabajador = m.cod_trabajador  ;
