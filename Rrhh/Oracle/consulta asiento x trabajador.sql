select hc.concep,
       c.desc_concep,
       hc.imp_soles,
       DECODE(ct.cnta_cntbl_debe, NULL, ct.cnta_cntbl_haber, ct.cnta_cntbl_debe) as cnta_cntbl,
       DECODE(ct.cnta_cntbl_debe, NULL, 0, hc.imp_soles) as debe_sol,
       DECODE(ct.cnta_cntbl_haber, NULL, 0, hc.imp_soles) as haber_sol
from historico_calculo hc,
     concepto_tip_trab_cnta ct,
     concepto               c
where hc.cod_trabajador = '20000000'
  and hc.concep         = ct.concep             (+)
  and hc.tipo_trabajador  = ct.tipo_trabajador  (+)
  and hc.concep         = c.concep
  and hc.cod_origen     = ct.origen             (+)
  and TO_CHAR(hc.fec_calc_plan, 'yyyymm') = '201501'
  and hc.concep not in ('2398', '3099', '1499')
