create or replace procedure usp_racion is

ln_contador        integer ;
ln_importe_racion  racion_azucar_deveng.imp_pag_mes%type ;
ln_saldo_racion    racion_azucar_deveng.sldo_racion%type ;
ls_codigo          maestro.cod_trabajador%type ;

--  Concepto de raciones de azucar
Cursor c_maestro is
  Select m.cod_trabajador
  from maestro m
  order by m.cod_trabajador ;

--  Concepto de raciones de azucar
Cursor c_racion is
  Select rad.fec_proceso, rad.imp_pag_mes, rad.sldo_racion  
  from racion_azucar_deveng rad
  where rad.cod_trabajador = ls_codigo
        order by rad.cod_trabajador, rad.fec_proceso
        for update ;
        
        
begin
  
For rc_mae in c_maestro Loop      

ls_codigo := rc_mae.cod_trabajador ;

--  Guarda el ultimo registro del mes anterior al mes de proceso
ln_contador := 0 ;
For rc_rac in c_racion Loop

    ln_importe_racion := rc_rac.imp_pag_mes ;      
    ln_contador := ln_contador + 1 ;
    if ln_contador = 1 then
      ln_saldo_racion := rc_rac.sldo_racion ;
    end if ;
    if ln_contador > 1 then
      ln_saldo_racion := ln_saldo_racion - ln_importe_racion ;
      Update racion_azucar_deveng
      Set sldo_racion = ln_saldo_racion 
      where current of c_racion ;
    end if ;    

End Loop ;
End Loop ;

End usp_racion ;
/
