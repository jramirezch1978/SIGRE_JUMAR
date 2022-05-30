create or replace procedure usp_cons_ganancias_fijas
  ( as_tipo_trabajador   in maestro.tipo_trabajador%type ) is

--  Variables locales
ls_cod_trabajador       char(8) ;
ls_nombre               varchar2(100) ;
ls_cod_area             char(1) ;
ls_desc_area            varchar2(30) ;
ls_cod_seccion          char(3) ;
ls_desc_seccion         varchar2(30) ;
ls_cencos               char(10) ;
ls_desc_cencos          varchar2(40) ;
ls_concep               char(4) ;
ls_desc_concep          varchar2(25) ;
ln_importe              number(13,2) ;
ls_estado               maestro.flag_estado%type ;
ls_tipo_trabajador      maestro.tipo_trabajador%type ;

--  Cursor para la tabla de ganancias fijas
cursor c_ganancias is 
  select gdf.cod_trabajador, gdf.concep, gdf.flag_trabaj,
         gdf.flag_estado, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where substr(gdf.concep,1,1) = '1' and 
        gdf.flag_estado = '1' and
        gdf.flag_trabaj = '1'
  order by gdf.cod_trabajador, gdf.concep ;

begin

delete from tt_ganancias_fijas ;

--  Graba informacion a la tabla temporal
For rc_gan in c_ganancias Loop  

  ls_cod_trabajador := rc_gan.cod_trabajador ;
  ls_concep         := rc_gan.concep ;
  ln_importe        := rc_gan.imp_gan_desc ;

  Select m.flag_estado, m.tipo_trabajador, m.cencos, m.cod_seccion
    into ls_estado, ls_tipo_trabajador, ls_cencos, ls_cod_seccion
    from maestro m
    where m.cod_trabajador = ls_cod_trabajador ;

  If ls_tipo_trabajador = as_tipo_trabajador then
  
    If ls_cod_seccion is null then
      ls_cod_seccion := '340' ;
    End if ;
  
    If ls_estado = '1' then
      ls_cod_area := substr(ls_cod_seccion,1,1) ;
      ls_nombre   := usf_nombre_trabajador (ls_cod_trabajador) ;

      If ls_cod_area is not null then
        Select a.desc_area
          into ls_desc_area 
          from area a  
          where a.cod_area = ls_cod_area;
          If ls_cod_seccion  is not null Then
            Select s.desc_seccion
              into ls_desc_seccion
              from seccion s
              where s.cod_seccion = ls_cod_seccion ;
          Else 
            ls_cod_seccion := '0' ;
          End if ;
      Else
        ls_cod_area    := '0' ;
        ls_cod_seccion := '0' ;
      End if ;
       
      If ls_cencos is not null then
        Select cc.desc_cencos
          into ls_desc_cencos
          from centros_costo cc
          where cc.cencos = ls_cencos ;
      Else
        ls_cencos := '0' ;
      End if ;
     
      If ls_concep is not null then
        Select c.desc_breve
          into ls_desc_concep
          from concepto c
          where c.concep = ls_concep ;
      Else
        ls_concep := '0' ;
      End if ;
     
    --  Insertar los Registro en la tabla tt_ganancias_fijas
    Insert into tt_ganancias_fijas
      (cod_trabajador, nombre, cod_area,
       desc_area, cod_seccion, desc_seccion,
       cencos, desc_cencos, concep, desc_concep,
       importe)
    Values
      (ls_cod_trabajador, ls_nombre, ls_cod_area,
       ls_desc_area, ls_cod_seccion, ls_desc_seccion,
       ls_cencos, ls_desc_cencos, ls_concep, ls_desc_concep,
       ln_importe ) ;
  
    End if ;

  End if ;

End loop ;

end usp_cons_ganancias_fijas ;
/
