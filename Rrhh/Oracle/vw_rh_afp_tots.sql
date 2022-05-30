create or replace view vw_rh_afp_tots as
select vrac.cod_trabajador, 
       vrac.fecha, 
       sum(vrac.gc033) as Aporte_obligatorio, 
       sum(vrac.gc034) as Seguros, 
       sum(vrac.gc035) as Comision_porcent, 
       sum(vrac.gc036) as Remuneracion_asegurable 
from vw_rh_afp_cols vrac
group by vrac.cod_trabajador, vrac.fecha

