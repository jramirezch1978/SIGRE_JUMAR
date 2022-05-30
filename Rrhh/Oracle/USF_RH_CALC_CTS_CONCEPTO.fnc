create or replace function USF_RH_CALC_CTS_CONCEPTO(
       ad_fecha_proceso in date, 
       as_cod_trabajador in maestro.cod_trabajador%type, 
       as_concepto in hist_prov_cts_det.concepto%type) 
  return number is
  
  ln_monto number;
  
  ln_count      Number ;
  
BEGIN 

SELECT count(*) 
  INTO ln_count 
  FROM hist_prov_cts_det h 
 WHERE h.fecha_proceso = ad_fecha_proceso and 
       h.cod_trabajador = as_cod_trabajador and 
       h.concepto = as_concepto ;

IF ln_count > 0 THEN 
  SELECT SUM(h.monto) 
    INTO ln_monto 
    FROM hist_prov_cts_det h 
   WHERE h.fecha_proceso = ad_fecha_proceso and 
         h.cod_trabajador = as_cod_trabajador and 
         h.concepto  = as_concepto ;
END IF ;

ln_monto := NVL(ln_monto,0) ;
      
RETURN(ln_monto);
  
end USF_RH_CALC_CTS_CONCEPTO;
/
