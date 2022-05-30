create or replace procedure usp_rh_liq_fondo_retiro (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

lk_fec_tope           constant date := to_date('31/12/1994','dd/mm/yyyy') ;
ld_fec_ingreso        date ;
ld_fec_proceso        date ;
ld_fec_gratif         date ;
ld_fec_promedio       date ;
ls_socio              char(1) ;
ln_sw                 integer ;
ln_verifica           integer ;
ln_num_mes            integer ;
ls_grupo_gan          char(3) ;

ls_year               char(4) ;
ln_ano_liq            number(4) ;
ln_mes_liq            number(2) ;
ln_dia_liq            number(2) ;
ln_ano_ing            number(4) ;
ln_mes_ing            number(2) ;
ln_dia_ing            number(2) ;
ln_ts_ano             number(2) ;
ln_ts_mes             number(2) ;
ln_ts_dia             number(2) ;
ln_fr_ano             number(2) ;
ln_fr_mes             number(2) ;
ln_fr_dia             number(2) ;
ln_ano_ret            number(4) ;
ln_mes_ret            number(2) ;
ln_dia_ret            number(2) ;

ls_grupo              char(6) ;
ls_sub_grupo          char(6) ;
ls_bonificacion       char(1) ;
ls_nivel              char(3) ;
ls_grp_raccoc         char(3) ;
ls_grp_25             char(3) ;
ls_grp_30             char(3) ;
ls_grat_jul           char(3) ;
ls_grat_dic           char(3) ;
ls_concepto           char(4) ;
ld_ran_ini            date ;
ld_ran_fin            date ;

ln_ult_remun          number(13,2) ;
ln_imp_racion         number(13,2) ;
ln_imp_variable       number(13,2) ;
ln_acum_sobret        number(13,2) ;
ln_prom_sobret        number(13,2) ;
ln_imp_bonif          number(13,2) ;
ln_factor             number(9,6) ;
ln_imp_gratif         number(13,2) ;

--  Lectura de remuneraciones del trabajador
cursor c_ganancias is
  select g.concep, g.imp_gan_desc
  from gan_desct_fijo g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.flag_estado,'0') = '1' and
        g.concep in ( select d.concepto_calc from grupo_calculo_det d
                      where d.grupo_calculo = ls_grupo_gan )
  order by g.cod_trabajador, g.concep ;

--  Lectura de conceptos para promedios de sobretiempos
cursor c_conceptos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = ls_nivel ;

begin

--  *****************************************************
--  ***   GENERA LIQUIDACION POR EL FONDO DE RETIRO   ***
--  *****************************************************

select p.prom_remun_vacac, p.calculo_racion_cocida, p.bonificacion25, p.bonificacion30,
       p.grati_medio_ano, p.grati_fin_ano, p.ganfij_provision_fond_ret
  into ls_nivel, ls_grp_raccoc, ls_grp_25, ls_grp_30,
       ls_grat_jul, ls_grat_dic, ls_grupo_gan
  from rrhhparam_cconcep p where p.reckey = '1' ;

select m.fec_ingreso, m.situa_trabaj, m.bonif_fija_30_25
  into ld_fec_ingreso, ls_socio, ls_bonificacion
  from maestro m
  where m.cod_trabajador = as_cod_trabajador ;

--  Determina tiempo de servicio
ln_ano_liq := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
ln_mes_liq := to_number(to_char(ad_fec_liquidacion,'mm')) ;
ln_dia_liq := to_number(to_char(ad_fec_liquidacion,'dd')) ;
ln_ano_ing := to_number(to_char(ld_fec_ingreso,'yyyy')) ;
ln_mes_ing := to_number(to_char(ld_fec_ingreso,'mm')) ;
ln_dia_ing := to_number(to_char(ld_fec_ingreso,'dd')) ;
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

--  Inserta registro de liquidacion por credito laboral
insert into rh_liq_credito_laboral (
  cod_trabajador, nro_liquidacion, flag_estado, fec_liquidacion,
  tm_anos, tm_meses, tm_dias, ult_remuneracion, imp_liq_befef_soc,
  imp_liq_remun, flag_juicio, flag_reposicion, flag_forma_pago )
values (
  as_cod_trabajador, null, '1', ad_fec_liquidacion,
  ln_ts_ano, ln_ts_mes, ln_ts_dia, 0, 0,
  0, null, null, null ) ;

