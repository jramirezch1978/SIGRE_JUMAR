create or replace view vw_rrhh_quincena as

select aq.concep as concep, aq.cod_trabajador as cod_trabajador, aq.imp_adelanto as importe, aq.fec_proceso  as fecha 
      from adelanto_quincena aq
      
   union all

   select hc.concep as concep, hc.cod_trabajador as cod_trabajador, hc.imp_soles as importe, hc.fec_calc_plan as fecha 
      from historico_calculo hc 
      inner join grupo_calculo gc on hc.concep = gc.concepto_gen
      left outer join adelanto_quincena aq 
         on hc.cod_trabajador = aq.cod_trabajador
         and hc.concep = aq.concep
         and trunc(hc.fec_calc_plan) = trunc(aq.fec_proceso)
      where gc.grupo_calculo = '001'
         and aq.concep is null
