CREATE OR REPLACE PROCEDURE usp_rh_calcula_provision_gra (
  as_codtra       in maestro.cod_trabajador%type, 
  ad_fec_proceso  in date ) is

lk_ganancia_fija          grupo_calculo.grupo_calculo%type ;
lk_sobretiempos           grupo_calculo.grupo_calculo%type ;
ls_bonificacion           maestro.bonif_fija_30_25%type ;
ln_ano                    cntbl_asiento.ano%type ;
ln_mes                    cntbl_asiento.mes%type ;
ls_flag_provis            maestro.flag_estado%type ;
ls_origen                 origen.cod_origen%type ;
ls_cencos                 centros_costo.cencos%type ;
ls_tipo_trabajador        tipo_trabajador.tipo_trabajador%type ;
ln_importe                number ;
ln_imp_hora_extra         number ;
ln_acumul_ant             number ;
ld_fec_ingreso            maestro.fec_ingreso%type ;
ln_contador               number ;
ln_dias                   number ;
ln_nro_meses              number ;
ls_periodo_ini            char(6) ;
ls_periodo_fin            char(6) ;

BEGIN

-- Validando la fecha del proceso a generar
IF trunc(ad_fec_proceso) > trunc(sysdate) THEN
   RAISE_APPLICATION_ERROR(-20000, 'Fecha de proceso superior a fecha del sistema') ;
   Return ;
END IF ;

--  *************************************************************
--  ***   REALIZA CALCULO DE PROVISIONES DE GRATIFICACIONES   ***
--  *************************************************************

SELECT c.ganfij_provision_gratif, c.prom_remun_vacac
  INTO lk_ganancia_fija, lk_sobretiempos
  FROM rrhhparam_cconcep c
 WHERE c.reckey = '1' ;

-- Elimina información del período en caso ya exista (Debe verificar si mes contable esta cerrado)
ln_ano := TO_NUMBER(TO_CHAR( ad_fec_proceso, 'yyyy' ) ) ;
ln_mes := TO_NUMBER(TO_CHAR( ad_fec_proceso, 'mm' ) ) ;

ls_flag_provis := 'G' ; -- Gratificaciones 

DELETE FROM rh_prov_vacac_gratif_cts r 
      WHERE r.ano = ln_ano 
        AND r.mes = ln_mes 
        AND r.cod_trabajador = as_codtra 
        AND r.flag_provis = ls_flag_provis ; 

-- Capturando datos del trabajador 
SELECT m.cod_origen, m.cencos, m.fec_ingreso, NVL(m.bonif_fija_30_25,'0'), m.tipo_trabajador
  INTO ls_origen, ls_cencos, ld_fec_ingreso, ls_bonificacion, ls_tipo_trabajador 
  FROM maestro m 
 WHERE m.cod_trabajador = as_codtra ;

IF ld_fec_ingreso IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'Fecha de ingreso errada de trabajador '|| as_codtra) ;
   RETURN ;
END IF ;

IF TO_CHAR(ad_fec_proceso,'mm')<='06' THEN
    IF ld_fec_ingreso < to_date('01/01/'||to_char(ad_fec_proceso,'yyyy'),'dd/mm/yyyy') THEN 
       ld_fec_ingreso := to_date('01/01/'||to_char(ad_fec_proceso,'yyyy'),'dd/mm/yyyy') ;
    END IF; 
ELSE
    IF ld_fec_ingreso < to_date('01/07/'||to_char(ad_fec_proceso,'yyyy'),'dd/mm/yyyy') THEN 
       ld_fec_ingreso := to_date('01/07/'||to_char(ad_fec_proceso,'yyyy'),'dd/mm/yyyy') ;
    END IF; 
END IF ;

ln_dias := trunc(ad_fec_proceso) - trunc(ld_fec_ingreso) + 1 ;

IF ln_dias < 1 THEN
   return ;
END IF ;

ln_nro_meses := ROUND( (ad_fec_proceso - ld_fec_ingreso) / 30, 0 ) ;

