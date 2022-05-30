select hc.tipo_trabajador,
       to_char(hc.fec_calc_plan, 'yyyymm') as periodo,
       m.COD_TRABAJADOR,
       m.NOM_TRABAJADOR,
       c.concep,
       c.desc_concep,
       sum(hc.imp_soles) as imp_soles,
       decode(ct.cnta_cntbl_debe, null, null, ct.cnta_cntbl_debe) as cnta_cntbl_debe,
       decode(ct.cnta_cntbl_haber, null, null, ct.cnta_cntbl_haber) as cnta_cntbl_haber,
       sum(decode(ct.cnta_cntbl_debe, null, 0, hc.imp_soles)) as debe,
       sum(decode(ct.cnta_cntbl_haber, null, 0, hc.imp_soles)) as haber
from historico_calculo hc,
     concepto_tip_trab_cnta ct,
     concepto               c,
     vw_pr_trabajador       m
where hc.concep          = ct.concep          (+)
  and hc.tipo_trabajador = ct.tipo_trabajador (+)
  and hc.concep          = c.concep
  and hc.cod_trabajador  = m.COD_TRABAJADOR
  --and c.desc_concep      like '%VACACIONES%'
  and to_char(hc.fec_calc_plan, 'yyyymm') = '201411'
  and hc.cod_trabajador = '10000508'
  and hc.concep not in ('2398', '1499', '3099')
group by hc.tipo_trabajador,
         to_char(hc.fec_calc_plan, 'yyyymm'),
         m.COD_TRABAJADOR,
         m.NOM_TRABAJADOR,
         c.concep,
         c.desc_concep,
         decode(ct.cnta_cntbl_debe, null, null, ct.cnta_cntbl_debe),
         decode(ct.cnta_cntbl_haber, null, null, ct.cnta_cntbl_haber)
