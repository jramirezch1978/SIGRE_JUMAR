create or replace function usf_meses_gratif
  (  ad_fec_proceso control.fec_proceso%type, 
     ad_fec_ingreso maestro.fec_ingreso%type 
       ) 
  return number is
  --Declaro Variables Locales
  ld_fec_proceso control.fec_proceso%type;
  ld_fec_ingreso maestro.fec_ingreso%type;
  ln_nro_meses number(6,2);
  ln_dia number(2);
  
begin
 --Asignacion de Valores
 ld_fec_proceso := ad_fec_proceso;
 ld_fec_ingreso := ad_fec_ingreso;
  
 --Verificamos si el dia es diferente de uno
 ln_dia := to_char(ad_fec_ingreso,'DD');
 
 IF ln_dia <> 1 THEN
    ld_fec_ingreso := LAST_DAY(ad_fec_ingreso);
    ld_fec_proceso := LAST_DAY(ad_fec_proceso); 
    ln_nro_meses := MONTHS_BETWEEN(ld_fec_proceso, ld_fec_ingreso);
 END IF;
 
 IF ln_dia = 1 THEN
    --Restamos un mes 
    ld_fec_ingreso := ld_fec_ingreso - 1;   
    ld_fec_proceso := LAST_DAY(ad_fec_proceso);  
    ln_nro_meses := MONTHS_BETWEEN(ld_fec_proceso, ld_fec_ingreso);    
 END IF; 
  
 return( ln_nro_meses );
end usf_meses_gratif;
/
