select c.concep,
       c.desc_concep,
       hc.tipo_trabajador,
       to_char(hc.fec_calc_plan, 'yyyymm') as periodo,
       sum(hc.imp_soles) as imp_Soles
  from historico_calculo hc,
       concepto          c
where hc.concep = c.concep
  and to_char(hc.fec_calc_plan, 'yyyy') = '2013'  
  and hc.concep like '1%'     
group by c.concep,
       c.desc_concep,
       hc.tipo_trabajador,
       to_char(hc.fec_calc_plan, 'yyyymm')
