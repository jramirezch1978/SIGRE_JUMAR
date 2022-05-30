CREATE OR REPLACE PROCEDURE usp_rh_cts_calculo_mensual (
  as_codtra in maestro.cod_trabajador%type, 
  ad_fec_proceso in date , 
  ad_fec_gratificacion in date, 
  ad_fec_inicio in date) is

-- as_codtra = Codigo de trabajador
-- ad_fec_proceso = Fecha de proceso (periodo a procesar)
-- ad_fec_gratificacion = Fecha de gratificacion
-- ad_fec_inicio = Fecha de inicio del periodo de CTS (01/05/yyyy - 01/11/yyyy)

ln_ano                   cntbl_asiento.ano%type ;
ln_mes                   cntbl_asiento.mes%type ;
ln_importe               historico_calculo.imp_soles%type ;
ln_imp_hora_extra        historico_calculo.imp_soles%type ;
ln_imp_gratificacion     historico_calculo.imp_soles%type ;
ls_flag_provis           cntbl_asiento.flag_estado%type ;
lk_ganancias_fijas       grupo_calculo.grupo_calculo%type ;
lk_gratificacion         grupo_calculo.grupo_calculo%type ;
lk_insist_cts            grupo_calculo.grupo_calculo%type ;
lk_reinte_cts            grupo_calculo.grupo_calculo%type ;
lc_grupo_variable        grupo_calculo.grupo_calculo%type ;
lk_horas_extras          grupo_calculo.grupo_calculo%type ; 
ld_fec_ingreso           date ;
ln_contador              number ;
ls_bonificacion          maestro.bonif_fija_30_25%type ;
ls_tipo_trabajador       tipo_trabajador.tipo_trabajador%type ;
ls_cencos                centros_costo.cencos%type ;
ls_cod_origen            origen.cod_origen%type ;
ln_dias_tot_inasist      number ;
ln_dias_inasis           number;
ln_dias_trabaj           number ;
ls_periodo_ini           char(6) ;
ls_periodo_fin           char(6) ;

BEGIN 

-- Validando las fechas de los parametros
IF ad_fec_proceso < ad_fec_inicio THEN
   RAISE_APPLICATION_ERROR(-20000, 'Fecha de proceso no puede ser menor a fecha de inicio de periodo de CTS del trabajador '|| as_codtra) ;
   Return ;
END IF ;

/*
Este caso si puede suceder, debe considerarse periodo de gratificación anterior
IF ad_fec_proceso < ad_fec_gratificacion THEN 
   RAISE_APPLICATION_ERROR(-20000, 'Fecha de proceso no puede ser menor a fecha de gratificación') ;
   Return ;
END IF ;*/

-- Eliminando datos anteriores en caso exista
ln_ano := TO_NUMBER(TO_CHAR(ad_fec_proceso, 'yyyy')) ;
ln_mes := TO_NUMBER(TO_CHAR(ad_fec_proceso, 'mm')) ;

ls_flag_provis := 'C' ;

-- Debe validarse antes cierre contable mensual????
DELETE FROM rh_prov_vacac_gratif_cts r
 WHERE r.ano = ln_ano 
   AND r.mes = ln_mes 
   AND r.cod_trabajador = as_codtra 
   AND r.flag_provis = ls_flag_provis ;

-- Capturando datos para el proceso
SELECT c.ganfij_provision_cts, c.concep_gratif, c.grp_dias_inasistencia_cts, 
       c.grp_dias_reintegro_cts, c.gan_var_ppto, c.grp_hora_extra_cts 
  INTO lk_ganancias_fijas, lk_gratificacion, lk_insist_cts, 
       lk_reinte_cts, lc_grupo_variable, lk_horas_extras 
  FROM rrhhparam_cconcep c 
 WHERE c.reckey = '1' ;

-- Capturando datos generales del trabajador 
SELECT m.fec_ingreso, nvl(m.bonif_fija_30_25,0), m.tipo_trabajador, m.cencos, m.cod_origen
  INTO ld_fec_ingreso, ls_bonificacion, ls_tipo_trabajador, ls_cencos, ls_cod_origen 
  FROM maestro m 
 WHERE m.cod_trabajador = as_codtra ;

