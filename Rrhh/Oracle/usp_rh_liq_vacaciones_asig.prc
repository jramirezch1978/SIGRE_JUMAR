create or replace procedure usp_rh_liq_vacaciones_asig (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ls_vacaci              char(3) ;
ls_bonifi              char(3) ;
ls_provac              char(3) ;
ls_bonificacion        char(1) ;
ls_grp_25              char(3) ;
ls_grp_30              char(3) ;

ln_verifica           integer ;
ld_fec_promedio       date ;
ln_prom_sobret        number(13,2) ;
ld_fec_proceso        date ;
ld_ran_ini            date ;
ld_ran_fin            date ;
ln_acum_sobret        number(13,2) ;
ln_num_mes            integer ;
ln_imp_variable       number(13,2) ;

ls_grupo               char(6) ;
ls_sub_grp_vacaci      char(6) ;
ls_sub_grp_bonifi      char(6) ;
ls_sub_grp_indemn      char(6) ;

ld_fec_ingreso         date ;
ld_fec_desde           date ;
ld_fec_hasta           date ;
ld_fec_tope            date ;
ln_ano_tope            number(4) ;

ln_importe             number(13,2) ;
ln_imp_vacaci          number(13,2) ;
ln_imp_bonifi          number(13,2) ;

ls_concepto            char(4) ;
ln_imp_bonif           number(13,2) ;
ln_factor              number(9,6) ;

--  Lectura de saldos por dias de vacaciones
cursor c_vacaciones is
  select v.periodo, v.sldo_dias_vacacio
  from vacac_bonif_deveng v
  where v.cod_trabajador = as_cod_trabajador and nvl(v.flag_estado,'0') = '1' and
        nvl(v.sldo_dias_vacacio,0) > 0
  order by v.cod_trabajador, v.periodo ;

--  Lectura de saldos por dias de bonificaciones vacacionales
cursor c_bonificaciones is
  select v.periodo, v.sldo_dias_bonif
  from vacac_bonif_deveng v
  where v.cod_trabajador = as_cod_trabajador and nvl(v.flag_estado,'0') = '1' and
        nvl(v.sldo_dias_bonif,0) > 0
  order by v.cod_trabajador, v.periodo ;

--  Lectura de conceptos para promedios de sobretiempos
cursor c_conceptos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = ls_provac ;

begin

--  ****************************************************************
--  ***   LIQUIDACION DE PAGOS POR VACACIONES Y BONIFICACIONES   ***
--  ****************************************************************

select m.bonif_fija_30_25 into ls_bonificacion from maestro m
  where m.cod_trabajador = as_cod_trabajador ;

select p.grp_remuneracion, p.sgrp_asig_vac, p.sgrp_vacaciones, p.sgrp_indem_vac
  into ls_grupo, ls_sub_grp_bonifi, ls_sub_grp_vacaci, ls_sub_grp_indemn
  from rh_liqparam p where p.reckey = '1' ;
    
select g.prom_remun_vacac, g.gan_fij_calc_vacac, g.gan_bonif_vacacion,
       g.bonificacion25, g.bonificacion30
  into ls_provac, ls_vacaci, ls_bonifi,
       ls_grp_25, ls_grp_30
  from rrhhparam_cconcep g where g.reckey = '1' ;
  
select m.fec_ingreso into ld_fec_ingreso from maestro m
  where m.cod_trabajador = as_cod_trabajador ;
  
--  Determina ganancias fijas para vacaciones
ln_imp_vacaci := 0 ;
select sum(nvl(g.imp_gan_desc,0)) into ln_imp_vacaci from gan_desct_fijo g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.flag_estado,'0') = '1' and
        g.concep in ( select d.concepto_calc from grupo_calculo_det d
                      where d.grupo_calculo = ls_vacaci ) ;

--  Determina ganancias fijas para bonificaciones vacacionales
ln_imp_bonifi := 0 ;
select sum(nvl(g.imp_gan_desc,0)) into ln_imp_bonifi from gan_desct_fijo g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.flag_estado,'0') = '1' and
        g.concep in ( select d.concepto_calc from grupo_calculo_det d
                      where d.grupo_calculo = ls_bonifi ) ;

--  Determina fecha tope para pago por indemnizacion vacacional
ln_ano_tope := to_number(to_char(ad_fec_liquidacion,'yyyy')) - 2 ;
ld_fec_tope := to_date(to_char(ad_fec_liquidacion,'dd/mm')||to_char(ln_ano_tope),'dd/mm/yyyy') + 1 ;

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

--  Determina bonificacion del 30% o 25% si lo percibiera
ln_imp_bonif := 0 ; ls_concepto := null ; ln_factor := 0 ;
if nvl(ls_bonificacion,'0') = '1' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_30 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_bonif := ln_imp_vacaci * ln_factor ;
elsif nvl(ls_bonificacion,'0') = '2' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_25 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_bonif := ln_imp_vacaci * ln_factor ;
end if ;

--  Genera pagos por vacaciones devengadas
ln_importe := 0 ;
for rc_vac in c_vacaciones loop

  ln_importe := (nvl(ln_imp_vacaci,0) + nvl(ln_imp_bonif,0)) / 30 * nvl(rc_vac.sldo_dias_vacacio,0) ;
  
  ld_fec_desde := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char((rc_vac.periodo-1)),'dd/mm/yyyy') ;
  ld_fec_hasta := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char(rc_vac.periodo),'dd/mm/yyyy') ;

  insert into rh_liq_tiempo_efectivo (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
    tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_vacaci, ld_fec_desde, ld_fec_hasta,
    0, 0, 0 ) ;
    
  insert into rh_liq_remuneracion (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
    fec_hasta, tm_ef_liq_anos )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_vacaci, ld_fec_desde,
    ld_fec_hasta, nvl(ln_importe,0) ) ;

  --  Determina pago por indemnizacion vacacional
  if ld_fec_hasta < ld_fec_tope then
  
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_indemn, ld_fec_desde, ld_fec_hasta,
      0, 0, 0 ) ;
    
    insert into rh_liq_remuneracion (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
      fec_hasta, tm_ef_liq_anos )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grp_indemn, ld_fec_desde,
      ld_fec_hasta, nvl(ln_importe,0) ) ;

  end if ;

end loop ;
  
--  Genera pagos por bonificaciones vacacionales
ln_importe := 0 ;
for rc_bon in c_bonificaciones loop

  ln_importe := (nvl(ln_imp_bonifi,0) + nvl(ln_imp_bonif,0)) / 30 * nvl(rc_bon.sldo_dias_bonif,0) ;
  
  ld_fec_desde := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char((rc_bon.periodo-1)),'dd/mm/yyyy') ;
  ld_fec_hasta := to_date(to_char(ld_fec_ingreso,'dd/mm')||to_char(rc_bon.periodo),'dd/mm/yyyy') ;

  insert into rh_liq_tiempo_efectivo (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
    tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_bonifi, ld_fec_desde, ld_fec_hasta,
    0, 0, 0 ) ;
    
  insert into rh_liq_remuneracion (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde,
    fec_hasta, tm_ef_liq_anos )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grp_bonifi, ld_fec_desde,
    ld_fec_hasta, nvl(ln_importe,0) ) ;

end loop ;

end usp_rh_liq_vacaciones_asig ;
/
