select hc.concep, c.desc_concep, 
       decode(t.cnta_cntbl_debe, null, t.cnta_cntbl_haber, t.cnta_cntbl_debe) as cnta_cntbl,
       hc.imp_soles,
       decode(t.cnta_cntbl_debe, null, 0, hc.imp_soles) as debe,
       decode(t.cnta_cntbl_haber, null, 0, hc.imp_soles) as haber
from historico_calculo hc, 
     concepto_tip_trab_cnta t,
     concepto               c
where hc.concep          = t.concep          (+)
  and hc.tipo_trabajador = t.tipo_trabajador (+)
  and hc.concep          = c.concep
  and hc.cod_trabajador = '20000594'         
  and hc.fec_calc_plan = to_date('17/07/2013', 'dd/mm/yyyy')
