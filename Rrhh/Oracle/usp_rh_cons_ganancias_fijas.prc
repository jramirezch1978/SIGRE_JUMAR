create or replace procedure usp_rh_cons_ganancias_fijas (
  as_tipo_trabajador in char, as_origen in char ) is

ls_nombre               varchar2(100) ;
ls_desc_area            varchar2(30) ;
ls_desc_seccion         varchar2(30) ;
ls_desc_cencos          varchar2(40) ;
ls_desc_concep          varchar2(25) ;

--  Cursor para la tabla de ganancias fijas
cursor c_ganancias is 
  select gdf.cod_trabajador, gdf.concep, gdf.imp_gan_desc, m.cencos, m.cod_seccion,
         m.cod_area
  from gan_desct_fijo gdf, maestro m
  where gdf.cod_trabajador = m.cod_trabajador and m.flag_estado = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen and
        substr(gdf.concep,1,1) = '1' and gdf.flag_estado = '1'
  order by gdf.cod_trabajador, gdf.concep ;

begin

--  *****************************************************
--  ***   CONSULTA DE GANANCIAS FIJAS POR CONCEPTOS   ***
--  *****************************************************

delete from tt_ganancias_fijas ;

for rc_gan in c_ganancias loop  

  ls_nombre := usf_rh_nombre_trabajador (rc_gan.cod_trabajador) ;

  select a.desc_area into ls_desc_area  from area a  
    where a.cod_area = rc_gan.cod_area ;
  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_gan.cod_area and s.cod_seccion = rc_gan.cod_seccion ;
       
  ls_desc_cencos := null ;
  if rc_gan.cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = rc_gan.cencos ;
  end if ;
     
  select c.desc_breve into ls_desc_concep from concepto c
    where c.concep = rc_gan.concep ;
     
  insert into tt_ganancias_fijas (
    cod_trabajador, nombre, cod_area, desc_area,
    cod_seccion, desc_seccion, cencos, desc_cencos,
    concep, desc_concep, importe )
  values (
    rc_gan.cod_trabajador, ls_nombre, rc_gan.cod_area, ls_desc_area,
    rc_gan.cod_seccion, ls_desc_seccion, rc_gan.cencos, ls_desc_cencos,
    rc_gan.concep, ls_desc_concep, nvl(rc_gan.imp_gan_desc,0) ) ;

end loop ;

end usp_rh_cons_ganancias_fijas ;
/
