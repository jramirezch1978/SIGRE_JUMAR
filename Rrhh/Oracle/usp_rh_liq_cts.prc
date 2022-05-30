create or replace procedure usp_rh_liq_cts (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

lk_fec_inicio          constant date := to_date('01/01/1995','dd/mm/yyyy') ;

ln_verifica            integer ;
ln_sw                  integer ;
ls_insist_cts          char(3) ;
ls_reinte_cts          char(3) ;

ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_socio               char(1) ;
ls_concepto            char(4) ;
ln_dias_lic_descto     number(4) ;

ld_fec_ingreso         date ;
ld_fec_inicio          date ;
ln_fac_cese            number(9,6) ;
ln_fac_prdo            number(9,6) ;
ln_fac_emplear         number(9,6) ;
ln_interes             number(13,2) ;
                       
ln_dias                number(2) ;
ln_ano_liq             number(4) ;
ln_mes_liq             number(2) ;
ln_dia_liq             number(2) ;
ln_ano_ing             number(4) ;
ln_mes_ing             number(2) ;
ln_dia_ing             number(2) ;
ln_ts_ano              number(2) ;
ln_ts_mes              number(2) ;
ln_ts_dia              number(2) ;

ld_prdo_ini            date ;
ld_prdo_fin            date ;

ln_ano                 number(4) ;
ln_dias_cts            number(5,2) ;
ln_dias_mes            number(5,2) ;
ln_dias_inasis         number(5,2) ;
ln_dias_reinte         number(5,2) ;
ln_ult_remun           number(13,2) ;

--  Lectura de depositos de C.T.S. por trabajador
cursor c_liquidacion_cts is
  select c.fec_prdo_dpsto, c.imp_prdo_dpsto
  from cnta_crrte_cts c
  where c.cod_trabajador = as_cod_trabajador
  order by c.cod_trabajador, c.fec_prdo_dpsto ;

begin

--  *********************************************************************
--  ***   GENERA LIQUIDACION DE COMPENSACION POR TIEMPO DE SERVICIO   ***
--  *********************************************************************

select nvl(p.dias_interes_cts,0) into ln_dias from rh_liqparam p
  where p.reckey = '1' ;
  
select m.fec_ingreso, m.situa_trabaj into ld_fec_ingreso, ls_socio from maestro m
  where m.cod_trabajador = as_cod_trabajador ;

if ld_fec_ingreso < lk_fec_inicio then
  ld_fec_inicio := lk_fec_inicio ;
  if nvl(ls_socio,' ') <> 'S' then
    ld_fec_inicio := ld_fec_ingreso ;
  end if ;
else
  ld_fec_inicio := ld_fec_ingreso ;
end if ;
  
--  Determina tiempo de servicio
ln_ano_liq := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
ln_mes_liq := to_number(to_char(ad_fec_liquidacion,'mm')) ;
ln_dia_liq := to_number(to_char(ad_fec_liquidacion,'dd')) ;
ln_ano_ing := to_number(to_char(ld_fec_inicio,'yyyy')) ;
ln_mes_ing := to_number(to_char(ld_fec_inicio,'mm')) ;
ln_dia_ing := to_number(to_char(ld_fec_inicio,'dd')) ;
if ln_mes_liq < ln_mes_ing then
  ln_ano_liq := ln_ano_liq - 1 ; ln_mes_liq := ln_mes_liq + 12 ;
end if ;
if ln_dia_liq < ln_dia_ing then
  ln_mes_liq := ln_mes_liq - 1 ; ln_dia_liq := ln_dia_liq + 30 ;
end if ;
if ln_mes_liq < ln_mes_ing then
  ln_ano_liq := ln_ano_liq - 1 ; ln_mes_liq := ln_mes_liq + 12 ;
end if ;
ln_ts_ano := ln_ano_liq - ln_ano_ing ;
ln_ts_mes := ln_mes_liq - ln_mes_ing ;
ln_ts_dia := ln_dia_liq - ln_dia_ing ;
ln_ts_dia := ln_ts_dia + 1 ;

--  Determina factor de C.T.S. a la fecha de cese
ln_verifica := 0 ; ln_fac_cese := 0 ;
select count(*) into ln_verifica from factor_planilla f
  where trunc(f.fec_calc_int) = trunc(ad_fec_liquidacion) ;
if ln_verifica > 0 then
  select nvl(f.fact_cts,0) into ln_fac_cese from factor_planilla f
    where trunc(f.fec_calc_int) = trunc(ad_fec_liquidacion) ;
  if nvl(ln_fac_cese,0) = 0 then
    raise_application_error
      ( -20000, 'Factor de C.T.S. al '||to_char(ad_fec_liquidacion,'dd/mm/yyyy')||
        ' Es cero. Por favor ingresar factor') ;
  end if ;
else
  raise_application_error
    ( -20001, 'No existe factor de C.T.S. al '||to_char(ad_fec_liquidacion,'dd/mm/yyyy')||
      '. Por favor ingresar factor') ;
end if ;

--  Calcula interes por depositos de C.T.S.
ln_sw := 0 ;
for rc_cts in c_liquidacion_cts loop

  --  Graba tiempo efectivo a liquidar por C.T.S.
  if ln_sw = 0 then
    ln_sw := 1 ;
    select p.grp_cts into ls_grupo
      from rh_liqparam p where p.reckey = '1' ;
    select d.cod_sub_grupo into ls_sub_grupo
      from rh_liq_grupo_det d where d.cod_grupo = ls_grupo ;
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo, ld_fec_inicio, ad_fec_liquidacion,
      nvl(ln_ts_ano,0), nvl(ln_ts_mes,0), nvl(ln_ts_dia,0) ) ;
  end if ;
  
  select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
    where trunc(f.fec_calc_int) = (trunc(rc_cts.fec_prdo_dpsto) - 1) ;
    
  ln_fac_emplear := (nvl(ln_fac_cese,0) / nvl(ln_fac_prdo,0)) - 1 ;
  ln_interes     := nvl(rc_cts.imp_prdo_dpsto,0) * nvl(ln_fac_emplear,0) ;

  --  Determina periodo de inicio y fin del deposito
  if to_char(rc_cts.fec_prdo_dpsto,'mm/yyyy') = '05/1995' then
    ld_prdo_ini := lk_fec_inicio ;
    ld_prdo_fin := trunc(rc_cts.fec_prdo_dpsto) - ln_dias ;
  else
    ld_prdo_ini := add_months((trunc(rc_cts.fec_prdo_dpsto) - ln_dias), -6) + 1 ;
    ld_prdo_fin := add_months(ld_prdo_ini, + 6) - 1 ;
  end if ;

  --  Inserta movimiento de C.T.S. por periodos
  insert into rh_liq_cts (
    cod_trabajador, cod_grupo, cod_sub_grupo, periodo_ini, periodo_fin,
    deposito, factor, interes )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo, ld_prdo_ini, ld_prdo_fin,
    nvl(rc_cts.imp_prdo_dpsto,0), nvl(ln_fac_emplear,0), nvl(ln_interes,0) ) ;

