create or replace procedure USP_RH_CAL_FERIADO(
  asi_codtra         in maestro.cod_trabajador%TYPE,
  adi_fec_proceso    in date,
  asi_origen         in origen.cod_origen%TYPE,
  ani_tipcam         in number,
  asi_tipo_trabaj    IN maestro.tipo_trabajador%TYPE,      -- Tipo de trabajador
  ani_dias_trabaj    IN NUMBER,
  asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) IS

  ls_tipo_obrero          rrhhparam.tipo_trab_obrero%TYPE;
  ls_cnc_feriado          asistparam.cnc_feriado%TYPE;
  ls_cnc_fer_dia_desc     asistparam.cnc_fer_dia_desc%TYPE;     -- Feriado en dia de descanso
  ls_cnc_asig_familiar    asistparam.cnc_asig_familiar%TYPE;    -- Asignacion Familiar
  ls_flag_tipo_sueldo     tipo_trabajador.flag_ingreso_boleta%TYPE;
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
  ld_fec_cese             maestro.fec_cese%TYPE;
  ld_fecha                DATE;
  
  -- Emergencia
  ls_cnc_gratif_ext     asistparam.cnc_gratif_ext%TYPE;
  ls_cnc_bon_gratif     asistparam.cnc_bonif_ext%TYPE;
  ln_porc_gratf         asistparam.porc_gratif_campo%TYPE;
  ln_porc_bonif         asistparam.porc_bonif_ext%TYPE;
  
  -- Vacaciones
  ls_cnc_vacaciones     concepto.concep%TYPE;


begin

--  ****************************************************************************************************
--  CALCULA EL DOMINICAL CORRESPONDIENTE, POR EL MOMENTO SOLAMENTE LO HACE CON LOS JORNALEROS
--  ****************************************************************************************************

IF ani_dias_trabaj = 0 THEN
   -- Si el numero de dias de Trabajo es cero entonces no tengo que hacer nada
   -- RETURN;
   null;
END IF;

SELECT r.tipo_trab_obrero
  INTO ls_tipo_obrero
  FROM rrhhparam r
 WHERE r.reckey = '1';

-- Obteniendo parametros para el calculo
SELECT t.cnc_feriado, t.cnc_fer_dia_desc, t.cnc_asig_familiar, t.cnc_gratif_ext, t.cnc_bonif_ext, t.porc_gratif_campo,
       t.porc_bonif_ext
  INTO ls_cnc_feriado, ls_cnc_fer_dia_desc, ls_cnc_asig_familiar, ls_cnc_gratif_ext, ls_cnc_bon_gratif,
       ln_porc_gratf, ln_porc_bonif
  FROM asistparam t
 WHERE t.reckey = '1';

-- Obteniendo el concepto de vacaciones
select gc.concepto_gen
  into ls_cnc_vacaciones
  from grupo_calculo gc
 where gc.grupo_calculo = (select r.gan_fij_calc_vacac from rrhhparam_cconcep r where reckey = '1');
 
-- El rango de fecha para el calculo por la fecha de proceso
SELECT t.fec_inicio, t.fec_final
  INTO ld_fec_ini, ld_fec_fin
  FROM rrhh_param_org t
 WHERE t.origen = asi_origen
   AND t.tipo_trabajador = asi_tipo_trabaj
   AND trunc(t.fec_proceso) = trunc(adi_fec_proceso)
   and t.tipo_planilla      = asi_tipo_planilla;

SELECT m.fec_ingreso, m.fec_cese
  INTO ld_fec_ingreso, ld_fec_cese
  FROM maestro m
 WHERE m.cod_trabajador = asi_codtra;

-- Obtengo el plag de pago de boleta si es jornal o sueldo
select t.flag_ingreso_boleta
  into ls_flag_tipo_sueldo
  from tipo_trabajador t
 where t.tipo_trabajador = asi_tipo_trabaj;

-- Si la fecha de ingreso de trabajador es mayor que la fecha hasta entonces no debo calcular nada
-- porque ingreso en un periodo posterior al periodo
IF ld_fec_ingreso > ld_fec_fin THEN
   RETURN;
