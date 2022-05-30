create or replace trigger TUA_RRHH_VACAC_TRABAJ_DET
  after update on rrhh_vacac_trabaj_det  
  for each row
declare
  -- local variables here
  ls_concep          concepto.concep%type ;
  ln_old_nro_dias    rrhh_vacaciones_trabaj.dias_totales%type ;
  ln_new_nro_dias    rrhh_vacaciones_trabaj.dias_totales%type ;
  
BEGIN


-- Valida que cambio de fechas actualice datos en maestro general de vacaciones.

IF (:old.fecha_inicio <> :new.fecha_inicio OR :old.fecha_fin <> :new.fecha_fin) THEN 
    ln_new_nro_dias := TRUNC(:new.fecha_inicio) - TRUNC(:new.fecha_fin) + 1;
    ln_old_nro_dias := TRUNC(:new.fecha_inicio) - TRUNC(:new.fecha_fin) + 1;
    
    -- Actualiza los dias programados (la base de datos valida que los datos programados no excedan a los dias_totales).
    UPDATE rrhh_vacaciones_trabaj v 
       SET v.dias_program = NVL(v.dias_program,0) - ln_old_nro_dias + ln_new_nro_dias 
     WHERE v.cod_trabajador = :new.cod_trabajador 
       AND v.periodo_inicio = :new.periodo_inicio ;
        
END IF ;

IF :old.flag_estado<>'2' AND :new.flag_estado='2' THEN 
   -- Solo debe sumar los dias gozados
    UPDATE rrhh_vacaciones_trabaj v 
      SET v.dias_gozados = NVL(v.dias_gozados,0) + NVL(:new.nro_dias,0)
    WHERE v.cod_trabajador = :new.cod_trabajador 
      AND v.periodo_inicio = :new.periodo_inicio ;
END IF ;

-- No debe pasar de estado 2 a otro estado. Debe ser controlado este caso.
/*IF :old.flag_estado='2' AND :new.flag_estado<>'2' THEN 
    UPDATE rrhh_vacaciones_trabaj v 
      SET v.dias_gozados = NVL(v.dias_gozados,0) - NVL(:new.nro_dias,0)
    WHERE v.cod_trabajador = :new.cod_trabajador 
      AND v.periodo_inicio = :new.periodo_inicio ;
END IF ;*/

IF (:old.fecha_proceso <> :new.fecha_proceso) AND (:new.fecha_proceso is not null) THEN
    -- Debe adicionar registros a la asisitencia
    SELECT r.concep  
      INTO ls_concep 
      FROM rrhh_vacaciones_trabaj r 
     WHERE r.cod_trabajador=:new.cod_trabajador 
       AND r.periodo_inicio=:new.periodo_inicio ;
    
    UPDATE inasistencia i 
       SET i.fec_hasta = :new.fecha_fin, 
           i.dias_inasist = NVL(i.dias_inasist,0) + :new.nro_dias, 
           i.cod_usr = :new.cod_usr
     WHERE i.cod_trabajador = :new.cod_trabajador 
       AND i.concep = ls_concep 
       AND i.fec_movim = :new.fecha_proceso ;
       
    IF SQL%NOTFOUND THEN 
       INSERT INTO inasistencia(cod_trabajador, concep, fec_movim, fec_desde, 
                                fec_hasta, dias_inasist, cod_usr, flag_replicacion, 
                                periodo_inicio) 
       VALUES ( :new.cod_trabajador, ls_concep, :new.fecha_proceso, :new.fecha_inicio, 
                :new.fecha_fin, :new.nro_dias, :new.cod_usr, '1', 
                :new.periodo_inicio ) ; 
    END IF ;
END IF ;

-- Anteriormente había generado movimiento en tabla de inasistencia
IF (:old.fecha_proceso <> :new.fecha_proceso) AND (:new.fecha_proceso is not null) THEN
   SELECT i.dias_inasist 
     INTO ln_new_nro_dias 
     FROM inasistencia i 
    WHERE i.cod_trabajador = :new.cod_trabajador 
      AND i.concep = ls_concep 
      AND i.fec_movim = :new.fecha_proceso ; 
   
   IF :new.nro_dias = ln_new_nro_dias THEN 
      DELETE FROM inasistencia i 
       WHERE i.cod_trabajador = :new.cod_trabajador and 
             i.concep = ls_concep and 
             i.fec_movim = :new.fecha_proceso ;
   ELSE
      UPDATE inasistencia i 
         SET i.dias_inasist = NVL(i.dias_inasist,0) - ln_new_nro_dias 
       WHERE i.cod_trabajador = :new.cod_trabajador 
         AND i.concep = ls_concep 
         AND i.fec_movim = :new.fecha_proceso ;
   END IF ;
 
END IF ;

END TUA_RRHH_VACAC_TRABAJ_DET;
/
