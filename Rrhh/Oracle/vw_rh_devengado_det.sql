create or replace view vw_rh_devengado_det as
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
         a.cod_trabajador,
         m.NOM_TRABAJADOR,
         m.TIPO_TRABAJADOR, tt.desc_tipo_tra,
         case when a.tipo_devengado = 'G' then '1.Gratificacion'
              when a.tipo_devengado = 'V' then '2.Vacaciones'
              when a.tipo_devengado = 'C' then '3.CTS'
         end as tipo_devengado,
         a.parte_fija,
         a.parte_variable,
         a.gratificacion,
         a.importe

  from rh_devengados_mes a,
       vw_pr_trabajador  m,
       tipo_trabajador   tt
  where a.cod_trabajador = m.cod_trabajador
    and m.tipo_trabajador = tt.tipo_trabajador
  order by ano, mes, tipo_devengado, tipo_trabajador, NOM_TRABAJADOR