-- Validando fecha de ingreso para el calculo 
IF ld_fec_ingreso IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'Fecha de ingreso errada de trabajador '|| as_codtra) ;
   Return ;
END IF ;
-- No procesa si fecha de ingreso es menor a fecha de proceso
IF trunc(ld_fec_ingreso) > trunc(ad_fec_proceso) THEN 
  return ;
END IF ;

-- Inicializando fecha de ingreso según fecha inicio de periodo de CTS, en caso sea inferior
IF ld_fec_ingreso < ad_fec_inicio THEN
   ld_fec_ingreso := ad_fec_inicio ;
END IF ;

-- Verificando que tenga datos de algún pago dentro del período de CTS
ln_contador := 0 ;

SELECT count(*) 
  INTO ln_contador 
  FROM calculo c
 WHERE c.cod_trabajador = as_codtra 
   AND c.fec_proceso BETWEEN ad_fec_inicio AND ad_fec_proceso;
 
IF ln_contador = 0 THEN
  SELECT count(*) 
    INTO ln_contador 
    FROM historico_calculo hc
   WHERE hc.cod_trabajador = as_codtra 
     AND hc.fec_calc_plan BETWEEN ad_fec_inicio AND ad_fec_proceso; 
END IF ;

-- Si no tiene datos, no calcula nada
IF ln_contador = 0 THEN
  return ;
END IF ;

-- Calculando los ingresos fijos del trabajador 
SELECT SUM(NVL(gdf.imp_gan_desc,0))
  INTO ln_importe 
  FROM gan_desct_fijo gdf
 WHERE gdf.cod_trabajador = as_codtra 
   AND gdf.flag_estado = '1' 
   AND gdf.concep in ( SELECT d.concepto_calc 
                         FROM grupo_calculo_det d
                        WHERE d.grupo_calculo = lk_ganancias_fijas ) ;

ln_importe := NVL(ln_importe,0) ;

-- Validando sobretiempos según fecha de periodo de inicio
ln_imp_hora_extra := 0 ;  

IF (ad_fec_proceso - ld_fec_ingreso) >= 90 THEN 
   ls_periodo_ini := to_char(ad_fec_inicio, 'yyyymm') ;
   ls_periodo_fin := to_char(ad_fec_proceso, 'yyyymm') ; 
   
   -- Verifica en cuantos meses por lo menos uno de sus conceptos del grupo de sobretiempos fue pagado
   SELECT count(distinct(TO_CHAR(fec_calc_plan,'yyyymm')))  
     INTO ln_contador 
     FROM historico_calculo hc 
    WHERE (hc.cod_trabajador = as_codtra) 
      AND (TO_CHAR(hc.fec_calc_plan,'yyyymm') BETWEEN ls_periodo_ini AND ls_periodo_fin) 
      AND hc.concep in (SELECT gcd.concepto_calc 
                          FROM grupo_calculo_det gcd 
                         WHERE gcd.grupo_calculo = lk_horas_extras ) ;
   
   -- Solo considera este caso si por lo menos a recibido por lo menos 03 meses o mas, pero el importe a considerar es 1/6
   IF ln_contador >= 3 THEN
       SELECT SUM(NVL(hc.imp_soles,0)) 
         INTO ln_imp_hora_extra 
         FROM historico_calculo hc 
        WHERE (hc.cod_trabajador = as_codtra) 
          AND (TO_CHAR(hc.fec_calc_plan,'yyyymm') BETWEEN ls_periodo_ini AND ls_periodo_fin)         
          AND hc.concep in (SELECT gcd.concepto_calc 
                              FROM grupo_calculo_det gcd 
                             WHERE gcd.grupo_calculo = lk_horas_extras ) ;
   ELSE
       ln_imp_hora_extra:= 0 ;
   END IF ;
   -- Solo se considera 1/6 de sumatoria promedio de horas extras
   ln_imp_hora_extra := ln_imp_hora_extra / 6 ;
END IF ;

-- Acumula importe a provisionar 
ln_importe := ln_importe + ln_imp_hora_extra ;

-- Incrementa el 25 0 30% según condición
IF ls_bonificacion = '1' THEN
   ln_importe := ln_importe * 1.30 ;
ELSIF ls_bonificacion = '2' THEN
   ln_importe := ln_importe * 1.25 ; 
END IF ;

