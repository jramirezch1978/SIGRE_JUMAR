create or replace view VW_RRHH_COMPET_COMPORT as

select c2.cod_competencia as cod_compet, 
       c1.desc_competencia as desc_compet, 
       c2.cod_comport as cod_comport, 
       substr(c2.desc_comport,1,35) as desc_comport
from rh_comportamiento c2, rh_competencia c1
where c2.cod_competencia = c1.cod_competencia
order by c2.cod_competencia, c2.cod_comport   