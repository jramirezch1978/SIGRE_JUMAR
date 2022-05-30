create or replace view trabaj_admin 
as

select m.cod_trabajador, 
       rtrim(apel_paterno)||' '||rtrim(apel_materno)||' '||
       nvl(rtrim(nombre1),' ')||' '||nvl(rtrim(nombre2),' ') as nombre,
       m.cod_area, a.desc_area, m.cod_seccion, s.desc_seccion
from maestro m, area a, seccion s 
where (m.cod_area = a.cod_area (+)) and 
      (a.cod_area = s.cod_area) and 
      (m.cod_seccion = s.cod_seccion (+)) 




   