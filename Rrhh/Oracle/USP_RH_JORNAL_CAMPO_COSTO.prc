CREATE OR REPLACE Procedure USP_RH_JORNAL_CAMPO_COSTO(
       adi_fecha1           in DATE,
       adi_fecha2           IN DATE
) Is

ln_jornal_basico    pd_jornal_campo.JORNAL_BASICO%TYPE;
ln_asign_familiar   pd_jornal_campo.ASIGN_FAMILIAR%TYPE;
ln_imp_hrs_norm     pd_jornal_campo.IMP_HRS_NORM%TYPE;
ln_imp_hrs_25       pd_jornal_campo.imp_hrs_25%TYPE;
ln_imp_hrs_35       pd_jornal_campo.imp_hrs_35%TYPE;
ln_imp_hrs_noc_35   pd_jornal_campo.imp_hrs_noc_35%TYPE;
ln_imp_hrs_100      pd_jornal_campo.imp_hrs_100%TYPE;
ln_imp_essalud      pd_jornal_campo.aporte_essalud%TYPE;
ln_imp_dominical    pd_jornal_campo.imp_dominical%TYPE;
ln_porc_essalud     concepto.fact_pago%TYPE;
ln_hrs_dominical    NUMBER;
ln_ganancia_bruta   NUMBER;
ls_cnc_asig_fam     asistparam.cnc_asig_familiar%TYPE;
ln_tope_hor_noc     NUMBER;
ln_count            NUMBER;
ls_cnc_basico       concepto.concep%TYPE;
ls_cnc_essalud      asistparam.cnc_essalud%TYPE;
ln_rmv              rmv_x_tipo_trabaj.rmv%TYPE;
ln_aporte_oblig     pd_jornal_campo.aporte_oblig%TYPE;
ln_comision_var     pd_jornal_campo.comision_var%TYPE;
ln_prima_seguro     pd_jornal_campo.prima_seguro%TYPE;
ln_imp_gratif       pd_jornal_campo.gratificacion%TYPE;
ln_imp_bonif        pd_jornal_campo.bon_gratificacion%TYPE;

-- Para distribuir por cada lote
ln_imp_x_dist      NUMBER;
ln_tot_has         NUMBER;
ln_imp_neto        pd_jornal_campo_lote.imp_neto%TYPE;
ln_diferencia      NUMBER;

-- Campo_lote
ln_nro_item        pd_jornal_campo_lote.nro_item%TYPE;
ls_nro_lote        pd_jornal_campo_lote.nro_lote%TYPE;

-- Para el calculo del SNP
ls_grp_SNP         rrhhparam_cconcep.snp%TYPE;
ls_cnc_SNP         concepto.concep%TYPE;
ln_factor_SNP      concepto.fact_pago%TYPE;
ln_min_SNP         concepto.imp_tope_min%TYPE;

-- Para el calculo de la gratificación y bonificación de la grati para
ln_factor_grat     configuracion.valor_dec%TYPE;
ld_fecha1          configuracion.valor_date%TYPE;
ld_fecha2          configuracion.valor_date%TYPE;

Cursor c_trabajador IS
  Select DISTINCT a.cod_trabajador, m.cod_afp, af.porc_jubilac, af.porc_invalidez,
         DECODE(m.flag_comision_afp, '1', af.porc_comision1,af.porc_comision2) as porc_comision,
         m.tipo_trabajador
    From pd_jornal_campo a,
         maestro m,
         admin_afp af
   Where a.cod_trabajador = m.cod_trabajador
     and m.cod_afp = af.cod_afp(+)
     and trunc(a.fecha) BETWEEN trunc(adi_fecha1) AND trunc(adi_fecha2);

Cursor c_asistencia(as_cod_trabajador maestro.cod_trabajador%TYPE) Is
  Select a.cod_trabajador, trunc(a.fecha) AS fecha, a.nro_item,
         a.hrs_normales, a.hrs_extras_25, a.hrs_extras_35, a.hrs_noc_extras_35, a.hrs_extras_100
    From pd_jornal_campo a
   Where trunc(a.fecha) BETWEEN trunc(adi_fecha1) AND trunc(adi_fecha2)
     and a.cod_trabajador = as_cod_trabajador
   Order by a.cod_trabajador, trunc(a.fecha);

