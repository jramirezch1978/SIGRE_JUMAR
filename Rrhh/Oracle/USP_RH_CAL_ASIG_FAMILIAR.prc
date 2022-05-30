create or replace procedure USP_RH_CAL_ASIG_FAMILIAR(
  asi_codtra           in maestro.cod_trabajador%TYPE,
  adi_fec_proceso      in date,
  asi_origen           in origen.cod_origen%TYPE,
  ani_tipcam           in number,
  asi_tipo_trabaj      IN  maestro.tipo_trabajador%TYPE,      -- Tipo de trabajador
  ani_dias_trabaj      in out rrhhparam.dias_mes_obrero%TYPE,
  asi_flag_dso_af      in char,
  asi_tipo_planilla    in calculo.tipo_planilla%TYPE
) is

ln_hrs_normales       NUMBER ;
ln_hrs_norm_cmp       number;   -- horas normales de campo
ln_imp_soles          calculo.imp_soles%TYPE ;
ln_imp_dolar          calculo.imp_dolar%TYPE ;
ls_tipo_obr           rrhhparam.tipo_trab_obrero%TYPE;
ld_fec_ini            DATE;
ld_fec_fin            DATE;


--Conceptos para la asistencia de los jornaleros
ls_cnc_asig_familiar  asistparam.cnc_asig_familiar%TYPE;
ls_flag_tipo_sueldo   tipo_trabajador.flag_ingreso_boleta%TYPE;
ls_sector_agrario     tipo_trabajador.flag_sector_agrario%TYPE;

ln_dias               calculo.dias_trabaj%TYPE;  -- Nro de dias
ln_dias_dtsjo         calculo.dias_trabaj%TYPE;
ln_dias_periodo       NUMBER;
ln_dia                number;
ln_dias_feriados      NUMBER;
ld_fecha              date;
ln_count              number;
ld_fec_ingreso        maestro.fec_ingreso%TYPE;  -- Fecha de ingreso de los trabajadores
ld_fec_cese           maestro.fec_cese%TYPE;


-- Emergencia
ls_cnc_gratif_ext     concepto.concep%TYPE;
ls_cnc_bon_gratif     concepto.concep%TYPE;
ln_porc_gratf         number := 9.74;
ln_imp_gratif         number := 0;
ln_acum_grat          number := 0;
ls_concepto           concepto.concep%TYPE;
ls_cnc_vacaciones     concepto.concep%TYPE;

ld_fin_mes            date;
ln_dias_semana        number;

cursor c_AsigFamiliar is
  SELECT G.CONCEP, G.IMP_GAN_DESC
    FROM GAN_DESCT_FIJO G
   WHERE G.COD_TRABAJADOR = ASI_CODTRA
     AND G.FLAG_ESTADO = '1'
     AND G.CONCEP = ls_cnc_asig_familiar;


begin

--  ****************************************************************************************************
--  CALCULA LA ASIGNACION FAMILIAR, ESTE PROCEDIMIENTO VA A CAMBIAR EN UN FUTURO
--  PARA QUE EL CONCEPTO SEA CALCULADO A PARTIR DE LOS DERECHOS HABIENTES QUE SEAN DEPENDIENTES
--  DEL TRABAJADOR
--  ****************************************************************************************************

IF ani_dias_trabaj = 0 THEN
   -- Si el numero de dias de Trabajo es cero entonces no tengo que hacer nada
   RETURN;
END IF;

-- Obtengo los parametros necesarios
SELECT r.tipo_trab_obrero
  INTO ls_tipo_obr
  FROM rrhhparam r
 WHERE reckey = '1';
 
-- Obtengo el concepto de vacaciones
select gc.concepto_gen
  into ls_cnc_vacaciones
  from grupo_calculo gc
 where gc.grupo_calculo = (select r.gan_fij_calc_vacac from rrhhparam_cconcep r where r.reckey = '1');

select t.flag_ingreso_boleta, t.flag_sector_agrario
  into ls_flag_tipo_sueldo, ls_sector_agrario
  from tipo_trabajador t
 where t.tipo_trabajador = asi_tipo_trabaj;

SELECT m.fec_ingreso, m.fec_cese
  INTO ld_fec_ingreso, ld_fec_cese
  FROM maestro m
 WHERE m.cod_trabajador = asi_codtra;

-- El rango de fecha para el calculo por la fecha de proceso
SELECT t.fec_inicio, t.fec_final
  INTO ld_fec_ini, ld_fec_fin
  FROM rrhh_param_org t
 WHERE t.origen = asi_origen
   AND t.tipo_trabajador = asi_tipo_trabaj
   AND trunc(t.fec_proceso) = trunc(adi_fec_proceso)
   and t.tipo_planilla      = asi_tipo_planilla;
   
-- Obtengo los días de la semana
ln_dias_semana := ld_fec_fin - ld_fec_ini + 1;

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


-- Luego los porcentajes y los conceptos de la asistencia
SELECT cnc_asig_familiar, t.cnc_gratif_ext, t.cnc_bonif_ext
  INTO ls_cnc_asig_familiar, ls_cnc_gratif_ext, ls_cnc_bon_gratif
  FROM asistparam t
 WHERE t.reckey = '1';

