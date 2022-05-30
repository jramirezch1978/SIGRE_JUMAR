create or replace procedure usp_rpt_comportamientos (
  as_area in char, as_competencia in char, as_comportamiento in char,
  ad_fec_desde in date, ad_fec_hasta in date, an_puntaje_desde in number,
  an_puntaje_hasta in number ) is
  
ls_codigo                 char(8) ;
ls_cargo                  char(8) ;
ls_seccion                char(3) ;
ls_nombres                varchar2(60) ;
ls_desc_area              varchar2(30) ;
ls_desc_seccion           varchar2(30) ;
ls_desc_ocupacion         varchar2(30) ;
ls_desc_competencia       varchar2(30) ;
ls_desc_comportamiento    varchar2(400) ;

--  Cursor para leer el trabajador seleccionado
cursor c_maestro is 
  select m.cod_trabajador, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and m.cod_area = as_area
  order by m.cod_seccion ;

--  Cursor para leer la evaluacion del trabajador
cursor c_evaluacion is
  select d.fecha_evaluacion, d.puntaje
  from rh_evaluacion_personal_det d
  where d.cod_trabajador = ls_codigo and d.cod_competencia = as_competencia and
        d.cod_comport = as_comportamiento and
        (d.puntaje between an_puntaje_desde and an_puntaje_hasta) and
        (d.fecha_evaluacion between ad_fec_desde and ad_fec_hasta)
  order by d.cod_trabajador, d.cod_competencia, d.cod_comport ;
  
begin

delete from tt_evaluacion_comportamiento ;

--  Determina la descripcion del area
select nvl(a.desc_area,' ')
  into ls_desc_area
  from area a where a.cod_area = as_area ;

--  Determina la descripcion de la competencia
select distinct(nvl(rhc.desc_competencia,' '))
  into ls_desc_competencia
  from rh_competencia rhc
  where rhc.cod_competencia = as_competencia ;
  
--  Determian la descripcion del comportamiento
select nvl(com.desc_comport,' ')
  into ls_desc_comportamiento
  from rh_comportamiento com
  where com.cod_competencia = as_competencia and
        com.cod_comport = as_comportamiento ;
  
--  *************************************************
--  ***   LECTURA DE TRABAJADORES SELECCIONADOS   ***
--  *************************************************
for rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_seccion := nvl(rc_mae.cod_seccion,' ') ;
  ls_nombres := usf_nombre_trabajador(ls_codigo) ;

  --  Determina la descripcion de la seccion
  ls_desc_seccion := ' ' ;
  if ls_seccion <> ' ' then
    select nvl(s.desc_seccion,' ')
      into ls_desc_seccion
      from seccion s 
      where s.cod_area=as_area and
      s.cod_seccion = rc_mae.cod_seccion ;
  end if ;
    
  --  Determina la descripcion de la ocupacion
  ls_desc_ocupacion := ' ' ;
  select max(nvl(cr.cod_cargo,' '))
    into ls_cargo
    from rh_cargo_real_trabajador cr
    where cr.cod_trabajador = ls_codigo ;
  if ls_cargo <> ' ' then
    select nvl(c.desc_cargo,' ')
      into ls_desc_ocupacion
      from cargo c where c.cod_cargo = ls_cargo ;
  end if ;
        
  --  *****************************************************
  --  ***   LECTURA DE EVALUACION POR CADA TRABAJADOR   ***
  --  *****************************************************
  for rc_eva in c_evaluacion loop
  
    insert into tt_evaluacion_comportamiento (
      fec_desde, fec_hasta, codigo, nombres, area,
      desc_area, seccion, desc_seccion, cargo,
      desc_cargo, competencia, desc_competencia, comportamiento,
      desc_comportamiento, fec_evaluacion, puntaje )
    values (
      ad_fec_desde, ad_fec_hasta, ls_codigo, ls_nombres, as_area,
      ls_desc_area, ls_seccion, ls_desc_seccion, ls_cargo,
      ls_desc_ocupacion, as_competencia, ls_desc_competencia, as_comportamiento,
      ls_desc_comportamiento, rc_eva.fecha_evaluacion, rc_eva.puntaje ) ;

  end loop ;

end loop ;

end usp_rpt_comportamientos ;
/
