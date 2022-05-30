CREATE OR REPLACE VIEW vw_rh_afp as
select c.cod_trabajador, 
       decode(m.flag_estado,'1','01','0','02') as tipo ,
       decode(m.flag_estado,'1',m.fec_ingreso,'0',m.fec_cese) as fecha_inegre,
       trunc(c.fec_proceso) as fecha,
       (select trim(concep_calculo_afp) from rrhhparam_cconcep where reckey = '1') as grupo_calculo,
       sum(c.imp_soles) as importe,

       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_cese,'yyyymm'),m.fec_cese,
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),m.fec_ingreso,
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                              USF_RRHH_FECHA_VAC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                              USF_RRHH_FECHA_LIC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),null  )))) as fecha_afp,
       
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_cese,'yyyymm'),'02',
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),'01',
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'05',
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'04',
       null )))) as codigo_afp
  from calculo c
  inner join maestro m
     on c.cod_trabajador = m.cod_trabajador
  where --nvl(m.flag_estado,'0') = '1' and
        trim(nvl(m.cod_afp,' ')) <> ' '
        and c.concep in ( select trim(d.concepto_calc) from grupo_calculo_det d where d.grupo_calculo = (select trim(concep_calculo_afp) from rrhhparam_cconcep where reckey = '1'))
   group by c.cod_trabajador,m.flag_estado ,m.fec_ingreso,m.fec_cese,trunc(c.fec_proceso) ,to_char(c.fec_proceso,'yyyymm'),m.cod_origen,m.tipo_trabajador
union all

select hc.cod_trabajador,
       decode(m.flag_estado,'1','01','0','02') as tipo,
       decode(m.flag_estado,'1',m.fec_ingreso,'0',m.fec_cese) as fecha_inegre, 
       trunc(hc.fec_calc_plan) as fecha, 
       (select trim(concep_calculo_afp) from rrhhparam_cconcep where reckey = '1') as grupo_calculo, 
       sum(hc.imp_soles) as importe,
       
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_cese,'yyyymm'),m.fec_cese,
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),m.fec_ingreso,
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                                 USF_RRHH_FECHA_VAC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                                 USF_RRHH_FECHA_LIC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),null  )))) as fecha_afp,
       
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_cese,'yyyymm'),'02',
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),'01',
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'05',
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'04', null )))) as codigo_afp
  from historico_calculo hc
  inner join maestro m
     on hc.cod_trabajador = m.cod_trabajador
  where --nvl(m.flag_estado,'0') = '1' and
        trim(nvl(m.cod_afp,' ')) <> ' '
        and hc.concep in ( select trim(d.concepto_calc) from grupo_calculo_det d where d.grupo_calculo = (select trim(concep_calculo_afp) from rrhhparam_cconcep where reckey = '1'))
   group by hc.cod_trabajador,m.flag_estado ,m.fec_ingreso,m.fec_cese,trunc(hc.fec_calc_plan),to_char(hc.fec_calc_plan,'yyyymm'),m.cod_origen,m.tipo_trabajador

union all

select c.cod_trabajador, 
       decode(m.flag_estado,'1','01','0','02') as tipo,
       decode(m.flag_estado,'1',m.fec_ingreso,'0',m.fec_cese) as fecha_inegre, 
       trunc(c.fec_proceso) as fecha, 
       gc.grupo_calculo, 
       sum(c.imp_soles) as importe,
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_cese,'yyyymm'),m.fec_cese,
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),m.fec_ingreso,
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                              USF_RRHH_FECHA_VAC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                              USF_RRHH_FECHA_LIC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),null )))) as fecha_afp,
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_cese,'yyyymm'),'02',
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),'01',
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'05',
       decode(to_char(c.fec_proceso,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(c.fec_proceso,'yyyymm'),c.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'04', null )))) as codigo_afp

   from calculo c
   inner join grupo_calculo gc
      on c.concep = gc.concepto_gen
   inner join maestro m
      on c.cod_trabajador = m.cod_trabajador
   where c.concep in (select trim(gc.concepto_gen) from grupo_calculo gc where gc.grupo_calculo in
         (select trim(afp_jubilacion) from rrhhparam_cconcep where reckey = '1'
          union
          select trim(afp_invalidez) from rrhhparam_cconcep where reckey = '1'
          union
          select trim(afp_comision) from rrhhparam_cconcep where reckey = '1')     )
      --and nvl(m.flag_estado,'0') = '1'
      and trim(nvl(m.cod_afp,' ')) <> ' '
   group by c.cod_trabajador,m.flag_estado ,m.fec_ingreso,m.fec_cese,  
            gc.grupo_calculo, trunc(c.fec_proceso),
            to_char(c.fec_proceso,'yyyymm'),m.cod_origen,m.tipo_trabajador

union all
select hc.cod_trabajador,
       decode(m.flag_estado,'1','01','0','02') as tipo ,
       decode(m.flag_estado,'1',m.fec_ingreso,'0',m.fec_cese) as fecha_inegre,
       trunc(hc.fec_calc_plan) as fecha,
       gc.grupo_calculo, 
       sum(hc.imp_soles) as importe,
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_cese,'yyyymm'),m.fec_cese,
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),m.fec_ingreso,
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                                 USF_RRHH_FECHA_VAC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),
                                                 USF_RRHH_FECHA_LIC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),null )))) as fecha_afp,
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_cese,'yyyymm'),'02',
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(m.fec_ingreso,'yyyymm'),'01',
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_VAC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'05',
       decode(to_char(hc.fec_calc_plan,'yyyymm'),to_char(USF_RRHH_FECHA_LIC(to_char(hc.fec_calc_plan,'yyyymm'),hc.cod_trabajador,m.cod_origen,m.tipo_trabajador),'yyyymm'),'04', null )))) as codigo_afp

  from historico_calculo hc inner join grupo_calculo gc  on hc.concep = gc.concepto_gen
                            inner join maestro m         on hc.cod_trabajador = m.cod_trabajador
                            left outer join calculo c    on hc.cod_trabajador = c.cod_trabajador
                                  and hc.concep = c.concep
                                  and trunc(hc.fec_calc_plan) = trunc(c.fec_proceso)
   where hc.concep in (select trim(gc.concepto_gen) from grupo_calculo gc where gc.grupo_calculo in (select trim(afp_jubilacion) from rrhhparam_cconcep where reckey = '1'
                                                                                               union
                                                                                               select trim(afp_invalidez) from rrhhparam_cconcep where reckey = '1'
                                                                                               union
                                                                                               select trim(afp_comision) from rrhhparam_cconcep where reckey = '1'))
      and c.concep is null
      --and nvl(m.flag_estado,'0') = '1'
      and trim(nvl(m.cod_afp,' ')) <> ' '
   group by hc.cod_trabajador, m.flag_estado , m.fec_ingreso, m.fec_cese, 
            gc.grupo_calculo,trunc(hc.fec_calc_plan),
            to_char(hc.fec_calc_plan,'yyyymm'),
            m.cod_origen,
            m.tipo_trabajador

