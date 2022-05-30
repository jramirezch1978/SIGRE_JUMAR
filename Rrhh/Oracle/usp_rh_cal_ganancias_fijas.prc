create or replace procedure usp_rh_cal_ganancias_fijas (
  asi_codtra       in maestro.cod_trabajador%TYPE,
  adi_fec_proceso  in date,
  asi_origen       in origen.cod_origen%TYPE,
  ani_tipcam       in number,
  asi_tipo_trabaj  IN  maestro.tipo_trabajador%TYPE,      -- Tipo de trabajador
  ani_dias_trabaj  in out rrhhparam.dias_mes_obrero%TYPE,
  ani_dias_mes     in number,
  asi_tipo_planilla in calculo.tipo_planilla%TYPE
) is

ln_hortra             NUMBER ;
ln_imp_soles          calculo.imp_soles%TYPE ;
ln_imp_dolar          calculo.imp_dolar%TYPE ;
ls_tipo_obr           rrhhparam.tipo_trab_obrero%TYPE;
ls_tipo_des           rrhhParam.tipo_trab_destajo%TYPE;
ls_tipo_ser           rrhhparam.tipo_trab_servis%TYPE;
ld_fec_ini            DATE;
ld_fec_fin            DATE;
ln_count              number;
ln_dias_ejo           number;


--Conceptos para la asistencia de los jornaleros
ls_cnc_diu_normal     asistparam.cnc_diu_normal%TYPE;
ls_cnc_noc_normal     asistparam.cnc_noc_normal%TYPE;
ls_cnc_diu_ext1       asistparam.cnc_diu_ext1%TYPE;
ls_cnc_diu_ext2       asistparam.cnc_diu_ext2%TYPE;
ls_cnc_noc_ext1       asistparam.cnc_noc_ext1%TYPE;
ls_cnc_noc_ext2       asistparam.cnc_noc_ext2%TYPE;
ls_cnc_asig_familiar  asistparam.cnc_asig_familiar%TYPE;
ls_cnc_fer_nor        asistparam.cnc_fer_hrs_nor%TYPE;
ls_cnc_fer_ext1       asistparam.cnc_fer_hrs_ext1%TYPE;
ls_cnc_fer_ext2       asistparam.cnc_fer_hrs_ext2%TYPE;
ls_cnc_dom_nor        asistparam.cnc_dom_hrs_nor%TYPE;
ls_cnc_dom_ext1       asistparam.cnc_dom_hrs_ext1%TYPE;
ls_cnc_dom_ext2       asistparam.cnc_dom_hrs_ext2%TYPE;
ls_cnc_dominical      asistparam.cnc_dominical%TYPE;
ls_cnc_prima_frio     rrhhparam.cnc_prima_frio%TYPE;

-- Grupos
ls_grp_calc_jornal    grupo_calculo.grupo_calculo%TYPE;

ls_concepto           calculo.concep%TYPE;

ln_porc_diu_normal    asistparam.porc_diu_nor%TYPE;
ln_porc_noc_normal    asistparam.porc_noc_nor%TYPE;
ln_porc_diu_ext1      asistparam.porc_diu_ext1%TYPE;
ln_porc_diu_ext2      asistparam.porc_diu_ext2%TYPE;
ln_porc_noc_ext1      asistparam.porc_noc_ext1%TYPE;
ln_porc_noc_ext2      asistparam.porc_noc_ext1%TYPE;
ln_fac_feriado        asistparam.factor_feriado%TYPE;
ln_fac_dom            asistparam.factor_dominical%type;

ln_imp_hora           NUMBER;
ln_factor             NUMBER;
ln_asig_familiar      number;
ln_dias               calculo.dias_trabaj%TYPE;  -- Nro de dias
ls_flag_tipo_sueldo   tipo_trabajador.flag_ingreso_boleta%TYPE;
ls_sector_agrario     tipo_trabajador.flag_sector_agrario%TYPE;

-- conceptos para los destajeros
ls_cnc_dstjo_basico   prod_param.cnc_dstjo_basico%TYPE;
ls_cnc_dstjo_hd       prod_param.cnc_dstjo_hd%TYPE;
ls_cnc_dstjo_hn       prod_param.cnc_dstjo_hn%TYPE;

-- Emergencia
ls_cnc_gratif_ext     concepto.concep%TYPE;
ls_cnc_bon_gratif     concepto.concep%TYPE;
ln_porc_gratf         asistparam.porc_gratif_campo%TYPE;
ln_imp_gratif         number := 0;
ln_acum_grat          number := 0;
ln_tot_hrs_nor        number := 0;
ln_horas              number := 0;
ln_tot_horas          number := 0;
ln_imp_fijo           number := 0; -- Importe incluyendo asignacion familiar

--  Lectura de ganancias fijas por trabajador
cursor c_ganancias_fijas is
  SELECT G.CONCEP, G.IMP_GAN_DESC
    FROM GAN_DESCT_FIJO G
   WHERE G.COD_TRABAJADOR = ASI_CODTRA
     AND G.FLAG_ESTADO = '1'
     AND G.CONCEP IN (SELECT D.CONCEPTO_CALC
                        FROM GRUPO_CALCULO_DET D
                       WHERE D.GRUPO_CALCULO = (SELECT C.CONCEP_GAN_FIJ
                                                  FROM RRHHPARAM_CCONCEP C
                                                 WHERE C.RECKEY = '1'))
     AND G.CONCEP not in(ls_cnc_asig_familiar);

