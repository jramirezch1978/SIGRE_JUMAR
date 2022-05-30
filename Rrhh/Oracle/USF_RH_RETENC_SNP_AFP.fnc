create or replace function USF_RH_RETENC_SNP_AFP(
       an_periodo in cntbl_asiento.ano%type, 
       as_origen in origen.cod_origen%type, 
       as_trabajador in maestro.cod_trabajador%type, 
       as_concepto in concepto.concep%type) 
       
return number is

  ln_retencion     number;
  ln_retenc_total  number ;
  
BEGIN 

ln_retenc_total:= 0 ;

-- Calculando en tabla "historico_calculo"
SELECT sum(hc.imp_soles) 
  INTO ln_retencion 
  FROM historico_calculo hc 
 WHERE hc.cod_trabajador = as_trabajador 
   AND TO_NUMBER(TO_CHAR(hc.fec_calc_plan,'yyyy'))  = an_periodo 
   AND hc.cod_origen     = as_origen 
   AND hc.concep         = as_concepto ;

ln_retenc_total := ln_retenc_total + NVL(ln_retencion,0) ;

-- Calculando en tabla "calculo"
SELECT sum(c.imp_soles) 
  INTO ln_retencion 
  FROM calculo c 
 WHERE c.cod_trabajador = as_trabajador 
   AND TO_NUMBER(TO_CHAR(c.fec_proceso,'yyyy')) = an_periodo 
   AND c.cod_origen = as_origen 
   AND c.concep = as_concepto ;

ln_retenc_total := ln_retenc_total + NVL(ln_retencion,0) ;

return(ln_retenc_total);

END USF_RH_RETENC_SNP_AFP;
/
