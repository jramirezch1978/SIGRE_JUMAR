create or replace procedure usp_cal_gratificacion (
  as_codtra      in maestro.cod_trabajador%type,
  ad_fec_proceso in rrhhparam.fec_proceso%type ) is

lk_ganancia_fija   constant char(3) := '220' ;
lk_sobretiempos    constant char(3) := '001' ;

ls_cod_seccion     char(3) ;
ls_bonificacion    char(1) ;
ld_fec_ingreso     date ;
ln_importe_bruto   number(13,2) ;
ln_importe_neto    number(13,2) ;
ln_importe         number(13,2) ;
ln_ganancia_fija   number(13,2) ;
ln_promedio_sob    number(13,2) ;
ln_acum_sob        number(13,2) ;
ld_ran_inicio      date ;
ld_ran_final       date ;
ln_nro_meses       integer ;
ln_contador        integer ;
ln_factor_descto   number(9,6) ;
ln_descto_ley      number(13,2) ;
ln_porcentaje_jud  number(4,2) ;
ln_descto_judicial number(13,2) ;
ln_judicial_fijo   number(13,2) ;
ld_fec_desde       date ;
ld_fec_hasta       date ;
ln_dias_mes        number(5,2) ;
ln_dias_inasist    number(5,2) ;
ln_dias_reinteg    number(5,2) ;
ld_new_fecha       date ;
ls_dia_ingreso     char(2) ;
ln_dias_meses      number(3) ;

--  Ganancias fijas afectos a la gratificacion
cursor c_ganancias_fijas is
  select rhnd.concep
  from  rrhh_nivel_detalle rhnd
  where rhnd.cod_nivel = lk_ganancia_fija ;

--  Conceptos de sobretiempos afectos a la gratificacion
cursor c_sobretiempos is
  select concep
  from rrhh_nivel_detalle rhnd
  where rhnd.cod_nivel = lk_sobretiempos ;

begin

--  Determina fechas para contabilizar inasistencias
if to_char(ad_fec_proceso,'MM') = '07' then
  ld_fec_desde := add_months(ad_fec_proceso, - 7) + 1 ;
  ld_fec_hasta := add_months(ad_fec_proceso, - 1) ;
elsif to_char(ad_fec_proceso,'MM') = '12' then
  ld_fec_desde := add_months(ad_fec_proceso, - 6) + 1 ;
  ld_fec_hasta := add_months(ad_fec_proceso, - 1) ;
end if ;

--  Determina datos del maestro de trabajadores
select m.fec_ingreso, nvl(m.cod_seccion,' '), nvl(m.bonif_fija_30_25,' '),
       nvl(m.porc_judicial,0)
  into ld_fec_ingreso, ls_cod_seccion, ls_bonificacion,
       ln_porcentaje_jud
  from maestro m
  where m.cod_trabajador = as_codtra  ;

--  Omite secciones para el calculo de gratificacion
if ls_cod_seccion = '951' or ls_cod_seccion = '952' or
   ls_cod_seccion = '953' then
   return ;
end if ;

--  Dias para el calculo de gratificacion, siempre y cuando su
--  fecha de ingreso este en el periodo correspondiente

ln_dias_meses := 0 ;
if ld_fec_ingreso between ld_fec_desde and ld_fec_hasta then

  ls_dia_ingreso := to_char(ld_fec_ingreso,'DD') ;

  if to_char(ad_fec_proceso,'MM') = '07' then
    if to_number(ls_dia_ingreso) > 1 then
      ld_fec_ingreso := last_day(ld_fec_ingreso) + 1 ;
    end if ;
    ln_dias_meses := ( to_number(to_char(ld_fec_hasta,'MM')) -
                     to_number(to_char(ld_fec_ingreso,'MM')) + 1 ) ;
    ln_dias_meses := ln_dias_meses * 30 ;
  elsif to_char(ad_fec_proceso,'MM') = '12' then
    ld_new_fecha := add_months(ld_fec_hasta, + 1) ;
    if to_number(ls_dia_ingreso) > 1 then
      ld_fec_ingreso := last_day(ld_fec_ingreso) + 1 ;
    end if ;
    ln_dias_meses := ( to_number(to_char(ld_new_fecha,'MM')) -
                     to_number(to_char(ld_fec_ingreso,'MM')) + 1 ) ;
    ln_dias_meses := ln_dias_meses * 30 ;
  end if ;

end if ;

ln_importe_bruto := 0 ; ln_importe_neto := 0 ;

