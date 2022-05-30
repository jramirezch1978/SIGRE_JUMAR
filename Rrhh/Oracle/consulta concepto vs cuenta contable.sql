select hc.tipo_trabajador,
       hc.cod_origen,
       hc.concep,
       c.desc_concep,
       decode(ct.cnta_cntbl_debe, null, null, ct.cnta_cntbl_debe) as cntbl_cnta_deb,
       decode(ct.cnta_cntbl_haber, null, null, ct.cnta_cntbl_haber) as cntbl_cnta_hab,
       sum(decode(ct.cnta_cntbl_debe, null, null, hc.imp_soles)) as debe,
       sum(decode(ct.cnta_cntbl_haber, null, null, hc.imp_soles)) as haber
from historico_calculo hc,
     concepto_tip_trab_cnta ct,
     concepto               c
where hc.tipo_trabajador = ct.tipo_trabajador (+)
  and hc.concep          = ct.concep          (+)
  and hc.cod_origen      = ct.origen          (+)
  and hc.concep          = c.concep
  and to_char(hc.fec_calc_plan, 'yyyy') = '2015'
  and hc.concep not in ('1499', '2398', '3099')
group by hc.tipo_trabajador,    
         hc.cod_origen,
       hc.concep,
       c.desc_concep,
       decode(ct.cnta_cntbl_debe, null, null, ct.cnta_cntbl_debe),
       decode(ct.cnta_cntbl_haber, null, null, ct.cnta_cntbl_haber)
order by tipo_trabajador, concep       