CURSOR c_lotes(ad_fecha      pd_jornal_campo_lote.fecha%TYPE,
               as_trabajador pd_jornal_campo_lote.cod_trabajador%TYPE,
               an_item       pd_jornal_campo_lote.nro_item%TYPE) IS
  SELECT a.fecha, a.cod_trabajador, a.nro_lote, a.nro_item, c.ha_cultivadas
    FROM pd_jornal_campo_lote a,
         cultivos             c
   WHERE a.nro_lote = c.nro_lote
     AND a.variedad = c.variedad
     AND a.fecha = trunc(ad_fecha)
     AND a.cod_trabajador = as_trabajador
     AND a.nro_item       = an_item;

Begin

 -- Parametros para el SNP  (Sistema Nacional de Pensiones
 SELECT r.snp
   INTO ls_grp_SNP
   FROM rrhhparam_cconcep r
  WHERE r.reckey = '1';

 IF ls_grp_SNP IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'Error, debe especificar el grupo de calculo del SNP en rrhhparam_cconcep');
 END IF;

 select count(*)
  into ln_count
  from grupo_calculo g
  where g.grupo_calculo = ls_grp_snp ;

 IF ln_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20000, 'Error, no existe grupo de cálculo ' || ls_grp_SNP || ', por favor verifique.');
 END IF;

 select g.concepto_gen, nvl(c.fact_pago,0), nvl(c.imp_tope_min,0)
   into ls_cnc_SNP, ln_factor_SNP, ln_min_SNP
   from grupo_calculo g,
        concepto      c
  where g.concepto_gen = c.concep
    and g.grupo_calculo = ls_grp_SNP ;

 -- Ahora calculo las fechas y el porcentaje de bonificación
 ld_fecha1       := USF_GET_PARAMETER_DATE('FEC.INICIO LEY 29531');
 ld_fecha2       := USF_GET_PARAMETER_DATE('FEC.FIN LEY 29531');
 ln_Factor_grat  := USF_GET_PARAMETER_DEC('PORC.GRATIF.JOR');

 --Se Capturan los porcentajes equivalentes por horario de trabajo.
 SELECT asp.cnc_asig_familiar, asp.cnc_essalud
   INTO ls_cnc_asig_fam, ls_cnc_essalud
   from asistparam asp
  Where asp.reckey = 1;

 -- Se Capturan los conceptos de Básico y Asignación Familiar
 ls_cnc_basico  := USF_GET_PARAMETER_STR('CNC.BASICO');

 Select Nvl(c.fact_pago,0) Into ln_porc_essalud
   from concepto c
  where c.concep = ls_cnc_essalud;

 For c_t in c_trabajador Loop

     Begin
        Select g.imp_gan_desc Into ln_jornal_basico
          from gan_desct_fijo g
         Where g.cod_trabajador = c_t.cod_trabajador
           and g.concep = ls_cnc_basico;
     Exception
     When No_Data_Found Then
          ln_jornal_basico := 0;
     End ;

     ln_jornal_basico := ln_jornal_basico / 30;

     Begin
        Select Nvl(g.imp_gan_desc,0) Into ln_asign_familiar
          from gan_desct_fijo g
         Where g.cod_trabajador = c_t.cod_trabajador
           and g.concep = ls_cnc_asig_fam;
     Exception
     When No_Data_Found Then
          ln_asign_familiar := 0;
     End ;

     ln_asign_familiar := ln_asign_familiar / 30;

     -- Cuento el nro de días de asistencia, solamente aquellas que tienen mas de 4 horas hormales
     If ln_jornal_basico > 0 Then
        For c_a in c_asistencia(c_t.cod_trabajador) LOOP

            -- Busco la remuneración minima vital
            SELECT COUNT(*)
              INTO ln_count
              FROM rmv_x_tipo_trabaj
             WHERE tipo_Trabajador = c_t.tipo_trabajador;

            IF ln_count = 0 THEN
               RAISE_APPLICATION_ERROR(-20000, 'No ha especificado una Remuneración mínima vital para el tipo de trabajador :'
                                                || c_t.tipo_trabajador || ' de Código: ' || c_t.cod_trabajador);
            END IF;

            SELECT rmv
              INTO ln_rmv
              FROM (SELECT t.rmv
                      FROM rmv_x_tipo_trabaj t
                     WHERE tipo_Trabajador = c_t.tipo_trabajador
                       AND t.fecha_desde <= c_a.fecha
                     ORDER BY t.fecha_desde DESC)
             WHERE rownum = 1;

            -- Con la remuneración minima calculo el tope minimo a pagar para los jornaleros de campo
            ln_tope_hor_noc := ln_rmv / 240 * 1.35;

            -- Realizo los cálculos necesarios
            ln_hrs_dominical := (c_a.hrs_normales + c_a.hrs_noc_extras_35) / 6;
            ln_imp_dominical := (ln_jornal_basico + ln_asign_familiar) / 8 * ln_hrs_dominical;
            ln_imp_hrs_norm  := (ln_jornal_basico + ln_asign_familiar) / 8 * c_a.hrs_normales;
            ln_imp_hrs_25    := (ln_jornal_basico + ln_asign_familiar) / 8 * c_a.hrs_extras_25 * 1.25;
            ln_imp_hrs_35    := (ln_jornal_basico + ln_asign_familiar) / 8 * c_a.hrs_extras_35 * 1.35;
            ln_imp_hrs_100   := (ln_jornal_basico + ln_asign_familiar) / 8 * c_a.hrs_extras_100 * 2.00;

            IF ln_jornal_basico / 8 * 1.35 < ln_tope_hor_noc THEN
               ln_imp_hrs_noc_35 := ln_jornal_basico / 8 * c_a.hrs_noc_extras_35 * 1.35;
            ELSE
               ln_imp_hrs_noc_35 := ln_tope_hor_noc * c_a.hrs_noc_extras_35 ;
            END IF;

            if ln_imp_hrs_noc_35 > 0 then
               null;
            end if;

            IF c_a.fecha BETWEEN ld_fecha1 AND ld_Fecha2 THEN
               -- Si la fecha esta en el rango indicado saco la gratificación y calculo la bonificación
               ln_ganancia_bruta := (ln_imp_hrs_norm + ln_imp_hrs_25 + ln_imp_hrs_35 + ln_imp_hrs_noc_35 + ln_imp_hrs_100 + ln_imp_dominical);
               ln_imp_gratif     := ln_ganancia_bruta * ln_factor_grat / 100;
               ln_imp_bonif      := ln_imp_gratif * ln_porc_essalud;
               ln_ganancia_bruta := ln_ganancia_bruta - ln_imp_gratif;
            ELSE
               ln_ganancia_bruta := (ln_imp_hrs_norm + ln_imp_hrs_25 + ln_imp_hrs_35 + ln_imp_hrs_noc_35 + ln_imp_hrs_100 + ln_imp_dominical);
               ln_imp_gratif     := 0;
               ln_imp_bonif      := 0;
            END IF;


            ln_imp_essalud    := ln_ganancia_bruta * ln_porc_essalud;

            IF c_t.cod_afp IS NULL THEN
               ln_aporte_oblig   := ln_ganancia_bruta * ln_factor_SNP;
               ln_comision_var   := 0;
               ln_prima_seguro   := 0;
            ELSE
               ln_aporte_oblig   := ln_ganancia_bruta * c_t.porc_jubilac/100;
               ln_comision_var   := ln_ganancia_bruta * c_t.porc_comision/100;
               ln_prima_seguro   := ln_ganancia_bruta * c_t.porc_invalidez/100;
            END IF;

            -- Primero los importes brutos por cada hora trabajada
            Update pd_jornal_campo a
               Set a.jornal_basico  = ln_jornal_basico,
                   a.asign_familiar = ln_asign_familiar,
                   a.imp_hrs_norm   = ln_imp_hrs_norm,
                   a.imp_hrs_25     = ln_imp_hrs_25,
                   a.imp_hrs_35     = ln_imp_hrs_35,
                   a.imp_hrs_noc_35 = ln_imp_hrs_noc_35,
                   a.imp_hrs_100    = ln_imp_hrs_100,
                   a.aporte_essalud = ln_imp_essalud,
                   a.aporte_oblig   = ln_aporte_oblig,
                   a.comision_var   = ln_comision_var,
                   a.prima_seguro   = ln_prima_seguro,
                   a.imp_dominical  = ln_imp_dominical,
                   a.gratificacion  = ln_imp_gratif,
                   a.bon_gratificacion = ln_imp_bonif
             Where trunc(a.fecha) = trunc(c_a.fecha)
               AND a.cod_trabajador   = c_t.cod_trabajador
               AND a.nro_item         = c_a.nro_item;


            -- Una vez obtenidos los importes totales, a continuacion distribuyo el importe por el detalle
            ln_imp_x_dist := ln_ganancia_bruta + ln_imp_essalud + ln_imp_bonif + ln_imp_gratif;

            SELECT SUM(c.ha_cultivadas)
              INTO ln_tot_has
              FROM pd_jornal_campo_lote a,
                   cultivos             c
             WHERE a.nro_lote = c.nro_lote
               AND a.variedad = c.variedad
               AND a.fecha    = c_a.fecha
               AND a.cod_trabajador = c_t.cod_trabajador
               AND a.nro_item       = c_a.nro_item;

            IF ln_tot_has > 0 THEN
               FOR lc_reg IN c_lotes(c_a.fecha, c_t.cod_trabajador, c_a.nro_item) LOOP
                   UPDATE pd_jornal_campo_lote t
                      SET t.imp_neto = ln_imp_x_dist * lc_reg.ha_cultivadas / ln_tot_has
                    WHERE t.fecha          = lc_reg.fecha
                      AND t.cod_trabajador = lc_reg.cod_trabajador
                      AND t.nro_item       = lc_reg.nro_item
                      AND t.nro_lote       = lc_reg.nro_lote;
               END LOOP;

               -- Ahora ajusto si el total distribuido coincide
               SELECT SUM(a.imp_neto)
                 INTO ln_imp_neto
                 FROM pd_jornal_campo_lote a,
                      cultivos             c
                WHERE a.nro_lote = c.nro_lote
                  AND a.variedad = c.variedad
                  AND a.fecha    = c_a.fecha
                  AND a.nro_item = c_a.nro_item
                  AND a.cod_trabajador = c_t.cod_trabajador;

               IF ln_imp_neto <> ln_imp_x_dist THEN
                  ln_diferencia := ln_imp_x_dist - ln_imp_neto;

                  -- Ahora obtengo el primer lote con el importe mas alto, a ese le aplico la diferencia
                  SELECT NRO_ITEM, NRO_LOTE
                    INTO ln_nro_item, ls_nro_lote
                    FROM (SELECT A.FECHA,
                                 A.COD_TRABAJADOR,
                                 A.NRO_LOTE, A.Nro_Item
                            FROM PD_JORNAL_CAMPO_LOTE A,
                                 CULTIVOS C
                           WHERE A.NRO_LOTE       = C.NRO_LOTE
                             AND A.VARIEDAD       = C.VARIEDAD
                             AND A.FECHA          = C_A.FECHA
                             AND A.COD_TRABAJADOR = C_T.COD_TRABAJADOR
                           ORDER BY A.IMP_NETO DESC)
                   WHERE ROWNUM = 1;

                  -- Actualizo la diferencia al mayor importe
                  UPDATE PD_JORNAL_CAMPO_LOTE T
                     SET T.IMP_NETO = T.IMP_NETO + LN_DIFERENCIA
                   WHERE t.fecha = C_A.fecha
                     AND t.cod_trabajador = C_A.cod_trabajador
                     AND t.nro_item       = ln_nro_item
                     AND t.nro_lote       = ls_nro_lote;
               END IF;
            END IF;
        End Loop;


     End If;

 End Loop;

 COMMIT;

End USP_RH_JORNAL_CAMPO_COSTO;
/
