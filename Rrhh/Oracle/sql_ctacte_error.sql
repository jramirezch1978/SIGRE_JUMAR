select c.cod_trabajador, c.tipo_doc, c.nro_doc, c.fec_prestamo, c.concep, c.mont_original, c.mont_cuota, c.sldo_prestamo, 
       m.cod_origen, m.tipo_trabajador, ccd.fec_dscto, ccd.imp_dscto
from cnta_crrte c, cnta_crrte_detalle ccd, maestro m 
where c.cod_trabajador=ccd.cod_trabajador and 
      c.tipo_doc = ccd.tipo_doc and 
      c.nro_doc = ccd.nro_doc and 
      c.cod_trabajador = m.cod_trabajador and 
      trunc(ccd.fec_dscto) > to_date('01/03/2008','dd/mm/yyyy')
order by m.cod_origen, m.tipo_trabajador, c.cod_trabajador, c.tipo_doc, c.nro_doc     
