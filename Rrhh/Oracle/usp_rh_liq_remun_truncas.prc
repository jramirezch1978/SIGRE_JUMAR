create or replace procedure usp_rh_liq_remun_truncas (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ls_vacaci              char(3) ;
ls_gratif              char(3) ;
ls_provac              char(3) ;
ls_bonificacion        char(1) ;
ls_grp_25              char(3) ;
ls_grp_30              char(3) ;

ln_importe             number(13,2) ;
ln_imp_vacaci          number(13,2) ;
ln_imp_gratif          number(13,2) ;

ln_verifica            integer ;
ld_fec_promedio        date ;
ln_prom_sobret         number(13,2) ;
ld_fec_proceso         date ;
ld_ran_ini             date ;
ld_ran_fin             date ;
ln_acum_sobret         number(13,2) ;
ln_num_mes             integer ;
ln_imp_variable        number(13,2) ;

ls_concepto            char(4) ;
ln_factor              number(9,6) ;
ln_control             integer ;
ls_grupo               char(6) ;
ls_sub_grp_vactru      char(6) ;
ls_sub_grp_gratru      char(6) ;
ls_vacaciones          char(4) ;
ls_grp_licencia_gra    char(3) ;
ln_ano                 number(4) ;
ln_dias                number(3) ;
ln_dias_vac            number(5,2) ;
ln_dias_gra            number(5,2) ;
ld_fec_ingreso         date ;
ld_fec_desde           date ;
ld_fec_tope            date ;
ld_fec_ini             date ;
ld_fec_fin             date ;

--  Lectura de conceptos para promedios de sobretiempos
cursor c_conceptos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = ls_provac ;

begin

--  **********************************************************
--  ***   LIQUIDACION DE PAGO POR REMUNERACIONES TRUNCAS   ***
--  **********************************************************

select m.fec_ingreso, m.bonif_fija_30_25 into ld_fec_ingreso, ls_bonificacion
  from maestro m where m.cod_trabajador = as_cod_trabajador ;

select p.grp_remuneracion, p.sgrp_grat_trunc, p.sgrp_vac_truncas, p.cncp_vacaciones
  into ls_grupo, ls_sub_grp_gratru, ls_sub_grp_vactru, ls_vacaciones
  from rh_liqparam p where p.reckey = '1' ;

select g.grp_dias_inasistencia_cts, g.prom_remun_vacac, g.gan_fij_calc_vacac,
       g.grati_medio_ano, g.bonificacion25, g.bonificacion30
  into ls_grp_licencia_gra, ls_provac, ls_vacaci,
       ls_gratif, ls_grp_25, ls_grp_30
  from rrhhparam_cconcep g where g.reckey = '1' ;
  
--  Determina ganancias fijas para vacaciones
ln_imp_vacaci := 0 ;
select sum(nvl(g.imp_gan_desc,0)) into ln_imp_vacaci from gan_desct_fijo g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.flag_estado,'0') = '1' and
        g.concep in ( select d.concepto_calc from grupo_calculo_det d
                      where d.grupo_calculo = ls_vacaci ) ;

--  Determina ganancias fijas para gratificaciones
ln_imp_gratif := 0 ;
select sum(nvl(g.imp_gan_desc,0)) into ln_imp_gratif from gan_desct_fijo g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.flag_estado,'0') = '1' and
        g.concep in ( select d.concepto_calc from grupo_calculo_det d
                      where d.grupo_calculo = ls_gratif ) ;

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

ln_prom_sobret := 0 ;
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
ln_imp_vacaci := ln_imp_vacaci + ln_prom_sobret ;
ln_imp_gratif := ln_imp_gratif + ln_prom_sobret ;

--  Determina bonificacion del 30% o 25% si lo percibiera
ls_concepto := null ; ln_factor := 0 ;
if nvl(ls_bonificacion,'0') = '1' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_30 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_vacaci := ln_imp_vacaci + (ln_imp_vacaci * ln_factor) ;
  ln_imp_gratif := ln_imp_gratif + (ln_imp_gratif * ln_factor) ;
