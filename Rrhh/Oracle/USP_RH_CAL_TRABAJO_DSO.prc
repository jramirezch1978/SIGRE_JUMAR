create or replace procedure usp_rh_cal_trabajo_dso(
  asi_codtra       in maestro.cod_trabajador%TYPE,
  adi_fec_proceso  in date,
  asi_origen       in origen.cod_origen%TYPE,
  ani_tipcam       in number,
  asi_tipo_trabaj  IN  maestro.tipo_trabajador%TYPE,      -- Tipo de trabajador
  ani_dias_trabaj  IN NUMBER
) IS

  ls_tipo_jor             rrhhparam.tipo_trab_obrero%TYPE;
  ls_tipo_des             rrhhparam.tipo_trab_destajo%TYPE;
  ls_flag_tipo_sueldo     tipo_trabajador.flag_ingreso_boleta%TYPE;
  ls_cnc_dominical        asistparam.cnc_dominical%TYPE;
  ln_dias                 NUMBER;
  ln_imp_soles            calculo.imp_soles%TYPE          := 0;
  ln_imp_dolar            calculo.imp_dolar%TYPE          := 0;
  ln_jornal               calculo.imp_soles%TYPE;
  ln_dias_periodo         NUMBER;
  ln_dias_feriados        NUMBER;
  ln_hrs_normales         calculo.horas_trabaj%TYPE;
  ln_hrs_norm_cmp         number;
  ls_flag_agrario         tipo_trabajador.flag_sector_agrario%TYPE;

  ld_fec_ini              DATE;
  ld_fec_fin              DATE;
  ln_dia                  number;
  ld_fec_ingreso          maestro.fec_ingreso%TYPE;  -- Fecha de ingreso de los trabajadores
  ld_fec_cese             maestro.fec_cese%TYPE;
  ld_fecha                date;
  ln_count                number;

begin

--  ************************************************************************************************************
--  CALCULA EL DESCANSO SEMANAL OBLIGATORIO CORRESPONDIENTE, POR EL MOMENTO SOLAMENTE LO HACE CON LOS JORNALEROS
--  ************************************************************************************************************

IF ani_dias_trabaj = 0 THEN
   RETURN;
END IF;

SELECT r.tipo_trab_obrero, r.tipo_trab_destajo
  INTO ls_tipo_jor, ls_tipo_des
  FROM rrhhparam r
 WHERE r.reckey = '1';

SELECT a.cnc_dominical
  INTO ls_cnc_dominical
  FROM asistparam a
 WHERE a.reckey = '1';

select t.flag_ingreso_boleta, t.flag_sector_agrario
  into ls_flag_tipo_sueldo, ls_flag_agrario
  from tipo_trabajador t
 where t.tipo_trabajador = asi_tipo_trabaj;

-- El rango de fecha para el calculo por la fecha de proceso
SELECT t.fec_inicio, t.fec_final
  INTO ld_fec_ini, ld_fec_fin
  FROM rrhh_param_org t
 WHERE t.origen = asi_origen
   AND t.tipo_trabajador = asi_tipo_trabaj
   AND trunc(t.fec_proceso) = trunc(adi_fec_proceso);

SELECT m.fec_ingreso, m.fec_cese
  INTO ld_fec_ingreso, ld_fec_cese
  FROM maestro m
 WHERE m.cod_trabajador = asi_codtra;

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

-- Calculo los dias del periodo
ln_dias_periodo := ld_fec_fin - ld_fec_ini + 1;

