create or replace procedure usp_rh_dev_calculo_rac (
  as_codtra in char, ad_fec_proceso in date, ad_fec_anterior in date ) is

ln_verifica        integer ;
ln_contador        integer ;

ld_fec_proceso     racion_azucar_deveng.fec_proceso%type ;
ln_importe_racion  racion_azucar_deveng.imp_pag_mes%type ;
ln_saldo_racion    racion_azucar_deveng.sldo_racion%type ;

--  Cursor de pagos efecutuados por raciones de azucar
cursor c_racion is
  select rad.fec_proceso, rad.imp_pag_mes, rad.sldo_racion
  from racion_azucar_deveng rad
  where rad.cod_trabajador = as_codtra
  order by rad.cod_trabajador, rad.fec_proceso
  for update ;

begin

--  ************************************************************
--  ***   ACTUALIZA SALDOS DE PAGOS POR RACIONES DE AZUCAR   ***
--  ************************************************************

ln_verifica := 0 ;
select count(*) into ln_verifica from sldo_deveng sd
  where sd.cod_trabajador = as_codtra and sd.fec_proceso = ad_fec_anterior
        and nvl(sd.sldo_racion,0) > 0 ;

if ln_verifica > 0 then

  for rc_rac in c_racion loop
    if to_char(rc_rac.fec_proceso,'mm/yyyy') <>
      to_char(ad_fec_proceso,'mm/yyyy') then
      ln_saldo_racion := nvl(rc_rac.sldo_racion,0) ;
    end if ;
  end loop ;

  if ln_saldo_racion > 0 then

    ln_contador := 0 ;
    select count(*) into ln_contador from racion_azucar_deveng rad
      where rad.cod_trabajador = as_codtra and to_char(rad.fec_proceso,'mm/yyyy') =
            to_char(ad_fec_proceso,'mm/yyyy') ;

    if ln_contador > 0 then

      for rc_rac in c_racion loop

        if to_char(rc_rac.fec_proceso,'mm/yyyy') =
          to_char(ad_fec_proceso,'mm/yyyy') then
          ln_importe_racion := nvl(rc_rac.imp_pag_mes,0) ;
          ln_saldo_racion := ln_saldo_racion - ln_importe_racion ;
          update racion_azucar_deveng
           set sldo_racion = ln_saldo_racion,
              flag_replicacion = '1'
           where current of c_racion ;
        end if ;

      end loop ;

    end if ;

  end if ;

end if ;

end usp_rh_dev_calculo_rac ;
/
