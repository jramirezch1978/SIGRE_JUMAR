create or replace procedure usp_rh_fmt_eval_pers_trab(
  as_cod_trab rh_cargo_real_trabajador.cod_trabajador%type)
  is
-- Procedimiento para generar formato de evaluacion de personal x area
   ls_nombre_trabajador varchar2(120) ;
   ls_nombre2      maestro.nombre2%type;
  
--  Cursor para hallar saldos por capital e interes
cursor c_evaluacion_cab( as_cod_area char) is 
Select cr.cod_trabajador, cr.cod_area, cr.cod_cargo, max(cr.fecha) as fecha,
       m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2,
       a.desc_area, c.desc_cargo
from rh_cargo_real_trabajador cr, maestro m, area a, cargo c
where cr.cod_trabajador = as_cod_trab and cr.flag_estado='1' and
      cr.cod_trabajador = m.cod_trabajador and
      cr.cod_area = a.cod_area and
      cr.cod_cargo = c.cod_cargo 
group by cr.cod_trabajador, cr.cod_area, cr.cod_cargo, 
      m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2, 
      a.desc_area, c.desc_cargo
order by cr.cod_area, cr.cod_cargo ;

--  Cursor para hallar saldos por capital e interes
cursor c_evaluacion_det is 
  Select tt.cod_trabajador, c.cod_competencia, c.cod_comport, 
         c1.desc_competencia, c2.desc_comport
  from tt_eval_desempeno_cab tt, rh_cargo_compet_comport c, 
       rh_competencia c1, rh_comportamiento c2
  where tt.cod_area = c.cod_area and tt.cod_cargo = c.cod_cargo and
        c.flag_estado = '1' and c.cod_competencia = c1.cod_competencia and
        c.cod_competencia = c2.cod_competencia and 
        c.cod_comport = c2.cod_comport ;
        
begin
-- Eliminado contenido de informacion
delete tt_eval_desempeno_det ;
delete tt_eval_desempeno_cab ;

For rc in c_evaluacion_cab(as_cod_trab) Loop
    ls_nombre2 := nvl(trim(rc.nombre2),'') ;
    ls_nombre_trabajador := trim( rc.apel_paterno ) || ' ' ||
                            trim( rc.apel_materno ) || '; ' ||
                            trim( rc.nombre1) || ' ' || ls_nombre2 ;
                           
    Insert into tt_eval_desempeno_cab tt
      (cod_trabajador, nom_trabajador, cod_area, desc_area,
       cod_cargo, desc_cargo, fecha)
    Values
      (rc.cod_trabajador, ls_nombre_trabajador, rc.cod_area, 
       rc.desc_area, rc.cod_cargo, rc.desc_cargo, rc.fecha ) ;
     
end loop;

-- Registrando el detalle  
For rd in c_evaluacion_det() Loop
    Insert into tt_eval_desempeno_det
          (cod_trabajador, cod_competencia, desc_competencia,
           cod_comport, desc_comport )
    Values
         (rd.cod_trabajador, rd.cod_competencia, rd.desc_competencia,
          rd.cod_comport, rd.desc_comport ) ;
end loop;
--commit ;
end usp_rh_fmt_eval_pers_trab;
/