-- Horas de cada dia de la asistencia
CURSOR c_asist IS
  SELECT sum(NVL(a.hor_diu_nor,0) + NVL(a.hor_noc_nor,0)) AS hor_diu_nor,
         0 AS hor_noc_nor,
         sum(nvl(a.hor_ext_diu_1,0) + nvl(a.hor_ext_noc_1,0)) AS hor_ext_diu_1,
         sum(NVL(a.hor_ext_diu_2,0) + NVL(a.hor_ext_noc_2,0)) AS hor_ext_diu_2,
         0 AS hor_ext_noc_1,
         0 AS hor_ext_noc_2,
         sum(NVL(a.hor_ext_100,0)) AS hor_ext_100,
         a.fec_movim,
         NVL(a.flag_feriado, '0')  AS flag_feriado,
         NVL(a.flag_descanso, '0') AS flag_descanso,
         NVL(a.flag_1mayo, '0')    AS flag_1mayo
    FROM asistencia a
   WHERE a.cod_trabajador = asi_codtra
     AND trunc(a.fec_movim) BETWEEN ld_fec_ini AND ld_fec_fin
   GROUP BY a.fec_movim,
            NVL(a.flag_feriado, '0'),
            NVL(a.flag_descanso, '0'),
            NVL(a.flag_1mayo, '0');

-- Para los jornaleros de campo
CURSOR c_jornal_campo IS
   SELECT NVL(sum(t.imp_hrs_norm),0) as imp_hrs_norm, 
          NVL(sum(t.imp_hrs_25),0) as imp_hrs_25, 
          NVL(sum(t.imp_hrs_35),0) as imp_hrs_35, 
          NVL(sum(t.imp_hrs_noc_35),0) as imp_hrs_noc_35, 
          NVL(sum(t.imp_hrs_100),0) as imp_hrs_100, 
          NVL(sum(t.imp_dominical),0) as imp_dominical,
          NVL(sum(t.hrs_normales),0) as hrs_normales, 
          NVL(sum(t.hrs_extras_25),0) as hrs_extras_25, 
          NVL(sum(t.hrs_extras_35),0) as hrs_extras_35, 
          NVL(sum(t.hrs_noc_extras_35),0) as hrs_noc_extras_35, 
          NVL(sum(t.hrs_extras_100),0) hrs_extras_100
     FROM pd_jornal_campo t
    WHERE trunc(t.fecha)  BETWEEN ld_fec_ini AND ld_fec_fin
      AND t.cod_trabajador = asi_codtra;

-- Cursor con los partes de produccion para el calculo del destajo
cursor c_destajo is
  select p.fec_parte, p.precio_unit, tf.flag_destajo, t.turno, t.tipo_turno, pd.cant_producida, 
         pd.cant_horas_diu, pd.cant_horas_noc
    from tg_pd_destajo p,
         tg_pd_destajo_det pd,
         tg_tarifario      tf,
         turno             t
   where p.nro_parte = pd.nro_parte
     and p.cod_especie   = tf.cod_especie
     and p.cod_presentacion = tf.cod_presentacion
     and p.cod_tarea        = tf.cod_tarea     
     and p.turno            = t.turno
     and p.flag_estado = '1'
     and p.fec_parte between ld_fec_ini and ld_fec_fin
     and pd.cod_trabajador = asi_codtra
     and ((tf.flag_destajo = 1 and pd.cant_producida > 0) or 
          (tf.flag_destajo = 0 and pd.cant_horas_diu + pd.cant_horas_noc > 0));      
begin

--  **************************************************
--  ***   CALCULA GANANCIAS FIJAS POR TRABAJADOR   ***
--  **************************************************

IF ani_dias_trabaj = 0 THEN
   -- Si el numero de dias de Trabajo es cero entonces no tengo que hacer nada
   RETURN;
END IF;

-- Obtengo los parametros necesarios
SELECT r.tipo_trab_obrero, r.tipo_trab_destajo, r.cnc_prima_frio, r.TIPO_TRAB_SERVIS
  INTO ls_tipo_obr, ls_tipo_des, ls_cnc_prima_frio, ls_tipo_ser
  FROM rrhhparam r
 WHERE reckey = '1';

-- El rango de fecha para el calculo por la fecha de proceso
SELECT t.fec_inicio, t.fec_final
  INTO ld_fec_ini, ld_fec_fin
  FROM rrhh_param_org t
 WHERE t.origen = asi_origen
   AND t.tipo_trabajador = asi_tipo_trabaj
   AND trunc(t.fec_proceso) = trunc(adi_fec_proceso)
   and t.tipo_planilla      = asi_tipo_planilla;

-- Parametros para los destajeros
select pp.cnc_dstjo_basico, pp.cnc_dstjo_hd, pp.cnc_dstjo_hn
  into ls_cnc_dstjo_basico, ls_cnc_dstjo_hd, ls_cnc_dstjo_hn
  from prod_param pp
 where reckey = '1';
 
-- Luego los porcentajes y los conceptos de la asistencia
SELECT cnc_diu_normal   , cnc_noc_normal , cnc_diu_ext1    , cnc_diu_ext2    , cnc_noc_ext1   , cnc_noc_ext2   ,
       porc_diu_nor     , porc_noc_nor   , porc_diu_ext1   , porc_diu_ext2   , porc_noc_ext1  , porc_noc_ext2   ,
       cnc_asig_familiar, cnc_fer_hrs_nor, cnc_fer_hrs_ext1, cnc_fer_hrs_ext2, cnc_dom_hrs_nor, cnc_dom_hrs_ext1,
       cnc_dom_hrs_ext2 , factor_feriado, factor_dominical, cnc_dominical, 
       t.cnc_gratif_ext, t.cnc_bonif_ext, t.porc_gratif_campo
  INTO ls_cnc_diu_normal   , ls_cnc_noc_normal , ls_cnc_diu_ext1 , ls_cnc_diu_ext2 , ls_cnc_noc_ext1 , ls_cnc_noc_ext2,
       ln_porc_diu_normal  , ln_porc_noc_normal, ln_porc_diu_ext1, ln_porc_diu_ext2, ln_porc_noc_ext1, ln_porc_noc_ext2,
       ls_cnc_asig_familiar, ls_cnc_fer_nor    , ls_cnc_fer_ext1 , ls_cnc_fer_ext2 , ls_cnc_dom_nor  , ls_cnc_dom_ext1,
       ls_cnc_dom_ext2     , ln_fac_feriado, ln_fac_dom, ls_cnc_dominical,
       ls_cnc_gratif_ext   , ls_cnc_bon_gratif, ln_porc_gratf
  FROM asistparam t
 WHERE t.reckey = '1';

