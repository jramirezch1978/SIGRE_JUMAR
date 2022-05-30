create or replace procedure usp_rh_rpt_provision_cts_gra (
  as_tipo_trabajador in char, as_origen in char, ad_fec_proceso in date ) is

ls_codigo         maestro.cod_trabajador%type ;
ls_nombres        varchar2(40) ;
ls_seccion        maestro.cod_seccion%type ;
ls_cencos         maestro.cencos%type ;
ls_descripcion    varchar2(40) ;
ln_imp_prov_cts   prov_cts_gratif.prov_cts_01%type ;
ln_imp_prov_gra   prov_cts_gratif.prov_gratif_01%type ;
ls_mes            char(2) ;
ln_contador       integer ;

--  Cursor para leer todos los activos del maestro
cursor c_maestro is 
  select m.cod_trabajador, m.cod_seccion, m.cod_area, m.cencos
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and m.tipo_trabajador =
        as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cencos, m.cod_seccion, m.cod_trabajador ;

--  Lectura de provisiones de gratificaciones
cursor c_provision is 
  select p.cod_trabajador, p.prov_gratif_01, p.prov_gratif_02, p.prov_gratif_03,
         p.prov_gratif_04, p.prov_gratif_05, p.prov_gratif_06, p.prov_gratif_07,
         p.prov_gratif_08, p.prov_gratif_09, p.prov_gratif_10, p.prov_gratif_11,
         p.prov_gratif_12
  from prov_cts_gratif p
  where p.cod_trabajador = ls_codigo ;

begin

--  *******************************************************************
--  ***   REPORTE DE PROVISIONES Y GRATIFICACIONES POR TRABAJADOR   ***
--  *******************************************************************

delete from tt_rpt_prov_cts_gra ;
ls_mes := to_char(ad_fec_proceso, 'MM') ;   

for rc_mae in c_maestro loop

  ls_codigo   := rc_mae.cod_trabajador ;
  ls_seccion  := rc_mae.cod_seccion ;
  ls_cencos   := rc_mae.cencos ;
  ls_nombres  := usf_rh_nombre_trabajador(ls_codigo) ;
       
  ln_contador := 0 ; ls_descripcion := null ;
  select count(*) into ln_contador from centros_costo cc
    where cc.cencos = ls_cencos ;
  if ln_contador > 0 then
    select nvl(cc.desc_cencos,' ') into ls_descripcion from centros_costo cc
      where cc.cencos = ls_cencos ;
  end if ;
  
  ln_imp_prov_gra := 0 ;
  for rc_pro in c_provision loop

    if ls_mes = '01' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_01,0) ;
    elsif ls_mes = '02' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_02,0) ;
    elsif ls_mes = '03' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_03,0) ;
    elsif ls_mes = '04' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_04,0) ;
    elsif ls_mes = '05' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_05,0) ;
    elsif ls_mes = '06' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_06,0) ;
    elsif ls_mes = '07' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_07,0) ;
    elsif ls_mes = '08' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_08,0) ;
    elsif ls_mes = '09' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_09,0) ;
    elsif ls_mes = '10' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_10,0) ;
    elsif ls_mes = '11' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_11,0) ;
    elsif ls_mes = '12' then
      ln_imp_prov_gra := nvl(rc_pro.prov_gratif_12,0) ;
    end if ;
    
  end loop ;     

  ln_contador := 0 ; ln_imp_prov_cts := 0 ;
  select count(*)
    into ln_contador from cts_decreto_urgencia d
    where d.cod_trabajador = ls_codigo and to_char(d.fec_proceso,'dd/mm/yyyy') =
          to_char(ad_fec_proceso,'dd/mm/yyyy') ;
  if ln_contador > 0 then
  select d.liquidacion
    into ln_imp_prov_cts from cts_decreto_urgencia d
    where d.cod_trabajador = ls_codigo and to_char(d.fec_proceso,'dd/mm/yyyy') =
          to_char(ad_fec_proceso,'dd/mm/yyyy') ;
  end if ;
    
  if ln_imp_prov_cts <> 0 or ln_imp_prov_gra <> 0 then
    insert into tt_rpt_prov_cts_gra (
      codigo, nombres, cod_seccion, cencos, desc_cencos,
      imp_prov_cts, imp_prov_gra, fecha_proceso )
    values (
      ls_codigo, ls_nombres, ls_seccion, ls_cencos, ls_descripcion,
      ln_imp_prov_cts, ln_imp_prov_gra, ad_fec_proceso ) ;
  end if ;

end loop ;

end usp_rh_rpt_provision_cts_gra ;
/