--  Verifica si se realiza calculo de fondo de retiro
ln_sw := 0 ; ln_fr_ano := 0 ; ln_fr_mes := 0 ; ln_fr_dia := 0 ;
if ls_socio = 'S' and trunc(ld_fec_ingreso) <= lk_fec_tope then

  --  Determina tiempo de liquidacion del fondo de retiro
  ln_sw      := 1 ;
  ln_ano_liq := to_number(to_char(lk_fec_tope,'yyyy')) ;
  ln_mes_liq := to_number(to_char(lk_fec_tope,'mm')) ;
  ln_dia_liq := to_number(to_char(lk_fec_tope,'dd')) ;
  ln_ano_ing := to_number(to_char(ld_fec_ingreso,'yyyy')) ;
  ln_mes_ing := to_number(to_char(ld_fec_ingreso,'mm')) ;
  ln_dia_ing := to_number(to_char(ld_fec_ingreso,'dd')) ;
  if ln_mes_liq < ln_mes_ing then
    ln_ano_liq := ln_ano_liq - 1 ; ln_mes_liq := ln_mes_liq + 12 ;
  end if ;
  if ln_dia_liq < ln_dia_ing then
    ln_mes_liq := ln_mes_liq - 1 ; ln_dia_liq := ln_dia_liq + 30 ;
  end if ;
  if ln_mes_liq < ln_mes_ing then
    ln_ano_liq := ln_ano_liq - 1 ; ln_mes_liq := ln_mes_liq + 12 ;
  end if ;
  ln_fr_ano := ln_ano_liq - ln_ano_ing ;
  ln_fr_mes := ln_mes_liq - ln_mes_ing ;
  ln_fr_dia := ln_dia_liq - ln_dia_ing ;
--  ln_fr_dia := ln_fr_dia + 1 ;

  --  Descuenta tiempo de servicio por fondo de retiro
  ln_verifica := 0 ; ln_ano_ret := 0 ; ln_mes_ret := 0 ; ln_dia_ret := 0 ;
  select count(*) into ln_verifica from ret_tiempo_servicio t
    where t.cod_trabajador = as_cod_trabajador and nvl(t.flag_tipo_oper,'0') = '1' ;
  if ln_verifica > 0 then
    select sum(nvl(t.ano_retencion,0)), sum(nvl(t.mes_retencion,0)), sum(nvl(t.dias_retencion,0))
      into ln_ano_ret, ln_mes_ret, ln_dia_ret
      from ret_tiempo_servicio t
      where t.cod_trabajador = as_cod_trabajador and nvl(t.flag_tipo_oper,'0') = '1' ;
    if ln_fr_mes < ln_mes_ret then
      ln_fr_ano := ln_fr_ano - 1 ; ln_fr_mes := ln_fr_mes + 12 ;
    end if ;
    if ln_fr_dia < ln_dia_ret then
      ln_fr_mes := ln_fr_mes - 1 ; ln_fr_dia := ln_fr_dia + 30 ;
    end if ;
    if ln_fr_mes < ln_mes_ret then
      ln_fr_ano := ln_fr_ano - 1 ; ln_fr_mes := ln_fr_mes + 12 ;
    end if ;
    ln_fr_ano := ln_fr_ano - ln_ano_ret ;
    ln_fr_mes := ln_fr_mes - ln_mes_ret ;
    ln_fr_dia := ln_fr_dia - ln_dia_ret ;
  end if ;
    
  --  Incrementa tiempo de servicio por fondo de retiro
  ln_verifica := 0 ; ln_ano_ret := 0 ; ln_mes_ret := 0 ; ln_dia_ret := 0 ;
  select count(*) into ln_verifica from ret_tiempo_servicio t
    where t.cod_trabajador = as_cod_trabajador and nvl(t.flag_tipo_oper,'0') = '2' ;
  if ln_verifica > 0 then
    select sum(nvl(t.ano_retencion,0)), sum(nvl(t.mes_retencion,0)), sum(nvl(t.dias_retencion,0))
      into ln_ano_ret, ln_mes_ret, ln_dia_ret
      from ret_tiempo_servicio t
      where t.cod_trabajador = as_cod_trabajador and nvl(t.flag_tipo_oper,'0') = '2' ;
    ln_fr_ano := ln_fr_ano + ln_ano_ret ;
    ln_fr_mes := ln_fr_mes + ln_mes_ret ;
    ln_fr_dia := ln_fr_dia + ln_dia_ret ;
    if ln_fr_dia > 30 then
      ln_fr_dia := ln_fr_dia - 30 ; ln_fr_mes := ln_fr_mes + 1 ;
    end if ;
    if ln_fr_mes > 12 then
      ln_fr_mes := ln_fr_mes - 12 ; ln_fr_ano := ln_fr_ano + 1 ;
    end if ;
  end if ;

  --  Graba tiempo efectivo a liquidar por el fondo de retiro
  select p.grp_fondo_retiro into ls_grupo
    from rh_liqparam p where p.reckey = '1' ;
  select d.cod_sub_grupo into ls_sub_grupo
    from rh_liq_grupo_det d where d.cod_grupo = ls_grupo ;
  insert into rh_liq_tiempo_efectivo (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
    tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo, ld_fec_ingreso, lk_fec_tope,
    nvl(ln_fr_ano,0), nvl(ln_fr_mes,0), nvl(ln_fr_dia,0) ) ;
        
