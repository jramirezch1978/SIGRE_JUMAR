CREATE OR REPLACE PROCEDURE usp_actualiza_vacaciones2(as_user in usuario.cod_usr%type) is

--  Lee maestro de trabajadores
CURSOR c_maestro is
SELECT distinct(r.cod_trabajador) 
  FROM rrhh_vacaciones_trabaj r 
ORDER BY r.cod_trabajador ;


CURSOR c_vacaciones(as_cod_trabajador in maestro.cod_trabajador%type) is 
  SELECT r.cod_trabajador, r.periodo_inicio, r.dias_totales, r.dias_gozados, r.dias_program, 
         r.flag_estado 
    FROM rrhh_vacaciones_trabaj r 
   WHERE r.cod_trabajador = as_cod_trabajador 
  ORDER BY r.cod_trabajador, r.periodo_inicio ;

ln_count   number ;
ld_fecha_ini      date ;
ld_fecha_fin      date ;
  
BEGIN 

UPDATE rrhh_vacaciones_trabaj r 
   SET r.flag_estado = '1' 
 WHERE r.dias_gozados > 0 
   AND r.dias_gozados < r.dias_totales ;

UPDATE rrhh_vacaciones_trabaj r 
   SET r.flag_estado = '2' 
 WHERE r.dias_gozados > 0 
   AND r.dias_gozados = r.dias_totales ; 
     
FOR rc_m in c_maestro LOOP
    
    SELECT count(*) 
      INTO ln_count 
      FROM rrhh_vacaciones_trabaj r 
     WHERE r.cod_trabajador = rc_m.cod_trabajador 
       AND r.dias_gozados > 0 ; 
     
    IF ln_count > 0 THEN

       FOR rc_v in c_vacaciones( rc_m.cod_trabajador ) LOOP
           
           IF rc_v.dias_gozados = 0 THEN 
               ld_fecha_ini := TO_DATE('01/01/'||TO_CHAR(rc_v.periodo_inicio),'dd/mm/yyyy') ;
               ld_fecha_fin := ld_fecha_ini + 30 - 1;
           ELSE
               ld_fecha_ini := TO_DATE('01/01/'||TO_CHAR(rc_v.periodo_inicio),'dd/mm/yyyy') ;
               ld_fecha_fin := ld_fecha_ini + rc_v.dias_gozados - 1;
           END IF ;
           
           INSERT INTO rrhh_vacac_trabaj_det(cod_trabajador, periodo_inicio, item, cod_usr,
                                             fecha_inicio, fecha_fin, fecha_proceso, nro_dias,
                                             flag_manual, flag_estado) 
           VALUES (rc_v.cod_trabajador, rc_v.periodo_inicio, 1, as_user, 
                   ld_fecha_ini, ld_fecha_fin, ld_fecha_fin, rc_v.dias_gozados, 
                   'P', '2') ;
           
           IF (rc_v.flag_estado = '1' OR rc_v.flag_estado = '2') THEN

                 UPDATE rrhh_vacaciones_trabaj r
                    SET r.dias_program = r.dias_gozados 
                  WHERE r.cod_trabajador = rc_v.cod_trabajador 
                    AND r.periodo_inicio = rc_v.periodo_inicio ;
           
              EXIT ;
           ELSE
           
              IF rc_v.dias_gozados = 0 THEN 
                 UPDATE rrhh_vacaciones_trabaj r
                    SET r.flag_estado = '2', 
                        r.dias_gozados = r.dias_totales, 
                        r.dias_program = r.dias_totales 
                  WHERE r.cod_trabajador = rc_v.cod_trabajador 
                    AND r.periodo_inicio = rc_v.periodo_inicio ;
              END IF ;
              
           END IF ; 
           
       END LOOP ;
       
    END IF ;
     
END LOOP ;

commit ;

END usp_actualiza_vacaciones2 ;
/
