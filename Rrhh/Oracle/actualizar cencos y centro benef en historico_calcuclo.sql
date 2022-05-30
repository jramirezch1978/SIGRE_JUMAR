update historico_calculo hc
   set hc.centro_benef = (select centro_benef from maestro m where m.cod_trabajador = hc.cod_trabajador)
where hc.cod_trabajador in (select cod_trabajador from maestro m where m.tipo_trabajador = 'EMP')
  and to_char(hc.fec_calc_plan, 'yyyy') = '2010'
  and (hc.centro_benef <> (select centro_benef from maestro m where m.cod_trabajador = hc.cod_trabajador)
  or hc.centro_benef is null)
  
  
update historico_distrib_cntble hdc
   set hdc.centro_benef = (select centro_benef from maestro m where m.cod_trabajador = hdc.cod_trabajador)
where hdc.cod_trabajador in (select cod_trabajador from maestro m where m.tipo_trabajador = 'EJO')
  and to_char(hdc.fec_calculo, 'yyyy') = '2010'
  and hdc.centro_benef <> (select m.centro_benef from maestro m where m.cod_trabajador = hdc.cod_trabajador)


select distinct hdc.centro_benef, m.centro_benef
from historico_distrib_cntble hdc,
     maestro                   m
where hdc.cod_trabajador = m.cod_trabajador
  and hdc.centro_benef is null
  and m.tipo_trabajador = 'EJO'     
  and to_char(hdc.fec_calculo, 'yyyy') = '2010'