end loop ;

--  **********************************************************
--  ***   GENERA PAGOS DE LIQUIDACION POR C.T.S. TRUNCAS   ***
--  **********************************************************

select c.grp_dias_inasistencia_cts, c.grp_dias_reintegro_cts
  into ls_insist_cts, ls_reinte_cts
  from rrhhparam_cconcep c where c.reckey = '1' ;

--  Determina numero de dias a liquidar
ln_ano := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
if to_char(ad_fec_liquidacion,'mm') <= '04' then
  ld_prdo_ini := to_date('01/11'||to_char((ln_ano-1)),'dd/mm/yyyy') ;
elsif to_char(ad_fec_liquidacion,'mm') > '04' and to_char(ad_fec_liquidacion,'mm') <= '10' then
  ld_prdo_ini := to_date('01/05'||to_char((ln_ano)),'dd/mm/yyyy') ;
elsif to_char(ad_fec_liquidacion,'mm') > '10' and to_char(ad_fec_liquidacion,'mm') <= '12' then
  ld_prdo_ini := to_date('01/11'||to_char((ln_ano)),'dd/mm/yyyy') ;
end if ;
if ld_fec_ingreso > ld_prdo_ini then
  ld_prdo_ini := ld_fec_ingreso ;
end if ;
ln_dias_cts := usf_rh_liq_dias_truncos(ld_prdo_ini, ad_fec_liquidacion) ;
if nvl(ln_dias_cts,0) > 180 then
  ln_dias_cts := 180 ;
