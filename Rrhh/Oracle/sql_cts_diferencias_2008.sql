select h.cod_trabajador, h.cod_origen, h.tipo_trabajador, h.dias_asist, 
       (h.cts_mes01+h.cts_mes02+h.cts_mes03+h.cts_mes04+h.cts_mes05+h.cts_mes06) as cts_manual, 
       round((h.ingresos_fijos+h.ingresos_variables+h.ingresos_h_extras+h.ingresos_gratif+h.ingresos_otros)/360*h.dias_asist,2) as cts_sist, 
       (h.cts_mes01+h.cts_mes02+h.cts_mes03+h.cts_mes04+h.cts_mes05+h.cts_mes06) - 
       round((h.ingresos_fijos+h.ingresos_variables+h.ingresos_h_extras+h.ingresos_gratif+h.ingresos_otros)/360*h.dias_asist,2) as diferenc
from hist_prov_cts_gratif h 
order by h.cod_origen, h.tipo_trabajador, h.cod_trabajador 