end if ;

--  Acumula remuneraciones de ganancias fijas
ln_ult_remun := 0 ; ln_imp_racion := 0 ;
for rc_gan in c_ganancias loop
  ln_verifica := 0 ; ls_concepto := null ;
  select count(*) into ln_verifica from grupo_calculo g
    where g.grupo_calculo = ls_grp_raccoc ;
  if ln_verifica > 0 then
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = ls_grp_raccoc ;
  end if ;
  if rc_gan.concep = ls_concepto then
    ln_imp_racion := ln_imp_racion + nvl(rc_gan.imp_gan_desc,0) ;
  else
    ln_ult_remun := ln_ult_remun + nvl(rc_gan.imp_gan_desc,0) ;
  end if ;
  if ln_sw = 1 then
    --  Inserta remuneracion valorizada por tiempo de servicio
    insert into rh_liq_fondo_retiro (
      cod_trabajador, cod_grupo, cod_sub_grupo, concep, importe,
      imp_x_liq_anos, imp_x_liq_meses, imp_x_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo, rc_gan.concep, nvl(rc_gan.imp_gan_desc,0),
      (nvl(rc_gan.imp_gan_desc,0) * nvl(ln_fr_ano,0)),
      (nvl(rc_gan.imp_gan_desc,0) / 12 * nvl(ln_fr_mes,0)),
      (nvl(rc_gan.imp_gan_desc,0) / 360 * nvl(ln_fr_dia,0)) ) ;
  end if ;
end loop ;

