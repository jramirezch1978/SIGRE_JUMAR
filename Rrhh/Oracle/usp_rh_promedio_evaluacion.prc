create or replace procedure usp_rh_promedio_evaluacion (
  an_desde in number, an_hasta in number,
  ad_fec_desde in date, ad_fec_hasta in date ) is

ls_nombres    varchar2(40);
ln_promedio   number(5,1) ;
ln_funcion    number(5,1) ;
ln_desde      number(5,1) ;
ln_hasta      number(5,1) ;

--  Lectura de evaluaciones de personal
cursor c_evaluacion is
  select e.fecha_evaluacion, e.cod_trabajador, e.cod_area, e.cod_cargo,
         a.desc_areas, m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2,
         c.desc_cargo
  from rh_evaluacion_personal e, tt_rrhh_areas a, maestro m, cargo c
  where e.cod_area = a.areas and e.cod_trabajador = m.cod_trabajador and
        /*e.flag_estado = m.flag_estado and*/ e.cod_cargo = c.cod_cargo and
        (e.fecha_evaluacion between ad_fec_desde and ad_fec_hasta)
  order by e.cod_area, e.cod_cargo, e.cod_trabajador,
           e.fecha_evaluacion ;

begin

delete from tt_rrhh_promedio_evaluacion ;

ln_desde := an_desde ;
ln_hasta := an_hasta + 0.9 ;

for rc_eva in c_evaluacion loop

  ls_nombres := trim(rc_eva.apel_paterno)||' '||trim(rc_eva.apel_materno)||' '||
                trim(rc_eva.nombre1)||' '||nvl(trim(rc_eva.nombre2),' ') ;
  
  ln_promedio := 0 ;
  --comportamiento
  select avg(nvl(d.puntaje,0))
    into ln_promedio
    from rh_evaluacion_personal_det d
    where d.cod_trabajador = rc_eva.cod_trabajador and
          to_char(d.fecha_evaluacion,'DD/MM/YYYY') =
          to_char(rc_eva.fecha_evaluacion,'DD/MM/YYYY') ;
    --funciones
  select avg(nvl(d.puntaje,0))
    into ln_funcion
    from rrhh_funcion_cargo_eval d
    where d.cod_trabajador = rc_eva.cod_trabajador and
          to_char(d.fecha,'DD/MM/YYYY') =
          to_char(rc_eva.fecha_evaluacion,'DD/MM/YYYY') ;
  
  if ln_promedio between ln_desde and ln_hasta then
    insert into tt_rrhh_promedio_evaluacion (
      area, desc_area, fecha, codigo, nombres,
      cargo, desc_cargo, puntaje, funcion )
    values (
      rc_eva.cod_area, rc_eva.desc_areas, rc_eva.fecha_evaluacion,
      rc_eva.cod_trabajador, ls_nombres, rc_eva.cod_cargo,
      rc_eva.desc_cargo, ln_promedio, ln_funcion ) ;
  end if ;
    
end loop ;
  
end usp_rh_promedio_evaluacion ;
/
