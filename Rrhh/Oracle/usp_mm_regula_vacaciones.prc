CREATE OR REPLACE procedure usp_mm_regula_vacaciones(as_user in usuario.cod_usr%type) is

-- Cursor de trabajadores
CURSOR c_personal is
 SELECT a.cod_trabajador, a.fec_ingreso, a.fec_cese, a.flag_estado, a.flag_cal_plnlla 
   FROM (SELECT distinct(m.cod_trabajador) as cod_trabajador, 
              m.fec_ingreso, m.fec_cese, m.flag_estado, m.flag_cal_plnlla
         FROM maestro m, historico_calculo hc
        WHERE m.cod_trabajador=hc.cod_trabajador 
       UNION
       SELECT distinct(ma.cod_trabajador) as cod_trabajador, 
              ma.fec_ingreso, ma.fec_cese, ma.flag_estado, ma.flag_cal_plnlla 
         FROM maestro ma, calculo c
        WHERE ma.cod_trabajador=c.cod_trabajador) a ;
   
-- Cursor de historico de vacaciones
  CURSOR c_historico(as_cod_trabajador in maestro.cod_trabajador%type) is
  SELECT v.cod_trabajador, v.periodo_inicio, v.cod_usr, v.periodo_fin, 
         v.dias_totales, v.dias_gozados, v.dias_program, v.flag_estado 
    FROM rrhh_vacaciones_trabaj v 
   WHERE v.cod_trabajador = as_cod_trabajador 
ORDER BY v.cod_trabajador, v.periodo_inicio ;

ln_item                    number ;
ld_fec_inicio              date ;
ld_fec_fin                 date ;
ld_fec_proceso             date ;
ls_ano                     char(4) ;
ls_mes                     char(2) ;
ln_count                   number ;
ls_flag_proceso            char(1) ;
ls_periodo                 char(6) ;
ln_dias                    number ;

BEGIN 

