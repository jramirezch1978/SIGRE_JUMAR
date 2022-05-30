create or replace procedure usp_rh_cal_enfermedad (
       asi_codtra        in maestro.cod_trabajador%TYPE,
       asi_tipo_trabaj   in maestro.tipo_trabajador%TYPE,
       adi_fec_proceso   in date,
       asi_origen        in origen.cod_origen%TYPE,
       an_tipcam         in number
) is

ls_grp_permiso20        rrhhparam_cconcep.enferm_patron_pirm20%TYPE;
ls_grp_subsidio         rrhhparam_cconcep.subsidio_enfermedad%TYPE;
ls_tipo_des             rrhhparam.tipo_trab_destajo%TYPE;
ls_cnc_subsidio         concepto.concep%TYPE;

ln_count                integer ;
ls_cnc_enfermedad       concepto.concep%TYPE;
ln_dias                 number(5,2) ;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_dolar%TYPE;

-- Para Jornaleros
ls_flag_tipo_sueldo     tipo_trabajador.flag_ingreso_boleta%TYPE;

-- Datos Generales
ln_year1                number;
ln_mes1                 number;
ln_year2                number;
ln_mes2                 number;


begin

--  **************************************************
--  ***   REALIZA CALCULO POR DIAS DE ENFERMEDAD   ***
--  **************************************************

select c.enferm_patron_pirm20, c.subsidio_enfermedad
  into ls_grp_permiso20, ls_grp_subsidio
  from rrhhparam_cconcep c
  where c.reckey = '1' ;
  
select r.tipo_trab_destajo
  into ls_tipo_des
  from rrhhparam r
 where r.reckey = '1';

-- Obtengo el plag de pago de boleta si es jornal o sueldo
select t.flag_ingreso_boleta
  into ls_flag_tipo_sueldo
  from tipo_trabajador t
 where t.tipo_trabajador = asi_tipo_trabaj;

select count(*)
  into ln_count
  from grupo_calculo g
  where g.grupo_calculo = ls_grp_permiso20 ;

