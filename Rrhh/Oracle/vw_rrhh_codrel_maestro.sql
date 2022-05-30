create or replace view vw_rrhh_codrel_maestro as
select m.cod_trabajador as codigo,
       trim(m.apel_paterno) || ' ' || trim(m.apel_materno) || ', ' || trim(m.nombre1) || ' ' || trim(m.nombre2) as nombre,
       m.dni,
       m.flag_estado, 
       m.cod_origen, 
       m.tipo_trabajador 
    from maestro m
    order by nombre

