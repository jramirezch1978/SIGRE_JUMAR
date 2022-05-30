create or replace procedure usp_rh_av_rpt_calif_objetivos (
  an_ano in number, an_mes in number ) is

lk_objetivos        constant char(3) := 'OBJ' ;

ls_desc_area        varchar2(30) ;
ls_desc_seccion     varchar2(30) ;
ls_nombres          varchar2(60) ;

--  Lectura de conceptos por objetivos segun area y seccion
cursor c_objetivos is
  select o.cod_area, o.cod_seccion, o.calif_concepto, o.porcentaje,
         o.cod_usr, c.descripcion
  from rrhh_calificacion_objetivo o, rrhh_calificacion_concepto c
  where o.calif_concepto = c.calif_concepto and c.calif_tipo = lk_objetivos and
        o.flag_estado = '1'
  order by o.cod_area, o.cod_seccion, o.calif_concepto ;
  
begin

--  **********************************************************
--  ***   GENERA REPORTE DE CALIFICACIONES POR OBJETIVOS   ***
--  **********************************************************

delete from tt_av_rpt_calif_objetivos ;

for rc_obj in c_objetivos loop
  
  select u.nombre into ls_nombres from usuario u
    where u.cod_usr = rc_obj.cod_usr ;

  select a.desc_area into ls_desc_area from area a
    where a.cod_area = rc_obj.cod_area ;
    
  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_obj.cod_area and s.cod_seccion = rc_obj.cod_seccion ;

  insert into tt_av_rpt_calif_objetivos (
    usuario, desc_usuario, area, desc_area, seccion,
    desc_seccion, calif_concepto, desc_concepto, porcentaje )
  values (
    rc_obj.cod_usr, ls_nombres, rc_obj.cod_area, ls_desc_area, rc_obj.cod_seccion,
    ls_desc_seccion, rc_obj.calif_concepto, rc_obj.descripcion, rc_obj.porcentaje ) ;
      
end loop ;
      
end usp_rh_av_rpt_calif_objetivos ;
/
