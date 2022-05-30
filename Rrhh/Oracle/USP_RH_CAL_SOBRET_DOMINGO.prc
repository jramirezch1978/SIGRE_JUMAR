create or replace procedure USP_RH_CAL_SOBRET_DOMINGO(
  asi_codtra       in maestro.cod_trabajador%TYPE,
  adi_fec_proceso  in date,
  asi_origen       in origen.cod_origen%TYPE,
  ani_tipcam       in number,
  asi_tipo_trabaj  IN  maestro.tipo_trabajador%TYPE,      -- Tipo de trabajador
  ani_dias_trabaj  IN NUMBER
) IS

  ls_tipo_des             rrhhparam.tipo_trab_destajo%TYPE;
  ls_cnc_fer_dia_desc     asistparam.cnc_fer_dia_desc%TYPE;     -- Feriado en dia de descanso
  ls_flag_tipo_sueldo     tipo_trabajador.flag_ingreso_boleta%TYPE;
  ls_concepto             concepto.concep%TYPE;

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

SELECT r.tipo_trab_destajo
  INTO ls_tipo_des
  FROM rrhhparam r
 WHERE r.reckey = '1';

-- Obteniendo parametros para el calculo
SELECT t.cnc_fer_dia_desc
  INTO ls_cnc_fer_dia_desc
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
   AND trunc(t.fec_proceso) = trunc(adi_fec_proceso);

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

ln_dias_periodo := ld_fec_fin - ld_fec_ini;

IF asi_tipo_trabaj in (ls_tipo_des) THEN

   FOR ln_dia IN 0..ln_dias_periodo LOOP
       ld_fecha := ld_fec_ini + ln_dia;
       
       --  Si la fecha resulta ser el domingo entonces procedo a calcular
       if to_number(to_char(ld_fecha, 'D')) = 1 then

          ls_concepto := ls_cnc_fer_dia_desc;

          -- SUmo lo que se ha trabajado ese día en caso que sea desjatero
          select nvl(sum(DECODE( tf.flag_destajo, '1',
                      p.precio_unit * pd.cant_producida,
                      p.precio_unit * (case
                                         when pd.cant_horas_diu > 8 then
                                           8 + (pd.cant_horas_diu - 8) * 1.25
                                         else
                                           pd.cant_horas_diu
                                       end +
                                       case
                                         when pd.cant_horas_noc > 8 then
                                           8 * 1.35 + (pd.cant_horas_noc - 8)
                                         else
                                           pd.cant_horas_noc * 1.35
                                       end
                                       ))),0) as importe
            into ln_jornal
            from tg_pd_destajo p,
                 tg_pd_destajo_det pd,
                 tg_tarifario      tf,
                 turno             t
           where p.nro_parte        = pd.nro_parte
             and p.cod_especie      = tf.cod_especie
             and p.cod_presentacion = tf.cod_presentacion
             and p.cod_tarea        = tf.cod_tarea
             and p.turno            = t.turno
             and p.flag_estado      = '1'
             and trunc(p.fec_parte) = trunc(ld_fecha)
             and pd.cod_trabajador  = asi_codtra
             and ((tf.flag_destajo  = 1 and pd.cant_producida > 0) or
                 (tf.flag_destajo = 0 and pd.cant_horas_diu + pd.cant_horas_noc > 0));
          
           --

         if ln_jornal > 0 and ani_dias_trabaj = 7 then
            -- Calculo el jornal
            ln_imp_soles := ln_jornal ;
            ln_imp_dolar := ln_imp_soles / ani_tipcam ;

            UPDATE calculo
               SET horas_trabaj = null,
                   horas_pag    = null,
                   dias_trabaj  = null,
                   imp_soles    = imp_soles + ln_imp_soles,
                   imp_dolar    = imp_dolar + ln_imp_dolar
             WHERE cod_trabajador = asi_codtra
               AND concep = ls_concepto;

             IF SQL%NOTFOUND THEN
                insert into calculo (
                       cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                       dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
                values (
                       asi_codtra, ls_concepto, adi_fec_proceso, null, null,
                       null, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;
             END IF;

         end if;
      end if;
   END LOOP;
END IF;

end USP_RH_CAL_SOBRET_DOMINGO;
/