elsif nvl(ls_bonificacion,'0') = '2' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_25 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_vacaci := ln_imp_vacaci + (ln_imp_vacaci * ln_factor) ;
  ln_imp_gratif := ln_imp_gratif + (ln_imp_gratif * ln_factor) ;
end if ;

--
--  ***   CALCULO DE VACACIONES TRUNCAS
--

ln_ano       := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
ld_fec_desde := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char(ln_ano),'dd/mm/yyyy') ;
if ld_fec_desde > ad_fec_liquidacion then
  ld_fec_desde := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char(ln_ano-1),'dd/mm/yyyy') ;
end if ;

ln_dias := usf_rh_liq_dias_truncos(ld_fec_desde, ad_fec_liquidacion) ;
if nvl(ln_dias,0) > 360 then
  ln_dias := 360 ;
end if ;

ln_verifica := 0 ; ln_dias_vac := 0 ;
select count(*) into ln_verifica from incidencia_trabajador i
  where i.cod_trabajador = as_cod_trabajador and
        to_char(i.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
        i.concep = ls_vacaciones and nvl(i.flag_conformidad,'0') = '1' ;
if ln_verifica > 0 then  
  select sum(nvl(i.nro_dias,0)) into ln_dias_vac from incidencia_trabajador i
    where i.cod_trabajador = as_cod_trabajador and
          to_char(i.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
          i.concep = ls_vacaciones and nvl(i.flag_conformidad,'0') = '1' ;
  ln_dias_vac := 360 * nvl(ln_dias_vac,0) / 30 ;
  ln_dias := nvl(ln_dias,0) - nvl(ln_dias_vac,0) ;
end if ;

ln_importe := nvl(ln_imp_vacaci,0) / 360 * nvl(ln_dias,0) ;
 
if nvl(ln_importe,0) > 0 then

  insert into rh_liq_tiempo_efectivo (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
    tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_vactru, ld_fec_desde, ad_fec_liquidacion,
    0, 0, 0 ) ;
    
  insert into rh_liq_remuneracion (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
    fec_hasta, tm_ef_liq_anos )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_vactru, ld_fec_desde,
    ad_fec_liquidacion, nvl(ln_importe,0) ) ;

end if ;

--
--  ***   CALCULO DE GRATIFICACIONES TRUNCAS
--

ln_control := 0 ;
select count(*) into ln_control from gratificacion g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.imp_adelanto,0) > 0 and
        to_char(g.fec_proceso,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') ;
  
if ln_control = 0 then

  ln_ano      := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
  ld_fec_tope := to_date('30/06'||to_char(ln_ano),'dd/mm/yyyy') ;
  if trunc(ad_fec_liquidacion) <= trunc(ld_fec_tope) then
    ld_fec_desde := to_date('01/01'||to_char(ln_ano),'dd/mm/yyyy') ;
  else
    ld_fec_desde := to_date('01/07'||to_char(ln_ano),'dd/mm/yyyy') ;
  end if ;

  if ld_fec_ingreso > ld_fec_desde then
    ld_fec_desde := ld_fec_ingreso ;
  end if ;

  ln_dias := usf_rh_liq_dias_truncos(ld_fec_desde, ad_fec_liquidacion) ;
  if nvl(ln_dias,0) > 180 then
    ln_dias := 180 ;
  end if ;

  ln_verifica := 0 ; ls_concepto := null ; ln_dias_gra := 0 ;
  select count(*) into ln_verifica from grupo_calculo c
    where c.grupo_calculo = ls_grp_licencia_gra ;
  if ln_verifica > 0 then  
    select c.concepto_gen into ls_concepto from grupo_calculo c
      where c.grupo_calculo = ls_grp_licencia_gra ;
    ln_verifica := 0 ;
    select count(*) into ln_verifica from incidencia_trabajador t
      where t.cod_trabajador = as_cod_trabajador and t.concep = ls_concepto and
            to_char(t.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
            nvl(t.flag_conformidad,'0') = '1' ;
    if ln_verifica > 0 then  
      select t.fecha_inicio, t.fecha_fin into ld_fec_ini, ld_fec_fin from incidencia_trabajador t
        where t.cod_trabajador = as_cod_trabajador and t.concep = ls_concepto and
              to_char(t.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
              nvl(t.flag_conformidad,'0') = '1' ;
      ln_dias_gra := usf_rh_liq_dias_truncos(ld_fec_ini, ld_fec_fin) ;
      if nvl(ln_dias_gra,0) > 180 then
        ln_dias_gra := 180 ;
      end if ;
      ln_dias := ln_dias - ln_dias_gra ;
    end if ;
  end if ;

  ln_importe := nvl(ln_imp_gratif,0) / 180 * nvl(ln_dias,0) ;

  if nvl(ln_importe,0) > 0 then

    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_gratru, ld_fec_desde, ad_fec_liquidacion,
      0, 0, 0 ) ;
    
    insert into rh_liq_remuneracion (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
      fec_hasta, tm_ef_liq_anos )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_gratru, ld_fec_desde,
      ad_fec_liquidacion, nvl(ln_importe,0) ) ;

  end if ;

end if ;

end usp_rh_liq_remun_truncas ;



/*
create or replace procedure usp_rh_liq_remun_truncas (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_control             integer ;
ls_grupo               char(6) ;
ls_sub_grp_vactru      char(6) ;
ls_sub_grp_gratru      char(6) ;
ls_vacaciones          char(4) ;

ln_importe             number(13,2) ;
ln_ult_remun           number(13,2) ;

ls_concepto            char(4) ;
ls_grat_jul            char(3) ;
ls_grat_dic            char(3) ;
ls_grp_licencia_gra    char(3) ;
ld_fec_gratif          date ;
ls_year                char(4) ;
ln_verifica            integer ;
ln_imp_gratif          number(13,2) ;

ln_ano                 number(4) ;
ln_dias                number(3) ;
ln_dias_vac            number(5,2) ;
ln_dias_gra            number(5,2) ;
ld_fec_ingreso         date ;
ld_fec_desde           date ;
ld_fec_tope            date ;
ld_fec_ini             date ;
ld_fec_fin             date ;

begin

--  **********************************************************
--  ***   LIQUIDACION DE PAGO POR REMUNERACIONES TRUNCAS   ***
--  **********************************************************

select p.grp_remuneracion, p.sgrp_grat_trunc, p.sgrp_vac_truncas, p.cncp_vacaciones
  into ls_grupo, ls_sub_grp_gratru, ls_sub_grp_vactru, ls_vacaciones
  from rh_liqparam p where p.reckey = '1' ;
    
select p.grp_dias_inasistencia_cts, p.grati_medio_ano, p.grati_fin_ano
  into ls_grp_licencia_gra, ls_grat_jul, ls_grat_dic
  from rrhhparam_cconcep p where p.reckey = '1' ;

select m.fec_ingreso into ld_fec_ingreso from maestro m
  where m.cod_trabajador = as_cod_trabajador ;
  
--  Determina ultima remuneracion para calculo de remuneraciones truncas
select nvl(l.ult_remuneracion,0) into ln_ult_remun
  from rh_liq_credito_laboral l
  where l.cod_trabajador = as_cod_trabajador ;
  
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

ln_ult_remun := nvl(ln_ult_remun,0) - nvl(ln_imp_gratif,0) ;

--
--  ***   CALCULO DE VACACIONES TRUNCAS
--

ln_ano       := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
ld_fec_desde := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char(ln_ano),'dd/mm/yyyy') ;
if ld_fec_desde > ad_fec_liquidacion then
  ld_fec_desde := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char(ln_ano-1),'dd/mm/yyyy') ;
end if ;

ln_dias := usf_rh_liq_dias_truncos(ld_fec_desde, ad_fec_liquidacion) ;
if nvl(ln_dias,0) > 360 then
  ln_dias := 360 ;
end if ;

ln_verifica := 0 ; ln_dias_vac := 0 ;
select count(*) into ln_verifica from incidencia_trabajador i
  where i.cod_trabajador = as_cod_trabajador and
        to_char(i.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
        i.concep = ls_vacaciones and nvl(i.flag_conformidad,'0') = '1' ;
if ln_verifica > 0 then  
  select sum(nvl(i.nro_dias,0)) into ln_dias_vac from incidencia_trabajador i
    where i.cod_trabajador = as_cod_trabajador and
          to_char(i.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
          i.concep = ls_vacaciones and nvl(i.flag_conformidad,'0') = '1' ;
  ln_dias_vac := 360 * nvl(ln_dias_vac,0) / 30 ;
  ln_dias := nvl(ln_dias,0) - nvl(ln_dias_vac,0) ;
end if ;

ln_importe := nvl(ln_ult_remun,0) / 360 * nvl(ln_dias,0) ;
 
if nvl(ln_importe,0) > 0 then

  insert into rh_liq_tiempo_efectivo (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
    tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_vactru, ld_fec_desde, ad_fec_liquidacion,
    0, 0, 0 ) ;
    
  insert into rh_liq_remuneracion (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
    fec_hasta, tm_ef_liq_anos )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_vactru, ld_fec_desde,
    ad_fec_liquidacion, nvl(ln_importe,0) ) ;

end if ;

--
--  ***   CALCULO DE GRATIFICACIONES TRUNCAS
--

ln_control := 0 ;
select count(*) into ln_control from gratificacion g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.imp_adelanto,0) > 0 and
        to_char(g.fec_proceso,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') ;
  
if ln_control = 0 then

  ln_ano      := to_number(to_char(ad_fec_liquidacion,'yyyy')) ;
  ld_fec_tope := to_date('30/06'||to_char(ln_ano),'dd/mm/yyyy') ;
  if trunc(ad_fec_liquidacion) <= trunc(ld_fec_tope) then
    ld_fec_desde := to_date('01/01'||to_char(ln_ano),'dd/mm/yyyy') ;
  else
    ld_fec_desde := to_date('01/07'||to_char(ln_ano),'dd/mm/yyyy') ;
  end if ;

  if ld_fec_ingreso > ld_fec_desde then
    ld_fec_desde := ld_fec_ingreso ;
  end if ;

  ln_dias := usf_rh_liq_dias_truncos(ld_fec_desde, ad_fec_liquidacion) ;
  if nvl(ln_dias,0) > 180 then
    ln_dias := 180 ;
  end if ;

  ln_verifica := 0 ; ls_concepto := null ; ln_dias_gra := 0 ;
  select count(*) into ln_verifica from grupo_calculo c
    where c.grupo_calculo = ls_grp_licencia_gra ;
  if ln_verifica > 0 then  
    select c.concepto_gen into ls_concepto from grupo_calculo c
      where c.grupo_calculo = ls_grp_licencia_gra ;
    ln_verifica := 0 ;
    select count(*) into ln_verifica from incidencia_trabajador t
      where t.cod_trabajador = as_cod_trabajador and t.concep = ls_concepto and
            to_char(t.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
            nvl(t.flag_conformidad,'0') = '1' ;
    if ln_verifica > 0 then  
      select t.fecha_inicio, t.fecha_fin into ld_fec_ini, ld_fec_fin from incidencia_trabajador t
        where t.cod_trabajador = as_cod_trabajador and t.concep = ls_concepto and
              to_char(t.fecha_movim,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') and
              nvl(t.flag_conformidad,'0') = '1' ;
      ln_dias_gra := usf_rh_liq_dias_truncos(ld_fec_ini, ld_fec_fin) ;
      if nvl(ln_dias_gra,0) > 180 then
        ln_dias_gra := 180 ;
      end if ;
      ln_dias := ln_dias - ln_dias_gra ;
    end if ;
  end if ;

  ln_importe := nvl(ln_ult_remun,0) / 180 * nvl(ln_dias,0) ;

  if nvl(ln_importe,0) > 0 then

    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_gratru, ld_fec_desde, ad_fec_liquidacion,
      0, 0, 0 ) ;
    
    insert into rh_liq_remuneracion (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
      fec_hasta, tm_ef_liq_anos )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_gratru, ld_fec_desde,
      ad_fec_liquidacion, nvl(ln_importe,0) ) ;

  end if ;

end if ;

end usp_rh_liq_remun_truncas ;
*/
/
