CREATE OR REPLACE FUNCTION USF_RH_BUSCA_CONC_CTACTE(
       as_codtra in        maestro.cod_trabajador%type, 
       as_grupo  in        grupo_calculo.grupo_calculo%type, 
       ad_fec_proceso in date) RETURN number is
       
  ln_count number;

-- as_grupo ==> 059 = Gratificaciones 
-- as_grupo ==> 515 = Vacaciones  
-- as_grupo ==> 531 = Utilidades 

BEGIN
  
SELECT count(*) 
  INTO ln_count 
  FROM calculo c, grupo_calculo gc, grupo_calculo_det gcd 
 WHERE gc.grupo_calculo     = gcd.grupo_calculo and 
       gcd.concepto_calc    = c.concep and 
       gcd.grupo_calculo    = as_grupo and 
       c.cod_trabajador     = as_codtra and 
       trunc(c.fec_proceso) = ad_fec_proceso ;
  
ln_count := NVL(ln_count, 0) ;
  
RETURN(ln_count);

END USF_RH_BUSCA_CONC_CTACTE;
/
