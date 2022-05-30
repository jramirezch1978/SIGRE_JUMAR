create or replace procedure USP_RH_CALC_FERIADO(
  asi_codtra       in maestro.cod_trabajador%TYPE,
  adi_fec_proceso  in date,
  asi_origen       in origen.cod_origen%TYPE,
  ani_tipcam       in number,
  asi_tipo_trabaj  IN  maestro.tipo_trabajador%TYPE,      -- Tipo de trabajador
  ani_dias_trabaj  IN NUMBER
) IS

  ls_tipo_obrero          rrhhparam.tipo_trab_obrero%TYPE;
  ls_cnc_feriado          asistparam.cnc_feriado%TYPE;
  ls_cnc_fer_dia_desc     asistparam.cnc_fer_dia_desc%TYPE;     -- Feriado en día de descanso
  ls_cnc_asig_familiar    asistparam.cnc_asig_familiar%TYPE;    -- Asignación Familiar
  ls_concepto             concepto.concep%TYPE;
  ln_item                 NUMBER;
  ln_count                NUMBER;

  ln_dia                  NUMBER;
  ln_imp_soles            calculo.imp_soles%TYPE;
  ln_imp_dolar            calculo.imp_dolar%TYPE;
  ln_jornal               calculo.imp_soles%TYPE;
  ln_dias_periodo         NUMBER;

  ld_fec_ini              DATE;
  ld_fec_fin              DATE;
  ld_fec_ingreso          maestro.fec_ingreso%TYPE;  -- Fecha de ingreso de los trabajadores
  ld_fecha                DATE;

begin

--  ****************************************************************************************************
--  CALCULA EL DOMINICAL CORRESPONDIENTE, POR EL MOMENTO SOLAMENTE LO HACE CON LOS JORNALEROS
--  ****************************************************************************************************

IF ani_dias_trabaj = 0 THEN
   -- Si el número de días de Trabajo es cero entonces no tengo que hacer nada
   RETURN;
END IF;

SELECT r.tipo_trab_obrero
  INTO ls_tipo_obrero
  FROM rrhhparam r
 WHERE r.reckey = '1';

SELECT t.cnc_feriado, t.cnc_fer_dia_desc, t.cnc_asig_familiar
  INTO ls_cnc_feriado, ls_cnc_fer_dia_desc, ls_cnc_asig_familiar
  FROM asistparam t
 WHERE t.reckey = '1';

-- El rango de fecha para el calculo por la fecha de proceso
SELECT t.fec_inicio, t.fec_final
  INTO ld_fec_ini, ld_fec_fin
  FROM rrhh_param_org t
 WHERE t.origen = asi_origen
   AND t.tipo_trabajador = asi_tipo_trabaj
   AND trunc(t.fec_proceso) = trunc(adi_fec_proceso);

SELECT m.fec_ingreso
  INTO ld_fec_ingreso
  FROM maestro m
 WHERE m.cod_trabajador = asi_codtra;

-- Si la fecha de ingreso de trabajador es mayor que la fecha hasta entonces no debo calcular nada
-- porque ingreso en un periodo posterior al periodo
IF ld_fec_ingreso > ld_fec_fin THEN
   RETURN;
END IF;

IF ld_fec_ingreso > ld_fec_ini THEN
   ld_fec_ini := ld_fec_ingreso;
END IF;

ln_dias_periodo := ld_fec_fin - ld_fec_ini + 1;

-- Obtengo primero el calculo por hora
SELECT sum(G.IMP_GAN_DESC)
  INTO ln_imp_soles
  FROM gan_desct_fijo g
 WHERE G.COD_TRABAJADOR = ASI_CODTRA
   AND G.FLAG_ESTADO = '1'
   AND G.CONCEP IN (SELECT D.CONCEPTO_CALC
                     FROM GRUPO_CALCULO_DET D
                    WHERE D.GRUPO_CALCULO =
                          (SELECT C.CONCEP_GAN_FIJ
                             FROM RRHHPARAM_CCONCEP C
                            WHERE C.RECKEY = '1'))
   AND g.concep <> ls_cnc_asig_familiar;

-- Busco el jornal diario
ln_jornal := ln_imp_soles / 30;

IF ln_jornal > 0 THEN
   -- Calculo el jornal
   ln_imp_soles := ln_jornal ;
   ln_imp_dolar := ln_imp_soles / ani_tipcam;

   FOR ln_dia IN 0..ln_dias_periodo - 1 LOOP
       ld_fecha := ld_fec_ini + ln_dia;

       -- Si es 1 de Mayo y es día de descanso entonces ya se gano un jornal mas sea jornal o empleado
       IF to_char(ld_fecha, 'mmdd') = '0501' AND usf_rh_is_dia_descanso(asi_codtra, ld_fecha) THEN
           ls_concepto := ls_cnc_feriado;

           SELECT COUNT(*)
             INTO ln_item
             FROM calculo c
            WHERE c.cod_trabajador = asi_codtra
              AND c.concep         = ls_concepto
              AND c.fec_proceso    = adi_fec_proceso;

           ln_item := ln_item + 1;

           insert into calculo (
                 cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                 dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
           values (
                 asi_codtra, ls_concepto, adi_fec_proceso, 8, 8,
                 1, ln_imp_soles, ln_imp_dolar, asi_origen, '1', ln_item ) ;

       END IF;

       -- Si es feriado entonces agrego un jornal adicional, esto es solamente para los obreros
       IF asi_tipo_trabaj = ls_tipo_obrero THEN
          SELECT COUNT(*)
            INTO ln_count
            FROM calendario_feriado cf
           WHERE cf.origen = asi_origen
             AND cf.mes    = to_number(to_char(ld_fecha, 'mm'))
             AND cf.dia    = to_number(to_char(ld_fecha, 'dd'));

          IF ln_count > 0 THEN
             UPDATE calculo
                SET horas_trabaj = horas_trabaj + 8,
                    horas_pag    = horas_pag + 8,
                    dias_trabaj  = dias_trabaj + 1,
                    imp_soles    = imp_soles + ln_imp_soles,
                    imp_dolar    = imp_dolar + ln_imp_dolar
              WHERE cod_trabajador = asi_codtra
                AND concep = ls_concepto;

                  IF SQL%NOTFOUND THEN
                     insert into calculo (
                        cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                        dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
                     values (
                        asi_codtra, ls_concepto, adi_fec_proceso, 8, 8,
                        1, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;
                  END IF;
          END IF;
       END IF;
   END LOOP;
END IF;

end USP_RH_CALC_FERIADO;
/
