create or replace procedure usp_rh_utl_calculo (
       ani_periodo          in utl_distribucion.periodo%TYPE, 
       ani_item             in utl_distribucion.item%TYPE,
       asi_tipo_trabaj      in tipo_trabajador.tipo_trabajador%TYPE
) is

ln_verifica            integer ;

ld_fec_ini             date ;
ld_fec_fin             date ;

ls_grp_remuner         utlparam.grp_remun_anual%TYPE ;
ls_grp_inasist         utlparam.grp_inasist_anual%TYPE;
ls_grp_reinteg         utlparam.grp_dias_reintegro%TYPE;
ln_dias_ano            number(3) ;
ls_codigo              maestro.cod_trabajador%TYPE;

ln_porc_dias_lab       number(5,2) ;
ln_porc_remunera       number(5,2) ;
ln_imp_distribuc       number(13,2) ;
ln_imp_dist_dias       number(13,2) ;
ln_imp_dist_remu       number(13,2) ;

ln_remun_trabaj        number(13,2) ;
ln_dias_trabaj         number(13,2) ;
ln_dias_reintegro      number(5,2) ;
ln_remun_extra         number(13,2) ;
ln_dias_extra          number(5,2) ;
ln_imp_remun_anual     number(13,2) ;
ln_imp_dias_efecti     number(13,2) ;
ln_factor              number(13,6) ;
ln_imp_adelantos       number(13,2) ;
ln_imp_reten_jud       number(13,2) ;

-- Totales por trabajador
ld_fec_ini_trabaj                  date ;
ld_fec_fin_trabaj                  date ;
ln_doming_tot_x_trabaj             number(4) ;
ln_feriado_x_trabaj                number(4) ;
ln_dias_inasist_x_trabaj           number(4) ;

--  Lectura del maestro de trabajadores para calculo de utilidades
cursor c_maestro is
  select distinct m.cod_trabajador, m.flag_cal_plnlla, m.flag_estado, m.fec_ingreso, m.fec_cese,
         m.porc_jud_util, m.tipo_trabajador, m.cod_origen
  from maestro m,
       historico_calculo hc
  where m.cod_trabajador = hc.cod_trabajador
    and m.tipo_trabajador like asi_tipo_trabaj 
    and trunc(hc.fec_calc_plan) between trunc(ld_fec_ini) and trunc(ld_fec_fin)
  order by m.cod_trabajador ;

--  Lectura de personal seleccionado para calculo de utilidades
cursor c_movimiento is
  select u.cod_trabajador, u.porc_jud, u.imp_remun, u.imp_dias_efec
  from tt_personal_utilidades u
  order by u.cod_trabajador ;

--  Lectura del personal extra que no esta en planilla
cursor c_personal_extra is
  select e.cod_relacion, e.remun_anual, e.dias_efect_ano
  from utl_personal_ext e
  where e.periodo = ani_periodo
  order by e.cod_relacion ;

begin

--  *******************************************************************
--  ***   CALCULO DE DISTRIBUCION POR PARTICIPACION DE UTILIDADES   ***
--  *******************************************************************

ln_verifica := 0 ;
select count(*) into ln_verifica 
  from utl_distribucion d
  where d.periodo = ani_periodo 
    and d.item    = ani_item;
    
if ln_verifica = 0 then
  raise_application_error (-20000, 'Registre información para proceso de Utilidades') ;
end if ;

delete from tt_personal_utilidades ;
delete from utl_ext_hist u
  where u.periodo = ani_periodo; 

select p.grp_remun_anual, p.grp_inasist_anual, p.grp_dias_reintegro, p.dias_tope_ano
  into ls_grp_remuner, ls_grp_inasist, ls_grp_reinteg, ln_dias_ano
  from utlparam p 
 where p.reckey = '1' ;

select (nvl(d.renta_neta,0) * nvl(d.porc_distribucion,0) / 100),
       d.porc_dias_laborados, d.porc_remuneracion, d.fecha_ini, d.fecha_fin
  into ln_imp_distribuc, ln_porc_dias_lab, ln_porc_remunera, ld_fec_ini, ld_fec_fin
  from utl_distribucion d
  where d.periodo = ani_periodo 
    and d.item    = ani_item;

