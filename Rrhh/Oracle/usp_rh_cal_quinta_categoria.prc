create or replace procedure usp_rh_cal_quinta_categoria (
    asi_codtra          in maestro.cod_trabajador%TYPE,
    asi_tipo_trabaj     IN maestro.tipo_trabajador%TYPE,
    adi_fec_proceso     in date,
    ani_tipcam          in number,
    asi_origen          in origen.cod_origen%TYPE,
    ani_dias_trabaj     IN NUMBER,
    asi_tipo_planilla   in calculo.tipo_planilla%TYPE
) is

ls_grp_quinta_categ    grupo_calculo.grupo_calculo%TYPE ;
ls_grp_ganan_imprec    grupo_calculo.grupo_calculo%TYPE ;
ls_grp_gratif_jul      grupo_calculo.grupo_calculo%TYPE ;
ls_grp_gratif_dic      grupo_calculo.grupo_calculo%TYPE ;
ls_flag_reg_laboral    maestro.flag_reg_laboral%TYPE;
ls_tipo_trip           rrhhparam.tipo_trab_tripulante%TYPE;
ls_grp_fijo_trip       grupo_calculo.grupo_calculo%TYPE := '037';
ls_grp_var_trip        grupo_calculo.grupo_calculo%TYPE := '038';

ln_count               number ;
ls_cnc_ret_quinta      concepto.concep%TYPE ;

-- Quinta Categoria
ln_acu_externa         quinta_categoria.rem_externa%TYPE ;
ln_acu_imprecisa       quinta_categoria.rem_imprecisa%TYPE ;
ln_acu_retencion       quinta_categoria.rem_retencion%TYPE ;
ln_acu_sueldo          quinta_categoria.sueldo%TYPE ;

-- Otros
ln_gratificacion       number(13,2) ;
ls_tipo_sueldo         tipo_trabajador.flag_ingreso_boleta%TYPE;

ln_rem_precisa         quinta_categoria.rem_proyectable%TYPE; 
ln_rem_imprecisa       quinta_categoria.rem_imprecisa%TYPE;
ln_rem_gratif          calculo.imp_soles%TYPE;

ln_sueldo_proy         number(13,2) ;
ln_retencion           quinta_categoria.rem_retencion%TYPE;
ln_imp_calculo         calculo.imp_soles%TYPE;

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
ln_meses_proy          number(2) := 0;
ln_meses_divide        number(2) := 0;
ln_mes                 number(2) := 0;
ln_ret_dscto_fijo      gan_desct_fijo.imp_gan_desc%TYPE;


--  Cursor que determina los porcentajes y los topes de retencion
cursor c_topes is
select r.secuencia, r.tasa, r.tope_ini, r.tope_fin
  from rrhh_impuesto_renta r
  where adi_fec_proceso between r.fecha_vig_ini and r.fecha_vig_fin
  order by r.secuencia ;