IF ls_cnc_asig_familiar IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado la asignacion familiar en asistparam');
END IF;

IF ls_cnc_diu_normal IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el Concepto de Horas Normales Diurnas en asistparam');
END IF;

IF ls_cnc_diu_ext1 IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el Concepto de Horas Extras Diurnas al 25% en asistparam');
END IF;

IF ls_cnc_diu_ext2 IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el Concepto de Horas Extras Diurnas al 35%  en asistparam');
END IF;

IF ls_cnc_noc_normal IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el Concepto de Horas Normales Nocturnas en asistparam');
END IF;

IF ls_cnc_noc_ext1 IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el Concepto de Horas Extras Nocturnas al 25% en asistparam');
END IF;

IF ls_cnc_noc_ext2 IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el Concepto de Horas Extras Nocturnas al 35%  en asistparam');
END IF;

-- Obtengo el grupo de calculo para el jornal
ls_grp_calc_jornal := PKG_CONFIG.USF_GET_PARAMETER('RRHH_GRUPO_CALCULO_JORNAL', '039');

-- Saco el tipo de Sueldo
select t.flag_ingreso_boleta, t.flag_sector_agrario
  into ls_flag_tipo_sueldo, ls_sector_agrario
  from tipo_trabajador t
 where t.tipo_trabajador = asi_tipo_trabaj;

