create or replace procedure usp_cons_dias_vac_bon
  ( as_tipo_trabajador  in maestro.tipo_trabajador%type ) is

ls_codigo             maestro.cod_trabajador%type ;
ls_area               area.cod_area%type ;
ls_desc_area          area.desc_area%type ;
ls_seccion            seccion.cod_seccion%type ;
ls_desc_seccion       seccion.desc_seccion%type ;
ls_cencos             centros_costo.cencos%type ;
ls_desc_cencos        centros_costo.desc_cencos%type ;
ls_nombre             varchar2(100) ;
ln_nro_dias_vac       number(6) ;
ln_nro_dias_bon       number(6) ;
ls_flag               char(1) ;
ln_importe            number(13,2) ;

--  Cursor de trabajadores, solo activos
Cursor c_trabajador is 
  Select m.cod_trabajador, m.cod_seccion, m.cencos,
         m.bonif_fija_30_25
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador ;
 
--  Cursor por dias de vacaciones y bonificaciones
Cursor c_vac_bon is 
  Select vbd.sldo_dias_vacacio, vbd.sldo_dias_bonif
  from vacac_bonif_deveng vbd
  where vbd.cod_trabajador = ls_codigo and
        vbd.flag_estado = '1'
  order by vbd.cod_trabajador, vbd.periodo ;
 
begin

--  Borra la informacion cada vez que se ejecuta
delete from tt_dias_vac_bon ;

For c_t in c_trabajador Loop

  ls_codigo  := c_t.cod_trabajador ;
  ls_nombre  := usf_nombre_trabajador(c_t.cod_trabajador);
  ls_seccion := c_t.cod_seccion ;
  If ls_seccion is null then
    ls_seccion := '340' ;
  End if ;
  ls_area    := substr(ls_seccion,1,1) ;
  ls_cencos  := c_t.cencos ;
  ls_flag    := c_t.bonif_fija_30_25 ;
  
  If ls_area is not null then
    Select a.desc_area
    into ls_desc_area 
    from area a  
    where a.cod_area = ls_area;
    If ls_seccion  is not null Then
      Select s.desc_seccion
      into ls_desc_seccion
      from seccion s
      where s.cod_seccion = ls_seccion ;
    Else 
      ls_seccion := '0' ;
    End if ;
  Else
    ls_area    := '0' ;
    ls_seccion := '0' ;
  End if ;
       
  If ls_cencos is not null then
    Select cc.desc_cencos
    into ls_desc_cencos
    from centros_costo cc
    where cc.cencos = ls_cencos ;
  Else
    ls_cencos := '0' ;
  End if ;

  ln_nro_dias_vac := 0 ;
  ln_nro_dias_bon := 0 ;
  For rc_vb in c_vac_bon Loop

    rc_vb.sldo_dias_vacacio := nvl(rc_vb.sldo_dias_vacacio,0) ;
    rc_vb.sldo_dias_bonif   := nvl(rc_vb.sldo_dias_bonif,0) ;
    ln_nro_dias_vac := ln_nro_dias_vac + rc_vb.sldo_dias_vacacio ;
    ln_nro_dias_bon := ln_nro_dias_bon + rc_vb.sldo_dias_bonif ;

  End Loop ;
    --  Calcula provision de vacaciones
    If ln_nro_dias_vac > 0 then
      ln_importe := 0;
      Select sum(gdf.imp_gan_desc ) 
        into ln_importe
        from gan_desct_fijo gdf 
        where gdf.cod_trabajador = ls_codigo and
              substr(gdf.concep,1,1) = '1' and
              gdf.flag_estado = '1' and
              gdf.flag_trabaj = '1' ;
      ln_importe := nvl(ln_importe,0) ;
      If ls_flag = '1' then 
         ln_importe := ln_importe * 1.3 ;
      Else
        If ls_flag = '2' then
          ln_importe := ln_importe * 1.25 ;
        End if ;    
      End If;
      ln_importe := (ln_importe * ln_nro_dias_vac) / 30 ;
      Insert into tt_dias_vac_bon (
        cod_trabajador, nombre_trabaj, cod_area,
        desc_area, cod_seccion, desc_seccion,
        cencos, desc_cencos, flag_vac_bon, desc_vac_bon,
        nro_trabajador, nro_dias, importe )
      Values (
        ls_codigo, ls_nombre, ls_area,
        ls_desc_area, ls_seccion, ls_desc_seccion,
        ls_cencos, ls_desc_cencos, '1', 'Vacaciones    ',
        1, ln_nro_dias_vac, ln_importe );
    End if ;
    --  Calcula provision de bonificaciones
    If ln_nro_dias_bon > 0 then
      ln_importe := 0;
      Select sum(gdf.imp_gan_desc ) 
        into ln_importe
        from gan_desct_fijo gdf 
        where gdf.cod_trabajador = ls_codigo and
              substr(gdf.concep,1,1) = '1' and
              gdf.flag_estado = '1' and
              gdf.flag_trabaj = '1' ;
      ln_importe := nvl(ln_importe,0) ;
      If ls_flag = '1' then 
         ln_importe := ln_importe * 1.3 ;
      Else
        If ls_flag = '2' then
          ln_importe := ln_importe * 1.25 ;
        End if ;    
      End If;
      ln_importe := (ln_importe * ln_nro_dias_bon) / 30 ;
      Insert into tt_dias_vac_bon (
        cod_trabajador, nombre_trabaj, cod_area,
        desc_area, cod_seccion, desc_seccion,
        cencos, desc_cencos, flag_vac_bon, desc_vac_bon,
        nro_trabajador, nro_dias, importe )
      Values (
        ls_codigo, ls_nombre, ls_area,
        ls_desc_area, ls_seccion, ls_desc_seccion,
        ls_cencos, ls_desc_cencos, '2', 'Bonificaciones',
        1, ln_nro_dias_bon, ln_importe );
    End if ;

End Loop;      

End usp_cons_dias_vac_bon ;
/
