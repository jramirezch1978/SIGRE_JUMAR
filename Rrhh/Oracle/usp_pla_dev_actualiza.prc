create or replace procedure usp_pla_dev_actualiza
  (as_codtra       in maestro.cod_trabajador%type,
   ad_fec_proceso  in date ) is

ln_contador             integer ;
ln_capital              number(15,2) ;
ln_interes              number(15,2) ;
ln_saldo_gratificacion  maestro_remun_gratif_dev.nvo_capital%type ;
ln_saldo_remuneracion   maestro_remun_gratif_dev.nvo_capital%type ;
ln_saldo_racion         racion_azucar_deveng.sldo_racion%type ;
ld_fec_proceso          date ;
ln_total                number(15,2) ;

--  Concepto de raciones de azucar
Cursor c_racion is
  Select rad.fec_proceso, rad.imp_pag_mes, rad.sldo_racion  
    from racion_azucar_deveng rad
    where rad.cod_trabajador = as_codtra
    order by rad.cod_trabajador, rad.fec_proceso ;

--  Maestro de saldos de devengados
Cursor c_devengados is
  Select d.sldo_gratif_dev, d.sldo_rem_dev, d.sldo_racion
    from sldo_deveng d
    where d.cod_trabajador = as_codtra and
          d.fec_proceso = ad_fec_proceso ;
        
begin

delete from sldo_deveng sd
  where sd.cod_trabajador = as_codtra and
        sd.fec_proceso = ad_fec_proceso ;

--  Guarda el ultimo saldo por gratificaciones
ln_contador := 0 ;
ln_saldo_gratificacion := 0 ;
Select count(*)
  into ln_contador
  from maestro_remun_gratif_dev rgd
  where rgd.cod_trabajador = as_codtra and
        rgd.concep = '1301' and
        rgd.fec_calc_int = ad_fec_proceso ;
  ln_contador := nvl(ln_contador,0) ;

If ln_contador > 0 then
  ln_capital := 0 ; ln_interes  := 0 ;
  Select rgd.nvo_capital, rgd.nvo_interes
    into ln_capital, ln_interes
    from maestro_remun_gratif_dev rgd
    where rgd.cod_trabajador = as_codtra and
          rgd.concep = '1301' and
          rgd.fec_calc_int = ad_fec_proceso ;
    ln_saldo_gratificacion := nvl(ln_capital,0) + nvl(ln_interes,0) ;
End if ;                   

--  Guarda el ultimo saldo por remuneraciones
ln_contador := 0 ;
ln_saldo_remuneracion := 0 ;
Select count(*)
  into ln_contador
  from maestro_remun_gratif_dev rgd
  where rgd.cod_trabajador = as_codtra and
        rgd.concep = '1302' and
        rgd.fec_calc_int = ad_fec_proceso ;
  ln_contador := nvl(ln_contador,0) ;

If ln_contador > 0 then
  ln_capital := 0 ; ln_interes  := 0 ;
  Select rgd.nvo_capital, rgd.nvo_interes
    into ln_capital, ln_interes
    from maestro_remun_gratif_dev rgd
    where rgd.cod_trabajador = as_codtra and
          rgd.concep = '1302' and
          rgd.fec_calc_int = ad_fec_proceso ;
    ln_saldo_remuneracion := nvl(ln_capital,0) + nvl(ln_interes,0) ;
End if ;                   

--  Guarda el ultimo registro por raciones de azucar
ln_saldo_racion := 0 ;
For rc_rac in c_racion Loop
  ln_saldo_racion := nvl(rc_rac.sldo_racion,0) ;
End Loop ;
ln_saldo_racion := nvl(ln_saldo_racion,0) ;

  ln_contador := 0 ;
  Select count(*)
    Into ln_contador
    from sldo_deveng dev
    where dev.cod_trabajador = as_codtra and
          dev.fec_proceso = add_months(ad_fec_proceso,-1) ;
  If ln_contador = 0 then
    ln_saldo_racion := 0 ;
  End if ;

ln_total := 0 ;
ln_total := ln_saldo_gratificacion + ln_saldo_remuneracion +
            ln_saldo_racion ;
            
If ln_total <> 0 then
  Insert into sldo_deveng (
    cod_trabajador, fec_proceso, sldo_gratif_dev,
    sldo_rem_dev, sldo_racion, imp_orig_racion,
    cant_azucar_racion )
  Values (
    as_codtra, ad_fec_proceso, ln_saldo_gratificacion,
    ln_saldo_remuneracion, ln_saldo_racion, 0,
    0 ) ;
End if ;

End usp_pla_dev_actualiza ;
/
