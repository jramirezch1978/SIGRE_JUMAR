create or replace procedure usp_rh_rpt_adeudos_laborales (
  as_tipo_trabajador in char, as_origen in char, ad_fec_proceso in date ) is

lk_prov_vac        char(3) ;
lk_prov_bon        char(3) ;

ln_imp_fdo_ret     fondo_retiro.importe%type ;
ln_imp_cts         cnta_crrte_cts.cts_dispon_ant%type ;
ln_disponible      cnta_crrte_cts.cts_dispon_ant%type ;
ln_imp_vac         prov_vac_bonif.importe%type ;
ln_imp_bon         prov_vac_bonif.importe%type ;
ln_imp_gra         sldo_deveng.sldo_gratif_dev%type ;
ln_imp_rem         sldo_deveng.sldo_rem_dev%type ;
ln_imp_rac         sldo_deveng.sldo_racion%type ;
ln_imp_total       number(13,2) ;

ls_codigo          maestro.cod_trabajador%type ;
ls_cencos          maestro.cencos%type ;
ls_seccion         maestro.cod_seccion%type ;
ls_nombres         varchar2(40) ;
ls_desc_seccion    varchar2(40) ;
ls_desc_cencos     varchar2(40) ;
ln_contador        integer ;

--  Cursor para leer todos los trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.cencos, m.cod_seccion, m.cod_area
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.cod_trabajador ;

--  Saldos por compensacion por tiempo de servicios
cursor c_cts is
  select ccc.imp_prdo_dpsto, ccc.cts_dispon_ant, ccc.int_legales
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = ls_codigo and ccc.flag_control = '0'
  order by ccc.cod_trabajador, ccc.fec_prdo_dpsto, ccc.fec_calc_int ;

--  Saldos de vacaciones devengadas
cursor c_vacaciones is
  select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = ls_codigo and pvb.concep in ( select g.concepto_gen
        from grupo_calculo g where g.grupo_calculo = lk_prov_vac ) ;

--  Saldos de bonificaciones vacacionales devengadas
cursor c_bonificacion is
  select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = ls_codigo and pvb.concep in ( select g.concepto_gen
        from grupo_calculo g where g.grupo_calculo = lk_prov_bon ) ;

begin

--  ************************************************************
--  ***   REPORTE DE ADEUDOS LABORALES DE LOS TRABAJADORES   ***
--  ************************************************************

delete from tt_rpt_deudas ;

select p.gan_fij_calc_vacac, p.gan_bonif_vacacion
  into lk_prov_vac, lk_prov_bon
  from rrhhparam_cconcep p
  where p.reckey = '1' ;
  
for rc_mae in c_maestro loop

  ln_imp_cts := 0 ; ln_imp_vac := 0 ; ln_imp_fdo_ret := 0 ;
  ln_imp_bon := 0 ; ln_imp_gra := 0 ;
  ln_imp_rem := 0 ; ln_imp_rac := 0 ;

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_cencos  := rc_mae.cencos ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_nombres := usf_rh_nombre_trabajador(ls_codigo) ;

  ls_desc_seccion := null ;
  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_mae.cod_area and s.cod_seccion = ls_seccion ;

  ls_desc_cencos := null ;
  if ls_cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = ls_cencos ;
  end if ;

  --  Halla importe por fondo de retiro
  ln_contador := 0 ; ln_imp_fdo_ret := 0 ;
  select count(*) into ln_contador from fondo_retiro fd
    where fd.cod_trabajador = ls_codigo and fd.fec_proceso = ad_fec_proceso ;
  if ln_contador > 0 then
    select nvl(fd.importe,0) into ln_imp_fdo_ret from fondo_retiro fd
      where fd.cod_trabajador = ls_codigo and fd.fec_proceso = ad_fec_proceso ;
  end if ;

  --  Halla saldos de C.T.S.
  ln_disponible := 0 ; ln_imp_cts := 0 ;
  for rc_cts in c_cts loop
    ln_disponible := ln_disponible + nvl(rc_cts.cts_dispon_ant,0) ;
    ln_imp_cts := nvl(rc_cts.imp_prdo_dpsto,0) + nvl(rc_cts.int_legales,0) ;
  end loop ;
  ln_imp_cts := ln_imp_cts + ln_disponible ;

  --  Halla saldos de vacaciones devengadas
  ln_imp_vac := 0 ;
  for rc_vac in c_vacaciones loop
    ln_imp_vac := nvl(rc_vac.importe,0) ;
  end loop ;

  --  Halla saldos de bonificacion vacacional devengadas
  ln_imp_bon := 0 ;
  for rc_bon in c_bonificacion loop
    ln_imp_bon := nvl(rc_bon.importe,0) ;
  end loop ;

  --  Halla saldos de gratificaciones, remuneraciones y raciones
  ln_contador := 0 ; ln_imp_gra := 0 ; ln_imp_rem := 0 ; ln_imp_rac := 0 ;
  select count(*) into ln_contador from sldo_deveng sd
    where sd.cod_trabajador = ls_codigo and sd.fec_proceso = ad_fec_proceso ;
  if ln_contador > 0 then
    select nvl(sd.sldo_gratif_dev,0), nvl(sd.sldo_rem_dev,0), nvl(sd.sldo_racion,0)
      into ln_imp_gra, ln_imp_rem, ln_imp_rac from sldo_deveng sd
      where sd.cod_trabajador = ls_codigo and sd.fec_proceso = ad_fec_proceso ;
  end if ;

  ln_imp_total := ln_imp_fdo_ret + ln_imp_cts + ln_imp_vac + ln_imp_bon +
                  ln_imp_gra + ln_imp_rem + ln_imp_rac ;
  ln_imp_total := nvl(ln_imp_total,0) ;

  --  Adiciona registros en la tabla temporal tt_rpt_deudas
  if ln_imp_total <> 0 then
    insert into tt_rpt_deudas (
      cod_trabajador, nombre, cod_seccion, desc_seccion, cencos, desc_cencos,
      fecha, imp_fdoret, imp_cts, imp_vacdev, imp_bondev, imp_gradev,
      imp_remdev, imp_racazu, imp_total )
    values (
      ls_codigo, ls_nombres, ls_seccion, ls_desc_seccion, ls_cencos, ls_desc_cencos,
      ad_fec_proceso, ln_imp_fdo_ret, ln_imp_cts, ln_imp_vac, ln_imp_bon, ln_imp_gra,
      ln_imp_rem, ln_imp_rac, ln_imp_total ) ;
  end if ;

end loop ;

end usp_rh_rpt_adeudos_laborales ;
/
