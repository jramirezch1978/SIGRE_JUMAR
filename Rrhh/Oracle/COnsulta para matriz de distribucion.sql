select distinct t.tipo_trabajador, 
                ct.cnta_cntbl_debe,
                cc.cencos, cc.desc_cencos
from historico_calculo t,
     centros_costo     cc,
     concepto_tip_trab_cnta ct
where t.cencos = cc.cencos    
  and t.concep = ct.concep
  and t.cod_origen = ct.origen
  and t.tipo_trabajador = ct.tipo_trabajador 
  and ct.cnta_cntbl_debe is not null
  and ct.cnta_cntbl_debe like '9%'
  and ct.cnta_cntbl_debe || t.cencos not in (select mm.ORG_CNTA_CTBL || mm.CENCOS
                                               from matriz_transf_cntbl_cencos mm)
order by 1, 2  