END IF;

if ld_fec_cese is not null then
   if ld_fec_cese < ld_fec_ini then
      return;
   elsif ld_fec_cese < ld_fec_fin then
      ld_fec_fin := ld_fec_cese;
   end if;
      
end if;

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
ln_jornal := ln_imp_soles / 30; -- ani_dias_mes;

IF ln_jornal > 0 THEN

   FOR ln_dia IN 0..ln_dias_periodo - 1 LOOP
       ld_fecha := ld_fec_ini + ln_dia;
       
       -- Si la fecha esta dentro de su periodo vacacional entonces no procedo al calculo
       select count(*)
         into ln_count
         from inasistencia i
        where i.cod_trabajador = asi_codtra
          and i.fec_movim      = adi_fec_proceso
          and ld_fecha         between i.fec_desde and i.fec_hasta;
       
       if ln_count = 0 then
          -- Calculo el jornal
          ln_imp_soles := ln_jornal ;
           
          ln_imp_dolar := ln_imp_soles / ani_tipcam;
          -- Si es feriado entonces agrego un jornal adicional, esto es solamente para los que perciban 
          -- sueldo de tipo Jornal y no fijo
          IF ls_flag_tipo_sueldo = 'J' THEN
          
             -- Si es 1 de Mayo y es dia de descanso entonces ya se gano un jornal mas sea jornal o empleado
             IF to_char(ld_fecha, 'mmdd') = '0501' AND usf_rh_is_dia_descanso(asi_codtra, ld_fecha) THEN
                ls_concepto := ls_cnc_feriado;

                SELECT COUNT(*)
                  INTO ln_item
                  FROM calculo c
                 WHERE c.cod_trabajador = asi_codtra
                   AND c.concep         = ls_concepto
                   AND c.fec_proceso    = adi_fec_proceso
                   and c.tipo_planilla  = asi_tipo_planilla;

                ln_item := ln_item + 1;

                insert into calculo (
                      cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                      dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
                values (
                      asi_codtra, ls_concepto, adi_fec_proceso, 8, 8,
                      1, ln_imp_soles, ln_imp_dolar, asi_origen, '1', ln_item, asi_tipo_planilla ) ;

             END IF;

          
             SELECT COUNT(*)
               INTO ln_count
               FROM calendario_feriado cf
              WHERE cf.origen = asi_origen
                AND cf.mes    = to_number(to_char(ld_fecha, 'mm'))
                AND cf.dia    = to_number(to_char(ld_fecha, 'dd'));

             IF ln_count > 0 THEN
                -- Si es un día feriado, valido que haya venido a trbajar en la semana, en este caso jornaleros simplemente
                -- Cambio realizado para CANTABRIA
                select count(*)
                  into ln_count
                  from asistencia a
                 where a.cod_trabajador = asi_codtra
                   and trunc(a.fec_movim) between trunc(ld_fec_ini) and trunc(ld_fec_fin);
                
                if ln_count > 0 then
                   IF usf_rh_is_dia_descanso(asi_codtra, ld_fecha) THEN
                      ls_concepto := ls_cnc_fer_dia_desc;
                   ELSE
                      ls_concepto := ls_cnc_feriado;
                   END IF;

                   UPDATE calculo
                      SET horas_trabaj = horas_trabaj + 8,
                          horas_pag    = horas_pag + 8,
                          dias_trabaj  = dias_trabaj + 1,
                          imp_soles    = imp_soles + ln_imp_soles,
                          imp_dolar    = imp_dolar + ln_imp_dolar
                    WHERE cod_trabajador = asi_codtra
                      AND concep         = ls_concepto
                      and tipo_planilla  = asi_tipo_planilla;

                   IF SQL%NOTFOUND THEN
                      insert into calculo (
                               cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                               dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, 
                               item, tipo_planilla )
                      values (
                               asi_codtra, ls_concepto, adi_fec_proceso, 8, 8,
                               1, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                               asi_tipo_planilla ) ;
                   END IF;
                end if;
                 
              END IF;
           END IF;
          
       end if;
       
   END LOOP;
END IF;

end USP_RH_CAL_FERIADO;
/
