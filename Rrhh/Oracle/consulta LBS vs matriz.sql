select to_char(lb.fec_proceso, 'yyyymm') as periodo,
       lb.nro_liquidacion,
       lbd.titulo,
       lbd.confin,
       md.matriz,
       max(decode(md.flag_debhab, 'D', md.cnta_ctbl, null)) as cnta_debe,
       max(decode(md.flag_debhab, 'H', md.cnta_ctbl, null)) as cnta_haber
from liquidacion_benef lb,
     liquidacion_benef_det lbd,
     concepto_financiero   cf,
     matriz_cntbl_finan_det md
where lb.nro_liquidacion = lbd.nro_liquidacion
  and lbd.confin         = cf.confin
  and cf.matriz_cntbl    = md.matriz 
  group by to_char(lb.fec_proceso, 'yyyymm'),
       lb.nro_liquidacion,
       lbd.titulo,
       lbd.confin,
       md.matriz   
order by periodo, nro_liquidacion, titulo        
