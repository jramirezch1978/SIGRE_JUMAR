create or replace procedure usp_cons_escala_categoria
  ( as_tipo_trabajador  in maestro.tipo_trabajador%type ) is

ls_codigo             maestro.cod_trabajador%type ;
ls_area               area.cod_area%type ;
ls_desc_area          area.desc_area%type ;
ls_seccion            seccion.cod_seccion%type ;
ls_desc_seccion       seccion.desc_seccion%type ;
ls_cencos             centros_costo.cencos%type ;
ls_desc_cencos        centros_costo.desc_cencos%type ;
ls_nombre             varchar2(100) ;
ls_categoria          char(2) ;
ln_importe            number(13,2) ;

--  Cursor de trabajadores, solo activos
Cursor c_trabajador is 
  Select m.cod_trabajador, m.cod_seccion, m.cencos, m.cod_categ_sal
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_categ_sal ;
 
begin

--  Borra la informacion cada vez que se ejecuta
delete from tt_escala_categoria ;

For c_t in c_trabajador Loop

  ls_codigo  := c_t.cod_trabajador ;
  ls_nombre  := usf_nombre_trabajador(c_t.cod_trabajador);
  ls_seccion := c_t.cod_seccion ;
  If ls_seccion is null then
    ls_seccion := '340' ;
  End if ;
  ls_area      := substr(ls_seccion,1,1) ;
  ls_cencos    := c_t.cencos ;
  ls_categoria := c_t.cod_categ_sal ;
  If ls_categoria is null then
    ls_categoria := 'SC' ;
  End if ;
  
  Select a.desc_area
    into ls_desc_area 
    from area a  
    where a.cod_area = ls_area;

  Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
       
  If ls_cencos is not null then
    Select cc.desc_cencos
    into ls_desc_cencos
    from centros_costo cc
    where cc.cencos = ls_cencos ;
  Else
    ls_cencos := '0' ;
  End if ;

  ln_importe := 0;
  Select sum(gdf.imp_gan_desc ) 
    into ln_importe
    from gan_desct_fijo gdf 
    where gdf.cod_trabajador = ls_codigo and
          gdf.concep = '1001' and
          gdf.flag_estado = '1' and
          gdf.flag_trabaj = '1' ;
  ln_importe := nvl(ln_importe,0) ;

  If ln_importe > 0 then
    Insert into tt_escala_categoria (
      cod_trabajador, nombre_trabaj, cod_area,
      desc_area, cod_seccion, desc_seccion,
      cencos, desc_cencos, categoria, importe )
    Values (
      ls_codigo, ls_nombre, ls_area,
      ls_desc_area, ls_seccion, ls_desc_seccion,
      ls_cencos, ls_desc_cencos, ls_categoria, ln_importe ) ;
    End if ;

End Loop;      

End usp_cons_escala_categoria ;
/
