create or replace procedure usp_mm_act_cts_semestral (
  as_origen in origen.cod_origen%type, as_tipo_trab in tipo_trabajador.tipo_trabajador%type, 
  ad_fec_proceso in date, ad_fec_pago_jul in date, ad_fec_pago_dic in date ) is

lk_ganancias_fijas   char(3) ;
lk_gra_jul           char(3) ;
lk_gra_dic           char(3) ;
lk_gratificacion     char(3) ;
lk_horas_extras      char(3) ;
lk_destajos          char(3) ;
lk_bonific_variab    char(3) ;
lk_inasist_cts       rrhhparam_cconcep.grp_dias_inasistencia_cts%type ;
ls_ttrab             tipo_trabajador.tipo_trabajador%type ;
ls_cod_origen        origen.cod_origen%type ;
ls_bonificacion      maestro.bonif_fija_30_25%type ;
ls_cod_seccion       maestro.cod_seccion%type ;
ld_fec_ingreso       maestro.fec_ingreso%type ;
ln_imp_soles         calculo.imp_soles%type ;
ln_imp_6to_mes       calculo.imp_soles%type ;
ln_imp_ingreso_fijo  calculo.imp_soles%type ;
ln_imp_hora_extra    calculo.imp_soles%type ;
ln_imp_destajo       calculo.imp_soles%type ;
ln_imp_bonificacion  calculo.imp_soles%type ;
ln_imp_gratificacion calculo.imp_soles%type ;
ld_fec_pago          date                 ;
ln_dia_tra           number ;
ln_dias_ina          prov_cts_gratif.dias_trabaj%type ;
ln_prov_acumul       prov_cts_gratif.prov_cts_01%type ;
ln_contador          integer ;
ln_num_reg           number(5) ;
ln_acu_soles         historico_calculo.imp_soles%type ;
ln_tot_soles         historico_calculo.imp_soles%type ;
ln_count             number ;
ls_periodo_ini       char(6) ;
ls_periodo_fin       char(6) ;
ls_banco_cts         maestro.cod_banco_cts%type ;
ls_nro_cnta_cts      maestro.nro_cnta_cts%type ;
ls_moneda_cts        maestro.moneda_cts%type ;
ln_item              number(2) ;


CURSOR c_personal is
SELECT m.cod_trabajador  
  FROM maestro m 
 WHERE m.cod_origen = as_origen and 
       m.tipo_trabajador = as_tipo_trab and 
       m.flag_estado = '1' and 
       m.flag_cal_plnlla = '1' ;
      
--  Lectura de conceptos de ganancias fijas
CURSOR c_ganancias_fijas(as_codtra in maestro.cod_trabajador%type) is
  select substr(c.desc_concep,1,40) as desc_concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf, concepto c 
  where gdf.concep = c.concep and 
        gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
        gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                        where d.grupo_calculo = lk_ganancias_fijas ) ;

--  Lectura para gratificaciones ( Julio o Diciembre )
CURSOR c_historico_calculo(as_codtra in maestro.cod_trabajador%type) is
  select hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = as_codtra 
    and to_char(hc.fec_calc_plan,'yyyymm') = to_char(ld_fec_pago,'yyyymm') and
        hc.concep in ( select g.concepto_gen from grupo_calculo g
        where g.grupo_calculo = lk_gratificacion ) ;

/*--  Determina factor de pago de conceptos para aplicar el 30% o 25%
cursor c_concepto ( as_concepto concepto.concep%type ) is
  select c.fact_pago
  from concepto c
  where c.concep = as_concepto ;*/

--  Conceptos para hallar promedio de los ultimos seis meses
CURSOR c_concep ( as_nivel in string ) is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = as_nivel ;