--  Calcula promedio de sobretiempos de los ultimos seis meses
ln_verifica := 0 ; ld_fec_promedio := null ;
select count(*) into ln_verifica from calculo c
  where to_char(c.fec_proceso,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') ;
if ln_verifica > 0 then
  ld_fec_promedio := ad_fec_liquidacion ;
else
  select max(c.fec_proceso)
    into ld_fec_promedio
    from calculo c ;
end if ;  

ln_prom_sobret := 0 ; ls_concepto := null ;
for rc_con in c_conceptos loop
  ld_fec_proceso := last_day(to_date('01'||'/'||to_char(ld_fec_promedio,'mm')||'/'||
                    to_char(ld_fec_promedio,'yyyy'),'dd/mm/yyyy')) ;
  ld_ran_ini := add_months(ld_fec_proceso, - 1) ;
  ln_num_mes := 0 ; ln_acum_sobret := 0 ;
  for x in reverse 1 .. 6 loop
    ld_ran_fin := ld_ran_ini ;
    ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
    ln_verifica := 0 ; ln_imp_variable := 0 ;
    select count(*)
      into ln_verifica from historico_calculo hc
      where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = as_cod_trabajador and
            hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
    if ln_verifica > 0 then
      select sum(nvl(hc.imp_soles,0))
        into ln_imp_variable from historico_calculo hc
        where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = as_cod_trabajador and
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
    end if ;
    if ln_imp_variable <> 0 then
      ln_num_mes := ln_num_mes + 1 ;
      ln_acum_sobret := ln_acum_sobret + ln_imp_variable ;
    end if ;
    ld_ran_ini := ld_ran_ini - 1 ;
  end loop ;
  if ln_num_mes > 2 then
    ln_prom_sobret := ln_prom_sobret + (ln_acum_sobret / 6 ) ;
  end if ;
end loop ;

select g.concepto_gen into ls_concepto from grupo_calculo g
  where g.grupo_calculo = ls_nivel ;
if ln_sw = 1 and nvl(ln_prom_sobret,0) > 0 then
  --  Inserta remuneracion variable valorizada por tiempo de servicio
  insert into rh_liq_fondo_retiro (
    cod_trabajador, cod_grupo, cod_sub_grupo, concep, importe,
    imp_x_liq_anos, imp_x_liq_meses, imp_x_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo, ls_concepto, nvl(ln_prom_sobret,0),
    (nvl(ln_prom_sobret,0) * nvl(ln_fr_ano,0)),
    (nvl(ln_prom_sobret,0) / 12 * nvl(ln_fr_mes,0)),
    (nvl(ln_prom_sobret,0) / 360 * nvl(ln_fr_dia,0)) ) ;
end if ;

ln_ult_remun := ln_ult_remun + ln_prom_sobret ;

--  Calcula bonificacion del 30% o 25%
ln_imp_bonif := 0 ; ls_concepto := null ; ln_factor := 0 ;
if nvl(ls_bonificacion,'0') = '1' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_30 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_bonif := ln_ult_remun * ln_factor ;
elsif nvl(ls_bonificacion,'0') = '2' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_25 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_bonif := ln_ult_remun * ln_factor ;
end if ;
if ln_sw = 1 and nvl(ln_imp_bonif,0) > 0 then
  --  Inserta bonificacion del 30% o 25% valorizada por tiempo de servicio
  insert into rh_liq_fondo_retiro (
    cod_trabajador, cod_grupo, cod_sub_grupo, concep, importe,
    imp_x_liq_anos, imp_x_liq_meses, imp_x_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo, ls_concepto, nvl(ln_imp_bonif,0),
    (nvl(ln_imp_bonif,0) * nvl(ln_fr_ano,0)),
    (nvl(ln_imp_bonif,0) / 12 * nvl(ln_fr_mes,0)),
    (nvl(ln_imp_bonif,0) / 360 * nvl(ln_fr_dia,0)) ) ;
end if ;
ln_ult_remun := ln_ult_remun + ln_imp_bonif + ln_imp_racion ;

--  Halla promedio de la ultima gratificacion
ls_concepto := null ;
if to_number(to_char(ad_fec_liquidacion,'mm')) <= 07 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grat_dic ;
  ls_year := to_char(to_number(to_char(ad_fec_liquidacion,'yyyy')) - 1) ;
  ld_fec_gratif := to_date('31'||'/'||'12'||'/'||ls_year,'dd/mm/yyyy') ;
elsif to_number(to_char(ad_fec_liquidacion,'mm')) > 07 or
      to_number(to_char(ad_fec_liquidacion,'mm')) < 12 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grat_jul ;
  ls_year := to_char (ad_fec_liquidacion,'yyyy') ;
  ld_fec_gratif := to_date('31'||'/'||'07'||'/'||ls_year,'dd/mm/yyyy') ;
elsif to_number(to_char(ad_fec_liquidacion,'mm')) = 12 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grat_jul ;
  ls_year := to_char(ad_fec_liquidacion,'yyyy') ;
  ld_fec_gratif := to_date('31'||'/'||'07'||'/'||ls_year,'dd/mm/yyyy') ;
end if ;
ln_verifica := 0 ; ln_imp_gratif := 0 ;
select count(*) into ln_verifica from historico_calculo hc
  where hc.concep = ls_concepto and hc.cod_trabajador = as_cod_trabajador and
        hc.fec_calc_plan = ld_fec_gratif ;
if ln_verifica > 0 then
  select sum(nvl(hc.imp_soles,0)) into ln_imp_gratif from historico_calculo hc
    where hc.concep = ls_concepto and hc.cod_trabajador = as_cod_trabajador and
          hc.fec_calc_plan = ld_fec_gratif ;
  ln_imp_gratif := ln_imp_gratif / 6 ;
else
  ln_verifica := 0 ;
  select count(*) into ln_verifica from calculo c
    where c.concep = ls_concepto and c.cod_trabajador = as_cod_trabajador ;
  if ln_verifica > 0 then
    select nvl(c.imp_soles,0) into ln_imp_gratif from calculo c
      where c.concep = ls_concepto and c.cod_trabajador = as_cod_trabajador ;
    ln_imp_gratif := ln_imp_gratif / 6 ;
  end if ;
end if ;
if ln_sw = 1 and nvl(ln_imp_gratif,0) > 0 then
  --  Inserta un sexto de la gratificacion valorizada por tiempo de servicio
  insert into rh_liq_fondo_retiro (
    cod_trabajador, cod_grupo, cod_sub_grupo, concep, importe,
    imp_x_liq_anos, imp_x_liq_meses, imp_x_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo, ls_concepto, nvl(ln_imp_gratif,0),
    (nvl(ln_imp_gratif,0) * nvl(ln_fr_ano,0)),
    (nvl(ln_imp_gratif,0) / 12 * nvl(ln_fr_mes,0)),
    (nvl(ln_imp_gratif,0) / 360 * nvl(ln_fr_dia,0)) ) ;
end if ;
ln_ult_remun := ln_ult_remun + ln_imp_gratif ;

--  Actualiza ultima remuneracion del trabajador
update rh_liq_credito_laboral l
  set l.ult_remuneracion = ln_ult_remun
  where l.cod_trabajador = as_cod_trabajador ;

end usp_rh_liq_fondo_retiro ;
/
