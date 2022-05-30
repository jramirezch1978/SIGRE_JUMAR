create or replace view vw_rh_ubigeo as
select p.cod_pais, de.cod_dpto, pc.cod_prov, p.nom_pais, de.desc_dpto, pc.desc_prov from pais p
      full join departamento_estado de on p.cod_pais = de.cod_pais
      full join provincia_condado pc on de.cod_pais = pc.cod_pais and de.cod_dpto = pc.cod_dpto