-- Calculando ganancias fijas provisionable 
SELECT sum(nvl(gdf.imp_gan_desc,0)) 
  INTO ln_importe
  FROM gan_desct_fijo gdf
 WHERE gdf.cod_trabajador = as_codtra 
   AND gdf.flag_estado = '1' 
   AND gdf.concep in ( SELECT d.concepto_calc 
                         FROM grupo_calculo_det d 
                        WHERE d.grupo_calculo = lk_ganancia_fija ) ;

-- ============== Calculo de promedio de horas extras en meses de Junio y Diciembre ============
IF to_char(ad_fec_proceso,'mm') = '06' OR to_char(ad_fec_proceso,'mm') = '12' THEN
    --  Inicializando periodos de sobretiempos de los ultimos seis meses (6*30=180) 
    ls_periodo_ini := to_char(ad_fec_proceso - 180, 'yyyymm') ;
    ls_periodo_fin := to_char(ad_fec_proceso, 'yyyymm') ;
    
    -- Verifica en cuantos meses por lo menos uno de sus conceptos del grupo fue pagado
    SELECT count(distinct(to_char(fec_calc_plan,'yyyymm')))
      INTO ln_contador 
      FROM historico_calculo hc 
     WHERE hc.concep in (SELECT gd.concepto_calc 
                           FROM grupo_calculo_det gd 
                          WHERE gd.grupo_calculo = lk_sobretiempos) 
       AND (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and 
            to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) 
       AND hc.cod_trabajador=as_codtra ;
    
    -- Solo considera en caso tenga por lo menos en 03 meses o mas, pero el importe a considerar es 1/6.       
    IF ln_contador >= 3 THEN
      SELECT sum(NVL(hc.imp_soles,0)) 
        INTO ln_imp_hora_extra  
        FROM historico_calculo hc 
       WHERE hc.concep in (SELECT gd.concepto_calc 
                             FROM grupo_calculo_det gd 
                            WHERE gd.grupo_calculo=lk_sobretiempos) 
         AND (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) 
         AND hc.cod_trabajador=as_codtra ;
    ELSE
      ln_imp_hora_extra := 0 ;
    END IF ;
    ln_imp_hora_extra := ln_imp_hora_extra / 6 ;
ELSE
    ln_imp_hora_extra := 0 ;
END IF ;

-- Acumula monto a provisionar
ln_importe := ln_importe + ln_imp_hora_extra ;

--  Incrementa el 30% o 25% segun condicion
if ls_bonificacion = '1' then
  ln_importe := ln_importe * 1.30 ;
elsif ls_bonificacion = '2' then
  ln_importe := ln_importe * 1.25 ;
end if ;

-- Calculando el acumulado anterior 
IF TO_CHAR(ad_fec_proceso,'mm') <='06' THEN
    SELECT sum(nvl(r.importe,0)) 
      INTO ln_acumul_ant 
      FROM rh_prov_vacac_gratif_cts r 
     WHERE r.ano = ln_ano 
       AND r.mes <= ln_mes 
       AND r.cod_trabajador = as_codtra 
       AND r.flag_provis = ls_flag_provis ;
ELSE
    SELECT sum(nvl(r.importe,0)) 
      INTO ln_acumul_ant 
      FROM rh_prov_vacac_gratif_cts r 
     WHERE r.ano = ln_ano 
       AND r.mes > 6 
       AND r.mes <= ln_mes 
       AND r.cod_trabajador = as_codtra 
       AND r.flag_provis = ls_flag_provis ;
END IF ;

IF ln_dias < 30 THEN 
   ln_importe := (NVL(ln_importe,0) * ln_dias / 360 ) - NVL(ln_acumul_ant,0) ;
ELSE
   ln_importe := (NVL(ln_importe,0) * ln_nro_meses / 6 ) - NVL(ln_acumul_ant,0) ;
END IF ;

INSERT INTO rh_prov_vacac_gratif_cts(
       ano, mes, cod_trabajador,
       flag_provis, cencos, cod_origen,
       tipo_trabajador, importe) 
VALUES (ln_ano, ln_mes, as_codtra, 
        ls_flag_provis, ls_cencos, ls_origen, 
        ls_tipo_trabajador, ln_importe) ;

-- commit ;        

end usp_rh_calcula_provision_gra ;
/
