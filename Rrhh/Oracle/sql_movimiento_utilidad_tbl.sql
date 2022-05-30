select um.proveedor, trim(m.apel_paterno)||' '||trim(m.apel_materno)||', '||trim(m.nombre1)||' '||trim(nvl(m.nombre2,' ')) as nombre, 
       ud.renta_neta, ud.porc_distribucion, ud.porc_dias_laborados, ud.porc_remuneracion, ud.fecha_ini, ud.fecha_fin, 
       ud.tot_dias_ejer, (um.dias_total - um.dias_domingo - um.dias_feriado - um.dias_inasist) as dias, 
       ud.tot_remun_ejer, um.pagos, um.adelantos, um.dsctos, um.retencion_judic, 
       um.utilidad_pago, um.utilidad_asistencia, m.cod_origen, o.dir_calle 
from utl_distribucion ud, utl_movim_general um, maestro m, origen o 
where ud.periodo = um.periodo and 
      ud.item = um.item and 
      um.proveedor = m.cod_trabajador and 
      m.cod_origen = o.cod_origen and 
      ud.periodo = 2007 and ud.item=1