create or replace procedure usp_rh_presupuesto_anual_mm (
  asi_usuario    in usuario.cod_usr%TYPE,
  asi_origen     IN origen.cod_origen%TYPE,
  asi_tipo_trab  in tipo_trabajador.tipo_trabajador%type,
  asi_situa_trab IN situacion_trabajador.situa_trabaj%TYPE,
  asi_revertir   IN VARCHAR2,
  asi_preview    IN VARCHAR2,
  ani_periodo    in number,   
  ani_asiesc     in number,  
  ani_factor_01  in number,  ani_factor_02  in number,  ani_factor_03  in number,
  ani_factor_04  in number,  ani_factor_05  in number,  ani_factor_06  in number,
  ani_factor_07  in number,  ani_factor_08  in number,  ani_factor_09  in number,
  ani_factor_10  in number,  ani_factor_11  in number,  ani_factor_12  in number,
  ani_monfij_01  in number,  ani_monfij_02  in number,  ani_monfij_03  in number,
  ani_monfij_04  in number,  ani_monfij_05  in number,  ani_monfij_06  in number,
  ani_monfij_07  in number,  ani_monfij_08  in number,  ani_monfij_09  in number,
  ani_monfij_10  in number,  ani_monfij_11  in number,  ani_monfij_12  in number,
  ani_tipcam_01  in number,  ani_tipcam_02  in number,  ani_tipcam_03  in number,
  ani_tipcam_04  in number,  ani_tipcam_05  in number,  ani_tipcam_06  in number,
  ani_tipcam_07  in number,  ani_tipcam_08  in number,  ani_tipcam_09  in number,
  ani_tipcam_10  in number,  ani_tipcam_11  in number,  ani_tipcam_12  in NUMBER
) is

lk_promedio         rrhhparam_cconcep.gan_var_ppto%TYPE ;
ls_comentario       presupuesto_det.comentario%TYPE := 'PRESUPUESTO DE PLANILLA' ;
lk_cierre_pliego    rrhhparam_cconcep.bonif_cierre_planilla%TYPE ;
lk_racion_cocida    rrhhparam_cconcep.calculo_racion_cocida%TYPE ;
lk_rem_basica       rrhhparam_cconcep.remunerac_basica%TYPE ;
lk_promedio_var     rrhhparam_cconcep.sobret_sem_inglesa%TYPE ;
lk_gratif_julio     rrhhparam_cconcep.grati_medio_ano%TYPE ;
lk_quinquenio       rrhhparam_cconcep.concep_calc_quinquenio%TYPE ;
lk_asig_escolar     rrhhparam_cconcep.concep_asig_escolar%TYPE ;
lk_seguro_agrario   rrhhparam_cconcep.concep_seguro_agrario%TYPE ;
lk_senati           rrhhparam_cconcep.concep_afecto_senati%TYPE ;
lk_cts              rrhhparam_cconcep.deuda_laboral_cts%TYPE ;
lk_seccion_senati   constant char(1) :=  'C' ;   --  Grupo de secciones
ln_count            NUMBER;

ld_fec_ingreso      date ;           
ld_fec_proceso      date ;
ld_rani_ini         date ;           
ld_rani_fin         date ;
ld_fec_quinque      date ;           
ld_fec_asiesc       date ;
ls_bonificacion     char(1) ;
ls_mes_ingreso      char(2) ;
ls_cnta_prsp        presupuesto_cuenta.cnta_prsp%TYPE;
ln_importe          number(13,2) ;
ln_gan_variables    gan_desct_variable.imp_var%TYPE;
ln_acumulado        number(13,2) ;   
ln_gratif_jul       number(13,2) ;
ln_gratif_dic       number(13,2) ;   
ln_years            number(4,2) ;
ln_jornal           number(4,2) ;    
ln_factor           number(9,6) ;
ln_nro_meses        integer ;        
ln_quinquenio       integer ;        
ln_bonvac           integer ;
ls_concepto         char(4) ;
ls_gan_fijas        char(2) ;

ln_impor_fij number(13,2) ;
ln_imp01_fij  number(13,2) ;  ln_imp02_fij  number(13,2) ;
ln_imp03_fij  number(13,2) ;  ln_imp04_fij  number(13,2) ;
ln_imp05_fij  number(13,2) ;  ln_imp06_fij  number(13,2) ;
ln_imp07_fij  number(13,2) ;  ln_imp08_fij  number(13,2) ;
ln_imp09_fij  number(13,2) ;  ln_imp10_fij  number(13,2) ;
ln_imp11_fij  number(13,2) ;  ln_imp12_fij  number(13,2) ;

ln_imp01_fix  number(13,2) ;  ln_imp02_fix  number(13,2) ;
ln_imp03_fix  number(13,2) ;  ln_imp04_fix  number(13,2) ;
ln_imp05_fix  number(13,2) ;  ln_imp06_fix  number(13,2) ;
ln_imp07_fix  number(13,2) ;  ln_imp08_fix  number(13,2) ;
ln_imp09_fix  number(13,2) ;  ln_imp10_fix  number(13,2) ;
ln_imp11_fix  number(13,2) ;  ln_imp12_fix  number(13,2) ;

ln_imp01_var  number(13,2) ;  ln_imp02_var  number(13,2) ;
ln_imp03_var  number(13,2) ;  ln_imp04_var  number(13,2) ;
ln_imp05_var  number(13,2) ;  ln_imp06_var  number(13,2) ;
ln_imp07_var  number(13,2) ;  ln_imp08_var  number(13,2) ;
ln_imp09_var  number(13,2) ;  ln_imp10_var  number(13,2) ;
ln_imp11_var  number(13,2) ;  ln_imp12_var  number(13,2) ;

ln_imp01_vax  number(13,2) ;  ln_imp02_vax  number(13,2) ;
ln_imp03_vax  number(13,2) ;  ln_imp04_vax  number(13,2) ;
ln_imp05_vax  number(13,2) ;  ln_imp06_vax  number(13,2) ;
ln_imp07_vax  number(13,2) ;  ln_imp08_vax  number(13,2) ;
ln_imp09_vax  number(13,2) ;  ln_imp10_vax  number(13,2) ;
ln_imp11_vax  number(13,2) ;  ln_imp12_vax  number(13,2) ;

ln_imp01_qui  number(13,2) ;  ln_imp02_qui  number(13,2) ;
ln_imp03_qui  number(13,2) ;  ln_imp04_qui  number(13,2) ;
ln_imp05_qui  number(13,2) ;  ln_imp06_qui  number(13,2) ;
ln_imp07_qui  number(13,2) ;  ln_imp08_qui  number(13,2) ;
ln_imp09_qui  number(13,2) ;  ln_imp10_qui  number(13,2) ;
ln_imp11_qui  number(13,2) ;  ln_imp12_qui  number(13,2) ;

ln_imp01_apo  number(13,2) ;  ln_imp02_apo  number(13,2) ;
ln_imp03_apo  number(13,2) ;  ln_imp04_apo  number(13,2) ;
ln_imp05_apo  number(13,2) ;  ln_imp06_apo  number(13,2) ;
ln_imp07_apo  number(13,2) ;  ln_imp08_apo  number(13,2) ;
ln_imp09_apo  number(13,2) ;  ln_imp10_apo  number(13,2) ;
ln_imp11_apo  number(13,2) ;  ln_imp12_apo  number(13,2) ;

ln_imp01_cts  number(13,2) ;  ln_imp02_cts  number(13,2) ;
ln_imp03_cts  number(13,2) ;  ln_imp04_cts  number(13,2) ;
ln_imp05_cts  number(13,2) ;  ln_imp06_cts  number(13,2) ;
ln_imp07_cts  number(13,2) ;  ln_imp08_cts  number(13,2) ;
ln_imp09_cts  number(13,2) ;  ln_imp10_cts  number(13,2) ;
ln_imp11_cts  number(13,2) ;  ln_imp12_cts  number(13,2) ;