-- Calculando la gratificacion (1/12)
ln_imp_gratificacion := 0 ;

SELECT count(*) 
  INTO ln_contador 
  FROM historico_calculo hc 
 WHERE hc.cod_trabajador = as_codtra 
   AND TO_CHAR(hc.fec_calc_plan,'yyyymm') = TO_CHAR(ad_fec_gratificacion,'yyyymm') 
   AND hc.concep in (SELECT gcd.concepto_calc 
                       FROM grupo_calculo_det gcd 
                      WHERE gcd.grupo_calculo = lk_gratificacion ) ;

IF ln_contador > 0 THEN 
    SELECT SUM(NVL(hc.imp_soles,0)) 
      INTO ln_imp_gratificacion 
      FROM historico_calculo hc 
     WHERE hc.cod_trabajador = as_codtra 
       AND TO_CHAR(hc.fec_calc_plan,'yyyymm') = TO_CHAR(ad_fec_gratificacion,'yyyymm') 
       AND hc.concep in (SELECT gcd.concepto_calc 
                           FROM grupo_calculo_det gcd 
                          WHERE gcd.grupo_calculo = lk_horas_extras ) ;
    
    ln_imp_gratificacion := ln_imp_gratificacion/6 ;
ELSE  
    ln_imp_gratificacion := 0 ;
END IF ;                     
 
ln_imp_gratificacion := ROUND(ln_imp_gratificacion / 12) ;

-- Acumula 1/12 del importe de gratificacion a provisionar 
ln_importe := ln_importe + ln_imp_gratificacion ;

-- Calculando las faltas del periodo seleccionado (solo de un mes)
ln_dias_tot_inasist := 0 ;

SELECT count(*) 
  INTO ln_contador 
  FROM inasistencia i
 WHERE i.cod_trabajador = as_codtra 
   AND to_char(i.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') 
   and i.concep in ( SELECT g.concepto_calc 
                       FROM grupo_calculo_det g
                      WHERE g.grupo_calculo = lk_insist_cts ) ;

IF ln_contador > 0 THEN 
  SELECT sum(nvl(i.dias_inasist,0)) 
    INTO ln_dias_inasis 
    FROM inasistencia i
   WHERE i.cod_trabajador = as_codtra and
         to_char(i.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
         i.concep in ( SELECT g.concepto_calc 
                         FROM grupo_calculo_det g
                        WHERE g.grupo_calculo = lk_insist_cts ) ;
ELSE
   ln_dias_inasis := 0 ;
END IF ;
ln_dias_tot_inasist := ln_dias_tot_inasist + ln_dias_inasis ;

SELECT count(*) 
  INTO ln_contador 
  FROM historico_inasistencia hi
 WHERE hi.cod_trabajador = as_codtra 
   AND to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') 
   AND hi.concep in ( SELECT g.concepto_calc 
                        FROM grupo_calculo_det g
                       WHERE g.grupo_calculo = lk_insist_cts ) ;

IF ln_contador > 0 then
   SELECT sum(nvl(hi.dias_inasist,0)) 
     INTO ln_dias_inasis 
     FROM historico_inasistencia hi
    WHERE hi.cod_trabajador = as_codtra 
      AND to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') 
      AND hi.concep in ( SELECT g.concepto_calc 
                           FROM grupo_calculo_det g
                          WHERE g.grupo_calculo = lk_insist_cts ) ;
ELSE
   ln_dias_inasis := 0 ;
end if ;

ln_dias_tot_inasist := ln_dias_tot_inasist + ln_dias_inasis ;

ln_dias_trabaj := 30 - nvl(ln_dias_tot_inasist,0) ;

-- Importe a provisionar (1/12 de sueldo provisionable)
ln_importe := (ln_importe*ln_dias_trabaj/30) / 12 ;

-- Ingresando el registro a la tabla de provisiones
INSERT INTO rh_prov_vacac_gratif_cts(ano, mes, cod_trabajador, flag_provis, cencos, cod_origen, importe, tipo_trabajador, dias)
VALUES(ln_ano, ln_mes, as_codtra, ls_flag_provis, ls_cencos, ls_cod_origen, ln_importe, ls_tipo_trabajador,  ln_dias_tot_inasist ) ;

END usp_rh_cts_calculo_mensual ;
/
