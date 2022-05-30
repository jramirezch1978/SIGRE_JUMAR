CREATE OR REPLACE PROCEDURE usp_rh_calcula_provision_vac (
  as_codtra       in maestro.cod_trabajador%type, 
  ad_fec_proceso  in date ) is

ln_ano              cntbl_asiento.ano%type ;
ln_mes              cntbl_asiento.mes%type ;
ls_origen           maestro.cod_origen%type ;
ls_cencos           centros_costo.cencos%type ;
ls_tipo_trabajador  tipo_trabajador.tipo_trabajador%type ;
ln_dias             number ; 
ls_flag_provis      maestro.flag_estado%type ;
ln_importe          gan_desct_fijo.imp_gan_desc%type ;
ln_acumul_ant       gan_desct_fijo.imp_gan_desc%type ;
ls_flag             maestro.bonif_fija_30_25%type ;
ld_fec_ingreso      maestro.fec_ingreso%type ;
ln_nro_meses        number ;
lk_vac_bonif        grupo_calculo.grupo_calculo%type ;

BEGIN 

--  **************************************************************
--  ***   CALCULA PROVISIONES DE VACACIONES Y BONIFICACIONES   ***
--  **************************************************************

-- Validando la fecha del proceso a generar
IF trunc(ad_fec_proceso) > trunc(sysdate) THEN
   RAISE_APPLICATION_ERROR(-20000, 'Fecha de proceso superior a fecha del sistema') ;
   Return ;
END IF ;

SELECT c.ganfij_provision_vacac 
  INTO lk_vac_bonif 
  FROM rrhhparam_cconcep c
 WHERE c.reckey = '1' ;

-- Inicializando los datos en caso exista información
ln_ano := TO_NUMBER( TO_CHAR( ad_fec_proceso, 'yyyy')) ;
ln_mes := TO_NUMBER( TO_CHAR( ad_fec_proceso, 'mm')) ;

ls_flag_provis := 'V' ; -- Vacaciones

SELECT m.cod_origen, m.cencos, tipo_trabajador
  INTO ls_origen, ls_cencos, ls_tipo_trabajador 
  FROM maestro m 
WHERE m.cod_trabajador = as_codtra ;

-- Elimina información del periodo seleccionado
-- (Primero que verifica si mes contable permite borrarlo)
DELETE FROM rh_prov_vacac_gratif_cts r 
      WHERE r.ano = ln_ano AND 
            r.mes = ln_mes AND 
            r.cod_trabajador = as_codtra AND 
            r.flag_provis = ls_flag_provis ;

SELECT sum(nvl(gdf.imp_gan_desc,0)) 
  INTO ln_importe 
  FROM gan_desct_fijo gdf
 WHERE gdf.cod_trabajador = as_codtra 
   AND gdf.flag_estado = '1' 
   AND gdf.concep in ( SELECT d.concepto_calc 
                         FROM grupo_calculo_det d
                        WHERE d.grupo_calculo = lk_vac_bonif ) ;

SELECT nvl(m.bonif_fija_30_25,'0'), m.fec_ingreso
  INTO ls_flag, ld_fec_ingreso 
  FROM maestro m
 WHERE m.cod_trabajador = as_codtra ;

IF ls_flag = '1' then
  ln_importe := ln_importe * 1.30 ;
ELSIF ls_flag = '2' then
  ln_importe := ln_importe *  1.25 ;
END IF ;

IF ld_fec_ingreso < to_date('01/01/'||to_char(ad_fec_proceso,'yyyy'),'dd/mm/yyyy') THEN 
   ld_fec_ingreso := to_date('01/01/'||to_char(ad_fec_proceso,'yyyy'),'dd/mm/yyyy') ;
END IF; 

ln_dias := trunc(ad_fec_proceso) - trunc(ld_fec_ingreso) + 1 ;

IF ln_dias < 1 THEN
   return ;
END IF ;

-- Calcula previamente el acumulado anterior
SELECT sum(NVL(r.importe,0)) 
  INTO ln_acumul_ant 
  FROM rh_prov_vacac_gratif_cts r 
 WHERE r.ano = ln_ano 
   AND r.mes < ln_mes 
   AND r.cod_trabajador = as_codtra 
   AND r.flag_provis = ls_flag_provis ;

IF ln_dias < 30 THEN
  ln_importe := (ln_importe * ln_dias / 360) - nvl(ln_acumul_ant,0) ;
ELSE
  ln_nro_meses := ROUND( ( ad_fec_proceso - ld_fec_ingreso) / 30, 0) ;
  ln_importe := (ln_importe * ln_nro_meses / 12) - nvl(ln_acumul_ant,0) ;
END IF ;

-- Adiciona el registro 
INSERT INTO rh_prov_vacac_gratif_cts(
       ano, mes, cod_trabajador, 
       flag_provis, cencos, cod_origen, 
       tipo_trabajador, importe ) 
VALUES (ln_ano, ln_mes, as_codtra, 
        ls_flag_provis, ls_cencos, ls_origen,
        ls_tipo_trabajador, ln_importe ) ;

END usp_rh_calcula_provision_vac ;
/
