create or replace procedure usp_rh_calcula_deuda_laboral (
  as_codtra in char, ad_fec_proceso in date ) is

lk_prov_vac        char(3) ;
lk_prov_bon        char(3) ;
lk_fondo_retiro    char(3) ;
lk_cts             char(3) ;
lk_vacac_deveng    char(3) ;
lk_bonif_deveng    char(3) ;
lk_grati_deveng    char(3) ;
lk_remun_deveng    char(3) ;
lk_racion_azucar   char(3) ;

ls_concepto        char(4) ;
ln_imp_fdo_ret     fondo_retiro.importe%type ;
ln_imp_cts         cnta_crrte_cts.cts_dispon_ant%type ;
ln_disponible      cnta_crrte_cts.cts_dispon_ant%type ;
ln_imp_vac         prov_vac_bonif.importe%type ;
ln_imp_bon         prov_vac_bonif.importe%type ;
ln_imp_gra         sldo_deveng.sldo_gratif_dev%type ;
ln_imp_rem         sldo_deveng.sldo_rem_dev%type ;
ln_imp_rac         sldo_deveng.sldo_racion%type ;

ls_cencos          maestro.cencos%type ;
ls_seccion         maestro.cod_seccion%type ;
ln_contador        integer ;

--  Saldos por compensacion por tiempo de servicios
cursor c_cts is
  select ccc.imp_prdo_dpsto, ccc.cts_dispon_ant, ccc.int_legales
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = as_codtra and ccc.flag_control = '0'
  order by ccc.cod_trabajador, ccc.fec_prdo_dpsto, ccc.fec_calc_int ;

--  Saldos de vacaciones devengadas
cursor c_vacaciones is
  select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = as_codtra and pvb.concep in ( select g.concepto_gen
        from grupo_calculo g where g.grupo_calculo = lk_prov_vac ) ;

--  Saldos de bonificaciones vacacionales devengadas
cursor c_bonificacion is
  select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = as_codtra and pvb.concep in ( select g.concepto_gen
        from grupo_calculo g where g.grupo_calculo = lk_prov_bon ) ;

begin

--  ***************************************************************
--  ***   REALIZA CALCULO DE ADEUDOS LABORALES POR TRABAJADOR   ***
--  ***************************************************************

select c.gan_fij_calc_vacac, c.gan_bonif_vacacion, c.deuda_laboral_fond_ret,
       c.deuda_laboral_cts, c.deuda_laboral_vacac_deveng, c.deuda_laboral_bonif_deveng,
       c.deuda_laboral_gratif_deveng, c.deuda_laboral_remun_deveng, c.deuda_laboral_rac_azuc_deveng
  into lk_prov_vac, lk_prov_bon, lk_fondo_retiro,
       lk_cts, lk_vacac_deveng, lk_bonif_deveng,
       lk_grati_deveng, lk_remun_deveng, lk_racion_azucar
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

--  Halla datos del maestro
select m.cencos, m.cod_seccion into ls_cencos, ls_seccion
  from maestro m where m.cod_trabajador = as_codtra ;

--  Halla importe por fondo de retiro
ln_contador := 0 ;
select count(*) into ln_contador from fondo_retiro fd
  where fd.cod_trabajador = as_codtra ;
if ln_contador > 0 then
  select nvl(fd.importe,0) into ln_imp_fdo_ret from fondo_retiro fd
  where fd.cod_trabajador = as_codtra ;
end if ;

--  Halla saldos de C.T.S.
ln_disponible := 0 ;
for rc_cts in c_cts loop
  ln_disponible := ln_disponible + nvl(rc_cts.cts_dispon_ant,0) ;
  ln_imp_cts := rc_cts.imp_prdo_dpsto + nvl(rc_cts.int_legales,0) ;
end loop ;
ln_imp_cts := ln_imp_cts + ln_disponible ;

--  Halla saldos de vacaciones devengadas
for rc_vac in c_vacaciones loop
  ln_imp_vac := nvl(rc_vac.importe,0) ;
end loop ;

--  Halla saldos de bonificacion vacacional devengadas
for rc_bon in c_bonificacion loop
  ln_imp_bon := nvl(rc_bon.importe,0) ;
end loop ;

--  Halla saldos de gratificaciones, remuneraciones y raciones
ln_contador := 0 ;
select count(*) into ln_contador from sldo_deveng sd
  where sd.cod_trabajador = as_codtra ;
if ln_contador > 0 then
  select nvl(sd.sldo_gratif_dev,0), nvl(sd.sldo_rem_dev,0), nvl(sd.sldo_racion,0)
    into ln_imp_gra, ln_imp_rem, ln_imp_rac
    from sldo_deveng sd where sd.cod_trabajador = as_codtra ;
end if ;

--  Adiciona registros

--  Fondo de retiro
if ln_imp_fdo_ret > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_fondo_retiro ;
  insert into deuda (
    cod_trabajador, fec_proceso, cencos, concep, cod_seccion,
    flag_estado, importe, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ls_cencos, ls_concepto, ls_seccion,
    '1', ln_imp_fdo_ret, '1' ) ;
end if ;

--  Compensacion tiempo de servicio
if ln_imp_cts > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_cts ;
  insert into deuda (
    cod_trabajador, fec_proceso, cencos, concep, cod_seccion,
    flag_estado, importe, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ls_cencos, ls_concepto, ls_seccion,
    '1', ln_imp_cts, '1' ) ;
end if ;

--  Vacaciones devengadas
if ln_imp_vac > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_vacac_deveng ;
  insert into deuda (
    cod_trabajador, fec_proceso, cencos, concep, cod_seccion,
    flag_estado, importe, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ls_cencos, ls_concepto, ls_seccion,
    '1', ln_imp_vac, '1' ) ;
end if ;

--  Bonificacion vacacional devengada
if ln_imp_bon > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_bonif_deveng ;
  insert into deuda (
    cod_trabajador, fec_proceso, cencos, concep, cod_seccion,
    flag_estado, importe, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ls_cencos, ls_concepto, ls_seccion,
    '1', ln_imp_bon, '1' ) ;
end if ;

--  Gratificaciones devengadas
if ln_imp_gra > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_grati_deveng ;
  insert into deuda (
    cod_trabajador, fec_proceso, cencos, concep, cod_seccion,
    flag_estado, importe, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ls_cencos, ls_concepto, ls_seccion,
    '1', ln_imp_gra, '1' ) ;
end if ;

--  Remuneraciones devengadas
if ln_imp_rem > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_remun_deveng ;
  insert into deuda (
    cod_trabajador, fec_proceso, cencos, concep, cod_seccion,
    flag_estado, importe, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ls_cencos, ls_concepto, ls_seccion,
    '1', ln_imp_rem, '1' ) ;
end if ;

--  Raciones de Azucar devengadas
if ln_imp_rac > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_racion_azucar ;
  insert into deuda (
    cod_trabajador, fec_proceso, cencos, concep, cod_seccion,
    flag_estado, importe, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ls_cencos, ls_concepto, ls_seccion,
    '1', ln_imp_rac, '1' ) ;
end if ;

end usp_rh_calcula_deuda_laboral ;
/
