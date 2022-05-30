create or replace procedure usp_pla_dev_calculo_rac
   (as_codtra       in maestro.cod_trabajador%type ,
    ad_fec_proceso  in date
   ) is

ls_meses           char(2) ;
ls_years           char(4) ;
ln_contador        integer ;
ld_fec_proceso     racion_azucar_deveng.fec_proceso%type ;
ln_importe_racion  racion_azucar_deveng.imp_pag_mes%type ;
ln_saldo_racion    racion_azucar_deveng.sldo_racion%type ;

--  Concepto de raciones de azucar
Cursor c_racion is
  Select rad.fec_proceso, rad.imp_pag_mes, rad.sldo_racion  
  from racion_azucar_deveng rad
  where rad.cod_trabajador = as_codtra 
        order by rad.cod_trabajador, rad.fec_proceso
        for update ;
        
begin
        
-- Verifica si tiene saldo de raciones de azucar
ln_contador := 0 ;
Select count(*)
  into ln_contador
  from sldo_deveng sd
  where sd.cod_trabajador = as_codtra and
        sd.fec_proceso = add_months(ad_fec_proceso,-1) and
        sd.sldo_racion > 0 ;
ln_contador := nvl(ln_contador,0) ;

If ln_contador > 0 then
  
ls_meses := to_char(ad_fec_proceso, 'MM') ;
ls_years := to_char(ad_fec_proceso, 'YYYY') ;

--  Guarda el ultimo registro del mes anterior al mes de proceso
For rc_rac in c_racion Loop

  If to_char(rc_rac.fec_proceso, 'MM')   <> ls_meses
  or to_char(rc_rac.fec_proceso, 'YYYY') <> ls_years then
    ln_saldo_racion   := rc_rac.sldo_racion ;
  End if ;          

End Loop ;

ln_saldo_racion   := nvl(ln_saldo_racion,0) ;

--  Verifica si tiene saldos para actualizar
If ln_saldo_racion > 0 then

  ln_contador := 0 ;
  Select count(*)
    Into ln_contador
    from racion_azucar_deveng rad
    where rad.cod_trabajador = as_codtra
      and to_char(rad.fec_proceso, 'MM')   = ls_meses
      and to_char(rad.fec_proceso, 'YYYY') = ls_years ;

  --  Si existe registros del mes de proceso
  --  Actualiza
  If ln_contador > 0 then

    For rc_rac in c_racion Loop

      If to_char(rc_rac.fec_proceso, 'MM') = ls_meses
      and to_char(rc_rac.fec_proceso, 'YYYY') = ls_years then
        ln_importe_racion := rc_rac.imp_pag_mes ;      
        ln_saldo_racion := ln_saldo_racion - ln_importe_racion ;

        --  Actualiza registro
        Update racion_azucar_deveng
        Set sldo_racion = ln_saldo_racion 
        where current of c_racion ;
      End if ;
    
    End Loop ;

  End if ;

End if ;

End if ;

End usp_pla_dev_calculo_rac ;
/
