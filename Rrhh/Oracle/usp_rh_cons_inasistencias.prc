create or replace procedure usp_rh_cons_inasistencias (
  ad_fec_desde in date, ad_fec_hasta in date, as_tipo_trabajador in char,
  as_origen in char ) is

ls_nombre            varchar2(100) ;
ls_desc_area         varchar2(30) ;
ls_desc_seccion      varchar2(30) ;
ls_desc_cencos       varchar2(40) ;
ls_desc_concep       char(25) ; 

--  Lectura de inasistencias historicas de los trabajadores
cursor c_cons_hist_inasist is 
  select hi.cod_trabajador, hi.concep, hi.dias_inasist, hi.fec_desde,
         m.cod_area, m.cod_seccion, m.cencos
  from historico_inasistencia hi, maestro m
  where hi.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador = as_tipo_trabajador and hi.fec_movim between
        ad_fec_desde and ad_fec_hasta ;

begin

--  ******************************************************
--  ***   CONSULTA DE LOS REGISTROS DE INASISTENCIAS   ***
--  ******************************************************

delete from tt_cons_hist_inasist ;

for rc_hi in c_cons_hist_inasist loop 
     
  ls_nombre := usf_rh_nombre_trabajador(rc_hi.cod_trabajador) ;
  
  ls_desc_area := null ;
  select a.desc_area into ls_desc_area from area a  
    where a.cod_area = rc_hi.cod_area ;
        
  ls_desc_seccion := null ;
  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_hi.cod_area and s.cod_seccion = rc_hi.cod_seccion ;
        
  ls_desc_cencos := null ;
  if rc_hi.cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = rc_hi.cencos ;
  end if ;
        
  ls_desc_concep := null ;
  select c.desc_breve into ls_desc_concep from concepto c
    where c.concep = rc_hi.concep ;
     
  insert into tt_cons_hist_inasist (
    cod_trabajador, nombre, cod_area, desc_area,
    cod_seccion, desc_seccion, cencos, desc_cencos,
    concep, desc_concep, fec_desde, dias_inasist )
  values (
    rc_hi.cod_trabajador, ls_nombre, rc_hi.cod_area, ls_desc_area,
    rc_hi.cod_seccion, ls_desc_seccion, rc_hi.cencos, ls_desc_cencos,
    rc_hi.concep, ls_desc_concep, rc_hi.fec_desde, nvl(rc_hi.dias_inasist,0) ) ;

end loop ;

end usp_rh_cons_inasistencias ;
/
