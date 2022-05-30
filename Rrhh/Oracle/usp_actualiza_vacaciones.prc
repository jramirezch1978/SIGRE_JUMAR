CREATE OR REPLACE PROCEDURE usp_actualiza_vacaciones(as_user in usuario.cod_usr%type) is

--  Lee maestro de trabajadores
CURSOR c_maestro is
  SELECT m.cod_trabajador, m.cod_origen, m.fec_ingreso, m.fec_cese, m.tipo_trabajador, m.flag_estado, m.flag_cal_plnlla
    FROM maestro m
   WHERE m.cod_origen<>'TR' and m.fec_ingreso is not null 
ORDER BY m.cod_origen, m.cod_trabajador ;

ln_periodo_ini         number ;
ln_periodo_fin         number ;
ln_periodo             number ;
lc_concepto            concepto.concep%type ;

-- Concepto de vacaciones = '1463'
BEGIN 

lc_concepto := '1463' ;

DELETE FROM rrhh_vacac_trabaj_det ; 
DELETE FROM rrhh_vacaciones_trabaj ;

      
FOR rc_mae in c_maestro LOOP
    
    ln_periodo_ini := to_number(to_char(rc_mae.fec_ingreso,'yyyy')) ;
    
    IF rc_mae.fec_cese IS NULL THEN 
       ln_periodo_fin := to_number(to_char(sysdate,'yyyy')) ;
    ELSE
       ln_periodo_fin := to_number(to_char(rc_mae.fec_cese,'yyyy')) ;
    END IF ;
    
    FOR li_periodo in ln_periodo_ini .. ln_periodo_fin LOOP
        
        INSERT INTO rrhh_vacaciones_trabaj(cod_trabajador, periodo_inicio, periodo_fin, concep, dias_totales, dias_gozados, cod_usr, flag_estado, flag_replicacion)
        VALUES (rc_mae.cod_trabajador, ln_periodo_ini, ln_periodo_ini+1, lc_concepto, 30, 0, as_user, '3','1') ;
        
        ln_periodo_ini := ln_periodo_ini + 1 ;
        
    END LOOP ;
    
  
END LOOP ;

commit ;

END usp_actualiza_vacaciones ;
/
