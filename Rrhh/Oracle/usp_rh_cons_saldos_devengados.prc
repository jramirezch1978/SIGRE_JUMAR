create or replace procedure usp_rh_cons_saldos_devengados (
  as_tipo_trabajador in char, as_origen in char, ad_fec_proceso in date ) is

ls_nombre            varchar2(100) ;
ls_desc_area         area.desc_area%type ;
ls_desc_seccion      seccion.desc_seccion%type ;
ls_desc_cencos       centros_costo.desc_cencos%type ;
ls_suma              number(13,2) ;

--  Lectura de saldos por devengados de los trabajadores seleccionados
cursor c_saldos is
  select sd.cod_trabajador, sd.fec_proceso, sd.sldo_gratif_dev, sd.sldo_rem_dev,
         sd.sldo_racion, m.cod_area, m.cod_seccion, m.cencos
  from  sldo_deveng sd, maestro m
  where sd.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador = as_tipo_trabajador and sd.fec_proceso =
        ad_fec_proceso ;

begin

--  ****************************************************************
--  ***   CONSULTA DE SALDOS DE DEVENGADOS DE LOS TRABAJADORES   ***
--  ****************************************************************

delete from tt_cons_sldo_deveng ;

for rc_s in c_saldos loop

  ls_nombre  := usf_rh_nombre_trabajador(rc_s.cod_trabajador) ;

  ls_desc_area := null ;
  select a.desc_area into ls_desc_area from area a
    where a.cod_area = rc_s.cod_area ;

  ls_desc_seccion := null ;
    select s.desc_seccion into ls_desc_seccion from seccion s
      where s.cod_area = rc_s.cod_area and s.cod_seccion = rc_s.cod_seccion ;

  ls_desc_cencos := null ;
  if rc_s.cencos <> ' ' then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = rc_s.cencos ;
  end if ;

  ls_suma := nvl(rc_s.sldo_gratif_dev,0) + nvl(rc_s.sldo_rem_dev,0) +
             nvl(rc_s.sldo_racion,0) ;

  if ls_suma <> 0 then
    insert into tt_cons_sldo_deveng (
      cod_trabajador, nombre, cod_area, desc_area,
      cod_seccion, desc_seccion, cencos, desc_cencos,
      fec_proceso, sldo_gratif_dev, sldo_rem_dev,
      sldo_racion  )
  values (
    rc_s.cod_trabajador, ls_nombre, rc_s.cod_area, ls_desc_area,
    rc_s.cod_seccion, ls_desc_seccion, rc_s.cencos, ls_desc_cencos,
    ad_fec_proceso, nvl(rc_s.sldo_gratif_dev,0), nvl(rc_s.sldo_rem_dev,0),
    nvl(rc_s.sldo_racion,0) ) ;
  end if ;

end loop ;

end usp_rh_cons_saldos_devengados ;
/
