create or replace procedure USP_RH_HORAS_ASISTENCIA(
       adi_fecha1 IN DATE,
       adi_fecha2 IN DATE

) IS

  CURSOR c_fechas IS
     SELECT DISTINCT a.cod_trabajador, a.fec_movim, m.cod_origen
       FROM asistencia a,
            maestro    m
      WHERE a.cod_trabajador = m.cod_trabajador
        AND trunc(a.fec_movim) BETWEEN trunc(adi_fecha1) AND trunc(adi_fecha2)
        --AND a.cod_tipo_mov = (SELECT ap.mov_asist_nor FROM asistparam ap WHERE ap.reckey = '1')
      ORDER BY a.cod_trabajador, a.fec_movim;

  CURSOR c_datos(as_codtra asistencia.cod_trabajador%TYPE, ad_fecha DATE) IS
     SELECT a.fec_desde, a.fec_hasta, (a.fec_hasta - a.fec_desde) * 24 AS horas_trab,
            a.turno, a.cod_tipo_mov, to_char(a.fec_desde, 'dd/mm/yyyy hh:mm:ss') AS fec_desde_str,
            to_number(to_char(a.fec_movim, 'd')) as nro_dia,
            to_number(to_char(a.fec_hasta, 'd')) as nro_dia_hasta,
            a.flag_feriado, a.flag_descanso, a.flag_1mayo
       FROM asistencia a
      WHERE trunc(a.fec_movim) BETWEEN trunc(adi_fecha1) AND trunc(adi_fecha2)
        AND a.cod_trabajador = as_codtra
        AND a.fec_movim      = ad_fecha
        --AND a.cod_tipo_mov = (SELECT ap.mov_asist_nor FROM asistparam ap WHERE ap.reckey = '1')
      ORDER BY a.fec_desde;

  ls_hora_ini_noc      asistparam.hora_inicio_noc%TYPE;
  ls_hora_fin_noc      asistparam.hora_fin_noc%TYPE;
  ld_hora_ini_noc      DATE;
  ld_hora_fin_noc      DATE;
  ld_hora_ini_dia      DATE;  -- Fecha y hora del inicio de horario diurno
  ld_fin_dia           DATE;
  ld_ini_dia           DATE;
  ls_fecha             VARCHAR2(40);
  ld_fec_desde         DATE;
  ld_fec_hasta         DATE;

  ln_count             NUMBER;

  -- Ahora viene las horas
  ln_hrs_diu_nor       asistencia.hor_diu_nor%TYPE;
  ln_hrs_diu_ext1      asistencia.hor_ext_diu_1%TYPE;
  ln_hrs_diu_ext2      asistencia.hor_ext_diu_2%TYPE;
  ln_hrs_noc_nor       asistencia.hor_noc_nor%TYPE;
  ln_hrs_noc_ext1      asistencia.hor_ext_noc_1%TYPE;
  ln_hrs_noc_ext2      asistencia.hor_ext_noc_2%TYPE;
  ln_hrs_ext_100       asistencia.hor_ext_100%TYPE;

  -- Horas totales
  ln_tot_hrs_diu1      NUMBER;
  ln_tot_hrs_diu2      NUMBER;
  ln_tot_hrs_noc1      NUMBER;
  ln_tot_hrs_noc2      NUMBER;
  ln_tot_hrs_diu_nor   asistencia.hor_diu_nor%TYPE;
  ln_tot_hrs_diu_ext1  asistencia.hor_ext_diu_1%TYPE;
  ln_tot_hrs_diu_ext2  asistencia.hor_ext_diu_2%TYPE;
  ln_tot_hrs_noc_nor   asistencia.hor_noc_nor%TYPE;
  ln_tot_hrs_noc_ext1  asistencia.hor_ext_noc_1%TYPE;
  ln_tot_hrs_noc_ext2  asistencia.hor_ext_noc_2%TYPE;
  ln_tot_hrs_ext_100   asistencia.hor_ext_100%TYPE;

  -- Datos para determinar si es dia feriado, domingo o 1 Mayo
  ls_flag_descanso     asistencia.flag_descanso%TYPE;
  ls_flag_feriado      asistencia.flag_feriado%TYPE;
  ls_flag_1Mayo        asistencia.flag_1mayo%TYPE;
  ln_horas             number;

