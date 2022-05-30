select hc.cod_trabajador, hc.fec_calc_plan, hc.cencos, hc.concep, c.desc_concep, ct.cnta_prsp, hc.cod_origen, hc.tipo_trabajador, 
       hc.imp_soles, hc.imp_dolar
from historico_calculo hc, maestro m, concepto c, concepto_tip_trab_cnta ct 
where hc.cod_trabajador=m.cod_trabajador and 
      hc.concep=c.concep and 
      (hc.concep = ct.concep and hc.tipo_trabajador = ct.tipo_trabajador and c.concep = ct.concep) and 
      to_char(hc.fec_calc_plan,'yyyy')='2008' 
order by hc.cod_origen, hc.tipo_trabajador, hc.fec_calc_plan, hc.cod_trabajador, hc.concep    


