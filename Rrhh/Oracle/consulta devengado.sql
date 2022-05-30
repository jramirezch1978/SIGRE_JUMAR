  select a.ano, 
         case 
           when a.mes = '1' then '01.Enero'
           when a.mes = '2' then '02.Febrero'
           when a.mes = '3' then '03.Marzo'  
           when a.mes = '4' then '04.Abril'
           when a.mes = '5' then '05.Mayo'
           when a.mes = '6' then '06.Junio'  
           when a.mes = '7' then '07.Julio'
           when a.mes = '8' then '08.Agosto'
           when a.mes = '9' then '09.Setiembre'  
           when a.mes = '10' then '10.Octubre'
           when a.mes = '11' then '11.Noviembre'
           when a.mes = '12' then '12.Diciembre'  
         end as mes  ,
         case when a.tipo_devengado = 'G' then '1.Gratificacion'
              when a.tipo_devengado = 'V' then '2.Vacaciones'
              when a.tipo_devengado = 'C' then '3.CTS'
         end as tipo_devengado,
         nvl(sum(decode(a.tipo_trabajador, 'EMP', a.parte_fija, 0)), 0) as fijo_empleado,
         nvl(sum(decode(a.tipo_trabajador, 'EMP', a.parte_variable, 0)), 0) as var_empleado,
         nvl(sum(decode(a.tipo_trabajador, 'EMP', a.gratificacion, 0)), 0) as grati_empleado,
         nvl(sum(decode(a.tipo_trabajador, 'EMP', a.importe, 0)), 0) as dev_empleado,
         
         nvl(sum(decode(a.tipo_trabajador, 'DES', a.parte_fija, 0)), 0) as fijo_destajero,
         nvl(sum(decode(a.tipo_trabajador, 'DES', a.parte_variable, 0)), 0) as var_destajero,
         nvl(sum(decode(a.tipo_trabajador, 'DES', a.gratificacion, 0)), 0) as grati_destajero,
         nvl(sum(decode(a.tipo_trabajador, 'DES', a.importe, 0)), 0) as dev_destajero,
         
         nvl(sum(decode(a.tipo_trabajador, 'JOR', a.parte_fija, 0)), 0) as fijo_jornalero,
         nvl(sum(decode(a.tipo_trabajador, 'JOR', a.parte_variable, 0)), 0) as var_jornalero,
         nvl(sum(decode(a.tipo_trabajador, 'JOR', a.gratificacion, 0)), 0) as grati_jornalero,
         nvl(sum(decode(a.tipo_trabajador, 'JOR', a.importe, 0)), 0) as dev_jornalero,
         
         nvl(sum(decode(a.tipo_trabajador, 'TRI', a.parte_fija, 0)), 0) as fijo_tripulante,
         nvl(sum(decode(a.tipo_trabajador, 'TRI', a.parte_variable, 0)), 0) as var_tripulante,
         nvl(sum(decode(a.tipo_trabajador, 'TRI', a.gratificacion, 0)), 0) as grati_tripulante,
         nvl(sum(decode(a.tipo_trabajador, 'TRI', a.importe, 0)), 0) as dev_tripulante
         
  from rh_devengados_mes a,
       vw_pr_trabajador  m,
       tipo_trabajador   tt
  where a.cod_trabajador = m.cod_trabajador
    and m.tipo_trabajador = tt.tipo_trabajador
    and ano = 2014
    --and a.mes =
group by a.ano, 
         a.mes,
         a.tipo_devengado
order by 1, 2, 3         