-- Lee inasistencias
CURSOR c_inasistencia(as_grp_dias_inasis_cts in rrhhparam_cconcep.grp_dias_inasistencia_cts%type, as_codtra in maestro.cod_trabajador%type) is
select sum(h.dias_inasist) as dias_inasist 
  from historico_inasistencia h, grupo_calculo_det g 
 where h.concep = g.concepto_calc and 
       h.cod_trabajador = as_codtra and 
       g.grupo_calculo = as_grp_dias_inasis_cts and 
       trunc(fec_movim) between (ad_fec_proceso - 180) and ad_fec_proceso ; 

BEGIN 

--  **************************************************************
--  ***   REALIZA CALCULO DE C.T.S. SEMESTRAL POR TRABAJADOR   ***
--  **************************************************************
FOR c_per in c_personal LOOP 

  SELECT count(*) INTO ln_contador FROM hist_prov_cts_gratif h 
   WHERE h.fecha_proceso = ad_fec_proceso and h.cod_trabajador = c_per.cod_trabajador ;
  
  /*IF ln_contador > 0 THEN
     RAISE_APPLICATION_ERROR(-20000, 'PROCESO YA HA SIDO EJECUTADO ANTERIORMENTE ' || c_per.cod_trabajador) ;
     -- En caso se desea reprocesar, borrar el historico con dicha fecha de proceso
     Return ;
  END IF ;*/
  
  -- Elimina información histórica
  DELETE FROM hist_prov_cts_det hd WHERE hd.fecha_proceso=ad_fec_proceso and hd.cod_trabajador=c_per.cod_trabajador ;
  DELETE FROM hist_prov_cts_gratif h WHERE h.fecha_proceso=ad_fec_proceso and h.cod_trabajador=c_per.cod_trabajador ;
  
  -- Busca parametros grupos de calculos para CTS.
  SELECT c.gan_fij_calc_cts, c.grati_medio_ano, c.grati_fin_ano, c.grp_hora_extra_cts, 
         c.grp_destajo_cts, c.grp_bonific_cts, c.grp_dias_inasistencia_cts
    INTO lk_ganancias_fijas, lk_gra_jul, lk_gra_dic, lk_horas_extras, 
         lk_destajos, lk_bonific_variab, lk_inasist_cts 
    FROM rrhhparam_cconcep c
   WHERE c.reckey = '1' ;
  
  ln_contador := 0 ; 
  
  SELECT m.bonif_fija_30_25, m.cod_seccion, m.fec_ingreso, m.tipo_trabajador, m.cod_origen, 
         m.cod_banco_cts, m.nro_cnta_cts, m.moneda_cts
    INTO ls_bonificacion, ls_cod_seccion, ld_fec_ingreso, ls_ttrab, ls_cod_origen, 
         ls_banco_cts, ls_nro_cnta_cts, ls_moneda_cts 
    FROM maestro m 
   WHERE m.cod_trabajador = c_per.cod_trabajador ;
  
  /*if ls_cod_seccion = '950' then
    return ;
  end if ;
  */
  IF trunc(ld_fec_ingreso) > trunc(ad_fec_proceso ) then
    return ;
  END IF ;
  
  -- Ingresando información a archivo histórico
  INSERT INTO hist_prov_cts_gratif
  (fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador, 
   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
   cts_mes05, cts_mes06, dias_asist, ingresos_fijos, 
   ingresos_variables, ingresos_h_extras, ingresos_gratif, 
   ingresos_otros, fecha_calculo, banco_cts, nro_cuenta_cts, 
   moneda_cts)
  SELECT ad_fec_proceso, p.cod_trabajador, ls_cod_origen, ls_ttrab, 
        p.prov_cts_01, p.prov_cts_02, p.prov_cts_03, p.prov_cts_04, 
        p.prov_cts_05, 0, 0, 0, 
        0, 0, 0, 
        0, trunc(sysdate), ls_banco_cts, ls_nro_cnta_cts, 
        ls_moneda_cts
   FROM prov_cts_gratif p 
  WHERE p.cod_trabajador = c_per.cod_trabajador ;
  
  
  ln_imp_soles := 0 ;
  
  -- ============== Calculo de ganancias fijas ============
  ln_imp_ingreso_fijo := 0 ;
  ln_item := 1 ;
  FOR rc_gan IN c_ganancias_fijas(c_per.cod_trabajador) LOOP
    ln_imp_ingreso_fijo := NVL(ln_imp_ingreso_fijo,0) + nvl(rc_gan.imp_gan_desc,0) ;
    IF nvl(rc_gan.imp_gan_desc,0) > 0 THEN       
        -- Insertando detalle
        INSERT INTO hist_prov_cts_det(fecha_proceso, cod_trabajador, item, glosa, monto)
        VALUES (ad_fec_proceso, c_per.cod_trabajador, ln_item, rc_gan.desc_concep, nvl(rc_gan.imp_gan_desc,0) ) ;
        -- Aumenta item de correlativo
        ln_item := ln_item + 1 ;
    END IF ;
  END LOOP ;
  ln_imp_soles := ln_imp_soles + ln_imp_ingreso_fijo ;
  
  -- Calcula periodos iniciales y finales segun fecha de proceso
  SELECT to_char(ad_fec_proceso - 180,'yyyymm'), to_char(ad_fec_proceso, 'yyyymm') 
    INTO ls_periodo_ini, ls_periodo_fin 
    FROM dual ;
  
  -- ============== Calculo de promedio de horas extras ============
  ln_imp_hora_extra := 0 ;
  -- Calcula en cuantos meses por lo menos uno de sus conceptos del grupo fue pagado
  SELECT count(distinct(to_char(fec_calc_plan,'yyyymm')))
    INTO ln_contador 
    FROM historico_calculo hc 
   WHERE hc.concep in (SELECT gd.concepto_calc FROM grupo_calculo_det gd WHERE gd.grupo_calculo=lk_horas_extras) and 
        (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
         hc.cod_trabajador=c_per.cod_trabajador ;
  
  -- Solo considera en caso tenga por lo menos en 03 meses o mas        
  IF ln_contador >= 3 THEN
    SELECT sum(hc.imp_soles) 
      INTO ln_acu_soles 
      FROM historico_calculo hc 
     WHERE hc.concep in (SELECT gd.concepto_calc FROM grupo_calculo_det gd WHERE gd.grupo_calculo=lk_horas_extras) and 
          (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
           hc.cod_trabajador=c_per.cod_trabajador ;
  ELSE
    ln_acu_soles := 0 ;
  END IF ;
  
  -- Acumula monto a pagar de CTS
  ln_imp_hora_extra := ln_acu_soles / 6 ;
  ln_imp_soles := ln_imp_soles + ln_imp_hora_extra ;
  
  
  -- Insertando registro en historico detalle caso horas extras
  INSERT INTO hist_prov_cts_det(fecha_proceso, cod_trabajador, item, glosa, monto)
  VALUES (ad_fec_proceso, c_per.cod_trabajador, ln_item, 'Promedio de horas extras', ln_imp_hora_extra ) ;
  
  ln_item := ln_item + 1 ;
  
  -- ============== Calculo de promedio de destajo ============
  ln_imp_destajo := 0 ;
  -- Calcula en cuantos meses por lo menos uno de sus conceptos del grupo fue pagado
  SELECT count(distinct(to_char(fec_calc_plan,'yyyymm')))
    INTO ln_contador 
    FROM historico_calculo hc 
   WHERE hc.concep in (SELECT gd.concepto_calc FROM grupo_calculo_det gd WHERE gd.grupo_calculo=lk_destajos) and 
        (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
         hc.cod_trabajador=c_per.cod_trabajador ;
  
  -- Solo considera en caso tenga por lo menos en 03 meses o mas        
  IF ln_contador >= 3 THEN
    SELECT sum(hc.imp_soles) 
      INTO ln_acu_soles 
      FROM historico_calculo hc 
     WHERE hc.concep in (SELECT gd.concepto_calc FROM grupo_calculo_det gd WHERE gd.grupo_calculo=lk_destajos) and 
          (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
           hc.cod_trabajador=c_per.cod_trabajador ;
  ELSE
    ln_acu_soles := 0 ;
  END IF ;
  -- Acumula monto a pagar de CTS
  ln_imp_destajo := ln_acu_soles / 6 ;
  ln_imp_soles := ln_imp_soles + ln_imp_destajo ;
  
  -- Insertando registro en historico detalle caso destajo
  INSERT INTO hist_prov_cts_det(fecha_proceso, cod_trabajador, item, glosa, monto)
  VALUES (ad_fec_proceso, c_per.cod_trabajador, ln_item, 'Promedio de destajo', ln_imp_hora_extra ) ;
  
  ln_item := ln_item + 1 ;
  
  
  -- ============== Calculo de promedio de gratificacion ============
  ln_imp_gratificacion := 0 ;
  IF to_char(ad_fec_proceso,'mm') = '04' then    
    lk_gratificacion := lk_gra_dic ;
    ld_fec_pago := ad_fec_pago_dic ;
  ELSIF to_char(ad_fec_proceso,'mm') = '10' then
    lk_gratificacion := lk_gra_jul ;
    ld_fec_pago := ad_fec_pago_jul ;
  END IF ;
  
  -- Calcula un 6to de la gratificacion
  FOR rc_gra in c_historico_calculo(c_per.cod_trabajador) loop
    ln_imp_gratificacion := NVL(ln_imp_gratificacion,0) + ( nvl(rc_gra.imp_soles,0) / 6 ) ;
  END loop ;
  
  ln_imp_soles := ln_imp_soles + ln_imp_gratificacion ;
  
  -- Insertando registro en historico detalle caso gratificación
  INSERT INTO hist_prov_cts_det(fecha_proceso, cod_trabajador, item, glosa, monto)
  VALUES (ad_fec_proceso, c_per.cod_trabajador, ln_item, '1/6 de gratificación anterior', ln_imp_gratificacion ) ;
  
  ln_item := ln_item + 1 ;
  
  
  -- ============== Calculo de ganancias variables ============
  ln_imp_bonificacion := 0 ;
  ln_tot_soles := 0 ;
  -- Solo debe considerar si cada uno de los conceptos del grupo, esta por lo menos en 03 meses o mas.
  FOR rc_concep in c_concep ( lk_bonific_variab ) LOOP 
      SELECT count(distinct(to_char(fec_calc_plan,'yyyymm')))
        INTO ln_contador 
        FROM historico_calculo hc 
       WHERE hc.concep = rc_concep.concepto_calc and 
            (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
             hc.cod_trabajador=c_per.cod_trabajador ;
      
      IF ln_contador >= 3 THEN
        SELECT sum(hc.imp_soles) 
          INTO ln_acu_soles 
          FROM historico_calculo hc 
         WHERE hc.concep = rc_concep.concepto_calc and 
              (to_char(fec_calc_plan,'yyyymm')>=ls_periodo_ini and to_char(fec_calc_plan,'yyyymm')<=ls_periodo_fin) and 
               hc.cod_trabajador=c_per.cod_trabajador ;
      ELSE
          ln_acu_soles := 0 ;
      END IF ;
      
      IF ln_acu_soles > 0 THEN 
         ln_imp_bonificacion := NVL(ln_imp_bonificacion,0) + ln_acu_soles / 6 ;
      END IF ;
  END LOOP ;
  
  ln_imp_soles := ln_imp_soles + ln_imp_bonificacion ;
  
  -- Insertando registro en historico detalle caso bonificación (trabajos nocturnos)
  INSERT INTO hist_prov_cts_det(fecha_proceso, cod_trabajador, item, glosa, monto)
  VALUES (ad_fec_proceso, c_per.cod_trabajador, ln_item, 'Promedio bonificaciones (trab. nocturno)', ln_imp_bonificacion ) ;
  
  ln_item := ln_item + 1 ;
  
  --  Calcula C.T.S. del semestre
  SELECT count(*) 
    INTO ln_count 
    FROM prov_cts_gratif pcg 
   WHERE pcg.cod_trabajador = c_per.cod_trabajador ;
  
  IF ln_count>0 THEN  
    select pcg.dias_trabaj, (NVL(prov_cts_01,0) + NVL(prov_cts_02,0) + NVL(prov_cts_03,0) + NVL(prov_cts_04,0) + NVL(prov_cts_05,0) )
      into ln_dia_tra, ln_prov_acumul 
      from prov_cts_gratif pcg 
     where pcg.cod_trabajador = c_per.cod_trabajador ;
  ELSE
      ln_prov_acumul := 0 ;
  END IF ;
  --ln_imp_soles   := ln_imp_soles + ln_tot_soles ;
  ln_prov_acumul := nvl(ln_prov_acumul,0) ;
  
  ln_dia_tra := trunc(ad_fec_proceso) - trunc(ld_fec_ingreso) + 1;
  ln_dia_tra := nvl(ln_dia_tra,0) ;
  
  if ln_dia_tra > 180 then
    ln_dia_tra := 180 ;
  end if ;
  
  -- Capturando las inasistencias
  FOR c_ina IN c_inasistencia(lk_inasist_cts, c_per.cod_trabajador) LOOP
      ln_dias_ina := c_ina.dias_inasist ;
  END LOOP ;
  
  ln_dias_ina := NVL(ln_dias_ina, 0) ;
  ln_dia_tra := ln_dia_tra - ln_dias_ina ;
  
  -- ln_imp_soles = Total CTS
  ln_imp_6to_mes := ( ((ln_imp_soles / 360) * ln_dia_tra) - ln_prov_acumul ) ;
  
  ln_contador := 0 ;
  
  select count(*) into ln_contador from prov_cts_gratif p  where p.cod_trabajador = c_per.cod_trabajador ;
  
  
  IF ln_contador > 0 then
    update prov_cts_gratif p
       set prov_cts_06 = ln_imp_6to_mes, 
           dias_trabaj = ln_dia_tra, 
           flag_replicacion = '1', 
           p.cod_origen = ls_cod_origen, 
           p.tipo_trabajador = ls_ttrab
     where cod_trabajador = c_per.cod_trabajador ;
  ELSE
    INSERT INTO prov_cts_gratif (
      cod_trabajador, dias_trabaj, flag_estado, prov_cts_01, prov_cts_02,
      prov_cts_03, prov_cts_04, prov_cts_05, prov_cts_06, flag_replicacion, 
      cod_origen, tipo_trabajador)
    values (
      c_per.cod_trabajador, ln_dia_tra, '1', 0, 0,
      0, 0, 0, ln_imp_6to_mes, '1', ls_cod_origen, 
      ls_ttrab ) ;
  END IF ;
  
  -- Actualizando datos en historico
  UPDATE hist_prov_cts_gratif h 
     SET h.ingresos_fijos = ln_imp_ingreso_fijo, 
         h.ingresos_variables = ln_imp_bonificacion, 
         h.ingresos_h_extras = ln_imp_hora_extra, 
         h.ingresos_gratif = ln_imp_gratificacion, 
         h.ingresos_otros = ln_imp_destajo, 
         h.banco_cts = ls_banco_cts, 
         h.nro_cuenta_cts = ls_nro_cnta_cts, 
         h.moneda_cts = ls_moneda_cts, 
         h.cts_mes06 = ln_imp_6to_mes, 
         h.dias_asist = ln_dia_tra
   WHERE trunc(h.fecha_proceso) = trunc(ad_fec_proceso) and 
         h.cod_trabajador = c_per.cod_trabajador ;

END LOOP ;

END usp_mm_act_cts_semestral ;
/
