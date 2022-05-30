select m.COD_TRABAJADOR, m.DNI, m.COD_BANCO, m.NRO_CNTA_AHORRO,
       m.NOM_TRABAJADOR, g.imp_adelanto as gratificacion,
       usf_rh_nro_dias_tt(m.cod_trabajador, to_date('06/06/2010', 'dd/mm/yyyy'),to_date('28/11/2010', 'dd/mm/yyyy'))  as nro_dias_r1,
       (select sum(hc.imp_soles)
         from historico_calculo hc
        where hc.cod_trabajador = m.COD_TRABAJADOR
          and trunc(hc.fec_calc_plan) between to_date('06/06/2010', 'dd/mm/yyyy') and to_date('28/11/2010', 'dd/mm/yyyy')
          and hc.concep = '1499'
          and trunc(hc.fec_calc_plan) <> to_Date('15/07/2010', 'dd/mm/yyyy')) as total_remuneraciones_r1,          
       usf_rh_nro_dias_tt(m.cod_trabajador, to_date('04/07/2010', 'dd/mm/yyyy'),to_date('26/12/2010', 'dd/mm/yyyy'))  as nro_dias_r2,
       (select sum(hc.imp_soles)
         from historico_calculo hc
        where hc.cod_trabajador = m.COD_TRABAJADOR
          and trunc(hc.fec_calc_plan) between to_date('05/07/2010', 'dd/mm/yyyy') and to_date('26/12/2010', 'dd/mm/yyyy')
          and hc.concep = '1499'
          and trunc(hc.fec_calc_plan) <> to_Date('15/07/2010', 'dd/mm/yyyy')) as total_remuneraciones_r2,
       (select NVL(sum(hc.imp_soles),0)
         from historico_calculo hc
        where hc.cod_trabajador = m.COD_TRABAJADOR
          and trunc(hc.fec_calc_plan) = to_date('05/12/2010', 'dd/mm/yyyy')
          and hc.concep = '1499') as rem_05_12_2010,
       (select NVL(sum(hc.imp_soles),0)
         from historico_calculo hc
        where hc.cod_trabajador = m.COD_TRABAJADOR
          and trunc(hc.fec_calc_plan)  = to_date('12/12/2010', 'dd/mm/yyyy')
          and hc.concep = '1499') as rem_12_12_2010

from gratificacion g,
     vw_pr_trabajador m
where g.cod_trabajador = m.COD_TRABAJADOR  
  and m.TIPO_TRABAJADOR = 'DES'   
order by m.nom_trabajador
