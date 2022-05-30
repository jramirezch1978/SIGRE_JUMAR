CREATE OR REPLACE PROCEDURE usp_rh_calcula_provision_cts (
  as_codtra         in maestro.cod_trabajador%type, 
  ad_fec_proceso    in date,
  ad_fec_ini_cts    in date,
  ad_fec_fin_cts    in date,
  ad_fec_gratif     in date) is

lk_ganancias_fijas     grupo_calculo.grupo_calculo%type ;
lk_gratificacion       grupo_calculo.grupo_calculo%type ;
lk_horas_extras        grupo_calculo.grupo_calculo%type ;
lk_destajos            grupo_calculo.grupo_calculo%type ;
lk_bonific_variab      grupo_calculo.grupo_calculo%type ;
lk_inasist_cts         grupo_calculo.grupo_calculo%type ;

ld_fec_ingreso         date ;
ls_bonificacion        char(1) ;
ls_cod_origen          origen.cod_origen%type ;
ls_tipo_trabaj         tipo_trabajador.tipo_trabajador%type ;
ls_flag_provis         char(1) ;

ln_imp_soles           calculo.imp_soles%type ;
ln_imp_parcial         calculo.imp_soles%type ;
ln_imp_ingreso_fijo    calculo.imp_soles%type ;
ln_imp_horas_extras    calculo.imp_soles%type ;
ln_imp_destajo         calculo.imp_soles%type ;
ln_gratificacion       calculo.imp_soles%type ;
ln_imp_bonificacion    calculo.imp_soles%type ;
ln_dias_inasist        number ;
ln_dias_inasist_tot    number ;
ln_dias                number ;
ln_count               number ;
ls_periodo_ini         char(6);
ls_periodo_fin         char(6);
ls_cencos              centros_costo.cencos%type ;

--  Conceptos para hallar promedio de los ultimos seis meses
cursor c_concep ( as_nivel in string ) is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = as_nivel ;

BEGIN 

--  ***************************************************************************
--  ***   CAPTURA INFORMACION Y VALIDACIONES PREVIAS AL PROCESO DE CALCULO  ***
--  ***************************************************************************

-- Grupos de calculos
SELECT c.gan_fij_calc_cts, c.grp_hora_extra_cts, c.grp_destajo_cts, 
       c.grp_bonific_cts, c.grp_dias_inasistencia_cts 
  INTO lk_ganancias_fijas, lk_horas_extras, lk_destajos, 
       lk_bonific_variab, lk_inasist_cts
  FROM rrhhparam_cconcep c where c.reckey = '1' ;
  
-- Ojo que el parametro de las gratificaciones mensuales no es el mismo que el semestral, por un tema de ajuste
SELECT r.grp_ctacte_gratif 
  INTO lk_gratificacion 
  FROM rrhhparam_ctacte r 
 WHERE r.reckey='1' ;

-- Datos del trabajador
SELECT m.fec_ingreso, nvl(m.bonif_fija_30_25,0), m.cod_origen, m.tipo_trabajador, m.cencos
  INTO ld_fec_ingreso, ls_bonificacion, ls_cod_origen, ls_tipo_trabaj, ls_cencos 
  FROM maestro m 
 WHERE m.cod_trabajador = as_codtra ;   

-- Indicador de provisión (harcode, corregir)  
ls_flag_provis := 'C' ; --CTS

-- Verifica fecha de ingreso
IF trunc(ld_fec_ingreso) is null THEN
   RAISE_APPLICATION_ERROR(-20000, 'Fecha de ingreso errada de ' ||as_codtra) ;
   RETURN ;
END IF ;

IF TRUNC(ld_fec_ingreso) > TRUNC(ad_fec_proceso) THEN 
   RETURN ;
END IF ;

-- Verifica si tiene algun registro de un pago
SELECT count(*) 
  INTO ln_count 
  FROM calculo c
 WHERE c.cod_trabajador = as_codtra 
   AND TRUNC(c.fec_proceso) BETWEEN TRUNC(ad_fec_ini_cts) AND TRUNC(ad_fec_fin_cts) ;
   
IF ln_count = 0 THEN 
    SELECT count(*) 
      INTO ln_count 
      FROM historico_calculo hc
     WHERE hc.cod_trabajador = as_codtra 
       AND hc.fec_calc_plan BETWEEN TRUNC(ad_fec_ini_cts) AND TRUNC(ad_fec_fin_cts) ;
       
    IF ln_count = 0 THEN
       RETURN ;
    END IF ;