BEGIN

  -- Obtengo los datos del inicio y fin del horario nocturno
  SELECT COUNT(*)
    INTO ln_count
    FROM asistparam
   WHERE reckey = '1';

  IF ln_count = 0 THEN
     RAISE_APPLICATION_ERROR(-20000, 'Error, no existen parametros en ASISTPARAM');
  END IF;

  SELECT a.hora_inicio_noc, a.hora_fin_noc
    INTO ls_hora_ini_noc, ls_hora_fin_noc
    FROM asistparam a
   WHERE a.reckey = '1';

  -- Primero recorro todos los registros para determinar si es feriado, domingo o 1 de mayo
  FOR lc_reg IN c_fechas LOOP
      ls_flag_1Mayo := '0'; ls_flag_descanso := '0'; ls_flag_feriado := '0';

      -- El mas facil, valido si es 1 de Mayo
      IF to_char(lc_reg.fec_movim, 'ddmm') = '0105' THEN
         ls_flag_1Mayo := '1';
      END IF;

      -- Luego si es un feriado
      SELECT COUNT(*)
        INTO ln_count
        FROM calendario_feriado cf
       WHERE cf.origen = lc_reg.cod_origen
         AND cf.mes    = to_number(to_char(lc_reg.fec_movim, 'mm'))
         AND cf.dia    = to_number(to_char(lc_reg.fec_movim, 'dd'));

      IF ln_count > 0 THEN
         ls_flag_feriado := '1';
      END IF;

      -- Por ultimo el dia de descanso (por defecto debe ser el dia domingo)
      IF usf_rh_is_dia_descanso(lc_reg.cod_trabajador, lc_reg.fec_movim) THEN
         ls_flag_descanso := '1';
      END IF;

      -- Ahora actualizo los datos
      UPDATE asistencia a
         SET a.flag_feriado  = ls_flag_feriado,
             a.flag_descanso = ls_flag_descanso,
             a.flag_1mayo    = ls_flag_1Mayo
       WHERE a.cod_trabajador = lc_reg.cod_trabajador
         AND a.fec_movim      = lc_reg.fec_movim;

  END LOOP;
  

  FOR lc_reg IN c_fechas LOOP
      -- Inicializo los totales
      ln_tot_hrs_diu_nor := 0; ln_tot_hrs_diu_ext1 := 0; ln_tot_hrs_diu_ext2 := 0;
      ln_tot_hrs_noc_nor := 0; ln_tot_hrs_noc_ext1 := 0; ln_tot_hrs_noc_ext2 := 0;
      ln_tot_hrs_ext_100 := 0;

      -- Recorriendo los datos por cada fecha
      FOR lc_datos IN c_datos(lc_reg.cod_trabajador, lc_reg.fec_movim) LOOP
          -- Inicializo los datos para trabajar
          ln_hrs_diu_nor := 0; ln_hrs_diu_ext1 := 0; ln_hrs_diu_ext2 := 0;
          ln_hrs_noc_nor := 0; ln_hrs_noc_ext1 := 0; ln_hrs_noc_ext2 := 0;
          ln_hrs_ext_100 := 0;

          -- Inicializo los totales diurnos y nocturnos
          ln_tot_hrs_diu1 := 0; ln_tot_hrs_diu2 := 0;
          ln_tot_hrs_noc1 := 0; ln_tot_hrs_noc2 := 0;

          -- Ahora lo que tengo que hacer es sacar las horas diurnas completas y las horas
          -- nocturnas completas

          -- Primero saco la fecha de fin de dia
          ls_fecha := to_char(lc_datos.fec_desde, 'dd/mm/yyyy') || ' 23:59:59';
          ld_fin_dia := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');

          -- Luego saco la fecha y hora de inicio del dia
          ls_fecha := to_char(lc_datos.fec_desde, 'dd/mm/yyyy') || ' 00:00:00';
          ld_ini_dia := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');

          -- Tengo que sacar la fecha de inicio y de fin de horario nocturno
          IF pkg_config.USF_GET_PARAMETER('CALCULO_HORA_NOC', '1') = '1' THEN
             ls_fecha := to_char(lc_datos.fec_desde, 'dd/mm/yyyy') || ' ' || ls_hora_ini_noc;
             ld_hora_ini_noc := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');

             IF ls_hora_fin_noc < ls_hora_ini_noc THEN
                -- Si la hora de fin de horario nocturno es menor que la hora de inicio
                -- entoncese se trata de dos dias diferentes
                ls_fecha := to_char(lc_datos.fec_desde + 1, 'dd/mm/yyyy') || ' ' || ls_hora_fin_noc;
                ld_hora_fin_noc := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');
             ELSE
                -- Si la hora de fin es mayor que la hora de inicio entonces son del
                -- mismo dia
                ls_fecha := to_char(lc_datos.fec_desde, 'dd/mm/yyyy') || ' ' || ls_hora_fin_noc;
                ld_hora_fin_noc := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');
             END IF;
          else
             ld_hora_ini_noc := null;
             ld_hora_fin_noc := null;
          END IF;

          -- Para terminar saco la hora de fin de horario nocturno pero del mismo dia, esto es para aquellos personas que ingresan de madrugada
          -- y terminan antes del horario nocturno
          if ld_hora_fin_noc is not null then
             ls_fecha := to_char(lc_datos.fec_desde, 'dd/mm/yyyy') || ' ' || ls_hora_fin_noc;
             ld_hora_ini_dia := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');
          else
             ls_fecha := to_char(lc_datos.fec_desde, 'dd/mm/yyyy') || ' ' || '08:00:00';
             ld_hora_ini_dia := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');
          end if;

          -- Una vez que lo tengo entonces ahora empieza la comparacion
          -- primero obtengo las horas normales
          ld_fec_desde := lc_datos.fec_desde;
          ld_fec_hasta := lc_datos.fec_hasta;

          -- Si la Fecha de inicio es menor que la hora de inicio del horario nocturno significa
          -- entonces que tiene horas diurnas
          IF pkg_config.USF_GET_PARAMETER('CALCULO_HORA_NOC', '1') = '1' THEN
             IF lc_datos.fec_desde <= ld_hora_ini_noc THEN
                -- Verifico si la fecha desde es menor que la hora de fin de horario nocturno pero de la misma fecha
                if lc_datos.fec_desde < ld_hora_ini_dia THEN
                   IF ld_fec_hasta > ld_hora_ini_dia THEN
                      -- Si la fecha de ingreso es menor a la hora de fin de hora nocturna del mismo dia entonces ha hecho horas nocturnas
                      -- Saco las horas nocturnas
                      ln_tot_hrs_noc1 := ln_tot_hrs_noc1 + (ld_hora_ini_dia - ld_fec_desde) * 24;
                      ld_fec_desde := ld_hora_ini_dia;
                   ELSE
                      ln_tot_hrs_noc1 := ln_tot_hrs_noc1 + (ld_fec_hasta - ld_fec_desde) * 24;
                      ld_fec_desde := ld_fec_hasta;
                   END IF;
                end if;

                -- Tiene horas diurnas y posiblemente nocturnas
                IF ld_fec_hasta > ld_hora_ini_dia THEN
                   IF ld_fec_hasta < ld_hora_ini_noc THEN
                      ln_tot_hrs_diu1 := ln_tot_hrs_diu1 + (ld_fec_hasta - ld_fec_desde) * 24;
                   ELSE
                      -- Tiene horas diurnas y nocturnas, primero saco las horas diurnas
                      ln_tot_hrs_diu1 := ln_tot_hrs_diu1 + (ld_hora_ini_noc - ld_fec_desde) * 24;

                      -- Ahora verifico cuantas horas nocturnas ha hecho
                      -- Verifico si la hora de fin de turno es mayor o menor que la hora de fin de horario nocturno
                      IF lc_datos.fec_hasta < ld_hora_fin_noc THEN
                         ld_fec_hasta := lc_datos.fec_hasta;
                      ELSE
                         ld_fec_hasta := ld_hora_fin_noc;
                      END IF;

                      -- Obtengo las horas nocturnas
                      ln_tot_hrs_noc2 := ln_tot_hrs_noc2 + (ld_fec_hasta - ld_hora_ini_noc) * 24;

                      -- Luego verifico si la hora de salida es mayor a la hora de fin del horario nocturno
                      IF lc_datos.fec_hasta > ld_hora_fin_noc THEN
                         ln_tot_hrs_diu2 := ln_tot_hrs_diu2 + (lc_datos.fec_hasta - ld_hora_fin_noc)*24;
                      END IF;
                   END IF;
                END IF;
             ELSE
                -- No tiene horas diurnas
                ld_fec_desde := lc_datos.fec_desde;

                -- Verifico si la hora de fin de turno es mayor o menor que la hora de fin de horario nocturno
                IF lc_datos.fec_hasta < ld_hora_fin_noc THEN
                   ld_fec_hasta := lc_datos.fec_hasta;
                ELSE
                   ld_fec_hasta := ld_hora_fin_noc;
                END IF;

                -- Obtengo las horas nocturnas
                ln_tot_hrs_noc2 := ln_tot_hrs_noc2 + (ld_fec_hasta - ld_fec_desde) * 24;

                -- Luego verifico si la hora de salida es mayor a la hora de fin del horario nocturno
                IF lc_datos.fec_hasta > ld_hora_fin_noc THEN
                   ln_tot_hrs_diu2 := ln_tot_hrs_diu2 + (lc_datos.fec_hasta - ld_hora_fin_noc)*24;
                END IF;
             END IF;

          ELSE
             ln_tot_hrs_diu1 := lc_datos.horas_trab;
             ln_tot_hrs_noc1 := 0;
            
          end if;

          -- Ahora que ya tengo las horas totales diurnas y nocturnas tengo que procesarlas
          -- Primero las horas nocturnas antes de la hora de inicio de la hora diurna
          IF ln_tot_hrs_noc1 > 0 THEN
             -- En su totalidad serian horas normales, eso no hay problema
             ln_tot_hrs_noc_nor := ln_tot_hrs_noc1;
             ln_hrs_noc_nor := ln_tot_hrs_noc1;
             ln_tot_hrs_noc1 := 0;
          END IF;

          -- Primero las horas diurnas
          IF ln_tot_hrs_diu1 > 0 THEN
             -- primero saco las horas normales
             IF ln_tot_hrs_noc_nor + ln_tot_hrs_diu_nor < 8 THEN
                -- Saco las horas necesarias del total de horas
                IF ln_tot_hrs_diu1 >= (8 - (ln_tot_hrs_noc_nor + ln_tot_hrs_diu_nor)) THEN
                   ln_hrs_diu_nor := 8 - (ln_tot_hrs_noc_nor + ln_tot_hrs_diu_nor);
                   ln_tot_hrs_diu1 := ln_tot_hrs_diu1 - ln_hrs_diu_nor;
                ELSE
                   ln_hrs_diu_nor := ln_tot_hrs_diu1;
                   ln_tot_hrs_diu1 := 0;
                END IF;
             END IF;

             -- Si aun quedas horas diurnas veo si puedo llenar las horas extras 1
             IF ln_tot_hrs_diu1 > 0 THEN
                IF ln_tot_hrs_diu_ext1 < 2 THEN
                   IF ln_tot_hrs_diu1 > (2 - ln_tot_hrs_diu_ext1) THEN
                      ln_hrs_diu_ext1 := (2 - ln_tot_hrs_diu_ext1);
                      ln_tot_hrs_diu1 := ln_tot_hrs_diu1 - ln_hrs_diu_ext1;
                   ELSE
                      ln_hrs_diu_ext1 := ln_tot_hrs_diu1;
                      ln_tot_hrs_diu1 := 0;
                   END IF;
                END IF;
             END IF;

             -- Si aun quedan horas diurnas veo si puedo llenar las horas extras 2
             IF ln_tot_hrs_diu1 > 0 THEN
                ln_hrs_diu_ext2 := ln_tot_hrs_diu1;
             END IF;
          END IF;

          -- Luego las horas nocturnas
          IF ln_tot_hrs_noc2 > 0 THEN
             -- primero saco las horas normales nocturnas, para eso debo validar si las horas diurnas
             -- hasta ahora no suman las 8 horas
             IF ln_tot_hrs_diu_nor + ln_hrs_diu_nor + ln_tot_hrs_noc_nor < 8 THEN
                -- Saco las horas necesarias del total de horas
                IF ln_tot_hrs_noc2 >= (8 - (ln_tot_hrs_diu_nor + ln_hrs_diu_nor + ln_tot_hrs_noc_nor)) THEN
                   ln_hrs_noc_nor := 8 - (ln_tot_hrs_diu_nor + ln_hrs_diu_nor + ln_tot_hrs_noc_nor);
                   ln_tot_hrs_noc2 := ln_tot_hrs_noc2 - ln_hrs_noc_nor;
                ELSE
                   ln_hrs_noc_nor := ln_tot_hrs_noc2;
                   ln_tot_hrs_noc2 := 0;
                END IF;
             END IF;

             -- Si aun quedas horas nocturnas veo si puedo llenar las horas extras 1
             IF ln_tot_hrs_noc2 > 0 THEN
                -- Ahora averiguo cuanto si las horas extras diurnas hasta ahora no es mayor a 2 horas
                IF ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1 + ln_tot_hrs_noc_ext1 < 2 THEN
                   IF ln_tot_hrs_noc2 > (2 - (ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1 + ln_tot_hrs_noc_ext1)) THEN
                      ln_hrs_noc_ext1 := 2 - (ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1 + ln_tot_hrs_noc_ext1);
                      ln_tot_hrs_noc2 := ln_tot_hrs_noc2 - ln_hrs_noc_ext1;
                   ELSE
                      ln_hrs_noc_ext1 := ln_tot_hrs_noc2;
                      ln_tot_hrs_noc2  := 0;
                   END IF;
                END IF;
             END IF;

             -- Si aun quedan horas diurnas veo si puedo llenar las horas extras 2
             IF ln_tot_hrs_noc2 > 0 THEN
                ln_hrs_noc_ext2 := ln_tot_hrs_noc2;
             END IF;
          END IF;

          -- Ahora vienen las segundas horas diurnas, hay que tener cuidado porque generalmente si sa se tienen
          -- horas normales en diurno o en nocturno entonces
          IF ln_tot_hrs_diu2 > 0 THEN
             -- Averiguo si las horas normales diurnas + nocturnas hasta ahora no sumen 8
             IF ln_tot_hrs_diu_nor + ln_hrs_diu_nor + ln_tot_hrs_noc_nor + ln_hrs_noc_nor < 8 THEN
                -- Saco las horas necesarias del total de horas
                IF ln_tot_hrs_diu2 >= (8 - (ln_tot_hrs_diu_nor + ln_hrs_diu_nor + ln_tot_hrs_noc_nor + ln_hrs_noc_nor)) THEN
                   ln_hrs_diu_nor := ln_hrs_diu_nor + (8 - (ln_tot_hrs_diu_nor + ln_hrs_diu_nor + ln_tot_hrs_noc_nor + ln_hrs_noc_nor));
                   ln_tot_hrs_diu2 := ln_tot_hrs_diu2 - (8 - (ln_tot_hrs_diu_nor + ln_hrs_diu_nor + ln_tot_hrs_noc_nor + ln_hrs_noc_nor));
                ELSE
                   ln_hrs_diu_nor := ln_hrs_diu_nor + ln_tot_hrs_diu2;
                   ln_tot_hrs_diu2 := 0;
                END IF;
             END IF;

             -- Si aun quedas horas nocturnas veo si puedo llenar las horas extras 1
             IF ln_tot_hrs_diu2 > 0 THEN
                -- Ahora averiguo cuanto si las horas extras diurnas hasta ahora no es mayor a 2 horas
                IF ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1 + ln_tot_hrs_noc_ext1 + ln_hrs_noc_ext1 < 2 THEN
                   IF ln_tot_hrs_diu2 > (2 - (ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1 + ln_tot_hrs_noc_ext1 + ln_hrs_noc_ext1)) THEN
                      ln_hrs_diu_ext1 := ln_hrs_diu_ext1 + (2 - (ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1 + ln_tot_hrs_noc_ext1 + ln_hrs_noc_ext1));
                      ln_tot_hrs_diu2 := ln_tot_hrs_diu2 - (2 - (ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1 + ln_tot_hrs_noc_ext1 + ln_hrs_noc_ext1));
                   ELSE
                      ln_hrs_diu_ext1 := ln_tot_hrs_diu2;
                      ln_tot_hrs_diu2  := 0;
                   END IF;
                END IF;
             END IF;

             -- Si aun quedan horas diurnas veo si puedo llenar las horas extras 2
             IF ln_tot_hrs_diu2 > 0 THEN
                ln_hrs_diu_ext2 := ln_hrs_diu_ext2 + ln_tot_hrs_diu2;
             END IF;
          END IF;


          -- Actualizo los datos
          if lc_datos.nro_dia = 7 and lc_datos.nro_dia_hasta = 1 then
             -- Primero saco la fecha de fin de dia
             ls_fecha := to_char(lc_datos.fec_desde, 'dd/mm/yyyy') || ' 23:59:59';
             ld_fin_dia := to_date(ls_fecha, 'dd/mm/yyyy hh24:mi:ss');
             
             -- Horas que faltan para el día
             ln_horas := (ld_fin_dia - lc_datos.fec_desde ) * 24;
             
             if ln_horas < 8 then
                -- Si quedan menos de 8 horas entonces le quito del otro día para ponerlo al 100%
                ln_hrs_ext_100 := ln_hrs_noc_ext1 + ln_hrs_noc_ext2 + ln_hrs_diu_ext1 + ln_hrs_diu_ext2;
                ln_hrs_diu_ext1 := 0;
                ln_hrs_diu_ext2 := 0;
                ln_hrs_noc_ext1 := 0;
                ln_hrs_noc_ext2 := 0;
             else
                if ln_horas > ( ln_hrs_diu_nor + ln_hrs_noc_nor) then
                   ln_horas := ln_horas - ( ln_hrs_diu_nor + ln_hrs_noc_nor);
                else
                   ln_horas := 0;
                end if;
                
                if ln_horas > 2 then
                   ln_hrs_diu_ext1 := 2;
                   ln_hrs_noc_ext1 := 0;
                   ln_horas := ln_horas - 2;
                elsif ln_horas > 0 then
                   ln_hrs_diu_ext1 := ln_horas;
                   ln_hrs_noc_ext1 := 0;
                   ln_horas := 0;
                end if;
                
                if ln_horas > 0 then
                   ln_hrs_diu_ext2 := ln_horas;
                   ln_hrs_noc_ext2 := 0;
                   ln_horas := 0;
                end if;
                
                ln_hrs_ext_100 := (lc_datos.fec_hasta - ld_fin_dia) * 24;
                
             end if;
            
             -- Si el día es sabado y su fecha de termino es el día siguiente es domingo entonces las horas extras son consideradas al 100%
             
          elsif lc_datos.flag_feriado = '1' or lc_datos.flag_descanso = '1' or lc_datos.flag_1mayo = '1' then
             
             -- Todas las horas son de 100%
             ln_hrs_ext_100 := ln_hrs_noc_ext1 + ln_hrs_noc_ext2 + ln_hrs_diu_ext1 + ln_hrs_diu_ext2 + ln_hrs_noc_nor + ln_hrs_diu_nor;
             ln_hrs_diu_ext1 := 0;
             ln_hrs_diu_ext2 := 0;
             ln_hrs_noc_ext1 := 0;
             ln_hrs_noc_ext2 := 0;
             ln_hrs_diu_nor  := 0;
             ln_hrs_noc_nor  := 0;
          
          else
             
             ln_hrs_ext_100  := 0;
             
          end if;
          
          
          UPDATE asistencia a
             SET a.hor_diu_nor   = ln_hrs_diu_nor,
                 a.hor_ext_diu_1 = ln_hrs_diu_ext1,
                 a.hor_ext_diu_2 = ln_hrs_diu_ext2,
                 a.hor_noc_nor   = ln_hrs_noc_nor,
                 a.hor_ext_noc_1 = ln_hrs_noc_ext1,
                 a.hor_ext_noc_2 = ln_hrs_noc_ext2,
                 a.hor_ext_100   = ln_hrs_ext_100
           WHERE a.cod_trabajador = lc_reg.cod_trabajador
             AND a.fec_movim      = lc_reg.fec_movim
             AND a.turno          = lc_datos.turno
             AND a.cod_tipo_mov   = lc_datos.cod_tipo_mov
             AND a.fec_desde      = lc_datos.fec_desde;

          -- Ahora actualizo los totales
          ln_tot_hrs_diu_nor  := ln_tot_hrs_diu_nor + ln_hrs_diu_nor;
          ln_tot_hrs_diu_ext1 := ln_tot_hrs_diu_ext1 + ln_hrs_diu_ext1;
          ln_tot_hrs_diu_ext2 := ln_tot_hrs_diu_ext2 + ln_hrs_diu_ext2;
          ln_tot_hrs_noc_nor  := ln_tot_hrs_noc_nor + ln_hrs_noc_nor;
          ln_tot_hrs_noc_ext1 := ln_tot_hrs_noc_ext1 + ln_hrs_noc_ext1;
          ln_tot_hrs_noc_ext2 := ln_tot_hrs_noc_ext2 + ln_hrs_noc_ext2;
          ln_tot_hrs_ext_100  := ln_tot_hrs_ext_100  + ln_hrs_ext_100;

      END LOOP;

  END LOOP;
  
  /*
  -- LLeno las horas extras al 100%
  update asistencia a
     set a.hor_ext_100 = NVL(a.hor_diu_nor,0) + nvl(a.hor_noc_nor,0) + nvl(a.hor_ext_diu_1, 0) + nvl(a.hor_ext_diu_2, 0) +
                         NVL(a.hor_ext_noc_1, 0) + nvl(a.hor_ext_noc_2,0)
   where (a.flag_feriado  = '1'
          or a.flag_descanso = '1'
          or a.flag_1mayo    = '1')
     and a.hor_ext_100 <> NVL(a.hor_diu_nor,0) + nvl(a.hor_noc_nor,0) + nvl(a.hor_ext_diu_1, 0) + nvl(a.hor_ext_diu_2, 0) +
                         NVL(a.hor_ext_noc_1, 0) + nvl(a.hor_ext_noc_2,0) 
     and trunc(a.fec_movim) between trunc(adi_Fecha1) and trunc(adi_Fecha2);

  update asistencia a
     set a.hor_diu_nor = 0,
         a.hor_noc_nor = 0,
         a.hor_ext_diu_1 = 0,
         a.hor_ext_diu_2 = 0,
         a.hor_ext_noc_1 = 0,
         a.hor_ext_noc_2 = 0
   where (a.flag_feriado  = '1'
          or a.flag_descanso = '1'
          or a.flag_1mayo    = '1')
     and trunc(a.fec_movim) between trunc(adi_Fecha1) and trunc(adi_Fecha2);
  
  */

  -- Si todo esta bien entonces ejecuto el otro procedimiento
  USP_RH_ASIST_COSTO(adi_Fecha1, adi_Fecha2);

  COMMIT;

end USP_RH_HORAS_ASISTENCIA;
/