if nvl(ani_dias_trabaj,0) > 0 then

   IF ls_flag_tipo_sueldo = 'J' THEN
      -- Obtengo primero el calculo del jornal por hora
      SELECT NVL(sum(G.IMP_GAN_DESC),0)
        INTO ln_imp_soles
        FROM gan_desct_fijo g
       WHERE G.COD_TRABAJADOR = ASI_CODTRA
         AND G.FLAG_ESTADO = '1'
         AND G.CONCEP IN (SELECT D.CONCEPTO_CALC
                            FROM GRUPO_CALCULO_DET D
                           WHERE D.GRUPO_CALCULO =ls_grp_calc_jornal);
      
      if ln_imp_soles = 0 then
         -- En caso que el trabajador no tenga asignado ningun sueldo fijo y que no se destajero, entonces es un error
         if asi_tipo_trabaj = ls_tipo_des then return; end if;
         
         RAISE_APPLICATION_ERROR(-20000, 'El trabajador ' || asi_codtra || ' no tiene asignado ningun concepto para el calculo del JORNAL, por favor ingresarle su ganancia fija desde la Operacione / Calculo de Planilla / Ganancias Fijas. Por favor verifique!');
      end if;
      
      ln_imp_hora := ln_imp_soles / 240;
      ln_hortra   := 0;
      
      -- Calculo el monto de la asignacion
      SELECT NVL(sum(G.IMP_GAN_DESC),0)
        INTO ln_asig_familiar
        FROM gan_desct_fijo g
       WHERE G.COD_TRABAJADOR = ASI_CODTRA
         AND G.FLAG_ESTADO = '1'
         AND g.concep = ls_cnc_asig_familiar;
      
      ln_asig_familiar := ln_asig_familiar / 240;

      -- CAlculo del importe incluyendo la asignacion familiar
      SELECT sum(G.IMP_GAN_DESC)
        INTO ln_imp_fijo
        FROM gan_desct_fijo g
       WHERE G.COD_TRABAJADOR = ASI_CODTRA
         AND G.FLAG_ESTADO = '1'
         AND G.CONCEP IN (SELECT D.CONCEPTO_CALC
                            FROM GRUPO_CALCULO_DET D
                           WHERE D.GRUPO_CALCULO =
                                 (SELECT C.CONCEP_GAN_FIJ
                                    FROM RRHHPARAM_CCONCEP C
                                   WHERE C.RECKEY = '1'));
      
      
      -- Para la asistencia de los jornales
      FOR lc_reg IN c_asist LOOP
          -- Horas Diurnas Normales
          IF lc_reg.hor_diu_nor > 0 THEN
             IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' THEN
                ls_concepto := ls_cnc_fer_nor;
                ln_Factor   := ln_fac_feriado;
             ELSIF lc_reg.flag_descanso = '1' THEN
                ls_concepto := ls_cnc_dom_nor;
                ln_Factor   := ln_fac_dom;
             ELSE
                ls_concepto := ls_cnc_diu_normal;
                ln_factor   := 1;
             END IF;
             
             IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' or lc_reg.flag_descanso = '1' THEN
               ln_imp_soles := (ln_imp_fijo / 240) * lc_reg.hor_diu_nor * ln_porc_diu_normal/100 * ln_Factor;
             else
               ln_imp_soles := ln_imp_hora * lc_reg.hor_diu_nor * ln_porc_diu_normal/100 * ln_Factor;
             end if;
             ln_imp_dolar := ln_imp_soles / ani_tipcam ;
             ln_dias      := round(lc_reg.hor_diu_nor / 8,2);

             UPDATE calculo c
                SET horas_trabaj  = horas_trabaj + lc_reg.hor_diu_nor,
                    horas_pag     = horas_pag + lc_reg.hor_diu_nor,
                    c.dias_trabaj = c.dias_trabaj + ln_dias,
                    imp_soles     = imp_soles + ln_imp_soles,
                    imp_dolar     = imp_dolar + ln_imp_dolar
              WHERE cod_trabajador = asi_codtra
                AND concep         = ls_concepto
                and tipo_planilla  = asi_tipo_planilla;

             IF SQL%NOTFOUND THEN
                insert into calculo (
                   cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                   dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
                values (
                   asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.hor_diu_nor, lc_reg.hor_diu_nor,
                   ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
             END IF;

          END IF;

          -- Horas Diurnas Extras1
          IF lc_reg.hor_ext_diu_1 > 0 THEN
              IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' THEN
                 ls_concepto := ls_cnc_fer_ext1;
                 ln_Factor   := ln_fac_feriado;
              ELSIF lc_reg.flag_descanso = '1' THEN
                 ls_concepto := ls_cnc_dom_ext1;
                 ln_Factor   := ln_fac_feriado;
              ELSE
                 ls_concepto := ls_cnc_diu_ext1;
                 ln_factor   := 1;
              END IF;

              ln_imp_soles := ln_imp_hora * lc_reg.hor_ext_diu_1 * ln_porc_diu_ext1/100 * ln_Factor;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
              ln_dias      := 1;

              UPDATE calculo
                 SET horas_trabaj = horas_trabaj + lc_reg.hor_ext_diu_1,
                     horas_pag    = horas_pag + lc_reg.hor_ext_diu_1,
                     dias_trabaj  = dias_trabaj + ln_dias,
                     imp_soles    = imp_soles + ln_imp_soles,
                     imp_dolar    = imp_dolar + ln_imp_dolar
               WHERE cod_trabajador = asi_codtra
                 AND concep = ls_concepto
                 and tipo_planilla = asi_tipo_planilla;

              IF SQL%NOTFOUND THEN
                 insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
                 values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.hor_ext_diu_1, lc_reg.hor_ext_diu_1,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
              END IF;
          END IF;

          -- Horas Diurnas Extras2
          IF lc_reg.hor_ext_diu_2 > 0 THEN
              IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' THEN
                 ls_concepto := ls_cnc_fer_ext2;
                 ln_Factor   := ln_fac_feriado;
              ELSIF lc_reg.flag_descanso = '1' THEN
                 ls_concepto := ls_cnc_dom_ext2;
                 ln_Factor   := ln_fac_feriado;
              ELSE
                 ls_concepto := ls_cnc_diu_ext2;
                 ln_factor   := 1;
              END IF;

              ln_imp_soles := ln_imp_hora * lc_reg.hor_ext_diu_2 * ln_porc_diu_ext2/100 * ln_factor;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
              ln_dias      := 1;

              UPDATE calculo
                 SET horas_trabaj = horas_trabaj + lc_reg.hor_ext_diu_2,
                     horas_pag    = horas_pag + lc_reg.hor_ext_diu_2,
                     dias_trabaj  = dias_trabaj + ln_dias,
                     imp_soles    = imp_soles + ln_imp_soles,
                     imp_dolar    = imp_dolar + ln_imp_dolar
               WHERE cod_trabajador = asi_codtra
                 AND concep         = ls_concepto
                 and tipo_planilla  = asi_tipo_planilla;

              IF SQL%NOTFOUND THEN
                 insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                    tipo_planilla )
                 values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.hor_ext_diu_2, lc_reg.hor_ext_diu_2,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
              END IF;
          END IF;

          -- Horas Nocturnas Normales
          IF lc_reg.hor_noc_nor > 0 THEN
              IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' THEN
                 ls_concepto := ls_cnc_fer_nor;
                 ln_Factor   := ln_fac_feriado;
              ELSIF lc_reg.flag_descanso = '1' THEN
                 ls_concepto := ls_cnc_dom_nor;
                 ln_Factor   := ln_fac_feriado;
              ELSE
                 ls_concepto := ls_cnc_noc_normal;
                 ln_factor   := 1;
              END IF;

              ln_imp_soles := ln_imp_hora  * lc_reg.hor_noc_nor * ln_porc_noc_normal/100 * ln_Factor;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
              ln_dias      := lc_reg.hor_noc_nor / 8;
 
              UPDATE calculo
                 SET horas_trabaj = horas_trabaj + lc_reg.hor_noc_nor,
                     horas_pag    = horas_pag + lc_reg.hor_noc_nor,
                     dias_trabaj  = dias_trabaj + ln_dias,
                     imp_soles    = imp_soles + ln_imp_soles,
                     imp_dolar    = imp_dolar + ln_imp_dolar
               WHERE cod_trabajador = asi_codtra
                 AND concep         = ls_concepto
                 and tipo_planilla  = asi_tipo_planilla;

              IF SQL%NOTFOUND THEN
                 insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                    tipo_planilla )
                 values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.hor_noc_nor, lc_reg.hor_noc_nor,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
              END IF;
          END IF;

          -- Horas Nocturnas Extras1
          IF lc_reg.hor_ext_noc_1 > 0 THEN
              IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' THEN
                 ls_concepto := ls_cnc_fer_ext1;
                 ln_Factor   := ln_fac_feriado;
              ELSIF lc_reg.flag_descanso = '1' THEN
                 ls_concepto := ls_cnc_dom_ext1;
                 ln_Factor   := ln_fac_feriado;
              ELSE
                 ls_concepto := ls_cnc_noc_ext1;
                 ln_factor   := 1;
              END IF;

              ln_imp_soles := (ln_imp_hora + ln_asig_familiar) * lc_reg.hor_ext_noc_1 * ln_porc_noc_ext1/100 * ln_factor;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
              ln_dias      := 1;

              UPDATE calculo
                 SET horas_trabaj = horas_trabaj + lc_reg.hor_ext_noc_1,
                     horas_pag    = horas_pag + lc_reg.hor_ext_noc_1,
                     imp_soles    = imp_soles + ln_imp_soles,
                     imp_dolar    = imp_dolar + ln_imp_dolar
               WHERE cod_trabajador = asi_codtra
                 AND concep         = ls_concepto
                 and tipo_planilla  = asi_tipo_planilla;

              IF SQL%NOTFOUND THEN
                 insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                    tipo_planilla )
                 values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.hor_ext_noc_1, lc_reg.hor_ext_noc_1,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
              END IF;
          END IF;

          -- Horas Nocturnas Extras2
          IF lc_reg.hor_ext_noc_2 > 0 THEN
              IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' THEN
                 ls_concepto := ls_cnc_fer_ext2;
                 ln_Factor   := ln_fac_feriado;
              ELSIF lc_reg.flag_descanso = '1' THEN
                 ls_concepto := ls_cnc_dom_ext2;
                 ln_Factor   := ln_fac_feriado;
              ELSE
                 ls_concepto := ls_cnc_noc_ext2;
                 ln_factor   := 1;
              END IF;

              ln_imp_soles := (ln_imp_hora + ln_asig_familiar) * lc_reg.hor_ext_noc_2 * ln_porc_noc_ext2/100 * ln_factor;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
              ln_dias      := 1;

              UPDATE calculo
                 SET horas_trabaj = horas_trabaj + lc_reg.hor_ext_noc_2,
                     horas_pag    = horas_pag + lc_reg.hor_ext_noc_2,
                     imp_soles    = imp_soles + ln_imp_soles,
                     imp_dolar    = imp_dolar + ln_imp_dolar
               WHERE cod_trabajador = asi_codtra
                 AND concep         = ls_concepto
                 and tipo_planilla  = asi_tipo_planilla;

              IF SQL%NOTFOUND THEN
                 insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
                 values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.hor_ext_noc_2, lc_reg.hor_ext_noc_2,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
              END IF;
          END IF;
          
          -- Horas Extras al 100%
          IF lc_reg.hor_ext_100 > 0 THEN
              IF lc_reg.flag_feriado = '1' OR lc_reg.flag_1mayo = '1' THEN
                 ls_concepto := ls_cnc_fer_ext2;
                 ln_Factor   := ln_fac_feriado;
              ELSE
                 ls_concepto := ls_cnc_dom_ext2;
                 ln_factor   := 2;
              END IF;

              ln_imp_soles := ln_imp_hora  * lc_reg.hor_ext_100 * 2;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
              ln_dias      := 1;

              UPDATE calculo
                 SET horas_trabaj = horas_trabaj + lc_reg.hor_ext_diu_2,
                     horas_pag    = horas_pag + lc_reg.hor_ext_diu_2,
                     dias_trabaj  = dias_trabaj + ln_dias,
                     imp_soles    = imp_soles + ln_imp_soles,
                     imp_dolar    = imp_dolar + ln_imp_dolar
               WHERE cod_trabajador = asi_codtra
                 AND concep         = ls_concepto
                 and tipo_planilla  = asi_tipo_planilla;

              IF SQL%NOTFOUND THEN
                 insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                    tipo_planilla )
                 values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.hor_ext_diu_2, lc_reg.hor_ext_diu_2,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
              END IF;
          END IF;

          ln_hortra := ln_hortra + lc_reg.hor_diu_nor + lc_reg.hor_noc_nor;

      END LOOP;
      
      -- Para los jornales de campo
      ln_imp_gratif := 0; ln_acum_grat := 0; ln_tot_hrs_nor := 0;
      
      FOR lc_reg2 IN c_jornal_campo LOOP
      
          -- Remuneracion basica
          ln_imp_soles := lc_reg2.imp_hrs_norm;
          
          -- A la remuneracion basica le saco el dominical
          ln_imp_soles := ln_imp_soles - (ln_asig_familiar * lc_reg2.hrs_normales);
          
          -- Le calculo la gratificacion
          ln_imp_gratif := ln_imp_soles * ln_porc_gratf / 100;
          -- Le quitamos el importe al importe 
          ln_imp_soles := ln_imp_soles - ln_imp_gratif;
          -- Acumulo la gratificacion
          ln_acum_grat := ln_acum_grat + ln_imp_gratif;
          
          ln_imp_dolar := ln_imp_soles / ani_tipcam ;
          ls_concepto  := ls_cnc_diu_normal;
          ln_dias      := (lc_reg2.hrs_normales) / 8;
          
          UPDATE calculo c
             SET horas_trabaj = horas_trabaj + lc_reg2.hrs_normales,
                 horas_pag    = horas_pag + lc_reg2.hrs_normales,
                 imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar,
                 c.dias_trabaj = c.dias_trabaj + ln_dias
            WHERE cod_trabajador = asi_codtra
              AND concep         = ls_concepto
              and tipo_planilla  = asi_tipo_planilla;

          IF SQL%NOTFOUND THEN
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
             values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg2.hrs_normales, lc_reg2.hrs_normales,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
          END IF;
          
          -- Horas Extras 25%
          ln_imp_soles := lc_reg2.imp_hrs_25;
          
          -- Le calculo la gratificacion
          ln_imp_gratif := ln_imp_soles * ln_porc_gratf / 100;
          -- Le quitamos el importe al importe 
          ln_imp_soles := ln_imp_soles - ln_imp_gratif;
          -- Acumulo la gratificacion
          ln_acum_grat := ln_acum_grat + ln_imp_gratif;

          ln_imp_dolar := ln_imp_soles / ani_tipcam ;
          ls_concepto  := ls_cnc_diu_ext1 ;
          UPDATE calculo
             SET horas_trabaj = horas_trabaj + lc_reg2.hrs_extras_25,
                 horas_pag    = horas_pag + lc_reg2.hrs_extras_25,
                 imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar
            WHERE cod_trabajador = asi_codtra
              AND concep         = ls_concepto
              and tipo_planilla  = asi_tipo_planilla;

          IF SQL%NOTFOUND THEN
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
             values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg2.hrs_extras_25, lc_reg2.hrs_extras_25,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
          END IF;

          -- Horas Extras 35%
          ln_imp_soles := lc_reg2.imp_hrs_35;

          -- Le calculo la gratificacion
          ln_imp_gratif := ln_imp_soles * ln_porc_gratf / 100;
          -- Le quitamos el importe al importe 
          ln_imp_soles := ln_imp_soles - ln_imp_gratif;
          -- Acumulo la gratificacion
          ln_acum_grat := ln_acum_grat + ln_imp_gratif;
          
          ln_imp_dolar := ln_imp_soles / ani_tipcam ;
          ls_concepto  := ls_cnc_diu_ext2 ;
          UPDATE calculo
             SET horas_trabaj = horas_trabaj + lc_reg2.hrs_extras_35,
                 horas_pag    = horas_pag + lc_reg2.hrs_extras_35,
                 imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar
            WHERE cod_trabajador = asi_codtra
              AND concep         = ls_concepto
              and tipo_planilla  = asi_tipo_planilla;

          IF SQL%NOTFOUND THEN
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                    tipo_planilla )
             values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg2.hrs_extras_35, lc_reg2.hrs_extras_35,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
          END IF;

          -- Horas Nocturnas 35%
          ln_imp_soles := lc_reg2.imp_hrs_noc_35;
          
          -- Le calculo la gratificacion
          ln_imp_gratif := ln_imp_soles * ln_porc_gratf / 100;
          -- Le quitamos el importe al importe 
          ln_imp_soles := ln_imp_soles - ln_imp_gratif;
          -- Acumulo la gratificacion
          ln_acum_grat := ln_acum_grat + ln_imp_gratif;
          
          ln_imp_dolar := ln_imp_soles / ani_tipcam ;
          ls_concepto  := ls_cnc_noc_ext2 ;
          ln_dias      := (lc_reg2.hrs_noc_extras_35) / 8;
          
          UPDATE calculo
             SET horas_trabaj = horas_trabaj + lc_reg2.hrs_noc_extras_35 ,
                 horas_pag    = horas_pag + lc_reg2.hrs_noc_extras_35,
                 dias_trabaj  = dias_trabaj + ln_dias,
                 imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar
            WHERE cod_trabajador = asi_codtra
              AND concep         = ls_concepto
              and tipo_planilla  = asi_tipo_planilla;

          IF SQL%NOTFOUND THEN
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                    tipo_planilla )
             values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg2.hrs_noc_extras_35, lc_reg2.hrs_noc_extras_35,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
          END IF;

          -- Horas Domingos 100%
          ln_imp_soles := lc_reg2.imp_hrs_100;

          -- Le calculo la gratificacion
          ln_imp_gratif := ln_imp_soles * ln_porc_gratf / 100;
          -- Le quitamos el importe al importe 
          ln_imp_soles := ln_imp_soles - ln_imp_gratif;
          -- Acumulo la gratificacion
          ln_acum_grat := ln_acum_grat + ln_imp_gratif;
          
          ln_imp_dolar := ln_imp_soles / ani_tipcam ;
          ls_concepto  := ls_cnc_dom_ext1 ;
          ln_dias      := (lc_reg2.hrs_normales) / 8;
          
          UPDATE calculo
             SET horas_trabaj = horas_trabaj + lc_reg2.hrs_extras_100 ,
                 horas_pag    = horas_pag + lc_reg2.hrs_extras_100,
                 imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar
            WHERE cod_trabajador = asi_codtra
              AND concep         = ls_concepto
              and tipo_planilla  = asi_tipo_planilla;

          IF SQL%NOTFOUND THEN
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
             values (
                    asi_codtra, ls_concepto, adi_fec_proceso, lc_reg2.hrs_extras_100, lc_reg2.hrs_extras_100,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
          END IF;
          
          -- sumo el Total de Horas Normales
          ln_tot_hrs_nor := ln_tot_hrs_nor + lc_reg2.hrs_normales + lc_reg2.hrs_noc_extras_35;
      END LOOP;
      
      -- Para los partes de produccion
      for lc_reg in c_destajo loop
          if lc_reg.flag_destajo = '1' then
             ls_concepto  := ls_cnc_dstjo_basico;
             
             -- Obtengo el importe normal y lo paso a dolares
             ln_imp_soles := lc_reg.precio_unit * lc_reg.cant_producida;
             ln_imp_dolar := ln_imp_soles / ani_tipcam ;
             
             UPDATE calculo c
                SET horas_trabaj = horas_trabaj + lc_reg.cant_horas_diu + lc_reg.cant_horas_noc,
                    horas_pag    = horas_pag + lc_reg.cant_horas_diu + lc_reg.cant_horas_noc,
                    imp_soles    = imp_soles + ln_imp_soles,
                    imp_dolar    = imp_dolar + ln_imp_dolar,
                    c.dias_trabaj = ani_dias_trabaj
               WHERE cod_trabajador = asi_codtra
                 AND concep         = ls_concepto
                 and tipo_planilla  = asi_tipo_planilla;

             IF SQL%NOTFOUND THEN
                insert into calculo (
                       cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                       dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                       tipo_planilla )
                values (
                       asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.cant_horas_diu + lc_reg.cant_horas_noc, lc_reg.cant_horas_diu + lc_reg.cant_horas_noc,
                       ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, 
                       asi_tipo_planilla ) ;
             END IF;             

             -- Verifico si ha trabajado en un dia feriado, para incrementarle en un 100%
             SELECT COUNT(*)
               INTO ln_count
               FROM calendario_feriado cf
              WHERE cf.origen = asi_origen
                AND cf.mes    = to_number(to_char(lc_reg.fec_parte, 'mm'))
                AND cf.dia    = to_number(to_char(lc_reg.fec_parte, 'dd'));

             IF ln_count > 0 THEN
                -- Si es un dia feriado, entonces su remuneracion es de 100%, cambio autorizado por Victor Mena el 05 de Agosto 2014
                ls_concepto := ls_cnc_fer_ext1;
                ln_imp_soles := ln_imp_soles * ln_fac_feriado;
                
                ln_imp_dolar := ln_imp_soles / ani_tipcam ;
             
                UPDATE calculo c
                   SET horas_trabaj = horas_trabaj + lc_reg.cant_horas_diu + lc_reg.cant_horas_noc,
                       horas_pag    = horas_pag + lc_reg.cant_horas_diu + lc_reg.cant_horas_noc,
                       imp_soles    = imp_soles + ln_imp_soles,
                       imp_dolar    = imp_dolar + ln_imp_dolar,
                       c.dias_trabaj = ani_dias_trabaj
                 WHERE cod_trabajador = asi_codtra
                   AND concep         = ls_concepto
                   and tipo_planilla  = asi_tipo_planilla;

                IF SQL%NOTFOUND THEN
                   insert into calculo (
                          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                          tipo_planilla )
                   values (
                          asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.cant_horas_diu + lc_reg.cant_horas_noc, lc_reg.cant_horas_diu + lc_reg.cant_horas_noc,
                          ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                          asi_tipo_planilla ) ;
                END IF;  
                
             end if;
            
             
          else
            if lc_reg.cant_horas_diu > 0 then
               ln_tot_horas := lc_reg.cant_horas_diu;
               
               -- Obteniento el horario normal diurno
               if ln_tot_horas > 8 then
                  ln_imp_soles := lc_reg.precio_unit * 8;
                  ln_horas := 8;
                  ln_tot_horas := ln_tot_horas - 8;
               else
                  ln_horas := ln_tot_horas;
                  ln_tot_horas := 0;
                  ln_imp_soles := lc_reg.precio_unit * ln_horas;
               end if;
               
               ln_imp_dolar := ln_imp_soles / ani_tipcam ;
               ls_concepto := ls_cnc_diu_normal;
               
               UPDATE calculo c
                  SET horas_trabaj = horas_trabaj + ln_horas,
                      horas_pag    = horas_pag + ln_horas,
                      imp_soles    = imp_soles + ln_imp_soles,
                      imp_dolar    = imp_dolar + ln_imp_dolar,
                      c.dias_trabaj = ani_dias_trabaj
                 WHERE cod_trabajador = asi_codtra
                   AND concep         = ls_concepto
                   and tipo_planilla  = asi_tipo_planilla;

               IF SQL%NOTFOUND THEN
                  insert into calculo (
                         cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                         dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                         tipo_planilla )
                  values (
                         asi_codtra, ls_concepto, adi_fec_proceso, ln_horas, ln_horas,
                         ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                         asi_tipo_planilla ) ;
               END IF;      
               
               -- Calculo las horas extras al 25%
               if ln_tot_horas > 0 then
                   ln_horas := ln_tot_horas;
                   ln_tot_horas := 0;
                   
                   ln_imp_soles := lc_reg.precio_unit * ln_horas * 1.25;
                   ln_imp_dolar := ln_imp_soles / ani_tipcam ;
                   ls_concepto := ls_cnc_diu_ext1;
                   
                   UPDATE calculo c
                      SET horas_trabaj = horas_trabaj + ln_horas,
                          horas_pag    = horas_pag + ln_horas,
                          imp_soles    = imp_soles + ln_imp_soles,
                          imp_dolar    = imp_dolar + ln_imp_dolar
                     WHERE cod_trabajador = asi_codtra
                       AND concep         = ls_concepto
                       and tipo_planilla  = asi_tipo_planilla;

                   IF SQL%NOTFOUND THEN
                      insert into calculo (
                             cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                             dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                             tipo_planilla )
                      values (
                             asi_codtra, ls_concepto, adi_fec_proceso, ln_horas, ln_horas,
                             ln_horas/8, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                             asi_tipo_planilla ) ;
                   END IF;      
                 
               end if;  
               
               -- Calculo de horas por feriado
               SELECT COUNT(*)
                 INTO ln_count
                 FROM calendario_feriado cf
                WHERE cf.origen = asi_origen
                  AND cf.mes    = to_number(to_char(lc_reg.fec_parte, 'mm'))
                  AND cf.dia    = to_number(to_char(lc_reg.fec_parte, 'dd'));

               IF ln_count > 0 THEN
                  -- Si es un dia feriado, entonces su remuneracion es de 100%, cambio autorizado por Victor Mena el 05 de Agosto 2014
                  ls_concepto := ls_cnc_fer_ext1;
                  ln_imp_soles := lc_reg.precio_unit * lc_reg.cant_horas_diu * ln_fac_feriado;
                  ln_imp_dolar := ln_imp_soles / ani_tipcam ;
               
                  UPDATE calculo c
                     SET horas_trabaj = horas_trabaj + lc_reg.cant_horas_diu,
                         horas_pag    = horas_pag + lc_reg.cant_horas_diu,
                         imp_soles    = imp_soles + ln_imp_soles,
                         imp_dolar    = imp_dolar + ln_imp_dolar,
                         c.dias_trabaj = ani_dias_trabaj
                   WHERE cod_trabajador = asi_codtra
                     AND concep         = ls_concepto
                     and tipo_planilla  = asi_tipo_planilla;

                  IF SQL%NOTFOUND THEN
                     insert into calculo (
                            cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                            dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                            tipo_planilla )
                     values (
                            asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.cant_horas_diu, lc_reg.cant_horas_diu,
                            ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                            asi_tipo_planilla ) ;
                  END IF;  
                  
               end if;       
            end if;

            if lc_reg.cant_horas_noc > 0 then
               ln_tot_horas := lc_reg.cant_horas_noc;
               
               -- Obteniento el horario normal diurno
               if ln_tot_horas > 8 then
                  ln_horas := 8;
                  ln_tot_horas := ln_tot_horas - 8;
               else
                  ln_horas := ln_tot_horas;
                  ln_tot_horas := 0;

               end if;
               
               ln_imp_soles := lc_reg.precio_unit * ln_horas * 1.35;               
               ln_imp_dolar := ln_imp_soles / ani_tipcam ;
               ls_concepto := ls_cnc_noc_normal;
               
               UPDATE calculo c
                  SET horas_trabaj = horas_trabaj + ln_horas,
                      horas_pag    = horas_pag + ln_horas,
                      imp_soles    = imp_soles + ln_imp_soles,
                      imp_dolar    = imp_dolar + ln_imp_dolar,
                      c.dias_trabaj = c.dias_trabaj + 1
                 WHERE cod_trabajador = asi_codtra
                   AND concep         = ls_concepto
                   and tipo_planilla  = asi_tipo_planilla;

               IF SQL%NOTFOUND THEN
                  insert into calculo (
                         cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                         dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                         tipo_planilla )
                  values (
                         asi_codtra, ls_concepto, adi_fec_proceso, ln_horas, ln_horas,
                         ln_horas/8, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                         asi_tipo_planilla ) ;
               END IF;               

               -- Calculo las horas extras al 25% en horario nocturno
               if ln_tot_horas > 0 then
                   ln_horas := ln_tot_horas;
                   ln_tot_horas := 0;
                   
                   ln_imp_soles := lc_reg.precio_unit * ln_horas;
                   ln_imp_dolar := ln_imp_soles / ani_tipcam ;
                   ls_concepto := ls_cnc_noc_ext1;
                   
                   UPDATE calculo c
                      SET horas_trabaj = horas_trabaj + ln_horas,
                          horas_pag    = horas_pag + ln_horas,
                          imp_soles    = imp_soles + ln_imp_soles,
                          imp_dolar    = imp_dolar + ln_imp_dolar
                     WHERE cod_trabajador = asi_codtra
                       AND concep         = ls_concepto
                       and tipo_planilla  = asi_tipo_planilla;

                   IF SQL%NOTFOUND THEN
                      insert into calculo (
                             cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                             dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                             tipo_planilla )
                      values (
                             asi_codtra, ls_concepto, adi_fec_proceso, ln_horas, ln_horas,
                             ln_horas/8, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                             asi_tipo_planilla ) ;
                   END IF;      
                 
               end if; 

               -- Calculo de horas por feriado
               SELECT COUNT(*)
                 INTO ln_count
                 FROM calendario_feriado cf
                WHERE cf.origen = asi_origen
                  AND cf.mes    = to_number(to_char(lc_reg.fec_parte, 'mm'))
                  AND cf.dia    = to_number(to_char(lc_reg.fec_parte, 'dd'));

               IF ln_count > 0 THEN
                  -- Si es un dia feriado, entonces su remuneracion es de 100%, cambio autorizado por Victor Mena el 05 de Agosto 2014
                  ls_concepto := ls_cnc_fer_ext1;
                  ln_imp_soles := lc_reg.precio_unit * lc_reg.cant_horas_noc * ln_fac_feriado * 1.35;
                  ln_imp_dolar := ln_imp_soles / ani_tipcam ;
               
                  UPDATE calculo c
                     SET horas_trabaj = horas_trabaj + lc_reg.cant_horas_noc,
                         horas_pag    = horas_pag + lc_reg.cant_horas_noc,
                         imp_soles    = imp_soles + ln_imp_soles,
                         imp_dolar    = imp_dolar + ln_imp_dolar,
                         c.dias_trabaj = ani_dias_trabaj
                   WHERE cod_trabajador = asi_codtra
                     AND concep         = ls_concepto
                     and tipo_planilla  = asi_tipo_planilla;

                  IF SQL%NOTFOUND THEN
                     insert into calculo (
                            cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                            dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                            tipo_planilla )
                     values (
                            asi_codtra, ls_concepto, adi_fec_proceso, lc_reg.cant_horas_noc, lc_reg.cant_horas_noc,
                            ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, 
                            asi_tipo_planilla ) ;
                  END IF;  
                  
               end if;       
            end if;                       
          end if;
          
          

      end loop;
      
   ELSE
      ln_hortra := ani_dias_trabaj * 8 ;
      for rc_gan in c_ganancias_fijas loop

        ln_imp_soles := rc_gan.imp_gan_desc / ani_dias_mes * ani_dias_trabaj ;
        ln_imp_dolar := ln_imp_soles / ani_tipcam ;
        
        UPDATE calculo
           SET horas_trabaj = ln_hortra,
               horas_pag    = ln_hortra,
               imp_soles    = imp_soles + ln_imp_soles,
               imp_dolar    = imp_dolar + ln_imp_dolar,
               DIAS_TRABAJ  = ani_dias_trabaj
          WHERE cod_trabajador = asi_codtra
            AND concep         = rc_gan.concep
            and tipo_planilla  = asi_tipo_planilla;
        
        if SQL%NOTFOUND then
            insert into calculo (
              cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
              dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
            values (
              asi_codtra, rc_gan.concep, adi_fec_proceso, ln_hortra, ln_hortra,
              ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
        end if;
        
      end loop ;

   END IF;

   -- Falta el calculo de la asignacion familiar, para esto debe ponerlo de manera automatica solamente
   -- si tiene hijos menores de 18 a?os, y debe ser el 10% del Minimo Vital


end if ;

end usp_rh_cal_ganancias_fijas ;
/