end if ;

--  Determina dias de inasistencias
ln_verifica := 0 ; ln_dias_inasis := 0 ; ln_dias_mes := 0 ;
select count(*) into ln_verifica from historico_inasistencia hi
  where hi.cod_trabajador = as_cod_trabajador and
        (trunc(hi.fec_movim) between ld_prdo_ini and ad_fec_liquidacion) and
        hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                       where g.grupo_calculo = ls_insist_cts ) ;
if ln_verifica > 0 then  
  select sum(nvl(hi.dias_inasist,0)) into ln_dias_inasis from historico_inasistencia hi
    where hi.cod_trabajador = as_cod_trabajador and
          (trunc(hi.fec_movim) between ld_prdo_ini and ad_fec_liquidacion) and
          hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                         where g.grupo_calculo = ls_insist_cts ) ;
end if ;
ln_verifica := 0 ;
select count(*) into ln_verifica from inasistencia i
  where i.cod_trabajador = as_cod_trabajador and
        (trunc(i.fec_movim) between ld_prdo_ini and ad_fec_liquidacion) and
        i.concep in ( select g.concepto_calc from grupo_calculo_det g
                      where g.grupo_calculo = ls_insist_cts ) ;
if ln_verifica > 0 then  
  select sum(nvl(i.dias_inasist,0)) into ln_dias_mes from inasistencia i
    where i.cod_trabajador = as_cod_trabajador and
          (trunc(i.fec_movim) between ld_prdo_ini and ad_fec_liquidacion) and
          i.concep in ( select g.concepto_calc from grupo_calculo_det g
                        where g.grupo_calculo = ls_insist_cts ) ;
  ln_dias_inasis := ln_dias_inasis + ln_dias_mes ;
end if ;

--  Determina dias de reintegros
ln_verifica := 0 ; ln_dias_reinte := 0 ; ln_dias_mes := 0 ;
select count(*) into ln_verifica from historico_inasistencia hi
  where hi.cod_trabajador = as_cod_trabajador and
        (trunc(hi.fec_movim) between ld_prdo_ini and ad_fec_liquidacion) and
        hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                       where g.grupo_calculo = ls_reinte_cts ) ;
if ln_verifica > 0 then  
  select sum(nvl(hi.dias_inasist,0)) into ln_dias_reinte from historico_inasistencia hi
    where hi.cod_trabajador = as_cod_trabajador and
          (trunc(hi.fec_movim) between ld_prdo_ini and ad_fec_liquidacion) and
          hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                         where g.grupo_calculo = ls_reinte_cts ) ;
end if ;
ln_verifica := 0 ;
select count(*) into ln_verifica from inasistencia i
  where i.cod_trabajador = as_cod_trabajador and
        i.concep in ( select g.concepto_calc from grupo_calculo_det g
                      where g.grupo_calculo = ls_reinte_cts ) ;
if ln_verifica > 0 then  
  select sum(nvl(i.dias_inasist,0)) into ln_dias_mes from inasistencia i
    where i.cod_trabajador = as_cod_trabajador and
          i.concep in ( select g.concepto_calc from grupo_calculo_det g
                        where g.grupo_calculo = ls_reinte_cts ) ;
  ln_dias_reinte := ln_dias_reinte + ln_dias_mes ;
end if ;

