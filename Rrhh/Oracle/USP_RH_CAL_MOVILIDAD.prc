create or replace procedure USP_RH_CAL_MOVILIDAD(
      asi_codtra         in maestro.cod_trabajador%TYPE,
      adi_fec_proceso    in date,
      asi_origen         in origen.cod_origen%TYPE,
      ani_tipcam         in number,
      asi_tipo_trabaj    IN  maestro.tipo_trabajador%TYPE,      -- Tipo de trabajador
      ani_dias_trabaj    IN NUMBER,
      asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) IS

  ln_dias_habiles       number;
  ln_imp_soles          calculo.imp_soles%TYPE;
  ln_imp_dolar          calculo.imp_dolar%TYPE;
  
  cursor c_ganancias_fijas is
    SELECT G.CONCEP, G.IMP_GAN_DESC
      FROM GAN_DESCT_FIJO G
     WHERE G.COD_TRABAJADOR = ASI_CODTRA
       AND G.FLAG_ESTADO = '1'
       AND G.CONCEP = PKG_RRHH.is_cnc_movilidad;
  
begin

  --  ****************************************************************************************************
  --  CALCULA LA MOVILIDAD SOLO PARA EMPLEADOS JORNALEROS UNICAMENTE
  --  ****************************************************************************************************

  -- Si no hay días trabajados simplemente lo retorno
  IF ani_dias_trabaj = 0 THEN RETURN; END IF;

  -- Por ahora la movilidad es solo para empleados jornaleros
  if asi_tipo_trabaj <> PKG_RRHH.is_tipo_ejo then return; end if;

  ln_dias_habiles := PKG_RRHH.of_dias_habiles(asi_origen, asi_codtra, adi_fec_proceso, asi_tipo_planilla);

  -- Si no hay días hábiles entonces simplemente no ingreso nada
  if ln_dias_habiles = 0 then return; end if;  

  for lc_reg in c_ganancias_fijas loop
      ln_imp_soles := lc_reg.imp_gan_desc / ln_dias_habiles * ani_dias_trabaj;
      
      if ln_imp_soles > 0 then
          ln_imp_dolar := ln_imp_soles / ani_tipcam ;

          UPDATE calculo
             SET horas_trabaj = null,
                 horas_pag    = null,
                 dias_trabaj  = ani_dias_trabaj,
                 imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar
           WHERE cod_trabajador = asi_codtra
             AND concep         = PKG_RRHH.is_cnc_movilidad
             and tipo_planilla  = asi_tipo_planilla;

          IF SQL%NOTFOUND THEN
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                    tipo_planilla )
             values (
                    asi_codtra, PKG_RRHH.is_cnc_movilidad, adi_fec_proceso, null, null,
                    ani_dias_trabaj, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                    asi_tipo_planilla ) ;

          END IF;
      end if;
 
  end loop;

end USP_RH_CAL_MOVILIDAD;
/