if ln_count > 0 then

  select g.concepto_gen
    into ls_cnc_enfermedad
    from grupo_calculo g
    where g.grupo_calculo = ls_grp_permiso20;

  select count(*)
    into ln_count
    from inasistencia i
    where i.cod_trabajador = asi_codtra
      and i.concep = ls_cnc_enfermedad
      AND trunc(i.fec_movim) = trunc(adi_fec_proceso);

  if ln_count > 0 then

    select sum(nvl(i.dias_inasist,0))
      into ln_dias
      from inasistencia i
      where i.cod_trabajador   = asi_codtra
        and i.concep           = ls_cnc_enfermedad
        AND trunc(i.fec_movim) = trunc(adi_fec_proceso) ;

    -- Si no es trabajador de tipo destajo simplemente le calculo lo que esta en ganancias y descuentos fijos 
    if asi_tipo_trabaj <> ls_tipo_des then
       -- Si es jornalero le calculo en base a lo que gana como jornal fijo 
       select NVL(sum(nvl(gdf.imp_gan_desc,0)),0)
         into ln_imp_soles
         from gan_desct_fijo gdf
        where gdf.cod_trabajador = asi_codtra
          and gdf.flag_estado = '1'
          and gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                                where d.grupo_calculo = ls_grp_permiso20 ) ;

       ln_imp_soles := (ln_imp_soles / 30) * ln_dias ;
    else
      
       -- Calculo en base a los ulitmos 6 meses que ha ganado
       ln_year1 := to_number(to_char(adi_fec_proceso, 'yyyy'));
       ln_mes1  := to_number(to_char(adi_fec_proceso, 'mm'));
       
       ln_mes1 := ln_mes1 - 1;
       
       if ln_mes1 <= 0 then
          ln_mes1 := 12;
          ln_year1 := ln_year1 - 1;
       end if;
       
       ln_mes2 := ln_mes1 - 6;
       ln_year2 := ln_year1;
       
       if ln_mes2 <= 0 then
          ln_mes2 := 12 + ln_mes2;
          ln_year2 := ln_year2 - 1;
       end if;

       select NVL(sum(nvl(hc.imp_soles,0)),0)
         into ln_imp_soles
         from historico_calculo hc
        where hc.cod_trabajador = asi_codtra
          and to_char(hc.fec_calc_plan, 'yyyymm') between trim(to_char(ln_year2, '0000')) || trim(to_char(ln_mes2, '00')) and trim(to_char(ln_year1, '0000')) || trim(to_char(ln_mes1, '00'))
          and hc.concep in ( select d.concepto_calc from grupo_calculo_det d
                                where d.grupo_calculo = ls_grp_permiso20 ) ;
                                
       ln_imp_soles := (ln_imp_soles / 180) * ln_dias ;
       
    end if;
    ln_imp_dolar := ln_imp_soles / an_tipcam ;

    UPDATE calculo
     SET horas_trabaj = null,
         horas_pag    = null,
         dias_trabaj  = dias_trabaj + ln_dias,
         imp_soles    = imp_soles + ln_imp_soles,
         imp_dolar    = imp_dolar + ln_imp_dolar
    WHERE cod_trabajador = asi_codtra
      AND concep = ls_cnc_enfermedad;

    if SQL%NOTFOUND then
        insert into calculo (
                  cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                  dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
        values (
                  asi_codtra, ls_cnc_enfermedad, adi_fec_proceso, 0, 0,
                  ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;
    end if;

  end if ;

end if;

-- Ahora viene el subsidio

select count(*)
  into ln_count
  from grupo_calculo g
  where g.grupo_calculo = ls_grp_subsidio ;

if ln_count > 0 then

  select g.concepto_gen
    into ls_cnc_subsidio
    from grupo_calculo g
    where g.grupo_calculo = ls_grp_subsidio;

  select count(*)
    into ln_count
    from inasistencia i
    where i.cod_trabajador = asi_codtra
      and i.concep = ls_cnc_subsidio
      AND trunc(i.fec_movim) = trunc(adi_fec_proceso);

  if ln_count > 0 then

    select sum(nvl(i.dias_inasist,0))
      into ln_dias
      from inasistencia i
      where i.cod_trabajador = asi_codtra
        and i.concep = ls_cnc_subsidio
        AND trunc(i.fec_movim) = trunc(adi_fec_proceso);

        -- Si no es trabajador de tipo destajo simplemente le calculo lo que esta en ganancias y descuentos fijos 
    if asi_tipo_trabaj <> ls_tipo_des then
       -- Si es jornalero le calculo en base a lo que gana como jornal fijo 
       select NVL(sum(nvl(gdf.imp_gan_desc,0)),0)
         into ln_imp_soles
         from gan_desct_fijo gdf
        where gdf.cod_trabajador = asi_codtra
          and gdf.flag_estado = '1'
          and gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                                where d.grupo_calculo = ls_grp_subsidio ) ;

       ln_imp_soles := (ln_imp_soles / 30) * ln_dias ;
    else
      
       -- Calculo en base a los ulitmos 6 meses que ha ganado
       ln_year1 := to_number(to_char(adi_fec_proceso, 'yyyy'));
       ln_mes1  := to_number(to_char(adi_fec_proceso, 'mm'));
       
       ln_mes1 := ln_mes1 - 1;
       
       if ln_mes1 <= 0 then
          ln_mes1 := 12;
          ln_year1 := ln_year1 - 1;
       end if;
       
       ln_mes2 := ln_mes1 - 6;
       ln_year2 := ln_year1;
       
       if ln_mes2 <= 0 then
          ln_mes2 := 12 + ln_mes2;
          ln_year2 := ln_year2 - 1;
       end if;

       select NVL(sum(nvl(hc.imp_soles,0)),0)
         into ln_imp_soles
         from historico_calculo hc
        where hc.cod_trabajador = asi_codtra
          and to_char(hc.fec_calc_plan, 'yyyymm') between trim(to_char(ln_year2, '0000')) || trim(to_char(ln_mes2, '00')) and trim(to_char(ln_year1, '0000')) || trim(to_char(ln_mes1, '00'))
          and hc.concep in ( select d.concepto_calc from grupo_calculo_det d
                                where d.grupo_calculo = ls_grp_permiso20 ) ;
                                
       ln_imp_soles := (ln_imp_soles / 180) * ln_dias ;
       
    end if;

    ln_imp_dolar := ln_imp_soles / an_tipcam ;
    
    UPDATE calculo
      SET horas_trabaj = null,
          horas_pag    = null,
          dias_trabaj  = dias_trabaj + ln_dias,
          imp_soles    = imp_soles + ln_imp_soles,
          imp_dolar    = imp_dolar + ln_imp_dolar
     WHERE cod_trabajador = asi_codtra
       AND concep = ls_cnc_enfermedad;

    if SQL%NOTFOUND then
        insert into calculo (
                  cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                  dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
        values (
                  asi_codtra, ls_cnc_subsidio, adi_fec_proceso, 0, 0,
                  ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;
    end if;

  end if ;
end if;


end usp_rh_cal_enfermedad ;
/
