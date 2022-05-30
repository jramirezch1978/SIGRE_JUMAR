create or replace procedure usp_rh_cal_quinta_categoria_bk (
    asi_codtra          in maestro.cod_trabajador%TYPE,
    asi_tipo_trabaj     IN maestro.tipo_trabajador%TYPE,
    adi_fec_proceso     in date,
    ani_tipcam          in number,
    asi_origen          in origen.cod_origen%TYPE,
    ani_dias_trabaj     IN NUMBER,
    ani_dias_mes        in number
) is

ls_grp_quinta_categ    grupo_calculo.grupo_calculo%TYPE ;
ls_grp_ganan_imprec    grupo_calculo.grupo_calculo%TYPE ;
ls_grp_gratif_jul      grupo_calculo.grupo_calculo%TYPE ;
ls_grp_gratif_dic      grupo_calculo.grupo_calculo%TYPE ;

ln_count               number ;
ls_concepto            concepto.concep%TYPE ;

-- Quinta Categoría
ln_acu_proyectable     quinta_categoria.rem_proyectable%TYPE ;
ln_acu_imprecisa       quinta_categoria.rem_imprecisa%TYPE ;
ln_acu_retencion       quinta_categoria.rem_retencion%TYPE ;
ln_acu_gratificacion   quinta_categoria.rem_gratif%TYPE ;
ln_acu_sueldo          quinta_categoria.sueldo%TYPE ;

-- Otros
ln_gratificacion       number(13,2) ;
ls_tipo_sueldo         tipo_trabajador.flag_ingreso_boleta%TYPE;
ln_sueldo_mes          number(13,2) ;
ln_sueldo_proy         number(13,2) ;
ln_imprecisa           quinta_categoria.rem_imprecisa%TYPE;
ln_retencion           quinta_categoria.rem_retencion%TYPE;
ln_imp_calculo         quinta_categoria.rem_proyectable%TYPE;
ln_meses_proy          NUMBER(2);

-- Calculo de Quinta para Jornaleros
ln_dias_year           NUMBER;
ld_fec_fin_per         DATE;
ld_fec_fin_year        DATE;

lc_flag_estado         concepto.flag_estado%type ;
ln_UIT                 UIT.IMPORTE%TYPE;
ln_base_imponible      rrhhparam.und_impos_tribut%TYPE;
ln_importe             NUMBER;
ln_soles_ret           calculo.imp_soles%TYPE;
ln_dolar_ret           calculo.imp_dolar%TYPE;



--  Cursor de ganancias proyectables en el mes
cursor c_ganancias is
  select c.concep, c.imp_soles
    from calculo c
  where c.cod_trabajador = asi_codtra
    and c.concep in ( select d.concepto_calc
                        from grupo_calculo_det d
                       where d.grupo_calculo = ls_grp_quinta_categ ) ;

--  Cursor de las ganancias imprecisas afectas del mes
cursor c_imprecisas is
select gdv.concep, gdv.imp_var
  from gan_desct_variable gdv
  where gdv.cod_trabajador = asi_codtra
    and gdv.concep in ( select d.concepto_calc
                          from grupo_calculo_det d
                         where d.grupo_calculo = ls_grp_ganan_imprec ) ;

--  Cursor que determina los porcentajes y los topes de retencion
cursor c_topes is
select r.secuencia, r.tasa, r.tope_ini, r.tope_fin
  from rrhh_impuesto_renta r
  where adi_fec_proceso between r.fecha_vig_ini and r.fecha_vig_fin
  order by r.secuencia ;