-- Valido para personal que por lo menos una vez cobro un sueldo o jornal
FOR c_per IN c_personal LOOP
    ln_item := 1 ;
    ls_mes := TRIM(to_char(c_per.fec_ingreso,'mm')) ;

    IF c_per.flag_estado='1' AND c_per.flag_cal_plnlla='1' THEN
       -- Trabajador activo, busco si ha gozado algún día de vacaciones 
       SELECT count(*) 
         INTO ln_count 
         FROM rrhh_vacaciones_trabaj r
        WHERE r.cod_trabajador = c_per.cod_trabajador 
          AND r.dias_gozados > 0 
          AND r.flag_estado = '2' ;
       
       IF ln_count = 0 THEN
          ls_flag_proceso := 0 ;
          -- Para probar que hace el exit
          EXIT ; 
       END IF ;
       
       ls_periodo := TRIM(to_char(c_per.fec_ingreso,'dd/mm/')) ;
       
       FOR c_hist IN c_historico(c_per.cod_trabajador) LOOP
           -- Validan un exit en subproceso
           IF ls_flag_proceso = '0' THEN
              EXIT ;
           END IF ; 
           
           ls_ano := TRIM(to_char(c_hist.periodo_fin)) ;
           ld_fec_inicio := to_date(ls_periodo||ls_ano,'dd/mm/yyyy') ;
           ld_fec_fin    := ld_fec_inicio + 30 ;
           ld_fec_proceso:=ld_fec_fin ;
           
           -- Actualiza dias gozados y estado 
           IF c_hist.dias_gozados = 0 AND c_hist.flag_estado='2' THEN
               IF ld_fec_inicio <= c_per.fec_cese THEN
                  UPDATE rrhh_vacaciones_trabaj v
                     SET v.dias_totales = 30, 
                         v.dias_gozados = 30, 
                         v.dias_program = 30, 
                         v.flag_estado = '2'
                  WHERE v.cod_trabajador = c_hist.cod_trabajador 
                    AND v.periodo_inicio = c_hist.periodo_inicio ;
               END IF ;
           END IF ;
           
           -- Actualizando detalle
           UPDATE rrhh_vacac_trabaj_det vd 
              SET vd.cod_trabajador = c_hist.cod_trabajador, 
                  vd.periodo_inicio = c_hist.periodo_inicio,
                  vd.item = ln_item, 
                  vd.cod_usr = as_user, 
                  vd.fecha_inicio = ld_fec_inicio, 
                  vd.fecha_fin = ld_fec_fin,
                  vd.fecha_proceso = ld_fec_proceso, 
                  vd.nro_dias = 30, 
                  vd.flag_manual='P',
                  vd.flag_estado = '2' 
            WHERE vd.cod_trabajador = c_hist.cod_trabajador 
              AND vd.periodo_inicio = c_hist.periodo_inicio ;
                   
           -- Si no encuentra detalle, actualiza registro
           IF sql%notfound THEN
              INSERT INTO rrhh_vacac_trabaj_det vd(cod_trabajador, periodo_inicio, item, cod_usr,
                     fecha_inicio, fecha_fin, fecha_proceso, nro_dias, flag_manual, flag_estado)
              VALUES(c_per.cod_trabajador, c_hist.periodo_inicio, ln_item, as_user, 
                     ld_fec_inicio, ld_fec_fin, ld_fec_proceso, 30, 'P', '2') ;
           END IF ;
       END LOOP ;
    ELSE
       -- Trabajador inactivo
       IF c_per.fec_cese is null THEN
          EXIT ;
       END IF ;
       
       FOR c_hist IN c_historico(c_per.cod_trabajador) LOOP
           ls_ano := TRIM(to_char(c_hist.periodo_fin)) ;
           ld_fec_inicio := to_date(ls_periodo||ls_ano,'dd/mm/yyyy') ;
           ln_dias := TRUNC(c_per.fec_cese) - TRUNC(ld_fec_inicio) + 1;  --Ojo, que el número de dias real es mas 1
         
           IF c_per.fec_cese >=ld_fec_inicio THEN
              IF ln_dias > 30 THEN
                 ln_dias := 30 ;
              END IF ;
              ld_fec_fin    := ld_fec_inicio + (ln_dias -1) ;
              ld_fec_proceso:=ld_fec_fin ;
              
              UPDATE rrhh_vacaciones_trabaj v
                 SET v.dias_totales = ln_dias, 
                     v.dias_gozados = ln_dias, 
                     v.dias_program = ln_dias, 
                     v.flag_estado = '2'
              WHERE v.cod_trabajador = c_hist.cod_trabajador 
                AND v.periodo_inicio = c_hist.periodo_inicio ;
                
              -- Actualizando detalle
              UPDATE rrhh_vacac_trabaj_det vd 
                 SET vd.cod_trabajador = c_hist.cod_trabajador, 
                     vd.periodo_inicio = c_hist.periodo_inicio,
                     vd.item = ln_item, 
                     vd.cod_usr = as_user, 
                     vd.fecha_inicio = ld_fec_inicio, 
                     vd.fecha_fin = ld_fec_fin,
                     vd.fecha_proceso = ld_fec_proceso, 
                     vd.nro_dias = ln_dias, 
                     vd.flag_manual='P',
                     vd.flag_estado = '2' 
               WHERE vd.cod_trabajador = c_hist.cod_trabajador 
                 AND vd.periodo_inicio = c_hist.periodo_inicio ;
                   
              -- Si no encuentra detalle, actualiza registro
              IF sql%notfound THEN
                 INSERT INTO rrhh_vacac_trabaj_det vd(cod_trabajador, periodo_inicio, item, cod_usr,
                        fecha_inicio, fecha_fin, fecha_proceso, nro_dias, flag_manual, flag_estado)
                 VALUES(c_per.cod_trabajador, c_hist.periodo_inicio, ln_item, as_user, 
                        ld_fec_inicio, ld_fec_fin, ld_fec_proceso, 30, 'P', '2') ;
              END IF ;
           
           ELSE
          
               DELETE FROM rrhh_vacaciones_trabaj v
                   WHERE v.cod_trabajador = c_per.cod_trabajador 
                     AND v.periodo_inicio = c_hist.periodo_inicio  ;
           END IF ;
       END LOOP ;
    
    END IF ;    
    
END LOOP ;

END usp_mm_regula_vacaciones;
/