ln_dias_cts := ln_dias_cts - nvl(ln_dias_inasis,0) + nvl(ln_dias_reinte,0) ;

--  Determina ultima remuneracion percibida
select nvl(l.ult_remuneracion,0) into ln_ult_remun
  from rh_liq_credito_laboral l
  where l.cod_trabajador = as_cod_trabajador ;
  
--  Calcula C.T.S. truncas
ln_verifica := 0 ;
select count(*) into ln_verifica from grupo_calculo c
  where c.grupo_calculo = ls_insist_cts ;
if ln_verifica > 0 then  
  select c.concepto_gen into ls_concepto from grupo_calculo c
    where c.grupo_calculo = ls_insist_cts ;
  ln_verifica := 0 ; ln_dias_lic_descto := 0 ;
  select count(*) into ln_verifica from incidencia_trabajador t
    where t.cod_trabajador = as_cod_trabajador and t.concep = ls_concepto and
          nvl(t.flag_conformidad,'0') = '1' ;
  if ln_verifica > 0 then  
    select sum(nvl(t.nro_dias,0)) into ln_dias_lic_descto from incidencia_trabajador t
      where t.cod_trabajador = as_cod_trabajador and t.concep = ls_concepto and
            nvl(t.flag_conformidad,'0') = '1' ;
    ln_dias_cts := ln_dias_cts - ln_dias_lic_descto ;
  end if ;
end if ;

ln_ult_remun := (nvl(ln_ult_remun,0) / 360) * nvl(ln_dias_cts,0) ;

--  Determina tiempo de servicio si no tiene C.T.S. semestrales pendientes
if ln_sw = 0 then

  ln_ano_liq := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
  ln_mes_liq := to_number(to_char(ad_fec_liquidacion,'mm')) ;
  ln_dia_liq := to_number(to_char(ad_fec_liquidacion,'dd')) ;
  ln_ano_ing := to_number(to_char(ld_prdo_ini,'yyyy')) ;
  ln_mes_ing := to_number(to_char(ld_prdo_ini,'mm')) ;
  ln_dia_ing := to_number(to_char(ld_prdo_ini,'dd')) ;
  if ln_mes_liq < ln_mes_ing then
    ln_ano_liq := ln_ano_liq - 1 ; ln_mes_liq := ln_mes_liq + 12 ;
  end if ;
  if ln_dia_liq < ln_dia_ing then
    ln_mes_liq := ln_mes_liq - 1 ; ln_dia_liq := ln_dia_liq + 30 ;
  end if ;
  if ln_mes_liq < ln_mes_ing then
    ln_ano_liq := ln_ano_liq - 1 ; ln_mes_liq := ln_mes_liq + 12 ;
  end if ;
  ln_ts_ano := ln_ano_liq - ln_ano_ing ;
  ln_ts_mes := ln_mes_liq - ln_mes_ing ;
  ln_ts_dia := ln_dia_liq - ln_dia_ing ;
  ln_ts_dia := ln_ts_dia + 1 ;

  select p.grp_cts into ls_grupo
    from rh_liqparam p where p.reckey = '1' ;
  select d.cod_sub_grupo into ls_sub_grupo
    from rh_liq_grupo_det d where d.cod_grupo = ls_grupo ;
  insert into rh_liq_tiempo_efectivo (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
    tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo, ld_prdo_ini, ad_fec_liquidacion,
    nvl(ln_ts_ano,0), nvl(ln_ts_mes,0), nvl(ln_ts_dia,0) ) ;

end if ;

--  Inserta movimiento de C.T.S. truncas
 insert into rh_liq_cts (
  cod_trabajador, cod_grupo, cod_sub_grupo, periodo_ini, periodo_fin,
  deposito, factor, interes )
values (
  as_cod_trabajador, ls_grupo, ls_sub_grupo, ld_prdo_ini, ad_fec_liquidacion,
  nvl(ln_ult_remun,0), 0, 0 ) ;

end usp_rh_liq_cts ;
/