begin

  --  **************************************************************
  --  ***   REALIZA CALCULO DE QUINTA CATEGORIA POR TRABAJADOR   ***
  --  **************************************************************
  -- Busco el UIT de acuerdo a la fecha
  SELECT COUNT(*)
    INTO ln_count
    FROM uit t
   WHERE trunc(fec_ini_vigen) <= trunc(adi_fec_proceso);

  IF ln_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20000, '"NO HA ESPECIFICADO LA UIT PARA EL AÑO ' || to_char(adi_fec_proceso, 'YYYY'));
  END IF;

  SELECT importe
    INTO LN_UIT
    FROM (SELECT t.importe
            FROM UIT T
           WHERE TRUNC(FEC_INI_VIGEN) <= TRUNC(ADI_FEC_PROCESO)
           ORDER BY t.ano DESC, t.fec_ini_vigen DESC)
   WHERE ROWNUM = 1;

  -- Calculo de la base imponible, que vendría a ser 7 veces la UIT
  ln_base_imponible := ln_UIT * 7;

  -- Obtengo los parámetros necesarios para trabajar
  select c.quinta_cat_proyecta, c.quinta_cat_imprecisa, c.grati_medio_ano, c.grati_fin_ano
    into ls_grp_quinta_categ, ls_grp_ganan_imprec, ls_grp_gratif_jul, ls_grp_gratif_dic
    from rrhhparam_cconcep c
    where c.reckey = '1' ;

  -- Obtengo el estado del concepto de Retención de Quinta Categoría
  select con.flag_estado
    into lc_flag_estado
    from concepto con
   where con.concep in ( select g.concepto_gen
                           from grupo_calculo g
                          where g.grupo_calculo = ls_grp_quinta_categ) ;

  -- Si el concepto está anulado entonces no tengo nada mas que hacer
  if lc_flag_estado = '0'  then return; end if ;

  delete from quinta_categoria qc
   where qc.fec_proceso = adi_fec_proceso
     and qc.cod_trabajador = asi_codtra 
     AND qc.flag_automatico = '1';

  -- Obtengo el tipo de salario si es sueldo o jornal
  -- S = Sueldo; J = Jornal
  SELECT NVL(t.flag_ingreso_boleta, 'S')
    INTO ls_tipo_sueldo
    FROM tipo_trabajador t
   WHERE t.tipo_trabajador = asi_tipo_trabaj;
   
  select count(*)
    into ln_count
    from grupo_calculo g
   where g.grupo_calculo = ls_grp_quinta_categ ;

  IF ln_count = 0 THEN RETURN; END IF;

  select g.concepto_gen
    into ls_concepto
    from grupo_calculo g
   where g.grupo_calculo = ls_grp_quinta_categ ;

   --  Acumula importes a la fecha en el periodo
   select NVL(SUM(q.rem_proyectable),0), NVL(SUM(q.rem_imprecisa),0), 
          NVL(SUM(q.rem_retencion),0), NVL(sum(q.rem_gratif),0), 
          NVL(SUM(q.sueldo), 0) 
     into ln_acu_proyectable, ln_acu_imprecisa, ln_acu_retencion, ln_acu_gratificacion,
          ln_acu_sueldo
     from quinta_categoria q
    where q.cod_trabajador = asi_codtra
      and to_char(q.fec_proceso,'yyyy') = to_char(adi_fec_proceso,'yyyy') 
      AND trunc(q.fec_proceso) <= trunc(adi_fec_proceso);

   --  Acumula ganancias proyectables del mes
   -- Si la ganancia no es de 30 días calculo aparte un sueldo proyectado que lo comenzare a proyectar
   -- desde el siguiente mes
   ln_sueldo_mes  := 0;
   ln_sueldo_proy := 0;
   
   -- Sumo el sueldo del mes que se ha calculado
   for rc_gan in c_ganancias loop
       ln_sueldo_mes   := ln_sueldo_mes + NVL(rc_gan.imp_soles,0);
   end loop ;
   
   -- Saco el sueldo proyectado (sueldo bruto) para la remuneración proyectada
   SELECT NVL(SUM(t.imp_gan_desc),0)
     INTO ln_sueldo_proy
     FROM gan_desct_fijo t
    WHERE t.cod_trabajador = asi_codtra
      and t.concep in ( select d.concepto_calc
                        from grupo_calculo_det d
                       where d.grupo_calculo = ls_grp_quinta_categ );
   
   -- Si la gratificacion es cero significa que estoy procesando a un empleado
   ln_gratificacion := ln_sueldo_mes / 6;

   --  Acumula ganancias imprecisas del mes
   ln_imprecisa := 0 ;
   for rc_imp in c_imprecisas loop
       ln_imprecisa := ln_imprecisa + nvl(rc_imp.imp_var,0) ;
   end loop ;

   -- Le quito lo impreciso al tema del proyectable
   --ln_sueldo_proy := ln_sueldo_proy - ln_imprecisa;
   ln_sueldo_mes := ln_sueldo_mes - ln_imprecisa;

   -- Ahora con los datos necesarios procedo a calcular la quinta categoría
   IF ls_tipo_sueldo = 'S' THEN
      -- Calculo el numero de meses
      ln_meses_proy := 12 - to_number(to_char(adi_fec_proceso, 'mm'));
      -- Ahora calculo la proyeccion
      ln_imp_calculo := (ln_sueldo_proy + ln_sueldo_proy/6) * ln_meses_proy;
      -- Sumo el total
      ln_imp_calculo := ln_imp_calculo + ln_sueldo_mes + ln_imprecisa + ln_gratificacion + ln_acu_gratificacion 
                     + ln_acu_sueldo + ln_acu_imprecisa ;
                     
      ln_imp_calculo := ln_imp_calculo - ln_base_imponible ;
      if ln_imp_calculo > 0 then
         ln_importe   := 0 ; ln_retencion := 0 ;
         --  Calcula porcentaje a retener
         for rc_top in c_topes loop
              if ln_imp_calculo <= rc_top.tope_fin then
                 ln_importe := ln_imp_calculo - rc_top.tope_ini ;
                 if ln_importe > 0 then
                    ln_importe   := ln_importe * (nvl(rc_top.tasa,0)/100)  ;
                    ln_retencion := ln_retencion + ln_importe ;
                 end if ;
              else
                 ln_importe   := rc_top.tope_fin - rc_top.tope_ini ;
                 ln_importe   := ln_importe * (nvl(rc_top.tasa,0)/100)  ;
                 ln_retencion := ln_retencion + ln_importe ;
              end if ;
          end loop ; 
          --  Realiza retencion de quinta categoria del mes de proceso
          ln_soles_ret := (ln_retencion - ln_acu_retencion) / (ln_meses_proy + 1);
          ln_dolar_ret := ln_soles_ret / ani_tipcam ;
          if ln_soles_ret > 0 then
             --  Inserta registros en la tabla CALCULO
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
             values(
                    asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
                    0, ln_soles_ret, ln_dolar_ret, asi_origen, '1', 1 ) ;
          end if ;
       end if ;
   ELSE
      -- Primero calculo cuantos días quedan, para ello resto la fecha de fin de año con la fecha de fin de periodo
      ld_fec_fin_year := to_date('31/12/' || to_char(adi_fec_proceso, 'yyyy'), 'dd/mm/yyyy');
      
      -- ahora capturo la fecha de fin del periodo
      SELECT COUNT(*)
        INTO ln_count
        FROM rrhh_param_org t
       WHERE trunc(t.fec_proceso) = trunc(adi_fec_proceso)
         AND t.tipo_trabajador    = asi_tipo_trabaj;
      
      IF ln_count = 0 THEN
         RAISE_APPLICATION_ERROR(-20000, 'No se han definido parámetros de Fechas de Calculo para el tipo de trabajador: ' ||
                                         asi_tipo_trabaj || ' fecha de proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
      END IF;
      
      SELECT t.fec_final
        INTO ld_fec_fin_per
        FROM rrhh_param_org t
       WHERE trunc(t.fec_proceso) = trunc(adi_fec_proceso)
         AND t.tipo_trabajador    = asi_tipo_trabaj;
      
      -- Ahora calculo los días faltantes
      IF trunc(ld_fec_fin_per) <= trunc(ld_fec_fin_year) THEN
         ln_dias_year := ld_fec_fin_year - ld_fec_fin_per;
      ELSE
         RAISE_APPLICATION_ERROR(-20000, 'La fecha de fin del Periodo del proceso no puede ser mayor a la fecha de fin de año'
                                         || chr(13) || 'Fecha de fin de periodo: ' || to_char(ld_fec_fin_per, 'dd/mm/yyyy')
                                         || chr(13) || 'Fecha de fin de año: ' || to_char(ld_fec_fin_year, 'dd/mm/yyyy'));
      END IF;
      
      -- Obtengo el jornal proyectable
      select NVL(SUM(gf.imp_gan_desc),0)
        INTO ln_sueldo_proy
        from gan_desct_fijo gf
       where gf.cod_trabajador = asi_codtra
         and gf.concep in ( select d.concepto_calc
                             from grupo_calculo_det d
                            where d.grupo_calculo = ls_grp_quinta_categ ) ;

      ln_sueldo_proy := ln_sueldo_proy / 30;
      
      -- Ahora calculo la proyeccion del jornal por los días que quedan en el año
      ln_imp_calculo := (ln_sueldo_proy + ln_sueldo_proy/6) * ln_dias_year;
      
      -- Sumo el total
      ln_imp_calculo := ln_imp_calculo + ln_sueldo_mes + ln_imprecisa + ln_gratificacion + ln_acu_gratificacion 
                     + ln_acu_sueldo + ln_acu_imprecisa ;
                     
      ln_imp_calculo := ln_imp_calculo - ln_base_imponible ;
      if ln_imp_calculo > 0 then
         ln_importe   := 0 ; ln_retencion := 0 ;
         --  Calcula porcentaje a retener
         for rc_top in c_topes loop
              if ln_imp_calculo <= rc_top.tope_fin then
                 ln_importe := ln_imp_calculo - rc_top.tope_ini ;
                 if ln_importe > 0 then
                    ln_importe   := ln_importe * (nvl(rc_top.tasa,0)/100)  ;
                    ln_retencion := ln_retencion + ln_importe ;
                 end if ;
              else
                 ln_importe   := rc_top.tope_fin - rc_top.tope_ini ;
                 ln_importe   := ln_importe * (nvl(rc_top.tasa,0)/100)  ;
                 ln_retencion := ln_retencion + ln_importe ;
              end if ;
          end loop ; 
          
          --  Calculo la retencion, correspondiente al periodo
          ln_soles_ret := (ln_retencion - ln_acu_retencion) / (ln_dias_year + ani_dias_trabaj) * ani_dias_trabaj;
          ln_dolar_ret := ln_soles_ret / ani_tipcam ;
          if ln_soles_ret > 0 then
             --  Inserta registros en la tabla CALCULO
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
             values(
                    asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
                    0, ln_soles_ret, ln_dolar_ret, asi_origen, '1', 1 ) ;
          end if ;
       end if ; 
      
   END IF;

   --  Inserta registros en la tabla QUINTA_CATEGORIA
   IF ln_soles_ret IS NULL THEN ln_soles_ret := 0; END IF;
   
   insert into quinta_categoria (
          cod_trabajador, fec_proceso, rem_proyectable,
          rem_imprecisa, rem_retencion, rem_gratif, flag_replicacion, 
          nro_dias, sueldo, flag_automatico  )
   values (
          asi_codtra, adi_fec_proceso, ln_sueldo_proy,
          ln_imprecisa, ln_soles_ret, ln_gratificacion, '1', 
          ani_dias_trabaj, ln_sueldo_mes, '1' ) ;



end usp_rh_cal_quinta_categoria_bk ;
/
