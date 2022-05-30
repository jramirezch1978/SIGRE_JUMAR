create or replace procedure usp_rh_cons_categoria_salarial (
  as_tipo_trabajador in char, as_origen in char ) is

lk_basico             char(3) ;

ls_desc_area          area.desc_area%type ;
ls_desc_seccion       seccion.desc_seccion%type ;
ls_desc_cencos        centros_costo.desc_cencos%type ;
ls_nombre             varchar2(100) ;
ls_categoria          char(2) ;
ln_importe            number(13,2) ;
ls_concepto_1         char(4) ;

--  Cursor de trabajadores seleccionados
cursor c_trabajador is
  select m.cod_trabajador, m.cod_seccion, m.cod_area, m.cencos, m.cod_categ_sal
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_categ_sal ;

begin

--  *********************************************************************
--  ***   CONSULTA DE LAS CATEGORIAS SALARIALES DE LOS TRABAJADORES   ***
--  *********************************************************************

delete from tt_escala_categoria ;

select p.remunerac_basica
  into lk_basico
  from rrhhparam_cconcep p
  where p.reckey = '1' ;
  
for c_t in c_trabajador loop

  ls_nombre  := usf_rh_nombre_trabajador(c_t.cod_trabajador) ;
  ls_categoria := c_t.cod_categ_sal ;

  if ls_categoria is null then
    ls_categoria := 'SC' ;
  end if ;

  select a.desc_area into ls_desc_area from area a
    where a.cod_area = c_t.cod_area ;

  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = c_t.cod_area and s.cod_seccion = c_t.cod_seccion ;

  ls_desc_cencos := null ;
  if c_t.cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
    where cc.cencos = c_t.cencos ;
  end if ;

  select g.concepto_gen into ls_concepto_1 from grupo_calculo g
    where g.grupo_calculo = lk_basico ;

  ln_importe := 0;
  select sum(nvl(gdf.imp_gan_desc,0)) into ln_importe from gan_desct_fijo gdf
    where gdf.cod_trabajador = c_t.cod_trabajador and
          gdf.concep = ls_concepto_1 and gdf.flag_estado = '1' ;
  ln_importe := nvl(ln_importe,0) ;

  if ln_importe > 0 then
    insert into tt_escala_categoria (
      cod_trabajador, nombre_trabaj, cod_area,
      desc_area, cod_seccion, desc_seccion,
      cencos, desc_cencos, categoria, importe )
    values (
      c_t.cod_trabajador, ls_nombre, c_t.cod_area,
      ls_desc_area, c_t.cod_seccion, ls_desc_seccion,
      c_t.cencos, ls_desc_cencos, ls_categoria, ln_importe ) ;
  end if ;

end loop;

end usp_rh_cons_categoria_salarial ;
/
