create or replace procedure usp_rh_actualiza_saldo_dev (
  as_codtra in char, ad_fec_proceso in date, ad_fec_anterior in date ) is

lk_gratificaciones      char(3) ;
lk_remuneraciones       char(3) ;

ln_verifica             integer ;
ln_contador             integer ;
ls_concepto             char(4) ;

ln_saldo_gratificacion  number(13,2) ;
ln_saldo_remuneracion   number(13,2) ;
ln_capital              number(13,2) ;
ln_interes              number(13,2) ;
ln_saldo_racion         number(13,2) ;
ln_total                number(13,2) ;

--  Cursor de saldos de raciones de azucar
cursor c_racion is
  select rad.sldo_racion
  from racion_azucar_deveng rad
  where rad.cod_trabajador = as_codtra
  order by rad.cod_trabajador, rad.fec_proceso ;

begin

--  *********************************************************
--  ***   ACTUALIZA SALDOS DE DEVENGADOS POR TRABAJADOR   ***
--  *********************************************************

select c.gratific_deveng, c.remun_deveng
  into lk_gratificaciones, lk_remuneraciones
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

delete from sldo_deveng sd
  where sd.cod_trabajador = as_codtra and sd.fec_proceso = ad_fec_proceso ;

ln_verifica := 0 ; ln_saldo_gratificacion := 0 ;
select count(*) into ln_verifica from grupo_calculo g
  where g.grupo_calculo = lk_gratificaciones ;
if ln_verifica > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_gratificaciones ;
  ln_contador := 0 ;
  select count(*)
    into ln_contador from maestro_remun_gratif_dev rgd
    where rgd.cod_trabajador = as_codtra and rgd.concep = ls_concepto and
          rgd.fec_calc_int = ad_fec_proceso ;
  if ln_contador > 0 then
    select nvl(rgd.nvo_capital,0), nvl(rgd.nvo_interes,0)
      into ln_capital, ln_interes from maestro_remun_gratif_dev rgd
      where rgd.cod_trabajador = as_codtra and rgd.concep = ls_concepto and
          rgd.fec_calc_int = ad_fec_proceso ;
    ln_saldo_gratificacion := nvl(ln_capital,0) + nvl(ln_interes,0) ;
  end if ;
end if ;

ln_verifica := 0 ; ln_saldo_remuneracion := 0 ;
select count(*) into ln_verifica from grupo_calculo g
  where g.grupo_calculo = lk_remuneraciones ;
if ln_verifica > 0 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_remuneraciones ;
  ln_contador := 0 ;
  select count(*)
    into ln_contador from maestro_remun_gratif_dev rgd
    where rgd.cod_trabajador = as_codtra and rgd.concep = ls_concepto and
          rgd.fec_calc_int = ad_fec_proceso ;
  if ln_contador > 0 then
    select nvl(rgd.nvo_capital,0), nvl(rgd.nvo_interes,0)
      into ln_capital, ln_interes from maestro_remun_gratif_dev rgd
      where rgd.cod_trabajador = as_codtra and rgd.concep = ls_concepto and
          rgd.fec_calc_int = ad_fec_proceso ;
    ln_saldo_remuneracion := nvl(ln_capital,0) + nvl(ln_interes,0) ;
  end if ;
end if ;

ln_saldo_racion := 0 ;
for rc_rac in c_racion loop
  ln_saldo_racion := nvl(rc_rac.sldo_racion,0) ;
end loop ;

ln_contador := 0 ;
select count(*) into ln_contador from sldo_deveng dev
  where dev.cod_trabajador = as_codtra and
        dev.fec_proceso = ad_fec_anterior ;
if ln_contador = 0 then
  ln_saldo_racion := 0 ;
end if ;

ln_total := 0 ;
ln_total := ln_saldo_gratificacion + ln_saldo_remuneracion + ln_saldo_racion ;

if ln_total <> 0 then
  insert into sldo_deveng (
    cod_trabajador, fec_proceso, sldo_gratif_dev,
    sldo_rem_dev, sldo_racion, imp_orig_racion, cant_azucar_racion, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, ln_saldo_gratificacion,
    ln_saldo_remuneracion, ln_saldo_racion, 0, 0, '1' ) ;
end if ;

end usp_rh_actualiza_saldo_dev ;
/