IF ls_flag_tipo_sueldo = 'J' or asi_tipo_trabaj = ls_tipo_jor THEN
   -- Realizo el calculo del Descanso semanal obligatorio para los jornaleros

   if ls_flag_agrario = '1' then
       -- Obtengo primero el calculo por hora
       SELECT sum(G.IMP_GAN_DESC)
         INTO ln_imp_soles
         FROM gan_desct_fijo g
        WHERE G.COD_TRABAJADOR = ASI_CODTRA
          AND G.FLAG_ESTADO = '1'
          AND G.CONCEP IN (SELECT D.CONCEPTO_CALC
                            FROM GRUPO_CALCULO_DET D
                           WHERE D.GRUPO_CALCULO = (SELECT C.GRP_DOMINICAL
                                                      FROM RRHHPARAM_CCONCEP C
                                                     WHERE C.RECKEY = '1'));

       -- Busco el jornal diario
       ln_jornal := ln_imp_soles / 30; -- ani_dias_mes;

       -- Ahora cuento los dias normales trabajados
       SELECT NVL(SUM(a.hor_diu_nor + a.hor_noc_nor),0)
         INTO ln_hrs_normales
         FROM asistencia a
        WHERE a.cod_trabajador = asi_codtra
          AND trunc(a.fec_movim) BETWEEN trunc(ld_fec_ini) AND trunc(ld_fec_fin)
          AND a.flag_feriado = '0'
          AND Nvl(a.flag_descanso,'0') = '0'
          AND a.flag_1mayo = '0';

       -- Ahora cuento los dias normales trabajados
       SELECT NVL(SUM(p.hrs_normales + p.hrs_noc_extras_35),0)
         INTO ln_hrs_norm_cmp
         FROM pd_jornal_campo p
        WHERE p.cod_trabajador = asi_codtra
          AND trunc(p.fecha) BETWEEN trunc(ld_fec_ini) AND trunc(ld_fec_fin);

      if ls_flag_agrario = '1' then
         ln_dias := round(ln_hrs_normales  + ln_hrs_norm_cmp / 8,2);
      else
         ln_dias := ani_dias_trabaj;
      end if;

      -- Luego cuento los dias feriados del periodo que no esten en vacaciones
      ln_dias_feriados := 0;
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
             SELECT COUNT(*)
               INTO ln_count
               FROM calendario_feriado cf
              WHERE cf.origen = asi_origen
                AND cf.mes    = to_number(to_char(ld_fecha, 'mm'))
                AND cf.dia    = to_number(to_char(ld_fecha, 'dd'));

             IF ln_count > 0 THEN
                ln_dias_feriados := ln_dias_feriados + 1;
             end if;

          end if;
      end loop;

      ln_dias := ln_dias + ln_dias_feriados;
      ln_hrs_normales := ln_hrs_normales + ln_hrs_norm_cmp + ln_dias_feriados * 8;

      IF ln_dias > ln_dias_periodo THEN
         ln_dias := ln_dias_periodo;
      END IF;

      -- Calculo el dso
      ln_imp_soles := ln_jornal / 6 * ln_dias;
      
   else
      -- Obtengo primero el calculo por hora
      SELECT sum(c.imp_soles)
        INTO ln_imp_soles
        FROM calculo c
       WHERE c.COD_TRABAJADOR = ASI_CODTRA
         AND c.CONCEP IN (SELECT D.CONCEPTO_CALC
                            FROM GRUPO_CALCULO_DET D
                           WHERE D.GRUPO_CALCULO = (SELECT C.GRP_DOMINICAL
                                                      FROM RRHHPARAM_CCONCEP C
                                                     WHERE C.RECKEY = '1'));

      ln_dias := ani_dias_trabaj;

      -- Luego cuento los dias feriados del periodo que no esten en vacaciones
      ln_dias_feriados := 0;
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
             SELECT COUNT(*)
               INTO ln_count
               FROM calendario_feriado cf
              WHERE cf.origen = asi_origen
                AND cf.mes    = to_number(to_char(ld_fecha, 'mm'))
                AND cf.dia    = to_number(to_char(ld_fecha, 'dd'));

             IF ln_count > 0 THEN
                ln_dias_feriados := ln_dias_feriados + 1;
             end if;

          end if;
      end loop;

      ln_dias := ln_dias + ln_dias_feriados;
      ln_hrs_normales := 0;

      IF ln_dias > ln_dias_periodo THEN
         ln_dias := ln_dias_periodo;
      END IF;

      -- Calculo el dominical
      ln_imp_soles := ln_imp_soles / 6;
   end if;
   
elsif asi_tipo_trabaj = ls_tipo_des then
   -- Calculo del Descanso Semanal obligatorio para los Destajeros
   
   -- Obtengo primero el calculo por hora
   SELECT sum(c.imp_soles)
     INTO ln_imp_soles
     FROM calculo c
    WHERE c.COD_TRABAJADOR = ASI_CODTRA
      AND c.CONCEP IN (SELECT D.CONCEPTO_CALC
                         FROM GRUPO_CALCULO_DET D
                        WHERE D.GRUPO_CALCULO = (SELECT C.GRP_DOMINICAL
                                                   FROM RRHHPARAM_CCONCEP C
                                                  WHERE C.RECKEY = '1'));

   IF ani_dias_trabaj > ln_dias_periodo THEN
      ln_dias := ln_dias_periodo;
   else
      ln_dias := ani_dias_trabaj;
   END IF;

   -- Calculo el dominical
   ln_imp_soles := ln_imp_soles / 6;
END IF;

IF ln_imp_soles > 0 THEN
   ln_imp_dolar := ln_imp_soles / ani_tipcam;
   
   update calculo c
      set c.horas_trabaj = ln_hrs_normales,
          c.horas_pag    = ln_hrs_normales,
          c.dias_trabaj  = ln_dias,
          c.imp_soles    = ln_imp_soles,
          c.imp_dolar    = ln_imp_dolar
    where c.cod_trabajador = asi_codtra
      and c.concep         = ls_cnc_dominical
      and c.fec_proceso    = adi_fec_proceso; 

   if SQL%NOTFOUND then
      insert into calculo (
                 cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                 dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
      values (
                 asi_codtra, ls_cnc_dominical, adi_fec_proceso, ln_hrs_normales, ln_hrs_normales ,
                 ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;
   end if;
END IF;


end usp_rh_cal_trabajo_dso;
/
