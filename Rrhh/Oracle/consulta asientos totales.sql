select hc.concep,
       c.desc_concep,
       ct.cnta_cntbl_debe,
       ct.cnta_cntbl_haber,
       sum(decode(ct.cnta_cntbl_debe, null, 0, hc.imp_soles)) as debe,
       sum(decode(ct.cnta_cntbl_haber, null, 0, hc.imp_soles)) as haber
from historico_calculo hc,
     concepto_tip_trab_cnta ct,
     concepto               c
where hc.concep = ct.concep
  and hc.tipo_trabajador = ct.tipo_trabajador     
  and hc.concep          = c.concep
  and hc.tipo_trabajador = 'DES'
  and to_char(hc.fec_calc_plan, 'yyyymm') = '201308'
group by hc.concep,
       c.desc_concep,
       ct.cnta_cntbl_debe,
       ct.cnta_cntbl_haber  
