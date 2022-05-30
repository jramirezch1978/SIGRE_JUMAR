create or replace trigger TIA_RH_UTL_DISTRIBUCION
  before insert on utl_distribucion  
  for each row
declare
  -- local variables here
  ln_nro_dias_per        number ;
  ln_nro_dias_ano        number ;
  ld_fecha_ini_ano       date ;
  ld_fecha_fin_ano       date ;
  ls_ano                 char(4) ;

BEGIN

  ls_ano := to_char(:new.fecha_ini,'yyyy') ;
  ld_fecha_ini_ano := to_date('01/01/'||ls_ano,'dd/mm/yyyy') ;
  ld_fecha_fin_ano := to_date('31/12/'||ls_ano,'dd/mm/yyyy') ;

  SELECT (ld_fecha_fin_ano - ld_fecha_ini_ano) + 1 
    INTO ln_nro_dias_ano 
    FROM dual ;
    
  ln_nro_dias_per := (:new.fecha_fin - :new.fecha_ini) + 1 ;
  
  :new.dias_periodo := ROUND(ln_nro_dias_per ,0) ;

end TIA_UTL_DISTRIBUCION;
/