ln_mes        number(2) ;
--  Lectura de registros del maestro de personal
cursor c_maestro is
  select m.cod_trabajador, m.fec_ingreso, m.bonif_fija_30_25,
         m.tipo_trabajador, m.cencos, m.cod_seccion, m.cod_area,
         m.situa_trabaj, m.cod_origen, m.centro_benef
  from maestro m
  where m.flag_estado = '1' 
    and m.flag_cal_plnlla = '1' 
    and m.cencos IS NOT NULL 
    AND m.cod_origen      = asi_origen
    AND m.tipo_trabajador LIKE asi_tipo_trab
    AND m.situa_trabaj    LIKE asi_situa_trab
  order by m.cencos, m.cod_trabajador ;

--  Lectura de ganancias fijas por trabajador
cursor c_ganancias(as_trabajador IN maestro.cod_trabajador%TYPE) IS
  select gdf.concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf, concepto_tip_trab_cnta c
  where gdf.
  gdf.cod_trabajador = as_trabajador 
    and gdf.flag_estado = '1' 
    AND substr(gdf.concep,1,2) = ls_gan_fijas
  order by gdf.cod_trabajador, gdf.concep ;

--  Lectura de conceptos variables afectos a promedios
cursor c_concepto is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = lk_promedio ;

--  Lectura de carga familiar por trabajador
cursor c_carga(as_trabajador IN maestro.cod_trabajador%TYPE) is
  select f.cod_parent, f.fec_nacimiento
  from carga_familiar f
  where f.cod_trabajador = as_trabajador 
    AND (f.cod_parent = '02' or f.cod_parent = '03')
  order by f.cod_trabajador, f.secuencia ;

begin
  
  select c.gan_var_ppto, c.bonif_cierre_planilla, c.calculo_racion_cocida,
         c.remunerac_basica, c.sobret_sem_inglesa, c.grati_medio_ano,
         c.concep_calc_quinquenio, c.concep_asig_escolar, c.concep_seguro_agrario,
         c.concep_afecto_senati, c.deuda_laboral_cts
    into lk_promedio, lk_cierre_pliego, lk_racion_cocida,
         lk_rem_basica, lk_promedio_var, lk_gratif_julio,
         lk_quinquenio, lk_asig_escolar, lk_seguro_agrario,
         lk_senati, lk_cts
    from rrhhparam_cconcep c
    where c.reckey = '1' ;

  IF lk_cts IS NULL THEN
     RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el Grupo de Calculo para el CTS');
  END IF;

-- Si esta marcada la opción de revertir y no esta en modo preliminar
-- entonces simplemente elimino todo de presupuesto_det
IF asi_revertir = '1' AND asi_preview = '0' THEN
   delete presupuesto_det pd
    where pd.ano = ani_periodo 
      and pd.flag_proceso = 'A'
      AND pd.tipo_trabajador LIKE asi_tipo_trab
      AND pd.situa_trabaj    LIKE asi_situa_trab
      AND pd.cod_origen      LIKE asi_origen;
   
   RETURN;
END IF;

-- Verifico si se ha corrido el proceso para el tipo_trabajador
-- y situacion indicada
IF asi_preview = '0' THEN
   SELECT COUNT(*)
     INTO ln_count
     FROM presupuesto_det pd
    where pd.ano = ani_periodo 
      and pd.flag_proceso = 'A'
      AND pd.tipo_trabajador LIKE asi_tipo_trab
      AND pd.situa_trabaj    LIKE asi_situa_trab
      AND pd.cod_origen      LIKE asi_origen;
   
   IF ln_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20000, 'Ya se ha realizado el proceso para el '
                            || chr(13) || 'Tipo de trabajador ' || asi_tipo_trab 
                            || chr(13) || 'Situacion de trabajador: ' || asi_situa_trab
                            || chr(13) || 'Periodo: ' || to_char(ani_periodo));
   END IF;

END IF;

delete from tt_pto_presupuesto_det ;

select rh.grc_gnn_fija 
  into ls_gan_fijas
  from rrhhparam rh 
 where rh.reckey = '1' ;