IF ls_cnc_asig_familiar IS NULL THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado la asignacion familiar en asistparam');
END IF;

if nvl(ani_dias_trabaj,0) > 0 then

   IF ls_flag_tipo_sueldo = 'J' THEN
      -- Primero calculo las horas normales
      SELECT NVL(SUM(a.hor_diu_nor + a.hor_noc_nor),0)
        INTO ln_hrs_normales
        FROM asistencia a
       WHERE a.cod_trabajador = asi_codtra
         AND trunc(a.fec_movim) BETWEEN trunc(ld_fec_ini) AND trunc(ld_fec_fin)
         and Nvl(a.flag_descanso,'0')='0' 
         and NVL(a.flag_feriado, '0') = '0' 
         and NVL(a.flag_1mayo, '0') = '0';

      SELECT NVL(SUM(p.hrs_normales + p.hrs_noc_extras_35),0)
        INTO ln_hrs_norm_cmp
        FROM pd_jornal_campo p
       WHERE p.cod_trabajador = asi_codtra
         AND trunc(p.fecha) BETWEEN trunc(ld_fec_ini) AND trunc(ld_fec_fin);
      
      -- Luego calculo los dias normales segun las horas trabajadas
      if ls_flag_tipo_sueldo = 'J' then
         ln_dias := round((ln_hrs_normales + ln_hrs_norm_cmp)/ 8,2);
      else
         ln_dias := ani_dias_trabaj;
      end if;

      -- Agrego los días de acuerdo a destajo
      select count(distinct p.fec_parte)
        into ln_dias_dtsjo
        from tg_pd_destajo p,
             tg_pd_destajo_det pd
       where p.nro_parte = pd.nro_parte
         and pd.cod_trabajador = asi_codtra
         and trunc(p.fec_parte) BETWEEN trunc(ld_fec_ini) AND trunc(ld_fec_fin)
         and p.flag_estado = '1';
         
      ln_dias := ln_dias + ln_dias_dtsjo;

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
                
             elsif usf_rh_is_dia_descanso(asi_codtra, ld_fecha) and asi_flag_dso_af = '1' then
          
                -- Considero tambien los domingos
                ln_dias_feriados := ln_dias_feriados + 1;
                
             end if;
             
          end if;
      end loop;
      
      -- A los dias normales se les suma los dias feriados, considerados como dias laborales completos para la asignacion familiar
     -- ln_dias := Round(ln_dias + ln_dias_feriados,0);
     ln_dias := Round(ln_dias + ln_dias_feriados,2);
     ln_acum_grat := 0; 
     
     -- cambio para CANTABRIA
     ld_fin_mes := last_day(adi_fec_proceso);
     if trunc(adi_fec_proceso) = trunc(ld_fin_mes) and ln_dias_semana < 7 then
        ln_dias := ln_dias + 1;
     end if;

     -- El Total de Días Trabajados no sobrepase a los días del periodo
     IF ln_dias > ln_dias_periodo and ln_dias_periodo >= 7 THEN
        ln_dias := ln_dias_periodo;
     END IF;
     
      for rc_gan in c_AsigFamiliar loop


          ln_imp_soles := rc_gan.imp_gan_desc / 30 * ln_dias;
          
          if ls_sector_agrario = '1' then
             -- Le calculo la gratificacion
             ln_imp_gratif := ln_imp_soles * ln_porc_gratf/100;
             ln_acum_grat := ln_acum_grat + ln_imp_gratif;
              
             -- Le quito la gratificacion
             ln_imp_soles := ln_imp_soles - ln_imp_gratif;
          end if;
          
          ln_imp_dolar := ln_imp_soles / ani_tipcam ;
          
          UPDATE calculo
             SET horas_trabaj = null,
                 horas_pag    = null,
                 imp_soles    = ln_imp_soles,
                 imp_dolar    = ln_imp_dolar
            WHERE cod_trabajador = asi_codtra
              AND concep         = ls_concepto
              and tipo_planilla  = asi_tipo_planilla;


          IF SQL%NOTFOUND THEN
             insert into calculo (
                   cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                   dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, 
                   item, tipo_planilla )
             values (
                   asi_codtra, rc_gan.concep, adi_fec_proceso, ln_hrs_normales + ln_hrs_norm_cmp, 
                   ln_hrs_normales + ln_hrs_norm_cmp,
                   ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                   asi_tipo_planilla ) ;
          END IF;

      end loop ;
      

   ELSE
      ln_hrs_normales := ani_dias_trabaj * 8 ;
      for rc_gan in c_AsigFamiliar loop

        ln_imp_soles := rc_gan.imp_gan_desc; --/ ani_dias_mes * ani_dias_trabaj ;
        ln_imp_dolar := ln_imp_soles / ani_tipcam ;

        insert into calculo (
          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
          tipo_planilla )
        values (
          asi_codtra, rc_gan.concep, adi_fec_proceso, ln_hrs_normales, ln_hrs_normales,
          ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
          asi_tipo_planilla ) ;

      end loop ;

   END IF;

   -- Falta el calculo de la asignacion familiar, para esto debe ponerlo de manera automatica solamente
   -- si tiene hijos menores de 18 años, y debe ser el 10% del Minimo Vital


end if ;

end USP_RH_CAL_ASIG_FAMILIAR ;
/