ln_imp_dist_dias := NVL(ln_imp_distribuc * ln_porc_dias_lab / 100, 0);
ln_imp_dist_remu := NVL(ln_imp_distribuc * ln_porc_remunera / 100, 0) ;

if (ln_imp_dist_dias + ln_imp_dist_remu) <> ln_imp_distribuc then
  ln_imp_dist_remu := ln_imp_dist_remu + (ln_imp_distribuc - (ln_imp_dist_dias + ln_imp_dist_remu)) ;
end if ;

--  Determina remuneraciones y dias efectivos del ejercicio por trabajador
for rc_mae in c_maestro loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica 
    from utl_excl_trabajador e
    where e.periodo = ani_periodo 
      and e.item    = ani_item
      and e.cod_trabajador = rc_mae.cod_trabajador ;
  
  
  if ln_verifica = 0 then
     -- Actualizar los dias totales por trabajador
     IF rc_mae.fec_ingreso <= ld_fec_ini THEN
        ld_fec_ini_trabaj := ld_fec_ini ;
     ELSE 
        ld_fec_ini_trabaj := rc_mae.fec_ingreso ;
     END IF ;
    
     IF NVL(rc_mae.fec_cese, ld_fec_fin)>=ld_fec_fin THEN
        ld_fec_fin_trabaj := ld_fec_fin ;
     ELSE
        ld_fec_fin_trabaj := rc_mae.fec_cese ;
     END IF ;
     
     --Calculando los dias totales trabajados (360/ln_dias_ano, factor de conversión)
    ln_dias_trabaj := USF_RH_DIAS_TOT_UTIL(rc_mae.cod_trabajador, rc_mae.tipo_trabajador, 
                                                 ld_fec_ini_trabaj, ld_fec_fin_trabaj ) ;

    -- Actualizar los domingos (incluye sabados para empleados Lima)
    ln_doming_tot_x_trabaj := USF_RH_CALC_DOMINGOS(ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;
    
    -- Actualizar los feriados
    ln_feriado_x_trabaj := USF_RH_DIAS_FERIADO(rc_mae.cod_origen, ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;
    
    -- Actualizar las inasistencias (descontar domingos y feriados) 
    ln_dias_inasist_x_trabaj := USF_RH_DIAS_INASIST_UTIL(rc_mae.cod_trabajador, ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;

    select nvl(sum(nvl(hi.dias_inasist,0)),0) 
      into ln_dias_reintegro 
      from historico_inasistencia hi
     where hi.cod_trabajador = rc_mae.cod_trabajador 
       and to_number(to_char(hi.fec_movim,'yyyy')) = ani_periodo 
       and hi.concep in ( select d.concepto_calc 
                            from grupo_calculo_det d
                           where d.grupo_calculo = ls_grp_reinteg ) ;
      
    ln_dias_trabaj := nvl(ln_dias_trabaj,0) + nvl(ln_dias_reintegro,0) - nvl(ln_dias_inasist_x_trabaj,0) ;

    select NVL(sum(nvl(hc.imp_soles,0)),0) 
      into ln_remun_trabaj 
      from historico_calculo hc,
           grupo_calculo_det gcd
      where hc.cod_trabajador = rc_mae.cod_trabajador 
        and hc.concep         = gcd.concepto_calc
        and trunc(hc.fec_calc_plan) between trunc(ld_fec_ini) and trunc(ld_fec_fin)
        and gcd.grupo_calculo = ls_grp_remuner;

    select nvl(sum(p.remun_anual),0), nvl(sum(p.dias_efect_ano),0)
      into ln_remun_extra, ln_dias_extra
      from utl_personal_ext p
      where p.periodo = ani_periodo 
        and p.item    = ani_item
        and p.cod_relacion = rc_mae.cod_trabajador ;
        
    ln_remun_trabaj := ln_remun_trabaj + ln_remun_extra ;
    ln_dias_trabaj  := ln_dias_trabaj + ln_dias_extra ;

    insert into tt_personal_utilidades (
        cod_trabajador, porc_jud, imp_remun, imp_dias_efec )
    values (
        rc_mae.cod_trabajador, rc_mae.porc_jud_util, ln_remun_trabaj, ln_dias_trabaj ) ;

  end if ;

end loop ;

--  Adiciona personal extra que no esta registrado en la planilla
for rc_ext in c_personal_extra loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica from tt_personal_utilidades u
    where u.cod_trabajador = rc_ext.cod_relacion ;
  if ln_verifica = 0 then
    insert into tt_personal_utilidades (
      cod_trabajador, porc_jud, imp_remun, imp_dias_efec )
    values (
      rc_ext.cod_relacion, 0, nvl(rc_ext.remun_anual,0), nvl(rc_ext.dias_efect_ano,0) ) ;
  end if ;

end loop ;

--  Actualiza remuneraciones y dias efectivos del ejercicio
ln_remun_trabaj := 0 ; ln_dias_trabaj := 0 ;
select sum(nvl(u.imp_remun,0)), sum(nvl(u.imp_dias_efec,0))
  into ln_remun_trabaj, ln_dias_trabaj
  from tt_personal_utilidades u ;
  
update utl_distribucion d
  set d.tot_remun_ejer = nvl(ln_remun_trabaj,0) ,
      d.tot_dias_ejer  = nvl(ln_dias_trabaj,0)
  where d.periodo = ani_periodo 
    and d.item    = ani_item;
    
ln_factor := nvl(ln_imp_dist_dias,0) / nvl(ln_dias_trabaj,0) ;

--  Realiza calculo de distribucion de utilidades por trabajador
for rc_mov in c_movimiento loop

  ls_codigo := rc_mov.cod_trabajador ;

  ln_imp_remun_anual := nvl(ln_imp_dist_remu,0) * nvl(rc_mov.imp_remun,0) /
                        nvl(ln_remun_trabaj,0) ;
  ln_imp_dias_efecti := nvl(rc_mov.imp_dias_efec,0) * nvl(ln_factor,0) ;

  ln_verifica := 0 ; ln_imp_adelantos := 0 ;
  select count(*) into ln_verifica from utl_adlt_ext a
    where a.periodo = ani_periodo and a.cod_relacion = ls_codigo ;
  if ln_verifica > 0 then
    select sum(nvl(a.imp_adelanto,0)) into ln_imp_adelantos from utl_adlt_ext a
      where a.periodo = ani_periodo and a.cod_relacion = ls_codigo ;
  end if ;

  ln_imp_reten_jud := 0 ;
  if rc_mov.porc_jud > 0 then
    ln_imp_reten_jud := (nvl(ln_imp_remun_anual,0) + nvl(ln_imp_dias_efecti,0) *
                        nvl(rc_mov.porc_jud,0)) / 100 ;
  end if ;

  insert into utl_ext_hist (
    periodo, cod_relacion, remun_anual, imp_utl_remun_anual, dias_efectivos,
    imp_ult_dias_efect, adelantos, reten_jud, item )
  values (
    ani_periodo, ls_codigo, rc_mov.imp_remun, ln_imp_remun_anual, rc_mov.imp_dias_efec,
    ln_imp_dias_efecti, ln_imp_adelantos, ln_imp_reten_jud, ani_item ) ;

end loop ;

--  Ajuste de pagos de utilidades al ultimo trabajador
ln_remun_trabaj := 0 ; ln_dias_trabaj := 0 ;
select sum(nvl(u.imp_utl_remun_anual,0)), sum(nvl(u.imp_ult_dias_efect,0))
  into ln_remun_trabaj, ln_dias_trabaj
  from utl_ext_hist u 
 where u.periodo = ani_periodo ;

if nvl(ln_remun_trabaj,0) <> nvl(ln_imp_dist_remu,0) then
  update utl_ext_hist u
    set u.imp_utl_remun_anual = u.imp_utl_remun_anual + (ln_imp_dist_remu - ln_remun_trabaj)
    where u.periodo = ani_periodo 
      and u.item    = ani_item
      and u.cod_relacion = ls_codigo ;
end if ;

if nvl(ln_dias_trabaj,0) <> nvl(ln_imp_dist_dias,0) then
  update utl_ext_hist u
    set u.imp_ult_dias_efect = u.imp_ult_dias_efect + (ln_imp_dist_dias - ln_dias_trabaj)
    where u.periodo = ani_periodo 
      and u.item    = ani_item
      and u.cod_relacion = ls_codigo ;
end if ;

commit;

end usp_rh_utl_calculo ;
/
