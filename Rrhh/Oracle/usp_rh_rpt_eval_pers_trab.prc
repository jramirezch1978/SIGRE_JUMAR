create or replace procedure usp_rh_rpt_eval_pers_trab (
  ad_fec_desde in date, ad_fec_hasta in date,
  as_cod_trab rh_evaluacion_personal.cod_trabajador%type ) is

-- Procedimiento para generar formato de evaluacion de personal x area
   ls_nombre_trabajador varchar2(120) ;
   ls_nombre2      maestro.nombre2%type;
  
--  Cursor para hallar saldos por capital e interes
cursor c_evaluacion_cab( as_cod_trab char) is 
Select rh.cod_trabajador, rh.cod_area, rh.cod_cargo, max(rh.fecha_evaluacion) as fecha,
       m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2,
       a.desc_area, c.desc_cargo
from rh_evaluacion_personal rh, maestro m, area a, cargo c
where rh.cod_trabajador = as_cod_trab and rh.flag_estado<>'0' and
      rh.cod_trabajador = m.cod_trabajador and
      rh.cod_area = a.cod_area and
      rh.cod_cargo = c.cod_cargo and
      (rh.fecha_evaluacion between ad_fec_desde and ad_fec_hasta)
group by rh.cod_trabajador, rh.cod_area, rh.cod_cargo, 
      m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2, 
      a.desc_area, c.desc_cargo
order by rh.cod_area, rh.cod_cargo ;

--  Cursor para hallar saldos por capital e interes
cursor c_evaluacion_det (ad_fecha in date, as_cod_trabajador in char) 
  is 
  Select rd.cod_trabajador, rd.cod_competencia, rd.cod_comport, rd.puntaje, 
         c.desc_competencia, co.desc_comport
  from rh_evaluacion_personal_det rd, rh_competencia c, rh_comportamiento co
  where rd.fecha_evaluacion=ad_fecha and rd.cod_trabajador=as_cod_trabajador and
        rd.cod_competencia=c.cod_competencia and rd.cod_competencia=co.cod_competencia and
        rd.cod_comport=co.cod_comport
  order by rd.cod_trabajador, rd.cod_competencia, rd.cod_comport;
  
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
       
         -- Insertando detalle
         For rd in c_evaluacion_det(rc.fecha, rc.cod_trabajador) Loop
           Insert into tt_eval_desempeno_det
             (cod_trabajador, cod_competencia, desc_competencia,
              cod_comport, desc_comport, puntaje )
           Values
             (rd.cod_trabajador, rd.cod_competencia, rd.desc_competencia,
              rd.cod_comport, rd.desc_comport, rd.puntaje ) ;
         end loop;

     end loop;

end usp_rh_rpt_eval_pers_trab;
/