END IF ;

--  *******************************************************************
--  ***   DEPURA INFORMACION DE TABLAS QUE INTERVIENEN EN PROCESO   ***
--  *******************************************************************
--Elimina información de rh_prov_vacac_gratif_cts, caso CTS
DELETE FROM rh_prov_vacac_gratif_cts r 
 WHERE r.ano = TO_NUMBER(TO_CHAR(ad_fec_proceso,'yyyy')) 
   AND r.mes = TO_NUMBER(TO_CHAR(ad_fec_proceso,'mm')) 
   AND r.cod_trabajador = as_codtra 
   AND r.flag_provis = ls_flag_provis ;
 
--  *******************************************************************
--  ***   CALCULO DE PROVISION DE CTS, considerando asistencia      ***
--  *******************************************************************
ln_imp_soles := 0 ;

-- Ganancias fijas
  SELECT SUM(NVL(gdf.imp_gan_desc,0))
    INTO ln_imp_ingreso_fijo 
    FROM gan_desct_fijo gdf
   WHERE gdf.cod_trabajador = as_codtra 
     AND gdf.flag_estado = '1' 
     AND gdf.concep IN ( SELECT d.concepto_calc 
                           FROM grupo_calculo_det d 
                          WHERE d.grupo_calculo = lk_ganancias_fijas ) ;
  
  ln_imp_soles := NVL(ln_imp_soles,0) + NVL(ln_imp_ingreso_fijo,0) ;