--  ***********************************************************
--  ***   LECTURA DE TRABAJADORES DEL MAESTRO DE PERSONAL   ***
--  ***********************************************************
FOR rc_mae in c_maestro LOOP

    ld_fec_ingreso  := rc_mae.fec_ingreso ;
    ls_bonificacion := nvl(rc_mae.bonif_fija_30_25,'0') ;
    ls_mes_ingreso  := to_char(ld_fec_ingreso,'MM') ;
    
    --  Determina fecha de proceso del registro de parametros
    select p.fec_proceso 
      into ld_fec_proceso 
      from rrhh_param_org p
     where p.origen          = rc_mae.cod_origen   
       AND p.tipo_trabajador = rc_mae.tipo_trabajador ;
    
    ln_imp01_fix := 0 ;  ln_imp02_fix := 0 ;  ln_imp03_fix := 0 ;
    ln_imp04_fix := 0 ;  ln_imp05_fix := 0 ;  ln_imp06_fix := 0 ;
    ln_imp07_fix := 0 ;  ln_imp08_fix := 0 ;  ln_imp09_fix := 0 ;
    ln_imp10_fix := 0 ;  ln_imp11_fix := 0 ;  ln_imp12_fix := 0 ;


    --  ****************************
    --  ***   CIERRE DE PLIEGO   ***
    --  ****************************
    --  Inicializa variables
    ln_imp01_fij := 0 ;  ln_imp02_fij := 0 ;  ln_imp03_fij := 0 ;
    ln_imp04_fij := 0 ;  ln_imp05_fij := 0 ;  ln_imp06_fij := 0 ;
    ln_imp07_fij := 0 ;  ln_imp08_fij := 0 ;  ln_imp09_fij := 0 ;
    ln_imp10_fij := 0 ;  ln_imp11_fij := 0 ;  ln_imp12_fij := 0 ;
  
    select count(*) 
      into ln_count 
      from grupo_calculo g
     where g.grupo_calculo = lk_cierre_pliego ;

    -- Si existe cierre de pliego
    IF ln_count > 0 then
       select g.concepto_gen 
         into ls_concepto 
         from grupo_calculo g
        where g.grupo_calculo = lk_cierre_pliego ;
       
       select COUNT(*)
         into ln_count 
         from concepto_tip_trab_cnta c
        where c.concep          = ls_concepto 
          and c.tipo_trabajador = rc_mae.tipo_trabajador ;
       
       IF ln_count = 0 THEN
          RAISE_APPLICATION_ERROR(-20000, 'No existe Cuenta presupuestal para el concepto ' 
                                   || ls_concepto || ' y el tipo de trabajador ' || rc_mae.tipo_trabajador);
       END IF;
       
       select c.cnta_prsp 
         into ls_cnta_prsp 
         from concepto_tip_trab_cnta c
        where c.concep          = ls_concepto 
          and c.tipo_trabajador = rc_mae.tipo_trabajador ;
          
      if ls_cnta_prsp IS NOT NULL then
         SELECT DECODE(NVL(ani_tipcam_01,0), 0, 0, nvl(ani_monfij_01,0) / ani_tipcam_01) INTO ln_imp01_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_02,0), 0, 0, nvl(ani_monfij_02,0) / ani_tipcam_02) INTO ln_imp02_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_03,0), 0, 0, nvl(ani_monfij_03,0) / ani_tipcam_03) INTO ln_imp03_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_04,0), 0, 0, nvl(ani_monfij_04,0) / ani_tipcam_04) INTO ln_imp04_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_05,0), 0, 0, nvl(ani_monfij_05,0) / ani_tipcam_05) INTO ln_imp05_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_06,0), 0, 0, nvl(ani_monfij_06,0) / ani_tipcam_06) INTO ln_imp06_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_07,0), 0, 0, nvl(ani_monfij_07,0) / ani_tipcam_07) INTO ln_imp07_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_08,0), 0, 0, nvl(ani_monfij_08,0) / ani_tipcam_08) INTO ln_imp08_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_09,0), 0, 0, nvl(ani_monfij_09,0) / ani_tipcam_09) INTO ln_imp09_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_10,0), 0, 0, nvl(ani_monfij_10,0) / ani_tipcam_10) INTO ln_imp10_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_11,0), 0, 0, nvl(ani_monfij_11,0) / ani_tipcam_11) INTO ln_imp11_fij FROM dual;
         SELECT DECODE(NVL(ani_tipcam_12,0), 0, 0, nvl(ani_monfij_12,0) / ani_tipcam_12) INTO ln_imp12_fij FROM dual;
         
         -- ahora inserto en la tabla respectiva deacuerdo al flag indicado
         
         FOR ln_mes IN 1..12 LOOP
             IF ln_mes = 1 THEN
                ln_impor_fij := ln_imp01_fij ;
             ELSIF ln_mes = 2 THEN
                ln_impor_fij := ln_imp02_fij ;
             ELSIF ln_mes = 3 THEN
                ln_impor_fij := ln_imp03_fij ;
             ELSIF ln_mes = 4 THEN
                ln_impor_fij := ln_imp04_fij ;
             ELSIF ln_mes = 5 THEN
                ln_impor_fij := ln_imp05_fij ;
             ELSIF ln_mes = 6 THEN
                ln_impor_fij := ln_imp06_fij ;
             ELSIF ln_mes = 7 THEN
                ln_impor_fij := ln_imp07_fij ;
             ELSIF ln_mes = 8 THEN
                ln_impor_fij := ln_imp08_fij ;
             ELSIF ln_mes = 9 THEN
                ln_impor_fij := ln_imp09_fij ;
             ELSIF ln_mes = 10 THEN
                ln_impor_fij := ln_imp10_fij ;
             ELSIF ln_mes = 11 THEN
                ln_impor_fij := ln_imp11_fij ;
             ELSIF ln_mes = 12 THEN
                ln_impor_fij := ln_imp12_fij ;
             END IF ;
             
             IF asi_preview = '1' THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_impor_fij 
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = ln_mes 
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, ln_mes, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_impor_fij, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
             ELSE
                   UPDATE presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_impor_fij 
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = ln_mes
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, ln_mes, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_impor_fij, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
             END IF;
         END LOOP ;
      end if ; -- Fin cuenta presupuestal
    end if ;  -- Fin de cierre de pliego
         
    
    --  **************************************************
    --  ***   CALCULA GANANCIAS FIJAS POR TRABAJADOR   ***
    --  **************************************************
    ln_imp01_fij := 0 ;  ln_imp02_fij := 0 ;  ln_imp03_fij := 0 ;
    ln_imp04_fij := 0 ;  ln_imp05_fij := 0 ;  ln_imp06_fij := 0 ;
    ln_imp07_fij := 0 ;  ln_imp08_fij := 0 ;  ln_imp09_fij := 0 ;
    ln_imp10_fij := 0 ;  ln_imp11_fij := 0 ;  ln_imp12_fij := 0 ;
    
    FOR rc_gan IN c_ganancias(rc_mae.cod_trabajador) LOOP
        ln_importe  := nvl(rc_gan.imp_gan_desc,0) ;
        
        if ls_bonificacion = '1' then
           ln_importe := ln_importe * 1.30 ;
        elsif ls_bonificacion = '2' then
           ln_importe := ln_importe * 1.25 ;
        end if ;
        
        SELECT COUNT(*)
          INTO ln_count
          from concepto_tip_trab_cnta c
         where c.concep = rc_gan.concep 
           and c.tipo_trabajador = rc_mae.tipo_trabajador ;
        
        IF ln_count > 0 THEN
           select c.cnta_prsp 
             into ls_cnta_prsp 
             from concepto_tip_trab_cnta c
            where c.concep = rc_gan.concep 
              and c.tipo_trabajador = rc_mae.tipo_trabajador ;
        ELSE
           ls_cnta_prsp := NULL;
        END IF;
        
         
        if ls_cnta_prsp IS NOT NULL then
           ln_imp01_fij := (ln_importe * nvl(ani_factor_01,1)) / ani_tipcam_01 ;
           ln_imp02_fij := (ln_importe * nvl(ani_factor_02,1)) / ani_tipcam_02 ;
           ln_imp03_fij := (ln_importe * nvl(ani_factor_03,1)) / ani_tipcam_03 ;
           ln_imp04_fij := (ln_importe * nvl(ani_factor_04,1)) / ani_tipcam_04 ;
           ln_imp05_fij := (ln_importe * nvl(ani_factor_05,1)) / ani_tipcam_05 ;
           ln_imp06_fij := (ln_importe * nvl(ani_factor_06,1)) / ani_tipcam_06 ;
           ln_imp07_fij := (ln_importe * nvl(ani_factor_07,1)) / ani_tipcam_07 ;
           ln_imp08_fij := (ln_importe * nvl(ani_factor_08,1)) / ani_tipcam_08 ;
           ln_imp09_fij := (ln_importe * nvl(ani_factor_09,1)) / ani_tipcam_09 ;
           ln_imp10_fij := (ln_importe * nvl(ani_factor_10,1)) / ani_tipcam_10 ;
           ln_imp11_fij := (ln_importe * nvl(ani_factor_11,1)) / ani_tipcam_11 ;
           ln_imp12_fij := (ln_importe * nvl(ani_factor_12,1)) / ani_tipcam_12 ;
           
           FOR ln_mes IN 1..12 LOOP
              -- Captuto importes segun mes
              IF ln_mes = 1 THEN
                 ln_impor_fij := ln_imp01_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_impor_fij := ln_imp02_fij ;
              ELSIF ln_mes = 3 THEN
                 ln_impor_fij := ln_imp03_fij ;
              ELSIF ln_mes = 4 THEN
                 ln_impor_fij := ln_imp04_fij ;
              ELSIF ln_mes = 5 THEN
                 ln_impor_fij := ln_imp05_fij ;
              ELSIF ln_mes = 6 THEN
                 ln_impor_fij := ln_imp06_fij ;
              ELSIF ln_mes = 7 THEN
                 ln_impor_fij := ln_imp07_fij ;
              ELSIF ln_mes = 8 THEN
                 ln_impor_fij := ln_imp08_fij ;
              ELSIF ln_mes = 9 THEN
                 ln_impor_fij := ln_imp09_fij ;
              ELSIF ln_mes = 10 THEN
                 ln_impor_fij := ln_imp10_fij ;
              ELSIF ln_mes = 11 THEN
                 ln_impor_fij := ln_imp11_fij ;
              ELSIF ln_mes = 12 THEN
                 ln_impor_fij := ln_imp12_fij ;
              END IF ;
              
              IF asi_preview = '1' THEN
                  -- Actualizando datos en tabla temporal
                  IF ln_impor_fij <> 0 THEN
                     UPDATE tt_pto_presupuesto_det t
                        SET t.costo_unit = NVL(t.costo_unit, 0) + ln_impor_fij
                      WHERE t.ano             = ani_periodo
                        AND t.cencos          = rc_mae.cencos
                        AND t.cnta_prsp       = ls_cnta_prsp
                        AND t.mes_corresp     = ln_mes
                        AND t.cod_origen      = rc_mae.cod_origen
                        AND t.tipo_trabajador = rc_mae.tipo_trabajador
                        AND t.situa_trabaj    = rc_mae.situa_trabaj
                        AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                     
                     IF SQL%NOTFOUND THEN
                        INSERT INTO tt_pto_presupuesto_det(
                            ano, cencos, cnta_prsp, mes_corresp, fecha, 
                            flag_proceso, comentario, cod_usr, cantidad, 
                            costo_unit, tipo_trabajador, situa_trabaj,
                            cod_origen, centro_benef)
                        VALUES(
                            ani_periodo, rc_mae.cencos, ls_cnta_prsp, ln_mes, SYSDATE,
                            'A', ls_comentario, asi_usuario, 1,
                            ln_impor_fij, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                            rc_mae.cod_origen, rc_mae.centro_benef);
                     END IF;
                  END IF;
              ELSE
                  -- Actualizando datos en tabla de presupuesto detalle
                  IF ln_impor_fij <> 0 THEN
                     UPDATE presupuesto_det t
                        SET t.costo_unit = NVL(t.costo_unit, 0) + ln_impor_fij
                      WHERE t.ano             = ani_periodo
                        AND t.cencos          = rc_mae.cencos
                        AND t.cnta_prsp       = ls_cnta_prsp
                        AND t.mes_corresp     = ln_mes
                        AND t.cod_origen      = rc_mae.cod_origen
                        AND t.tipo_trabajador = rc_mae.tipo_trabajador
                        AND t.situa_trabaj    = rc_mae.situa_trabaj
                        AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                     
                     IF SQL%NOTFOUND THEN
                        INSERT INTO presupuesto_det(
                            ano, cencos, cnta_prsp, mes_corresp, fecha, 
                            flag_proceso, comentario, cod_usr, cantidad, 
                            costo_unit, tipo_trabajador, situa_trabaj,
                            cod_origen, centro_benef)
                        VALUES(
                            ani_periodo, rc_mae.cencos, ls_cnta_prsp, ln_mes, SYSDATE,
                            'A', ls_comentario, asi_usuario, 1,
                            ln_impor_fij, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                            rc_mae.cod_origen, rc_mae.centro_benef);
                     END IF;
                  END IF;
              END IF ;
              IF ln_mes = 1 THEN               
                 ln_imp01_fix := ln_imp01_fix + ln_imp01_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp02_fix := ln_imp02_fix + ln_imp02_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp03_fix := ln_imp03_fix + ln_imp03_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp04_fix := ln_imp04_fix + ln_imp04_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp05_fix := ln_imp05_fix + ln_imp05_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp06_fix := ln_imp06_fix + ln_imp06_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp07_fix := ln_imp07_fix + ln_imp07_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp08_fix := ln_imp08_fix + ln_imp08_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp09_fix := ln_imp09_fix + ln_imp09_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp10_fix := ln_imp10_fix + ln_imp10_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp11_fix := ln_imp11_fix + ln_imp11_fij ;
              ELSIF ln_mes = 2 THEN
                 ln_imp12_fix := ln_imp12_fix + ln_imp12_fij ;
              END IF ;
           END LOOP ;
         END IF ;
      END LOOP ;
           
    
    /*
    --  ******************************************************************
    --  ***   GENERA GANANCIAS VARIABLES APLICANDO PROMEDIOS SIMPLES   ***
    --  ******************************************************************
    ln_imp01_var := 0 ;  ln_imp02_var := 0 ;  ln_imp03_var := 0 ;
    ln_imp04_var := 0 ;  ln_imp05_var := 0 ;  ln_imp06_var := 0 ;
    ln_imp07_var := 0 ;  ln_imp08_var := 0 ;  ln_imp09_var := 0 ;
    ln_imp10_var := 0 ;  ln_imp11_var := 0 ;  ln_imp12_var := 0 ;
    ln_imp01_vax := 0 ;  ln_imp02_vax := 0 ;  ln_imp03_vax := 0 ;
    ln_imp04_vax := 0 ;  ln_imp05_vax := 0 ;  ln_imp06_vax := 0 ;
    ln_imp07_vax := 0 ;  ln_imp08_vax := 0 ;  ln_imp09_vax := 0 ;
    ln_imp10_vax := 0 ;  ln_imp11_vax := 0 ;  ln_imp12_vax := 0 ;
    ln_gan_variables := 0 ;
    
    for rc_con in c_concepto loop
        ld_rani_ini   := add_months(ld_fec_proceso, - 1) ;
        ln_nro_meses := 0 ; ln_acumulado := 0 ;
        
        for x in reverse 1 .. 6 loop
            ld_rani_fin := ld_rani_ini ;
            ld_rani_ini := add_months( ld_rani_fin, -1 ) + 1 ;
            ln_importe := 0 ; 
            select count(*)
              into ln_count
              from historico_calculo hc
              where hc.concep = rc_con.concepto_calc 
                and hc.cod_trabajador = rc_mae.cod_trabajador 
                AND trunc(hc.fec_calc_plan) between trunc(ld_rani_ini) and trunc(ld_rani_fin) ;
                
            if ln_count > 0 AND lk_racion_cocida IS NOT NULL then
               select g.concepto_gen 
                 into ls_concepto 
                 from grupo_calculo g
                where g.grupo_calculo = lk_racion_cocida ;
                
                select sum(hc.imp_soles)
                  into ln_importe
                  from historico_calculo hc
                 where hc.concep = rc_con.concepto_calc 
                   and hc.cod_trabajador = rc_mae.cod_trabajador 
                   AND trunc(hc.fec_calc_plan) between trunc(ld_rani_ini) and trunc(ld_rani_fin) ;
                    
                if rc_con.concepto_calc = lk_racion_cocida then
                   if rc_mae.cod_seccion <> '682' or rc_mae.cod_seccion <> '683' then
                      ln_importe := 0 ;
                   end if ;
                end if ;
                
                if ln_importe <> 0 then
                   ln_nro_meses := ln_nro_meses + 1 ;
                   ln_acumulado := ln_acumulado + ln_importe ;
                end if ;
            end if ;
            ld_rani_ini := ld_rani_ini - 1 ;
        end loop ;
        if ln_nro_meses > 2 then
           ln_importe       := ln_acumulado / ln_nro_meses ;
           ln_gan_variables := ln_gan_variables + ln_importe ;
        end if ;
    end loop ;
    
    if ln_gan_variables <> 0 then
       select g.concepto_gen 
         into ls_concepto 
         from grupo_calculo g
        where g.grupo_calculo = lk_rem_basica ;
        
       if ls_bonificacion = '1' then
          ln_imp01_vax := (ln_gan_variables / ani_tipcam_01) * 0.35 ;
          ln_imp02_vax := (ln_gan_variables / ani_tipcam_02) * 0.35 ;
          ln_imp03_vax := (ln_gan_variables / ani_tipcam_03) * 0.35 ;
          ln_imp04_vax := (ln_gan_variables / ani_tipcam_04) * 0.35 ;
          ln_imp05_vax := (ln_gan_variables / ani_tipcam_05) * 0.35 ;
          ln_imp06_vax := (ln_gan_variables / ani_tipcam_06) * 0.35 ;
          ln_imp07_vax := (ln_gan_variables / ani_tipcam_07) * 0.35 ;
          ln_imp08_vax := (ln_gan_variables / ani_tipcam_08) * 0.35 ;
          ln_imp09_vax := (ln_gan_variables / ani_tipcam_09) * 0.35 ;
          ln_imp10_vax := (ln_gan_variables / ani_tipcam_10) * 0.35 ;
          ln_imp11_vax := (ln_gan_variables / ani_tipcam_11) * 0.35 ;
          ln_imp12_vax := (ln_gan_variables / ani_tipcam_12) * 0.35 ;
          
          SELECT COUNT(*)
            INTO ln_count
            from concepto_tip_trab_cnta c
           where c.concep          = ls_concepto 
             and c.tipo_trabajador = rc_mae.tipo_trabajador ;
          
          IF ln_count > 0 THEN   
             select c.cnta_prsp 
               into ls_cnta_prsp 
               from concepto_tip_trab_cnta c
              where c.concep          = ls_concepto 
                and c.tipo_trabajador = rc_mae.tipo_trabajador ;
          ELSE
             ls_cnta_prsp := NULL;
          END IF;
             
          if ls_cnta_prsp IS NOT NULL then
             IF asi_preview = '1' THEN
                -- Enero
                IF ln_imp01_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 1
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp01_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
      
                -- Febrero
                IF ln_imp02_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 2
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp02_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                          
                -- Marzo
                IF ln_imp03_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 3
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp03_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Abril
                IF ln_imp04_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 4
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp04_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Mayo
                IF ln_imp05_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 5
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp05_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Junio
                IF ln_imp06_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 6
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp06_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Julio
                IF ln_imp07_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 7
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp07_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Agosto
                IF ln_imp08_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 8
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp08_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Setiembre
                IF ln_imp09_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 9
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp09_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Octubre
                IF ln_imp10_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 10
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp10_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Noviembre
                IF ln_imp11_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 11
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp11_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Diciembre
                IF ln_imp12_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 12
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO tt_pto_presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp12_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
             ELSE
                -- Enero
                IF ln_imp01_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 1
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp01_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
      
                -- Febrero
                IF ln_imp02_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 2
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp02_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                          
                -- Marzo
                IF ln_imp03_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 3
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp03_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Abril
                IF ln_imp04_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 4
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp04_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Mayo
                IF ln_imp05_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 5
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp05_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Junio
                IF ln_imp06_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 6
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp06_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Julio
                IF ln_imp07_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 7
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp07_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Agosto
                IF ln_imp08_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 8
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp08_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Setiembre
                IF ln_imp09_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 9
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp09_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Octubre
                IF ln_imp10_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 10
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp10_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Noviembre
                IF ln_imp11_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 11
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp11_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
                
                -- Diciembre
                IF ln_imp12_vax <> 0 THEN
                   UPDATE tt_pto_presupuesto_det t
                      SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_vax
                    WHERE t.ano             = ani_periodo
                      AND t.cencos          = rc_mae.cencos
                      AND t.cnta_prsp       = ls_cnta_prsp
                      AND t.mes_corresp     = 12
                      AND t.cod_origen      = rc_mae.cod_origen
                      AND t.tipo_trabajador = rc_mae.tipo_trabajador
                      AND t.situa_trabaj    = rc_mae.situa_trabaj
                      AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                   
                   IF SQL%NOTFOUND THEN
                      INSERT INTO presupuesto_det(
                          ano, cencos, cnta_prsp, mes_corresp, fecha, 
                          flag_proceso, comentario, cod_usr, cantidad, 
                          costo_unit, tipo_trabajador, situa_trabaj,
                          cod_origen, centro_benef)
                      VALUES(
                          ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                          'A', ls_comentario, asi_usuario, 1,
                          ln_imp12_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                          rc_mae.cod_origen, rc_mae.centro_benef);
                   END IF;
                END IF;
             END IF;
          end if ;
        
      elsif ls_bonificacion = '2' THEN
      
        ln_imp01_vax := (ln_gan_variables / ani_tipcam_01) * 0.30 ;
        ln_imp02_vax := (ln_gan_variables / ani_tipcam_02) * 0.30 ;
        ln_imp03_vax := (ln_gan_variables / ani_tipcam_03) * 0.30 ;
        ln_imp04_vax := (ln_gan_variables / ani_tipcam_04) * 0.30 ;
        ln_imp05_vax := (ln_gan_variables / ani_tipcam_05) * 0.30 ;
        ln_imp06_vax := (ln_gan_variables / ani_tipcam_06) * 0.30 ;
        ln_imp07_vax := (ln_gan_variables / ani_tipcam_07) * 0.30 ;
        ln_imp08_vax := (ln_gan_variables / ani_tipcam_08) * 0.30 ;
        ln_imp09_vax := (ln_gan_variables / ani_tipcam_09) * 0.30 ;
        ln_imp10_vax := (ln_gan_variables / ani_tipcam_10) * 0.30 ;
        ln_imp11_vax := (ln_gan_variables / ani_tipcam_11) * 0.30 ;
        ln_imp12_vax := (ln_gan_variables / ani_tipcam_12) * 0.30 ;
        
        SELECT COUNT(*)
          INTO ln_count
          from concepto_tip_trab_cnta c
         where c.concep          = ls_concepto 
           and c.tipo_trabajador = rc_mae.tipo_trabajador ;
        
        IF ln_count > 0 THEN   
           select c.cnta_prsp 
             into ls_cnta_prsp 
             from concepto_tip_trab_cnta c
            where c.concep          = ls_concepto 
              and c.tipo_trabajador = rc_mae.tipo_trabajador ;
        ELSE
           ls_cnta_prsp := NULL;
        END IF;
                     
        if ls_cnta_prsp IS NOT NULL then
           IF asi_preview = '1' THEN
              -- Enero
              IF ln_imp01_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 1
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp01_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
    
              -- Febrero
              IF ln_imp02_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 2
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp02_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
                        
              -- Marzo
              IF ln_imp03_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 3
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp03_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Abril
              IF ln_imp04_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 4
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp04_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Mayo
              IF ln_imp05_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 5
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp05_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Junio
              IF ln_imp06_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 6
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp06_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Julio
              IF ln_imp07_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 7
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp07_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Agosto
              IF ln_imp08_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 8
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp08_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Setiembre
              IF ln_imp09_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 9
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp09_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Octubre
              IF ln_imp10_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 10
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp10_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Noviembre
              IF ln_imp11_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 11
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp11_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Diciembre
              IF ln_imp12_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 12
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp12_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
           ELSE
              -- Enero
              IF ln_imp01_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 1
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp01_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
    
              -- Febrero
              IF ln_imp02_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 2
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp02_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
                        
              -- Marzo
              IF ln_imp03_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 3
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp03_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Abril
              IF ln_imp04_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 4
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp04_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Mayo
              IF ln_imp05_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 5
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp05_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Junio
              IF ln_imp06_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 6
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp06_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Julio
              IF ln_imp07_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 7
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp07_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Agosto
              IF ln_imp08_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 8
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp08_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Setiembre
              IF ln_imp09_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 9
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp09_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Octubre
              IF ln_imp10_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 10
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp10_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Noviembre
              IF ln_imp11_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 11
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp11_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Diciembre
              IF ln_imp12_vax <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_vax
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 12
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp12_vax, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
           END IF;
        end if ;
      end if ;
      
      SELECT COUNT(*)
        INTO ln_count
        from grupo_calculo g
       where g.grupo_calculo = lk_promedio_var ;
      
      IF ln_count > 0 THEN
         select g.concepto_gen 
           into ls_concepto 
           from grupo_calculo g
          where g.grupo_calculo = lk_promedio_var ;
    
         SELECT COUNT(*)
           INTO ln_count
           from concepto_tip_trab_cnta c
          where c.concep = ls_concepto 
            and c.tipo_trabajador = rc_mae.tipo_trabajador ;
         
         IF ln_count > 0 THEN
            select c.cnta_prsp 
              into ls_cnta_prsp 
              from concepto_tip_trab_cnta c
             where c.concep = ls_concepto 
               and c.tipo_trabajador = rc_mae.tipo_trabajador ;
         ELSE
            ls_cnta_prsp := NULL;
         END IF;  
      
      END IF;

      ln_imp01_var := (ln_gan_variables * nvl(ani_factor_01,1)) / ani_tipcam_01 ;
      ln_imp02_var := (ln_gan_variables * nvl(ani_factor_02,1)) / ani_tipcam_02 ;
      ln_imp03_var := (ln_gan_variables * nvl(ani_factor_03,1)) / ani_tipcam_03 ;
      ln_imp04_var := (ln_gan_variables * nvl(ani_factor_04,1)) / ani_tipcam_04 ;
      ln_imp05_var := (ln_gan_variables * nvl(ani_factor_05,1)) / ani_tipcam_05 ;
      ln_imp06_var := (ln_gan_variables * nvl(ani_factor_06,1)) / ani_tipcam_06 ;
      ln_imp07_var := (ln_gan_variables * nvl(ani_factor_07,1)) / ani_tipcam_07 ;
      ln_imp08_var := (ln_gan_variables * nvl(ani_factor_08,1)) / ani_tipcam_08 ;
      ln_imp09_var := (ln_gan_variables * nvl(ani_factor_09,1)) / ani_tipcam_09 ;
      ln_imp10_var := (ln_gan_variables * nvl(ani_factor_10,1)) / ani_tipcam_10 ;
      ln_imp11_var := (ln_gan_variables * nvl(ani_factor_11,1)) / ani_tipcam_11 ;
      ln_imp12_var := (ln_gan_variables * nvl(ani_factor_12,1)) / ani_tipcam_12 ;
      
      IF ls_cnta_prsp IS NOT NULL THEN
          IF asi_preview = '1' THEN
              -- Enero
              IF ln_imp01_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 1
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp01_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
    
              -- Febrero
              IF ln_imp02_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 2
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp02_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
                        
              -- Marzo
              IF ln_imp03_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 3
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp03_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Abril
              IF ln_imp04_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 4
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp04_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Mayo
              IF ln_imp05_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 5
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp05_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Junio
              IF ln_imp06_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 6
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp06_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Julio
              IF ln_imp07_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 7
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp07_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Agosto
              IF ln_imp08_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 8
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp08_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Setiembre
              IF ln_imp09_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 9
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp09_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Octubre
              IF ln_imp10_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 10
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp10_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Noviembre
              IF ln_imp11_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 11
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp11_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Diciembre
              IF ln_imp12_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 12
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO tt_pto_presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp12_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
           ELSE
              -- Enero
              IF ln_imp01_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 1
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp01_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
    
              -- Febrero
              IF ln_imp02_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 2
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp02_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
                        
              -- Marzo
              IF ln_imp03_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 3
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp03_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Abril
              IF ln_imp04_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 4
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp04_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Mayo
              IF ln_imp05_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 5
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp05_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Junio
              IF ln_imp06_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 6
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp06_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Julio
              IF ln_imp07_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 7
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp07_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Agosto
              IF ln_imp08_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 8
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp08_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Setiembre
              IF ln_imp09_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 9
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp09_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Octubre
              IF ln_imp10_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 10
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp10_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Noviembre
              IF ln_imp11_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 11
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp11_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
              
              -- Diciembre
              IF ln_imp12_var <> 0 THEN
                 UPDATE tt_pto_presupuesto_det t
                    SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_var
                  WHERE t.ano             = ani_periodo
                    AND t.cencos          = rc_mae.cencos
                    AND t.cnta_prsp       = ls_cnta_prsp
                    AND t.mes_corresp     = 12
                    AND t.cod_origen      = rc_mae.cod_origen
                    AND t.tipo_trabajador = rc_mae.tipo_trabajador
                    AND t.situa_trabaj    = rc_mae.situa_trabaj
                    AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                 
                 IF SQL%NOTFOUND THEN
                    INSERT INTO presupuesto_det(
                        ano, cencos, cnta_prsp, mes_corresp, fecha, 
                        flag_proceso, comentario, cod_usr, cantidad, 
                        costo_unit, tipo_trabajador, situa_trabaj,
                        cod_origen, centro_benef)
                    VALUES(
                        ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                        'A', ls_comentario, asi_usuario, 1,
                        ln_imp12_var, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                        rc_mae.cod_origen, rc_mae.centro_benef);
                 END IF;
              END IF;
           END IF;      
      END IF;
      
    end if ;
  
    --  *********************************************************
    --  ***   GENERA GRATIFICACIONES PARA JULIO Y DICIEMBRE   ***
    --  *********************************************************
    ln_gratif_jul := (ln_imp07_fix + ln_imp07_var) ;
    ln_gratif_dic := (ln_imp12_fix + ln_imp12_var) ;

    select g.concepto_gen 
      into ls_concepto 
      from grupo_calculo g
     where g.grupo_calculo = lk_gratif_julio ;
     
    select c.cnta_prsp 
      into ls_cnta_prsp 
      from concepto_tip_trab_cnta c
     where c.concep = ls_concepto 
       and c.tipo_trabajador = rc_mae.tipo_trabajador ;
       
     IF asi_preview = '1' THEN
        -- Julio
        IF ln_gratif_jul <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_gratif_jul
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 7
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_gratif_jul, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Diciembre
        IF ln_gratif_dic <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_gratif_dic
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 12
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_gratif_dic, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
     ELSE
        -- Julio
        IF ln_gratif_jul <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_gratif_jul
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 7
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_gratif_jul, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Diciembre
        IF ln_gratif_dic <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_gratif_dic
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 12
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_gratif_dic, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
     END IF;
       
    --  ***************************************************
    --  ***   CALCULO DE BONIFICACION POR QUINQUENIOS   ***
    --  ***************************************************
    ln_imp01_qui := 0 ;  ln_imp02_qui := 0 ;  ln_imp03_qui := 0 ;
    ln_imp04_qui := 0 ;  ln_imp05_qui := 0 ;  ln_imp06_qui := 0 ;
    ln_imp07_qui := 0 ;  ln_imp08_qui := 0 ;  ln_imp09_qui := 0 ;
    ln_imp10_qui := 0 ;  ln_imp11_qui := 0 ;  ln_imp12_qui := 0 ;
    ld_fec_quinque := to_date(to_char(ld_fec_ingreso,'dd/mm') ||'/'||
                      to_char(ani_periodo),'DD/MM/YYYY') ;
    ln_years := months_between(ld_fec_quinque,ld_fec_ingreso) / 12 ;
    if ln_years > 5 then
      ln_quinquenio := trunc(ln_years) ; 
      select count(*) 
        into ln_count 
        from quinquenio q
       where q.quinquenio = ln_quinquenio 
         AND to_char(ld_fec_ingreso,'MM') = to_char(ld_fec_quinque,'MM') ;
         
      if ln_count > 0 then
         select nvl(q.jornal,0) 
           into ln_jornal 
           from quinquenio q
          where q.quinquenio = ln_quinquenio;
         if ls_mes_ingreso = '01' then
            ln_imp01_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '02' then
            ln_imp02_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '03' then
            ln_imp03_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '04' then
            ln_imp04_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '05' then
            ln_imp05_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '06' then
            ln_imp06_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '07' then
            ln_imp07_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '08' then
            ln_imp08_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '09' then
            ln_imp09_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '10' then
            ln_imp10_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '11' then
            ln_imp11_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         elsif ls_mes_ingreso = '12' then
            ln_imp12_qui := (ln_imp04_fix / 30 * ln_jornal) ;
         end if ;
         select g.concepto_gen 
           into ls_concepto 
           from grupo_calculo g
          where g.grupo_calculo = lk_quinquenio ;
          
        select c.cnta_prsp 
          into ls_cnta_prsp 
          from concepto_tip_trab_cnta c
         where c.concep = ls_concepto 
           and c.tipo_trabajador = rc_mae.tipo_trabajador ;
        
        IF asi_preview = '1' THEN
          -- Enero
          IF ln_imp01_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 1
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp01_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;

          -- Febrero
          IF ln_imp02_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 2
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp02_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
                    
          -- Marzo
          IF ln_imp03_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 3
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp03_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Abril
          IF ln_imp04_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 4
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp04_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Mayo
          IF ln_imp05_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 5
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp05_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Junio
          IF ln_imp06_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 6
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp06_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Julio
          IF ln_imp07_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 7
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp07_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Agosto
          IF ln_imp08_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 8
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp08_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Setiembre
          IF ln_imp09_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 9
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp09_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Octubre
          IF ln_imp10_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 10
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp10_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Noviembre
          IF ln_imp11_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 11
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp11_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Diciembre
          IF ln_imp12_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 12
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO tt_pto_presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp12_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
       ELSE
          -- Enero
          IF ln_imp01_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 1
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp01_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;

          -- Febrero
          IF ln_imp02_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 2
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp02_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
                    
          -- Marzo
          IF ln_imp03_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 3
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp03_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Abril
          IF ln_imp04_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 4
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp04_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Mayo
          IF ln_imp05_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 5
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp05_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Junio
          IF ln_imp06_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 6
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp06_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Julio
          IF ln_imp07_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 7
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp07_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Agosto
          IF ln_imp08_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 8
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp08_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Setiembre
          IF ln_imp09_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 9
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp09_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Octubre
          IF ln_imp10_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 10
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp10_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Noviembre
          IF ln_imp11_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 11
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp11_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
          
          -- Diciembre
          IF ln_imp12_qui <> 0 THEN
             UPDATE tt_pto_presupuesto_det t
                SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_qui
              WHERE t.ano             = ani_periodo
                AND t.cencos          = rc_mae.cencos
                AND t.cnta_prsp       = ls_cnta_prsp
                AND t.mes_corresp     = 12
                AND t.cod_origen      = rc_mae.cod_origen
                AND t.tipo_trabajador = rc_mae.tipo_trabajador
                AND t.situa_trabaj    = rc_mae.situa_trabaj
                AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
             
             IF SQL%NOTFOUND THEN
                INSERT INTO presupuesto_det(
                    ano, cencos, cnta_prsp, mes_corresp, fecha, 
                    flag_proceso, comentario, cod_usr, cantidad, 
                    costo_unit, tipo_trabajador, situa_trabaj,
                    cod_origen, centro_benef)
                VALUES(
                    ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                    'A', ls_comentario, asi_usuario, 1,
                    ln_imp12_qui, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                    rc_mae.cod_origen, rc_mae.centro_benef);
             END IF;
          END IF;
       END IF;
      END IF;
    end if ;
  
    --  **********************************************************
    --  ***   CALCULA ASIGNACION ESCOLAR POR NUMERO DE HIJOS   ***
    --  **********************************************************
    IF ani_asiesc > 0 AND lk_asig_escolar IS NOT NULL THEN
        ln_importe := 0 ;
        select count(*) 
          into ln_count 
          from carga_familiar f
         where f.cod_trabajador = rc_mae.cod_trabajador ;
         
        if ln_count > 0 then
           ln_nro_meses := 0 ;
           for rc_car in c_carga(rc_mae.cod_trabajador) loop
               ld_fec_asiesc := to_date('31/12/' || to_char(ani_periodo),'dd/mm/yyyy') ;
               ln_years := months_between(ld_fec_asiesc,rc_car.fec_nacimiento) / 12 ;
               if ln_years >= 3 and ln_years < 23 then
                  ln_nro_meses := ln_nro_meses + 1 ;
               end if;
           end loop ;
           if ln_nro_meses > 0 then
              ln_importe := (ani_asiesc / ani_tipcam_03) * ln_nro_meses ;
              select g.concepto_gen 
                into ls_concepto 
                from grupo_calculo g
               where g.grupo_calculo = lk_asig_escolar ;
              
              SELECT COUNT(*)
                INTO ln_count
                from concepto_tip_trab_cnta c
               where c.concep = ls_concepto 
                 and c.tipo_trabajador = rc_mae.tipo_trabajador ;
              
              IF ln_count > 0 AND ls_cnta_prsp IS NOT NULL THEN
                  select c.cnta_prsp 
                    into ls_cnta_prsp 
                    from concepto_tip_trab_cnta c
                   where c.concep = ls_concepto 
                     and c.tipo_trabajador = rc_mae.tipo_trabajador ;
                     
                  IF asi_preview = '1' THEN
                      -- Marzo
                      IF ln_importe <> 0 THEN
                         UPDATE tt_pto_presupuesto_det t
                            SET t.costo_unit = NVL(t.costo_unit, 0) + ln_importe
                          WHERE t.ano             = ani_periodo
                            AND t.cencos          = rc_mae.cencos
                            AND t.cnta_prsp       = ls_cnta_prsp
                            AND t.mes_corresp     = 3
                            AND t.cod_origen      = rc_mae.cod_origen
                            AND t.tipo_trabajador = rc_mae.tipo_trabajador
                            AND t.situa_trabaj    = rc_mae.situa_trabaj
                            AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                         
                         IF SQL%NOTFOUND THEN
                            INSERT INTO tt_pto_presupuesto_det(
                                ano, cencos, cnta_prsp, mes_corresp, fecha, 
                                flag_proceso, comentario, cod_usr, cantidad, 
                                costo_unit, tipo_trabajador, situa_trabaj,
                                cod_origen, centro_benef)
                            VALUES(
                                ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                                'A', ls_comentario, asi_usuario, 1,
                                ln_importe, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                                rc_mae.cod_origen, rc_mae.centro_benef);
                         END IF;
                      END IF;
                      
                   ELSE
                      -- Marzo
                      IF ln_importe <> 0 THEN
                         UPDATE tt_pto_presupuesto_det t
                            SET t.costo_unit = NVL(t.costo_unit, 0) + ln_importe
                          WHERE t.ano             = ani_periodo
                            AND t.cencos          = rc_mae.cencos
                            AND t.cnta_prsp       = ls_cnta_prsp
                            AND t.mes_corresp     = 3
                            AND t.cod_origen      = rc_mae.cod_origen
                            AND t.tipo_trabajador = rc_mae.tipo_trabajador
                            AND t.situa_trabaj    = rc_mae.situa_trabaj
                            AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
                         
                         IF SQL%NOTFOUND THEN
                            INSERT INTO presupuesto_det(
                                ano, cencos, cnta_prsp, mes_corresp, fecha, 
                                flag_proceso, comentario, cod_usr, cantidad, 
                                costo_unit, tipo_trabajador, situa_trabaj,
                                cod_origen, centro_benef)
                            VALUES(
                                ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                                'A', ls_comentario, asi_usuario, 1,
                                ln_importe, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                                rc_mae.cod_origen, rc_mae.centro_benef);
                         END IF;
                      END IF;
                      
                   END IF;
              END IF;
          end if ;
        end if;
    END IF;
  
    --  *************************************************************
    --  ***   CALCULA APORTACIONES DE LA EMPRESA POR TRABAJADOR   ***
    --  *************************************************************
    select count(*) 
      into ln_count 
      from vacac_bonif_deveng b
     where b.cod_trabajador = rc_mae.cod_trabajador
       and b.flag_estado    = '1' ;
       
    if ln_count > 0 then
       select sum(nvl(b.sldo_dias_bonif,0)) 
         into ln_bonvac
         from vacac_bonif_deveng b
        where b.cod_trabajador = rc_mae.cod_trabajador 
          and b.flag_estado = '1' ;
       
       ln_importe := ln_imp01_fij * (ln_bonvac / 30) ;
    end if ;
    
    --  Seguro Agrario
    select g.concepto_gen 
      into ls_concepto 
      from grupo_calculo g
     where g.grupo_calculo = lk_seguro_agrario ;
    
    select nvl(c.fact_pago,0) 
      into ln_factor 
      from concepto c
     where c.concep = ls_concepto ;
     
    select c.cnta_prsp 
      into ls_cnta_prsp 
      from concepto_tip_trab_cnta c
     where c.concep = ls_concepto 
       and c.tipo_trabajador = rc_mae.tipo_trabajador ;
       
    ln_imp01_apo := (ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor ;
    ln_imp02_apo := (ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor ;
    ln_imp03_apo := (ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor ;
    ln_imp04_apo := (ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor ;
    ln_imp05_apo := (ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor ;
    ln_imp06_apo := (ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor ;
    ln_imp07_apo := (ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor ;
    ln_imp08_apo := (ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor ;
    ln_imp09_apo := (ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor ;
    ln_imp10_apo := (ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor ;
    ln_imp11_apo := (ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor ;
    ln_imp12_apo := (ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor ;
    
    --  SENATI
    select count(*) 
      into ln_count
      from seccion s
     where s.cod_area = lk_seccion_senati 
       and s.cod_seccion = rc_mae.cod_seccion ;
       
    if ln_count > 0 then
       select g.concepto_gen 
         into ls_concepto 
         from grupo_calculo g
        where g.grupo_calculo = lk_senati ;
        
       select nvl(c.fact_pago,0) 
         into ln_factor
         from concepto c 
        where c.concep = ls_concepto ;
        
       ln_imp01_apo := ln_imp01_apo + ((ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor) ;
       ln_imp02_apo := ln_imp02_apo + ((ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor) ;
       ln_imp03_apo := ln_imp03_apo + ((ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor) ;
       ln_imp04_apo := ln_imp04_apo + ((ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor) ;
       ln_imp05_apo := ln_imp05_apo + ((ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor) ;
       ln_imp06_apo := ln_imp06_apo + ((ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor) ;
       ln_imp07_apo := ln_imp07_apo + ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor) ;
       ln_imp08_apo := ln_imp08_apo + ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor) ;
       ln_imp09_apo := ln_imp09_apo + ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor) ;
       ln_imp10_apo := ln_imp10_apo + ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor) ;
       ln_imp11_apo := ln_imp11_apo + ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor) ;
       ln_imp12_apo := ln_imp12_apo + ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor) ;
    end if ;
    
    --  S.C.T.R. I.P.S.S.
    select nvl(s.porc_sctr_ipss,0) 
      into ln_factor 
      from seccion s
      where s.cod_seccion = rc_mae.cod_seccion 
        and s.cod_area    = rc_mae.cod_area ;
        
    if ln_factor > 0 then
       ln_imp01_apo := ln_imp01_apo + ((ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor / 100) ;
       ln_imp02_apo := ln_imp02_apo + ((ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor / 100) ;
       ln_imp03_apo := ln_imp03_apo + ((ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor / 100) ;
       ln_imp04_apo := ln_imp04_apo + ((ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor / 100) ;
       ln_imp05_apo := ln_imp05_apo + ((ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor / 100) ;
       ln_imp06_apo := ln_imp06_apo + ((ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor / 100) ;
       ln_imp07_apo := ln_imp07_apo + ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor / 100) ;
       ln_imp08_apo := ln_imp08_apo + ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor / 100) ;
       ln_imp09_apo := ln_imp09_apo + ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor / 100) ;
       ln_imp10_apo := ln_imp10_apo + ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor / 100) ;
       ln_imp11_apo := ln_imp11_apo + ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor / 100) ;
       ln_imp12_apo := ln_imp12_apo + ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor / 100) ;
    end if ;
    
    --  S.C.T.R. O.N.P.
    select nvl(s.porc_sctr_onp,0) 
      into ln_factor 
      from seccion s
     where s.cod_seccion = rc_mae.cod_seccion 
       and s.cod_area    = rc_mae.cod_area ;
       
    if ln_factor > 0 then
       ln_imp01_apo := ln_imp01_apo + ((ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor / 100) ;
       ln_imp02_apo := ln_imp02_apo + ((ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor / 100) ;
       ln_imp03_apo := ln_imp03_apo + ((ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor / 100) ;
       ln_imp04_apo := ln_imp04_apo + ((ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor / 100) ;
       ln_imp05_apo := ln_imp05_apo + ((ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor / 100) ;
       ln_imp06_apo := ln_imp06_apo + ((ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor / 100) ;
       ln_imp07_apo := ln_imp07_apo + ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor / 100) ;
       ln_imp08_apo := ln_imp08_apo + ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor / 100) ;
       ln_imp09_apo := ln_imp09_apo + ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor / 100) ;
       ln_imp10_apo := ln_imp10_apo + ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor / 100) ;
       ln_imp11_apo := ln_imp11_apo + ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor / 100) ;
       ln_imp12_apo := ln_imp12_apo + ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor / 100) ;
    end if ;
  
  IF asi_preview = '1' THEN
        -- Enero
        IF ln_imp01_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 1
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp01_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;

        -- Febrero
        IF ln_imp02_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 2
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp02_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
                  
        -- Marzo
        IF ln_imp03_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 3
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp03_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Abril
        IF ln_imp04_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 4
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp04_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Mayo
        IF ln_imp05_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 5
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp05_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Junio
        IF ln_imp06_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 6
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp06_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Julio
        IF ln_imp07_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 7
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp07_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Agosto
        IF ln_imp08_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 8
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp08_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Setiembre
        IF ln_imp09_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 9
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp09_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Octubre
        IF ln_imp10_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 10
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp10_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Noviembre
        IF ln_imp11_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 11
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp11_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Diciembre
        IF ln_imp12_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 12
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp12_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
     ELSE
        -- Enero
        IF ln_imp01_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 1
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp01_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;

        -- Febrero
        IF ln_imp02_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 2
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp02_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
                  
        -- Marzo
        IF ln_imp03_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 3
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp03_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Abril
        IF ln_imp04_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 4
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp04_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Mayo
        IF ln_imp05_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 5
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp05_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Junio
        IF ln_imp06_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 6
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp06_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Julio
        IF ln_imp07_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 7
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp07_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Agosto
        IF ln_imp08_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 8
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp08_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Setiembre
        IF ln_imp09_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 9
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp09_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Octubre
        IF ln_imp10_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 10
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp10_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Noviembre
        IF ln_imp11_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 11
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp11_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Diciembre
        IF ln_imp12_apo <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_apo
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 12
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp12_apo, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
     END IF;
       
    --  ********************************************
    --  ***   CALCULO DE PROVISIONES DE C.T.S.   ***
    --  ********************************************
    ln_imp01_cts := ((ln_imp01_fix + ln_imp01_apo + ln_imp01_vax) * 0.0833) ;
    ln_imp02_cts := ((ln_imp02_fix + ln_imp02_apo + ln_imp02_vax) * 0.0833) ;
    ln_imp03_cts := ((ln_imp03_fix + ln_imp03_apo + ln_imp03_vax) * 0.0833) ;
    ln_imp04_cts := ((ln_imp04_fix + ln_imp04_apo + ln_imp04_vax) * 0.0833) ;
    ln_imp05_cts := ((ln_imp05_fix + ln_imp05_apo + ln_imp05_vax) * 0.0833) ;
    ln_imp06_cts := ((ln_imp06_fix + ln_imp06_apo + ln_imp06_vax) * 0.0833) ;
    ln_imp07_cts := ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul) * 0.0833) ;
    ln_imp08_cts := ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax) * 0.0833) ;
    ln_imp09_cts := ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax) * 0.0833) ;
    ln_imp10_cts := ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax) * 0.0833) ;
    ln_imp11_cts := ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax) * 0.0833) ;
    ln_imp12_cts := ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic) * 0.0833) ;
    
    select g.concepto_gen 
      into ls_concepto 
      from grupo_calculo g
     where g.grupo_calculo = lk_cts ;

    select COUNT(*)
      into ln_count 
      from concepto_tip_trab_cnta c
     where c.concep          = ls_concepto 
       and c.tipo_trabajador = rc_mae.tipo_trabajador ;
     
    IF ln_count = 0 THEN
       RAISE_APPLICATION_ERROR(-20000, 'No existe Cuenta presupuestal para el concepto ' 
                                || ls_concepto || ' y el tipo de trabajador ' || rc_mae.tipo_trabajador);
    END IF;
    
    select c.cnta_prsp 
      into ls_cnta_prsp 
      from concepto_tip_trab_cnta c
     where c.concep = ls_concepto 
       and c.tipo_trabajador = rc_mae.tipo_trabajador ;
       
    IF asi_preview = '1' THEN
        -- Enero
        IF ln_imp01_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 1
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp01_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;

        -- Febrero
        IF ln_imp02_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 2
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp02_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
                  
        -- Marzo
        IF ln_imp03_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 3
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp03_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Abril
        IF ln_imp04_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 4
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp04_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Mayo
        IF ln_imp05_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 5
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp05_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Junio
        IF ln_imp06_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 6
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp06_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Julio
        IF ln_imp07_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 7
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp07_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Agosto
        IF ln_imp08_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 8
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp08_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Setiembre
        IF ln_imp09_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 9
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp09_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Octubre
        IF ln_imp10_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 10
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp10_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Noviembre
        IF ln_imp11_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 11
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp11_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Diciembre
        IF ln_imp12_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 12
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO tt_pto_presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp12_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
     ELSE
        -- Enero
        IF ln_imp01_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp01_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 1
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 1, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp01_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;

        -- Febrero
        IF ln_imp02_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp02_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 2
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 2, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp02_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
                  
        -- Marzo
        IF ln_imp03_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp03_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 3
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 3, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp03_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Abril
        IF ln_imp04_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp04_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 4
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 4, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp04_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Mayo
        IF ln_imp05_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp05_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 5
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 5, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp05_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Junio
        IF ln_imp06_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp06_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 6
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 6, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp06_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Julio
        IF ln_imp07_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp07_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 7
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 7, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp07_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Agosto
        IF ln_imp08_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp08_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 8
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 8, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp08_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Setiembre
        IF ln_imp09_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp09_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 9
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 9, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp09_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Octubre
        IF ln_imp10_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp10_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 10
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 10, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp10_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Noviembre
        IF ln_imp11_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp11_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 11
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 11, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp11_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
        -- Diciembre
        IF ln_imp12_cts <> 0 THEN
           UPDATE tt_pto_presupuesto_det t
              SET t.costo_unit = NVL(t.costo_unit, 0) + ln_imp12_cts
            WHERE t.ano             = ani_periodo
              AND t.cencos          = rc_mae.cencos
              AND t.cnta_prsp       = ls_cnta_prsp
              AND t.mes_corresp     = 12
              AND t.cod_origen      = rc_mae.cod_origen
              AND t.tipo_trabajador = rc_mae.tipo_trabajador
              AND t.situa_trabaj    = rc_mae.situa_trabaj
              AND NVL(t.centro_benef, ' ')    = NVL(rc_mae.centro_benef, ' ');
           
           IF SQL%NOTFOUND THEN
              INSERT INTO presupuesto_det(
                  ano, cencos, cnta_prsp, mes_corresp, fecha, 
                  flag_proceso, comentario, cod_usr, cantidad, 
                  costo_unit, tipo_trabajador, situa_trabaj,
                  cod_origen, centro_benef)
              VALUES(
                  ani_periodo, rc_mae.cencos, ls_cnta_prsp, 12, SYSDATE,
                  'A', ls_comentario, asi_usuario, 1,
                  ln_imp12_cts, rc_mae.tipo_trabajador, rc_mae.situa_trabaj,
                  rc_mae.cod_origen, rc_mae.centro_benef);
           END IF;
        END IF;
        
     END IF;
     */

  end loop ;

COMMIT;

end usp_rh_presupuesto_anual_mm ;
/
