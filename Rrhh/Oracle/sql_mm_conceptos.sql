select ct.concep, c.desc_concep, ct.tipo_trabajador, ct.cnta_cntbl_debe, ct.cnta_cntbl_haber, ct.cnta_cntbl_debe_veda, ct.cnta_prsp 
from concepto_tip_trab_cnta ct, concepto c
where ct.concep=c.concep and 
      c.flag_estado<>'0' 
order by ct.tipo_trabajador, ct.concep      