-- Promedio de horas extras
  ls_periodo_ini := to_char(ad_fec_ini_cts,'yyymm') ;
  ls_periodo_fin := to_char(ad_fec_fin_cts,'yyymm') ;
  
  ln_imp_horas_extras := 0 ;
  
  -- Calcula en cuantos meses por lo menos uno de sus conceptos del grupo fue pagado
  SELECT count(distinct(to_char(fec_calc_plan,'yyyymm')))
    INTO ln_count  
    FROM historico_calculo hc 
   WHERE hc.concep in (SELECT gd.concepto_calc FROM grupo_calculo_det gd WHERE gd.grupo_calculo=lk_horas_extras) and 
        (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
         hc.cod_trabajador=as_codtra ;
  
  -- Solo considera en caso tenga por lo menos en 03 meses o mas        
  IF ln_count >= 3 THEN
    SELECT sum(hc.imp_soles) 
      INTO ln_imp_horas_extras 
      FROM historico_calculo hc 
     WHERE hc.concep in (SELECT gd.concepto_calc FROM grupo_calculo_det gd WHERE gd.grupo_calculo=lk_horas_extras) and 
          (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
           hc.cod_trabajador=as_codtra ;
  ELSE
    ln_imp_horas_extras := 0 ;
  END IF ;
    
  -- Acumula monto a pagar de CTS
  ln_imp_horas_extras := NVL(ln_imp_horas_extras,0) / 6 ;
  
  ln_imp_soles := NVL(ln_imp_soles,0) + ln_imp_horas_extras ;
  
-- Promedio de destajo
  ln_imp_destajo := 0 ;
  -- Calcula en cuantos meses por lo menos uno de sus conceptos del grupo fue pagado
  SELECT count(distinct(to_char(fec_calc_plan,'yyyymm')))
    INTO ln_count 
    FROM historico_calculo hc 
   WHERE hc.concep in (SELECT gd.concepto_calc 
                         FROM grupo_calculo_det gd 
                        WHERE gd.grupo_calculo=lk_destajos) 
                          AND (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) 
                          AND hc.cod_trabajador = as_codtra ;
  
  -- Solo considera en caso tenga por lo menos en 03 meses o mas        
  IF ln_count >= 3 THEN
    SELECT sum(hc.imp_soles) 
      INTO ln_imp_destajo 
      FROM historico_calculo hc 
     WHERE hc.concep in (SELECT gd.concepto_calc 
                           FROM grupo_calculo_det gd 
                          WHERE gd.grupo_calculo=lk_destajos) 
                            AND (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) 
                            AND hc.cod_trabajador=as_codtra ;
  ELSE
    ln_imp_destajo := 0 ;
  END IF ;
  
  -- Acumula monto a pagar de CTS
  ln_imp_destajo := ln_imp_destajo / 6 ;
  ln_imp_soles := NVL(ln_imp_soles,0) + ln_imp_destajo ;

-- Promedio de gratificacion (grupo 806)
  SELECT sum(NVL(hc.imp_soles,0))
    INTO ln_gratificacion 
    FROM historico_calculo hc
   WHERE hc.cod_trabajador = as_codtra 
      and to_char(hc.fec_calc_plan,'mmyyyy') = to_char(ad_fec_gratif,'mmyyyy') 
      and hc.concep in ( select gd.concepto_calc  
                           from grupo_calculo g, grupo_calculo_det gd 
                          where g.grupo_calculo=gd.grupo_calculo and g.grupo_calculo = lk_gratificacion ) ;
  
  ln_gratificacion := (NVL(ln_gratificacion,0) / 2) / 6 ;
  ln_imp_soles := NVL(ln_imp_soles,0) + ln_gratificacion ;

-- Ganancias variables
  ln_imp_bonificacion := 0 ;
  -- Solo debe considerar si cada uno de los conceptos del grupo, esta por lo menos en 03 meses o mas.
  FOR rc_concep in c_concep ( lk_bonific_variab ) LOOP 
      SELECT count(distinct(to_char(fec_calc_plan,'yyyymm')))
        INTO ln_count 
        FROM historico_calculo hc 
       WHERE hc.concep = rc_concep.concepto_calc and 
            (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
             hc.cod_trabajador=as_codtra ;
      
      IF ln_count >= 3 THEN
        SELECT sum(hc.imp_soles) 
          INTO ln_imp_parcial 
          FROM historico_calculo hc 
         WHERE hc.concep = rc_concep.concepto_calc and 
              (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
               hc.cod_trabajador=as_codtra ;
      ELSE
          ln_imp_parcial := 0 ;
      END IF ;
      
      IF ln_imp_parcial > 0 THEN 
         ln_imp_bonificacion := NVL(ln_imp_bonificacion,0) + ln_imp_parcial / 6 ;
      END IF ;
  END LOOP ;  
  ln_imp_soles := NVL(ln_imp_soles,0) + ln_imp_bonificacion ;

--  *******************************************************************
--  ***   CALCULO DE INASISTENCIAS DEL PERIODO A PROCESAR    **********
--  *******************************************************************
ln_dias_inasist_tot := 0 ;

-- Inasistencias que no estan en el historico
SELECT count(*) 
  INTO ln_count
  FROM inasistencia i 
 WHERE i.cod_trabajador = as_codtra 
   AND TO_CHAR(i.fec_movim,'yyyymm') = TO_CHAR(ad_fec_proceso,'yyyymm') 
   AND i.concep IN (SELECT gcd.concepto_calc 
                      FROM grupo_calculo gc, grupo_calculo_det gcd 
                     WHERE gc.grupo_calculo=gcd.grupo_calculo 
                       AND gc.grupo_calculo=lk_inasist_cts) ;
IF ln_count > 0 THEN 
  SELECT sum(i.dias_inasist) 
    INTO ln_dias_inasist
    FROM inasistencia i 
   WHERE i.cod_trabajador = as_codtra 
     AND TO_CHAR(i.fec_movim,'yyyymm') = TO_CHAR(ad_fec_proceso,'yyyymm') 
     AND i.concep IN (SELECT gcd.concepto_calc 
                        FROM grupo_calculo gc, grupo_calculo_det gcd 
                       WHERE gc.grupo_calculo=gcd.grupo_calculo 
                         AND gc.grupo_calculo=lk_inasist_cts) ;
ELSE
    ln_dias_inasist := 0 ;
END IF ; 
ln_dias_inasist_tot := ln_dias_inasist_tot + ln_dias_inasist ;

-- Inasistencias que estan en el historico
SELECT count(*) 
  INTO ln_count
  FROM inasistencia i 
 WHERE i.cod_trabajador = as_codtra 
   AND TO_CHAR(i.fec_movim,'yyyymm') = TO_CHAR(ad_fec_proceso,'yyyymm') 
   AND i.concep IN (SELECT gcd.concepto_calc 
                      FROM grupo_calculo gc, grupo_calculo_det gcd 
                     WHERE gc.grupo_calculo=gcd.grupo_calculo 
                       AND gc.grupo_calculo=lk_inasist_cts) ;
IF ln_count > 0 THEN 
  SELECT sum(i.dias_inasist) 
    INTO ln_dias_inasist
    FROM inasistencia i 
   WHERE i.cod_trabajador = as_codtra 
     AND TO_CHAR(i.fec_movim,'yyyymm') = TO_CHAR(ad_fec_proceso,'yyyymm') 
     AND i.concep IN (SELECT gcd.concepto_calc 
                        FROM grupo_calculo gc, grupo_calculo_det gcd 
                       WHERE gc.grupo_calculo=gcd.grupo_calculo 
                         AND gc.grupo_calculo=lk_inasist_cts) ;
ELSE
    ln_dias_inasist := 0 ;
END IF ; 
ln_dias_inasist_tot := ln_dias_inasist_tot + ln_dias_inasist ;

-- dias trabajados en el mes
ln_dias := 30 - ln_dias_inasist_tot;

-- Se provisiona 1/12 del calculo (dato estimado)
ln_imp_soles := (ln_imp_soles / 12) * ln_dias / 30 ;

-- Actualizar información en tablas
-- Mes 11
IF to_char(ad_fec_proceso,'mm')='11' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes01 = ln_imp_soles      
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;
   
   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             ln_imp_soles, 0, 0, 0,
             0, 0 ) ;
   END IF ;
      
-- Mes 12
ELSIF to_char(ad_fec_proceso,'mm')='12' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes02 = ln_imp_soles     
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, ln_imp_soles, 0, 0,
             0, 0 ) ;
   END IF ;
-- Mes 01
ELSIF to_char(ad_fec_proceso,'mm')='01' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes03 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, ln_imp_soles, 0,
             0, 0 ) ;
   END IF ;

-- Mes 02
ELSIF to_char(ad_fec_proceso,'mm')='02' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes04 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, 0, ln_imp_soles,
             0, 0 ) ;
   END IF ;

