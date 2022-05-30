create or replace procedure usp_rh_fmt_eval_pers_cargo(
  as_cod_area area.cod_area%type, as_cod_cargo cargo.cod_cargo%type ) is

ls_nombre_trabajador    varchar2(120) ;
ls_nombre2              maestro.nombre2%type ;
  
--  Lectura de cargos reales de los trabajadores
cursor c_evaluacion_cab( as_cod_area char) is 
  select cr.cod_trabajador, cr.cod_area, cr.cod_cargo, max(cr.fecha) as fecha,
         m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2, a.desc_area,
         c.desc_cargo
  from rh_cargo_real_trabajador cr, maestro m, area a, cargo c
  where cr.cod_area = as_cod_area and cr.cod_cargo = as_cod_cargo and
        cr.flag_estado = '1' and cr.cod_trabajador = m.cod_trabajador and
        cr.cod_area = a.cod_area and cr.cod_cargo = c.cod_cargo 
  group by cr.cod_trabajador, cr.cod_area, cr.cod_cargo, m.apel_paterno,
           m.apel_materno, m.nombre1, m.nombre2, a.desc_area, c.desc_cargo
  order by cr.cod_area, cr.cod_cargo ;

--  Lectura de competencias de los trabajadores
cursor c_evaluacion_det is 
  select tt.cod_trabajador, c.cod_competencia, c.cod_comport, c1.desc_competencia,
         c2.desc_comport
  from tt_eval_desempeno_cab tt, rh_cargo_compet_comport c, rh_competencia c1,
       rh_comportamiento c2
  where tt.cod_area = c.cod_area and tt.cod_cargo = c.cod_cargo and
        c.flag_estado = '1' and c.cod_competencia = c1.cod_competencia and
        c.cod_competencia = c2.cod_competencia and c.cod_comport = c2.cod_comport ;
        
begin

--  *********************************************************
--  ***   FORMATO DE EVALUACION DE DESEMPENO POR CARGOS   ***
--  *********************************************************

delete tt_eval_desempeno_det ;
delete tt_eval_desempeno_cab ;

for rc in c_evaluacion_cab(as_cod_area) loop

  ls_nombre2 := nvl(trim(rc.nombre2),'') ;
  ls_nombre_trabajador := trim( rc.apel_paterno ) || ' ' ||
                          trim( rc.apel_materno ) || '; ' ||
                          trim( rc.nombre1) || ' ' || ls_nombre2 ;
                           
  insert into tt_eval_desempeno_cab tt (
    cod_trabajador, nom_trabajador, cod_area, desc_area,
    cod_cargo, desc_cargo, fecha )
  values (
    rc.cod_trabajador, ls_nombre_trabajador, rc.cod_area, 
    rc.desc_area, rc.cod_cargo, rc.desc_cargo, rc.fecha ) ;
     
end loop ;

for rd in c_evaluacion_det() loop

  insert into tt_eval_desempeno_det (
    cod_trabajador, cod_competencia, desc_competencia,
    cod_comport, desc_comport )
  values (
    rd.cod_trabajador, rd.cod_competencia, rd.desc_competencia,
    rd.cod_comport, rd.desc_comport ) ;

end loop ;

end usp_rh_fmt_eval_pers_cargo ;
/