begin
  
  --  **************************************************************
  --  28/01/2010: Se realiza un cambio en el calculo de la quinta 
  --  categoria, segun requerimiento de RRHH por intermedio de la Sra
  --  Patricia Cordoba Ballesteros, presentando el sustento legal con 
  --  Correo el dia 28/01/2010.....
  --  Encargado: Ing CIP Jhonny Ramirez Chiroque
  --  **************************************************************
  
  --  **************************************************************
  --  ***   REALIZA CALCULO DE QUINTA CATEGORIA POR TRABAJADOR   ***
  --  **************************************************************
  -- Busco el UIT de acuerdo a la fecha
  SELECT COUNT(*)
    INTO ln_count
    FROM uit t
   WHERE trunc(fec_ini_vigen) <= trunc(adi_fec_proceso);

  IF ln_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20000, '"NO HA ESPECIFICADO LA UIT PARA EL A?O ' || to_char(adi_fec_proceso, 'YYYY'));
  END IF;

  SELECT importe
    INTO LN_UIT
    FROM (SELECT t.importe
            FROM UIT T
           WHERE TRUNC(FEC_INI_VIGEN) <= TRUNC(ADI_FEC_PROCESO)
           ORDER BY t.ano DESC, t.fec_ini_vigen DESC)
   WHERE ROWNUM = 1;
  
  select m.flag_reg_laboral
    into ls_flag_reg_laboral
    from maestro m
   where m.cod_trabajador = asi_codtra;
  
  select r.tipo_trab_tripulante
    into ls_tipo_trip
    from rrhhparam r
   where r.reckey = '1';
   
  -- Calculo de la base imponible, que vendria a ser 7 veces la UIT
  ln_base_imponible := ln_UIT * 7;

  -- Obtengo los parametros necesarios para trabajar
  select c.quinta_cat_proyecta, c.quinta_cat_imprecisa, c.grati_medio_ano, c.grati_fin_ano
    into ls_grp_quinta_categ, ls_grp_ganan_imprec, ls_grp_gratif_jul, ls_grp_gratif_dic
    from rrhhparam_cconcep c
    where c.reckey = '1' ;

  -- Obtengo el estado del concepto de Retencion de Quinta Categoria
  select count(*)
    into ln_count
    from grupo_calculo g
   where g.grupo_calculo = ls_grp_quinta_categ ;

  IF ln_count = 0 THEN RETURN; END IF;

  select con.flag_estado, con.concep
    into lc_flag_estado, ls_cnc_ret_quinta
    from concepto con
   where con.concep in ( select g.concepto_gen
                           from grupo_calculo g
                          where g.grupo_calculo = ls_grp_quinta_categ) ;

  -- Si el concepto esta anulado entonces no tengo nada mas que hacer
  if lc_flag_estado = '0'  then return; end if ;
  
  -- elimino los registros de la Quinta Categoria
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
   
   --  Acumula importes a la fecha en el periodo
   select NVL(SUM(q.rem_externa),0), NVL(SUM(q.rem_imprecisa),0), NVL(SUM(q.rem_retencion),0), 
          NVL(SUM(q.sueldo),0)
     into ln_acu_externa, ln_acu_imprecisa, ln_acu_retencion, ln_acu_sueldo
     from quinta_categoria q
    where q.cod_trabajador = asi_codtra
      and to_char(q.fec_proceso,'yyyy') = to_char(adi_fec_proceso,'yyyy') 
      AND trunc(q.fec_proceso) <= trunc(adi_fec_proceso);

   
   /******************************************************************************************
   PASO 4 : Monto de la retencion
      Finalmente, para obtener el monto que se debe retener cada mes, se sigue el procedimiento siguiente:
      ?	En los meses de enero a marzo, el impuesto anual se divide entre doce. 
      ?	En el mes de abril, al impuesto anual se le deducen las retenciones efectuadas de enero a marzo. 
        El resultado se divide entre 9. 
      ?	En los meses de mayo a julio, al impuesto anual se le deducen las retenciones efectuadas en los meses de enero 
        a abril. El resultado se divide entre 8. 
      ?	En agosto, al impuesto anual se le deducen las retenciones efectuadas en los meses de enero a julio. 
        El resultado se divide entre 5. 
      ?	En los meses de septiembre a noviembre, al impuesto anual se le deducen las retenciones efectuadas en 
        los meses de enero a agosto. El resultado se divide entre 4. 
      ?	En diciembre, con motivo de la regularizacion anual, al impuesto anual se le deducira las retenciones 
        efectuadas en los meses de enero a noviembre del mismo ejercicio. 
        
      El monto obtenido en cada mes por el procedimiento antes indicado sera el impuesto que el agente de retencion 
      se encargara de retener en cada mes.
      
      Base Legal:
      Articulo 53? del TUO de la Ley del Impuesto a la Renta - Decreto Supremo 179-2004-EF y modificatorias.
      Articulo 40? del Reglamento de la Ley del Impuesto a la Renta - Decreto Supremo N? 122-94-EF y modificatorias.

   ******************************************************************************************/
   -- Obtengo el mes
   ln_mes         := to_number(to_char(adi_fec_proceso, 'mm'));

   -- Meses que faltan
   ln_meses_proy := 12 - ln_mes;
   ln_meses_divide := ln_meses_proy + 1;

   -- Acumulado de la retencion
   select NVL(SUM(hc.imp_soles),0)
     into ln_acu_retencion
     from historico_calculo hc
    where hc.cod_trabajador = asi_codtra
      and to_char(hc.fec_calc_plan,'yyyy') = to_char(adi_fec_proceso,'yyyy') 
      and to_char(hc.fec_calc_plan,'mm') <= ln_mes
      AND trunc(hc.fec_calc_plan) < trunc(adi_fec_proceso)
      and hc.concep in ('2007', '2204');
   
   
   
   -- Calculo de lo que se le ha pagado la remuneracion proyectable
   if asi_tipo_trabaj = ls_tipo_trip then
       select NVL(sum(c.imp_soles),0)
         into ln_rem_precisa
         from calculo c
        where c.cod_trabajador = asi_codtra
          and c.tipo_planilla  = asi_tipo_planilla
          and c.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_fijo_trip ) ;
   else
       select NVL(sum(c.imp_soles),0)
         into ln_rem_precisa
         from calculo c
        where c.cod_trabajador = asi_codtra
          and c.tipo_planilla  = asi_tipo_planilla
          and c.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_quinta_categ ) ;
   end if;
   
   -- Calculo cuanto se le ha pagado de sueldo hasta ahora
   if asi_tipo_trabaj = ls_tipo_trip then
       select NVL(sum(c.imp_soles),0)
         into ln_acu_sueldo
         from historico_calculo c
        where c.cod_trabajador = asi_codtra
          and to_char(c.fec_calc_plan,'yyyy') = to_char(adi_fec_proceso,'yyyy')
          and trunc(c.fec_calc_plan) < trunc(adi_fec_proceso)
          and c.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_fijo_trip ) ;
   else
       select NVL(sum(c.imp_soles),0)
         into ln_acu_sueldo
         from historico_calculo c
        where c.cod_trabajador = asi_codtra
          and to_char(c.fec_calc_plan,'yyyy') = to_char(adi_fec_proceso,'yyyy')
          and trunc(c.fec_calc_plan) < trunc(adi_fec_proceso)
          and c.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_quinta_categ ) ;
   end if;
   
   -- Calculo la remuneracion imprecisa de lo que se le ha calculado
   if asi_tipo_trabaj = ls_tipo_trip then
       select NVL(sum(c.imp_soles),0)
         into ln_rem_imprecisa
         from calculo c
        where c.cod_trabajador = asi_codtra
          and c.tipo_planilla  = asi_tipo_planilla
          and c.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_var_trip ) ;
   else
       select NVL(sum(c.imp_soles),0)
         into ln_rem_imprecisa
         from calculo c
        where c.cod_trabajador = asi_codtra
          and c.tipo_planilla  = asi_tipo_planilla
          and c.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_ganan_imprec ) ;
   end if;
   -- Calculo la remuneracion imprecisa de lo que se le ha calculado
   if asi_tipo_trabaj = ls_tipo_trip then
       select NVL(sum(hc.imp_soles),0)
         into ln_acu_imprecisa
         from historico_calculo hc
        where hc.cod_trabajador = asi_codtra
          and to_char(hc.fec_calc_plan,'yyyy') = to_char(adi_fec_proceso,'yyyy')
          and trunc(hc.fec_calc_plan) < trunc(adi_fec_proceso)
          and hc.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_var_trip ) ;                         
   else
       select NVL(sum(hc.imp_soles),0)
         into ln_acu_imprecisa
         from historico_calculo hc
        where hc.cod_trabajador = asi_codtra
          and to_char(hc.fec_calc_plan,'yyyy') = to_char(adi_fec_proceso,'yyyy')
          and trunc(hc.fec_calc_plan) < trunc(adi_fec_proceso)
          and hc.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_ganan_imprec ) ;                         
   end if;
      
   -- Saco el sueldo proyectado (sueldo bruto) para la remuneracion proyectada
   if asi_tipo_trabaj = ls_tipo_trip then
       select NVL(sum(c.imp_soles),0)
         into ln_sueldo_proy
         from calculo c
        where c.cod_trabajador = asi_codtra
          and c.tipo_planilla  = asi_tipo_planilla
          and c.concep in ( select d.concepto_calc
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_fijo_trip ) ;
   else
       SELECT NVL(SUM(t.imp_gan_desc),0)
         INTO ln_sueldo_proy
         FROM gan_desct_fijo t
        WHERE t.cod_trabajador = asi_codtra
          and t.concep in ( select d.concepto_calc
                            from grupo_calculo_det d
                           where d.grupo_calculo = ls_grp_quinta_categ );
   end if;
   
   
   -- Calculo la remuneracion aplicable a la gratificacion
   select NVL(sum(g.imp_gan_desc),0)
     into ln_rem_gratif
     from gan_desct_fijo g
    where g.cod_trabajador = asi_codtra
      and g.concep in ( select d.concepto_calc
                        from grupo_calculo_det d
                       where d.grupo_calculo = (select grati_medio_ano from rrhhparam_cconcep where reckey = '1'));
   
   if ls_flag_reg_laboral = '1' then
      ln_rem_gratif := 740;
   end if;
   
   if ln_mes < 7 then
      ln_gratificacion := ln_rem_gratif * 2 * 1.09;
   elsif ln_mes between 7 and 11 then
      ln_gratificacion := ln_rem_gratif * 1.09;
   else
      ln_gratificacion := 0;
   end if;
   
   -- Ahora con los datos necesarios procedo a calcular la quinta categoria
   IF ls_tipo_sueldo = 'S' THEN
      
      -- Ahora calculo la proyeccion
      ln_imp_calculo := ln_sueldo_proy * ln_meses_proy + ln_gratificacion + ln_rem_imprecisa 
                      + ln_rem_precisa + ln_acu_sueldo + ln_acu_imprecisa;
      
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
          ln_soles_ret := (ln_retencion - ln_acu_retencion) / ln_meses_divide;
          
          if ln_soles_ret > 0 then
             
             -- Si el calculo de renta es mayor que cero procedo a convertirlo a dolares
             ln_dolar_ret := ln_soles_ret / ani_tipcam ;
             
             
             --  Inserta registros en la tabla CALCULO
             update calculo
                set imp_soles = ln_soles_ret,
                    imp_dolar = ln_dolar_ret
              where cod_trabajador = asi_codtra
                and concep         = ls_cnc_ret_quinta
                and tipo_planilla  = asi_tipo_planilla;
             
             if SQL%NOTFOUND then
                 insert into calculo (
                        cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                        dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                        tipo_planilla )
                 values(
                        asi_codtra, ls_cnc_ret_quinta, adi_fec_proceso, 0, 0,
                        0, ln_soles_ret, ln_dolar_ret, asi_origen, '1', 1,
                        asi_tipo_planilla ) ;
             end if;
          end if ;
       end if ;
   ELSE
      -- Solo para el sector agrila no tiene gratificacion los jornaleros
      ln_gratificacion := 0;
   
      -- Calculo la retencion de la quinta hasta ahora
      select NVL(SUM(q.rem_retencion),0)
        into ln_acu_retencion
        from quinta_categoria q
       where q.cod_trabajador = asi_codtra
         and to_char(q.fec_proceso,'yyyy') = to_char(adi_fec_proceso,'yyyy') 
         AND trunc(q.fec_proceso) <= trunc(adi_fec_proceso);

      -- Primero calculo cuantos dias quedan, para ello resto la fecha de fin de a?o con la fecha de fin de periodo
      ld_fec_fin_year := to_date('31/12/' || to_char(adi_fec_proceso, 'yyyy'), 'dd/mm/yyyy');
      
      -- ahora capturo la fecha de fin del periodo
      SELECT COUNT(*)
        INTO ln_count
        FROM rrhh_param_org t
       WHERE trunc(t.fec_proceso) = trunc(adi_fec_proceso)
         AND t.tipo_trabajador    = asi_tipo_trabaj
         and t.origen             = asi_origen
         and t.tipo_planilla      = asi_tipo_planilla;
      
      IF ln_count = 0 THEN
         RAISE_APPLICATION_ERROR(-20000, 'No se han definido parametros de Fechas de Calculo para el tipo de trabajador: ' ||
                                         asi_tipo_trabaj || ' fecha de proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
      END IF;
      
      SELECT t.fec_final
        INTO ld_fec_fin_per
        FROM rrhh_param_org t
       WHERE trunc(t.fec_proceso) = trunc(adi_fec_proceso)
         AND t.tipo_trabajador    = asi_tipo_trabaj
         and t.origen             = asi_origen
         and t.tipo_trabajador    = asi_tipo_planilla;
      
      -- Ahora calculo los dias faltantes
      IF trunc(ld_fec_fin_per) <= trunc(ld_fec_fin_year) THEN
         ln_dias_year := ld_fec_fin_year - ld_fec_fin_per;
      ELSE
         RAISE_APPLICATION_ERROR(-20000, 'La fecha de fin del Periodo del proceso no puede ser mayor a la fecha de fin de a?o'
                                         || chr(13) || 'Fecha de fin de periodo: ' || to_char(ld_fec_fin_per, 'dd/mm/yyyy')
                                         || chr(13) || 'Fecha de fin de a?o: ' || to_char(ld_fec_fin_year, 'dd/mm/yyyy'));
      END IF;
      
      -- Obtengo el jornal proyectable
      select NVL(SUM(gf.imp_gan_desc),0)
        INTO ln_sueldo_proy
        from gan_desct_fijo gf
       where gf.cod_trabajador = asi_codtra
         and gf.concep in ( select d.concepto_calc
                             from grupo_calculo_det d
                            where d.grupo_calculo = ls_grp_quinta_categ ) ;
      
      -- Ahora calculo la proyeccion del jornal por los dias que quedan en el a?o
      ln_sueldo_proy := ln_sueldo_proy / 30;
      ln_imp_calculo := ln_sueldo_proy * ln_dias_year;
      /*ln_imp_calculo := ln_sueldo_proy * ln_meses_proy;
      
      if to_char(adi_fec_proceso, 'dd') <= '15' then
         ln_imp_calculo := ln_imp_calculo + ln_sueldo_proy / 2;
      end if;
      */
      
      -- Sumo el total
      ln_imp_calculo := ln_imp_calculo + ln_rem_precisa + ln_rem_imprecisa 
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
          
          if ln_soles_ret > 0 then
             ln_dolar_ret := ln_soles_ret / ani_tipcam ;
             --  Inserta registros en la tabla CALCULO
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                    tipo_planilla )
             values(
                    asi_codtra, ls_cnc_ret_quinta, adi_fec_proceso, 0, 0,
                    0, ln_soles_ret, ln_dolar_ret, asi_origen, '1', 1, 
                    asi_tipo_planilla ) ;
          end if ;
       end if ; 
      
   END IF;
   
   -- Obtengo algun importe de la retención de quinta que se haya colocado en ganancias fijas para sumarlo
   select nvl(sum(t.imp_gan_desc),0)
     into ln_ret_dscto_fijo
     from gan_desct_fijo t
    where t.cod_trabajador = asi_codtra
      and t.concep         = ls_cnc_ret_quinta;
   
   if ln_ret_dscto_fijo > 0 then
      ln_dolar_ret := ln_ret_dscto_fijo / ani_tipcam ;

      --  Inserta registros en la tabla CALCULO
      update calculo
        set imp_soles = imp_soles + ln_ret_dscto_fijo,
            imp_dolar = imp_dolar + ln_dolar_ret
       where cod_trabajador = asi_codtra
         and concep         = ls_cnc_ret_quinta;
             
      if SQL%NOTFOUND then
           insert into calculo (
                  cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                  dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
           values(
                  asi_codtra, ls_cnc_ret_quinta, adi_fec_proceso, 0, 0,
                  0, ln_ret_dscto_fijo, ln_dolar_ret, asi_origen, '1', 1, asi_tipo_planilla ) ;
      end if;      
   end if;
   
   --  Inserta registros en la tabla QUINTA_CATEGORIA
   IF ln_soles_ret IS NULL THEN ln_soles_ret := 0; END IF;
   
   if ln_soles_ret  + ln_ret_dscto_fijo> 0 then
   
       insert into quinta_categoria (
              cod_trabajador, fec_proceso, rem_proyectable,
              rem_imprecisa, rem_retencion, rem_gratif, flag_replicacion, 
              nro_dias, sueldo, flag_automatico, gratif_proyect  )
       values (
              asi_codtra, adi_fec_proceso, ln_sueldo_proy,
              ln_rem_imprecisa, ln_soles_ret + ln_ret_dscto_fijo, ln_gratificacion, '1', 
              ani_dias_trabaj, ln_rem_precisa, '1', ln_gratificacion ) ;
   end if;


end usp_rh_cal_quinta_categoria ;
/
