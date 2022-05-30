create or replace trigger TUB_RRHH_VACAC_TRABAJ_DET
  before update on rrhh_vacac_trabaj_det  
  for each row
DECLARE
  -- local variables here
  ln_nro_dias        number ;
  
BEGIN
  
IF :old.flag_estado='2' THEN
    RAISE_APPLICATION_ERROR(-20000, 'Registro no puede modificarse. Consulte con Sistemas') ;
    RETURN ;
END IF ; 

-- Valida que cambio de fechas Actualiza datos si cambia fechas
IF (:old.fecha_inicio <> :new.fecha_inicio OR :old.fecha_fin <> :new.fecha_fin) THEN 
    ln_nro_dias := TRUNC(:new.fecha_inicio) - TRUNC(:new.fecha_fin) + 1;
    
    IF NVL(ln_nro_dias,0) <=0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Número de días de vacaciones no puede ser menor o igual a 0') ;
        RETURN ;
    END IF ;
    
    :new.nro_dias := ln_nro_dias ;
END IF ;    

END TUB_RRHH_VACAC_TRABAJ_DET;
/
