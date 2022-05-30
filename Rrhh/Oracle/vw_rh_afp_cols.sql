create or replace view vw_rh_afp_cols as
select vra.cod_trabajador,
      trunc(vra.fecha) as fecha,
      decode(vra.grupo_calculo,(select trim(afp_jubilacion) from rrhhparam_cconcep where reckey ='1'),sum(importe),0) as GC033,
      decode(vra.grupo_calculo,(select trim(afp_invalidez) from rrhhparam_cconcep where reckey ='1'),sum(importe),0) as GC034,
      decode(vra.grupo_calculo,(select trim(afp_comision) from rrhhparam_cconcep where reckey ='1'),sum(importe),0) as GC035,
      decode(vra.grupo_calculo,(select trim(concep_calculo_afp) from rrhhparam_cconcep where reckey ='1'),sum(importe),0) as GC036
from vw_rh_afp vra
group by vra.cod_trabajador,trunc(vra.fecha), vra.grupo_calculo