if ls_cod_seccion = '950' then

  --  **********************************************
  --  ***   CALCULA GRATIFICACION DE JUBILADOS   ***
  --  **********************************************
  select sum(nvl(g.imp_gan_desc,0))
    into ln_importe_bruto
    from gan_desct_fijo g
    where g.cod_trabajador = as_codtra and substr(g.concep,1,2) = '10' and
          g.flag_estado = '1' and g.flag_trabaj = '1' ;
  ln_importe_neto := ln_importe_bruto ;

else

  --  ******************************************************
  --  ***   CALCULA GRATIFICACION DEL PERSONAL ESTABLE   ***
  --  ******************************************************

  --  Acumula ganancias fijas por trabajador
  ln_ganancia_fija := 0 ;
  for rc_gan in c_ganancias_fijas loop
    ln_contador := 0 ;
    select count(*)
      into ln_contador
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
            gdf.flag_trabaj = '1' and gdf.concep = rc_gan.concep ;
    if ln_contador > 0 then
      select nvl(gdf.imp_gan_desc,0)
        into ln_importe
        from gan_desct_fijo gdf
        where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
              gdf.flag_trabaj = '1' and gdf.concep = rc_gan.concep ;
      ln_ganancia_fija := ln_ganancia_fija + ln_importe ;
    end if ;
  end loop;

  if ln_ganancia_fija = 0 then
    return ;
  end if ;

  --  Acumula promedios de sobretiempos de los ultimos seis meses
  ln_promedio_sob := 0 ;
  for rc_sob in c_sobretiempos loop

    ld_ran_inicio := add_months(ad_fec_proceso, - 1) ;
    ln_nro_meses  := 0 ; ln_acum_sob := 0 ;

    for x in reverse 1 .. 6 loop
      ld_ran_final := ld_ran_inicio ;
      ld_ran_inicio := add_months( ld_ran_final, -1 ) + 1 ;

      --  Determina si hay datos de sobretiempos en el mes
      ln_contador := 0 ; ln_importe := 0 ;
      select count(*)
      into ln_contador
      from historico_calculo hc
      where hc.concep = rc_sob.concep and hc.cod_trabajador = as_codtra and
            hc.fec_calc_plan between ld_ran_inicio and ld_ran_final ;

      if ln_contador > 0 then
        select sum(nvl(hc.imp_soles,0))
          into ln_importe
          from historico_calculo hc
          where hc.concep = rc_sob.concep and hc.cod_trabajador = as_codtra and
                hc.fec_calc_plan between ld_ran_inicio and ld_ran_final ;
        if ln_importe > 0 then
          ln_nro_meses := ln_nro_meses + 1 ;
          ln_acum_sob := ln_acum_sob + ln_importe ;
          ld_ran_inicio := ld_ran_inicio - 1 ;
        end if ;
      end if;

    end loop ;

    if ln_nro_meses > 2 then
      ln_promedio_sob := ln_promedio_sob + (ln_acum_sob / 6 );
    end if;

  end loop;

  --  Incrementa bonificacion del 30% o 25% si lo percibiera
  ln_importe_bruto := ln_ganancia_fija + ln_promedio_sob ;
  if ls_bonificacion = '1' then
    ln_importe_bruto := ln_importe_bruto * 1.30 ;
  elsif ls_bonificacion = '2' then
    ln_importe_bruto := ln_importe_bruto * 1.25 ;
  end if ;

  --  Acumula dias de inasistencias
  ln_dias_inasist := 0 ; ln_contador := 0 ;
  select count(*)
    into ln_contador
    from historico_inasistencia hi
    where hi.cod_trabajador = as_codtra and
          (to_number(hi.concep) between 2401 and 2404) and
          (hi.fec_movim between ld_fec_desde and ld_fec_hasta) ;
  if ln_contador > 0 then
    select sum(nvl(hi.dias_inasist,0))
      into ln_dias_inasist
      from historico_inasistencia hi
      where hi.cod_trabajador = as_codtra and
            (to_number(hi.concep) between 2401 and 2404) and
            (hi.fec_movim between ld_fec_desde and ld_fec_hasta) ;
  end if ;

  if to_char(ad_fec_proceso,'MM') = '12' then
    ln_dias_mes := 0 ; ln_contador := 0 ;
    select count(*)
      into ln_contador
      from inasistencia i
      where i.cod_trabajador = as_codtra and
            (to_number(i.concep) between 2401 and 2404) and
            to_char(i.fec_movim,'MM/YYYY') = to_char(ad_fec_proceso,'MM/YYYY') ;
    if ln_contador > 0 then
      select sum(nvl(i.dias_inasist,0))
        into ln_dias_mes
        from inasistencia i
        where i.cod_trabajador = as_codtra and
              (to_number(i.concep) between 2401 and 2404) and
              to_char(i.fec_movim,'MM/YYYY') = to_char(ad_fec_proceso,'MM/YYYY') ;
      ln_dias_inasist := ln_dias_inasist + ln_dias_mes ;
    end if ;
  end if ;

  --  Acumula dias de reintegros
  ln_dias_reinteg := 0 ; ln_contador := 0 ;
  select count(*)
    into ln_contador
    from historico_inasistencia hi
    where hi.cod_trabajador = as_codtra and
          hi.concep = '1426' and
          (hi.fec_movim between ld_fec_desde and ld_fec_hasta) ;
  if ln_contador > 0 then
    select sum(nvl(hi.dias_inasist,0))
      into ln_dias_reinteg
      from historico_inasistencia hi
      where hi.cod_trabajador = as_codtra and
            hi.concep = '1426' and
            (hi.fec_movim between ld_fec_desde and ld_fec_hasta) ;
  end if ;

  if to_char(ad_fec_proceso,'MM') = '12' then
    ln_dias_mes := 0 ; ln_contador := 0 ;
    select count(*)
      into ln_contador
      from inasistencia i
      where i.cod_trabajador = as_codtra and
            i.concep = '1426' and
            to_char(i.fec_movim,'MM/YYYY') = to_char(ad_fec_proceso,'MM/YYYY') ;
    if ln_contador > 0 then
      select sum(nvl(i.dias_inasist,0))
        into ln_dias_mes
        from inasistencia i
        where i.cod_trabajador = as_codtra and
              i.concep = '1426' and
              to_char(i.fec_movim,'MM/YYYY') = to_char(ad_fec_proceso,'MM/YYYY') ;
      ln_dias_reinteg := ln_dias_reinteg + ln_dias_mes ;
    end if ;
  end if ;

  --  ***********************************************************
  --  ***   ACTUALIZA IMPORTE BRUTO POR LOS DIAS TRABAJADOS   ***
  --  ***********************************************************

  ln_dias_mes := (180 + ln_dias_reinteg) - ln_dias_inasist ;
  if ln_dias_meses > 0 then
    ln_dias_mes := ln_dias_meses ;
  end if ;
  ln_importe_bruto := ln_importe_bruto / 180 * ln_dias_mes ;

  --  Calcula descuento de sistema nacional de pensiones
  select nvl(c.fact_pago,0)
    into ln_factor_descto
    from concepto c
    where c.concep = '2001' ;
  ln_descto_ley := ln_importe_bruto * ln_factor_descto ;

  --  Calcula descuento del porcentaje judicial
  ln_descto_judicial := 0 ;
  if ln_porcentaje_jud > 0 then
    ln_descto_judicial := (ln_importe_bruto - ln_descto_ley) * (ln_porcentaje_jud / 100) ;
  end if ;

  --  Calcula descuento judicial fijo
  ln_contador := 0 ; ln_judicial_fijo := 0 ;
  select count(*)
    into ln_contador
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra and gdf.concep = '2201' ;
  if ln_contador > 0 then
    select nvl(gdf.imp_gan_desc,0)
      into ln_judicial_fijo
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_codtra and gdf.concep = '2201' ;
  end if;

  --  Calcula importe neto de la gratificacion
  ln_importe_neto := ln_importe_bruto -
                     (ln_descto_ley + ln_descto_judicial + ln_judicial_fijo) ;

end if ;

--  Actualiza o inserta registros por pago de gratificaciones
ln_contador := 0 ;
select count(*)
  into ln_contador
  from gratificacion g
  where g.cod_trabajador = as_codtra and
        g.fec_proceso = ad_fec_proceso ;
if ln_contador > 0 then
  update gratificacion
    set imp_bruto = ln_importe_bruto
    where cod_trabajador = as_codtra and
          fec_proceso = ad_fec_proceso ;
else
  insert into gratificacion (
    cod_trabajador, fec_proceso, imp_bruto, imp_adelanto )
  values (
    as_codtra, last_day(ad_fec_proceso), ln_importe_bruto, ln_importe_neto ) ;
end if ;

end usp_cal_gratificacion ;
/