-- Mes 03
ELSIF to_char(ad_fec_proceso,'mm')='03' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes05 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, 0, 0, 
             ln_imp_soles, 0 ) ;
   END IF ;

-- Mes 04
ELSIF to_char(ad_fec_proceso,'mm')='04' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes06 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, 0, 0, 
             0, ln_imp_soles ) ;
   END IF ;

-- Mes 05
ELSIF to_char(ad_fec_proceso,'mm')='05' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes01 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             ln_imp_soles, 0, 0, 0, 
             0, 0 ) ;
   END IF ;

-- Mes 06
ELSIF to_char(ad_fec_proceso,'mm')='06' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes02 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, ln_imp_soles, 0, 0, 
             0, 0 ) ;
   END IF ;

-- Mes 07
ELSIF to_char(ad_fec_proceso,'mm')='07' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes03 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, ln_imp_soles, 0, 
             0, 0 ) ;
   END IF ;

-- Mes 08
ELSIF to_char(ad_fec_proceso,'mm')='08' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes04 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, 0, ln_imp_soles,
             0, 0 ) ;
   END IF ;

-- Mes 09
ELSIF to_char(ad_fec_proceso,'mm')='09' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes05 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, 0, 0,
             ln_imp_soles, 0 ) ;
   END IF ;

-- Mes 10
ELSIF to_char(ad_fec_proceso,'mm')='10' THEN 
   UPDATE hist_prov_cts_gratif h 
      SET h.cts_mes06 = ln_imp_soles
    WHERE TRUNC(h.fecha_proceso) = ad_fec_fin_cts 
      AND h.cod_trabajador = as_codtra ;

   IF SQL%NOTFOUND THEN
      -- Inicializa el registro
      INSERT INTO hist_prov_cts_gratif(
             fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
             cts_mes01, cts_mes02, cts_mes03, cts_mes04,
             cts_mes05, cts_mes06)
      VALUES(ad_fec_proceso, as_codtra, ls_cod_origen, ls_tipo_trabaj, 
             0, 0, 0, 0,
             0, ln_imp_soles ) ;
   END IF ;
END IF ;
 
-- Adiciona registro
INSERT INTO rh_prov_vacac_gratif_cts(
      ano, mes, cod_trabajador, 
      flag_provis, cencos, cod_origen,
      importe, tipo_trabajador, dias) 
VALUES( TO_NUMBER(TO_CHAR(ad_fec_proceso,'yyyy')), TO_NUMBER(TO_CHAR(ad_fec_proceso,'mm')), as_codtra, 
       ls_flag_provis, ls_cencos, ls_cod_origen, 
       ln_imp_soles, ls_tipo_trabaj, ln_dias) ; 

END usp_rh_calcula_provision_cts ;
/
