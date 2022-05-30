create or replace trigger TIA_RRHH_VACAC_TRABAJ_DET
  after insert on rrhh_vacac_trabaj_det  
  for each row
DECLARE

-- local variables here
ls_concep          concepto.concep%type ;  
  
BEGIN

-- Actualiza los dias programados
UPDATE rrhh_vacaciones_trabaj v 
   SET v.dias_program = NVL(v.dias_program,0) + NVL(:new.nro_dias,0)
 WHERE v.cod_trabajador = :new.cod_trabajador 
   AND v.periodo_inicio = :new.periodo_inicio ;

-- Actualiza los dias gozados si informacion ha pasado al historico
IF :new.flag_estado = '2' THEN
   UPDATE rrhh_vacaciones_trabaj v 
      SET v.dias_gozados = NVL(v.dias_gozados,0) + NVL(:new.nro_dias,0)
    WHERE v.cod_trabajador = :new.cod_trabajador 
      AND v.periodo_inicio = :new.periodo_inicio ;
END IF ;

-- Adicionando dato a tabla inasistencia_trabajador
IF :new.fecha_proceso IS NOT NULL THEN

   SELECT r.concep 
     INTO ls_concep 
     FROM rrhh_vacaciones_trabaj r 
    WHERE r.cod_trabajador = :new.cod_trabajador 
      AND r.periodo_inicio = :new.periodo_inicio ;
   
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
   
END IF;

END TIA_RRHH_VACAC_TRABAJ_DET;
/
