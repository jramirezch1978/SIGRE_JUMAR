SELECT m.cod_trabajador, m.dni, 
       trim(m.apel_paterno)||' '||trim(m.apel_materno)||', '||trim(m.nombre1)||' '||trim(nvl(m.nombre2,' ')) nombre, 
       m.cencos, '02' lugar_cts, 
       decode(hg.cod_origen,'LM','16','CN','17', 'SP', '18', 'PS', '19') lugar_proceso_cts, 
       decode(hg.moneda_cts,'S/.','01','02') tipo_moneda, 
       hg.tipo_trabajador, hg.banco_cts, hg.nro_cuenta_cts, 
       0 tasa_int_cts, 
       0 dias_atras, 
       hg.dias_asist, 
       sum(hd.monto) rem_comp
  FROM hist_prov_cts_gratif hg, hist_prov_cts_det hd, maestro m  
 WHERE hg.fecha_proceso=hd.fecha_proceso and 
       hg.cod_trabajador=hd.cod_trabajador and 
       hg.cod_trabajador=m.cod_trabajador and 
       hd.cod_trabajador=m.cod_trabajador 
GROUP BY m.cod_trabajador, 
         m.dni, 
         trim(m.apel_paterno)||' '||trim(m.apel_materno)||', '||trim(m.nombre1)||' '||trim(nvl(m.nombre2,' ')), 
       m.cencos, '02' , 
       decode(hg.cod_origen,'LM','16','CN','17', 'SP', '18', 'PS', '19'), 
       decode(hg.moneda_cts,'S/.','01','02'), 
       hg.tipo_trabajador, hg.banco_cts, hg.nro_cuenta_cts, 
       0 , 
       0 , 
       hg.dias_asist

--, --hg.dias_asist, hg.cts_mes01, hg.cts_mes02, hg.cts_mes03, hg.cts_mes04, hg.cts_mes05 ;