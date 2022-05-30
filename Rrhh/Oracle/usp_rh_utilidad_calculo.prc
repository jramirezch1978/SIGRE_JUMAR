create or replace procedure usp_rh_utilidad_calculo(
  an_periodo      in utl_distribucion.periodo%type, 
  an_item         in utl_distribucion.item%type, 
  as_flag_externo in utl_distribucion.flag_estado%type ) is

ln_verifica                        integer ;
-- Variables de parametros
ld_porc_distribucion               utl_distribucion.porc_distribucion%type ;
ld_renta_neta                      utl_distribucion.renta_neta%type ;
ld_porc_dias_laborados             utl_distribucion.porc_dias_laborados%type ;
ld_porc_renumeracion               utl_distribucion.porc_remuneracion%type ;
ls_grupo_pago                      grupo_calculo.grupo_calculo%type ;
ln_dias_tope_ano                   utlparam.dias_tope_ano%type ;

-- Variables del año
ld_ano_ini                         date ;
ld_ano_fin                         date ;
ln_dias_ano                        number(4) ;

-- Variables de configuracion de utilidad
ld_fecha_ini                       utl_distribucion.fecha_ini%type ;
ld_fecha_fin                       utl_distribucion.fecha_fin%type ;
ld_dias_utilidad                   number(13,2) ;
ln_dias_periodo                    number(4) ;
ln_dias_tot_periodo                number(4) ;
ln_domingos_periodo                number(4) ;
ln_feriados_periodo                number(4) ;
ln_util_pago                       number(12,2) ;
ln_util_asistencia                 number(12,2) ;

-- Totales por trabajador
ld_fec_ini_trabaj                  date ;
ld_fec_fin_trabaj                  date ;
ln_dias_tot_x_trabaj               number ;
ln_pagos_x_trabaj                  number(13,2) ;
ln_doming_tot_x_trabaj             number(4) ;
ln_feriado_x_trabaj                number(4) ;
ln_dias_inasist_x_trabaj           number(4) ;

--  Lectura del maestro de trabajadores para calculo de utilidades
CURSOR c_personal(ad_fecha_ini in date, ad_fecha_fin in date) is 
select distinct(hc.cod_trabajador) as cod_trabajador, hc.cod_origen, hc.tipo_trabajador, m.fec_ingreso, m.fec_cese
from historico_calculo hc, maestro m, grupo_calculo gc, grupo_calculo_det gcd 
where hc.cod_trabajador = m.cod_trabajador and 
      hc.cod_origen = as_origen and 
      hc.tipo_trabajador like as_tipo_trabaj and 
      TRUNC(hc.fec_calc_plan) between ad_fecha_ini and ad_fecha_fin and 
      gc.grupo_calculo = gcd.grupo_calculo and 
      hc.concep = gcd.concepto_calc 
ORDER BY hc.cod_trabajador ;

--  Lectura del personal extra que no esta en planilla
CURSOR c_personal_extra is
SELECT e.cod_relacion, e.remun_anual, e.dias_efect_ano, e.cod_origen, e.tipo_trabajador  
  FROM utl_personal_ext e
 WHERE e.periodo = an_periodo and e.item = an_item and e.cod_origen = as_origen and e.tipo_trabajador like as_tipo_trabaj 
order by e.cod_relacion ;

--  Cursor para calcular utilidades
CURSOR c_movimiento is
SELECT u.proveedor, u.pagos, u.reintegro, u.dias_total, u.dias_domingo, u.dias_feriado, u.dias_inasist 
  FROM utl_movim_general u 
ORDER BY u.cod_trabajador ;

BEGIN

--  *******************************************************************
--  ***   CALCULO DE DISTRIBUCION POR PARTICIPACION DE UTILIDADES   ***
--  *******************************************************************

-- Verifica si existe el periodo para calcular utilidades.
SELECT count(*) 
  INTO ln_verifica 
  FROM utl_distribucion d 
 WHERE d.periodo = an_periodo and d.item = an_item and d.flag_estado='1';
 
IF ln_verifica = 0 THEN
   raise_application_error (-20000, 'Registre información para proceso de Utilidades') ;
   return ;
END IF ;

IF ln_verifica > 1 THEN
   raise_application_error (-20001, 'Tiene mas de 1 periodo abierto de utilidades en el mismo año') ;
   return ;
END IF ;

-- Captura datos de utilidades
SELECT u.grp_remun_anual, u.dias_tope_ano INTO ls_grupo_pago, ln_dias_tope_ano FROM utlparam u WHERE u.reckey='1' ;

-- Verifica dias totales del periodo, que no debe exceder a 360 dias
SELECT SUM(u.dias_periodo)
  INTO ln_dias_periodo 
  FROM utl_distribucion u 
 WHERE u.periodo = an_periodo ;

IF ln_dias_periodo > ln_dias_tope_ano THEN
   raise_application_error (-20002, 'Los dias del periodo no pueden exceder al tope anual') ;
   return ;
END IF ;

IF ln_dias_periodo = 0 THEN
   raise_application_error (-20003, 'El periodo a calcular utilidades esta errado') ;
   return ;
END IF ;

-- Verfica datos para calcular utilidades
SELECT u.porc_distribucion, u.renta_neta, u.porc_dias_laborados, u.porc_remuneracion, u.fecha_ini, u.fecha_fin, u.dias_periodo
  INTO ld_porc_distribucion, ld_renta_neta, ld_porc_dias_laborados, ld_porc_renumeracion, ld_fecha_ini, ld_fecha_fin, ln_dias_periodo 
  FROM utl_distribucion u 
 WHERE u.periodo=an_periodo AND u.item=an_item ;

-- Eliminando datos de tabla de movimientos para regenerarlos
DELETE FROM utl_movim_general u 
 WHERE u.periodo=an_periodo 
   AND u.item=an_item 
   AND u.cod_origen=as_origen 
   AND u.tipo_trabajador like as_tipo_trabaj;

-- Calculando dias totales del periodo
ld_ano_ini := to_date('01/01/'||to_char(ld_fecha_ini,'yyyy'),'dd/mm/yyyy') ;
ld_ano_fin := to_date('31/12/'||to_char(ld_fecha_ini,'yyyy'),'dd/mm/yyyy') ;
ln_dias_ano := ld_ano_fin - ld_ano_ini + 1 ;

ln_dias_tot_periodo := ld_fecha_fin - ld_fecha_ini + 1 ;

-- Factor anual : 360 / ln_dias_ano 
ln_dias_periodo := ROUND(ln_dias_tot_periodo * ln_dias_tope_ano / ln_dias_ano,0) ; 

/*-- Calculo dias dominicales de periodo
ln_domingos_periodo := USF_RH_CALC_DOMINGOS(ld_fecha_ini, ld_fecha_fin) ;

-- Calcula dias feriados de periodo
ln_feriados_periodo := USF_RH_DIAS_FERIADO(as_origen, ld_fecha_ini, ld_fecha_fin ) ;*/

-- Calcula pagos del todo el personal
FOR c_p IN c_personal(ld_fecha_ini, ld_fecha_fin) LOOP
    -- Verifica si personal debe ser considerado en calculo o no
    SELECT count(*) 
      INTO ln_verifica 
      FROM utl_excl_trabajador u 
     WHERE u.cod_trabajador = c_p.cod_trabajador 
       AND u.periodo        = an_periodo 
       AND item             = an_item ;

    -- Continua el proceso
    IF ln_verifica = 1 THEN
       EXIT ;
    END IF ;
    
    SELECT sum(hc.imp_soles) 
      INTO ln_pagos_x_trabaj  
      FROM historico_calculo hc, maestro m, grupo_calculo gc, grupo_calculo_det gcd 
     WHERE hc.cod_trabajador = m.cod_trabajador and 
           hc.cod_trabajador = c_p.cod_trabajador and 
           hc.cod_origen = as_origen and 
           hc.tipo_trabajador like as_tipo_trabaj and 
           TRUNC(hc.fec_calc_plan) between ld_fecha_ini and ld_fecha_fin and 
           gc.grupo_calculo = gcd.grupo_calculo and 
           gc.grupo_calculo = ls_grupo_pago and 
           hc.concep = gcd.concepto_calc ; 
  
    -- Actualizar los dias totales por trabajador
    IF c_p.fec_ingreso <= ld_fecha_ini and NVL(c_p.fec_cese, ld_fecha_fin)>=ld_fecha_fin THEN
       ld_fec_ini_trabaj := ld_fecha_ini ;
       ld_fec_fin_trabaj := ld_fecha_fin ;
    END IF ;
    
    IF c_p.fec_ingreso <= ld_fecha_ini THEN
       ld_fec_ini_trabaj := ld_fecha_ini ;
    ELSE 
       ld_fec_ini_trabaj := c_p.fec_ingreso ;
    END IF ;
    
    IF NVL(c_p.fec_cese, ld_fecha_fin)>=ld_fecha_fin THEN
       ld_fec_fin_trabaj := ld_fecha_fin ;
    ELSE
       ld_fec_fin_trabaj := c_p.fec_cese ;
    END IF ;
    
    -- Calculando los dias totales trabajados (360/ln_dias_ano, factor de conversión)
    ln_dias_tot_x_trabaj := USF_RH_DIAS_TOT_UTIL(c_p.cod_trabajador, c_p.tipo_trabajador, 
                                                 ld_fec_ini_trabaj, ld_fec_fin_trabaj, ln_dias_ano ) ;

    -- Actualizar los domingos
    ln_doming_tot_x_trabaj := USF_RH_CALC_DOMINGOS(ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;
    -- Actualizar los feriados
    ln_feriado_x_trabaj := USF_RH_DIAS_FERIADO(as_origen, ld_fec_ini_trabaj, ld_fec_fin_trabaj ) ;
    -- Actualizar las inasistencias (descontar domingos y feriados) 
    ln_dias_inasist_x_trabaj := USF_RH_DIAS_INASIST_UTIL(c_p.cod_trabajador, ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;
    -- Actualiza adelantos por trabajador 
    -- utl_adlt_ext
    
    -- Actualiza datos de utilidades por trabajador 
    UPDATE utl_movim_general u 
       SET u.pagos = NVL(u.pagos,0) + ln_pagos_x_trabaj, 
           u.dias_total = NVL(u.dias_total,0) + ln_dias_tot_x_trabaj, 
           u.dias_domingo = NVL(u.dias_domingo,0) + ln_doming_tot_x_trabaj,
           u.dias_feriado = NVL(u.dias_feriado,0) + ln_feriado_x_trabaj,
           u.dias_inasist = NVL(u.dias_inasist,0) + ln_dias_inasist_x_trabaj
     WHERE u.periodo = an_periodo 
       AND u.item = an_item 
       AND u.proveedor = c_p.cod_trabajador ;
    
    -- Ingresa datos de pagos en caso no exista
    IF SQL%NOTFOUND THEN
       INSERT INTO utl_movim_general(
              periodo, 
              item, 
              proveedor, 
              pagos, 
              dsctos, 
              dias_total, 
              dias_domingo, 
              dias_feriado, 
              dias_inasist, 
              cod_origen, 
              tipo_trabajador)
       VALUES(
              an_periodo, 
              an_item, 
              c_p.cod_trabajador, 
              ln_pagos_x_trabaj, 
              0, 
              ln_dias_tot_x_trabaj, 
              ln_doming_tot_x_trabaj, 
              ln_feriado_x_trabaj, 
              ln_dias_inasist_x_trabaj, 
              c_p.cod_origen, 
              c_p.tipo_trabajador) ;
    END IF ;
    
END LOOP ;

IF as_flag_externo = '1' THEN 
    -- Agregar información de externos
    FOR c_e IN c_personal_extra LOOP
            -- Actualiza datos de utilidades por trabajador 
        UPDATE utl_movim_general u 
           SET u.pagos = NVL(u.pagos,0) + c_e.remun_anual, 
               u.dias_total = NVL(u.dias_total,0) + c_e.dias_efect_ano, 
               u.dias_domingo = NVL(u.dias_domingo,0) + 0,
               u.dias_feriado = NVL(u.dias_feriado,0) + 0,
               u.dias_inasist = NVL(u.dias_inasist,0) + 0
         WHERE u.periodo = an_periodo 
           AND u.item = an_item 
           AND u.proveedor = c_e.cod_relacion ;
        
        -- Ingresa datos de pagos en caso no exista
        IF SQL%NOTFOUND THEN
           INSERT INTO utl_movim_general(
                  periodo, 
                  item, 
                  proveedor, 
                  pagos, 
                  dsctos, 
                  dias_total, 
                  dias_domingo, 
                  dias_feriado, 
                  dias_inasist, 
                  cod_origen, 
                  tipo_trabajador)
           VALUES(
                  an_periodo, 
                  an_item, 
                  c_e.cod_relacion, 
                  c_e.remun_anual, 
                  0, 
                  c_e.dias_efect_ano, 
                  0, 
                  0, 
                  0, 
                  c_e.cod_origen, 
                  c_e.cod_relacion) ;
        END IF ;
        
    END LOOP ;
END IF ;

-- Si se indica que genere montos de utilidades
IF as_genera = '1' THEN 
    -- Actualiza tabla de parametros (En forma general, no por origen ni tipo de trabajador)
    SELECT sum(u.pagos + u.reintegro), sum(u.dias_total - u.dias_domingo - u.dias_feriado - u.dias_inasist)        
      INTO ln_util_pago, ln_util_asistencia 
      FROM utl_movim_general u 
     WHERE u.periodo = an_periodo and u.item=an_item ;
    
    UPDATE utl_distribucion u 
    SET u.tot_remun_ejer = ln_util_pago, 
        u.tot_dias_ejer = ln_util_asistencia 
    WHERE u.periodo = an_periodo and 
          u.item = an_item ;

    -- Captura datos para calcular utilidades
    SELECT u.porc_distribucion, u.renta_neta, u.porc_dias_laborados, u.porc_remuneracion, 
           u.tot_remun_ejer, u.tot_dias_ejer 
      INTO ld_porc_distribucion, ld_renta_neta, ld_porc_dias_laborados, ld_porc_renumeracion, ld_fecha_ini, ld_fecha_fin, ln_dias_periodo 
      FROM utl_distribucion u 
     WHERE u.periodo=an_periodo AND u.item=an_item ;
          
    -- Realiza calculo de distribucion de utilidades
    FOR c_m IN c_movimiento LOOP
        
    END LOOP ;
    -- Evaluar casos de retenciones judiciales (Debe calcularse pero no disminuir).
    
END IF ;





/*

delete from utl_ext_hist u
  where u.periodo = an_periodo ;

ld_fec_inicio := to_date('0101'||to_char(an_periodo),'dd/mm/yyyy') ;
ld_fec_final  := to_date('3112'||to_char(an_periodo),'dd/mm/yyyy') ;

select p.grp_remun_anual, p.grp_inasist_anual, p.grp_dias_reintegro, p.dias_tope_ano
  into ls_grp_remuner, ls_grp_inasist, ls_grp_reinteg, ln_dias_ano
  from utlparam p where p.reckey = '1' ;

select (nvl(d.renta_neta,0) * nvl(d.porc_distribucion,0) / 100),
       d.porc_dias_laborados, d.porc_remuneracion
  into ln_imp_distribuc, ln_porc_dias_lab, ln_porc_remunera
  from utl_distribucion d
  where d.periodo = an_periodo ;

ln_imp_dist_dias := ln_imp_distribuc * ln_porc_dias_lab / 100 ;
ln_imp_dist_remu := ln_imp_distribuc * ln_porc_remunera / 100 ;

if (nvl(ln_imp_dist_dias,0) + nvl(ln_imp_dist_remu,0)) <> nvl(ln_imp_distribuc,0) then
  ln_imp_dist_remu := nvl(ln_imp_dist_remu,0) + (nvl(ln_imp_distribuc,0) -
                      (nvl(ln_imp_dist_dias,0) + nvl(ln_imp_dist_remu,0))) ;
end if ;

--  Determina remuneraciones y dias efectivos del ejercicio por trabajador
for rc_mae in c_maestro loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica from utl_excl_trabajador e
    where e.periodo = an_periodo and e.cod_trabajador = rc_mae.cod_trabajador ;

  if ln_verifica = 0 then

    ln_sw := 0 ; ln_dias_trabaj := 0 ;
    if nvl(rc_mae.flag_cal_plnlla,'0') = '1' and nvl(rc_mae.flag_estado,'0') = '1' then
      ln_sw := 1 ;
      if to_number(to_char(rc_mae.fec_ingreso,'yyyy')) = an_periodo then
        ln_dias_trabaj := usf_rh_liq_dias_truncos(rc_mae.fec_ingreso, ld_fec_final) ;
        if nvl(ln_dias_trabaj,0) > nvl(ln_dias_ano,0) then
          ln_dias_trabaj := nvl(ln_dias_ano,0) ;
        end if ;
      else
        ln_dias_trabaj := nvl(ln_dias_ano,0) ;
      end if ;
    end if ;
    if nvl(rc_mae.flag_estado,'0') = '0' and to_number(to_char(rc_mae.fec_cese,'yyyy')) = an_periodo then
      ln_sw := 1 ;
      ln_dias_trabaj := usf_rh_liq_dias_truncos(ld_fec_inicio, rc_mae.fec_cese) ;
      
      if nvl(ln_dias_trabaj,0) > nvl(ln_dias_ano,0) then
        ln_dias_trabaj := nvl(ln_dias_ano,0) ;
      end if ;
    end if ;

    if ln_sw = 1 then

      ln_verifica := 0 ; ln_dias_reintegro := 0 ;
      select count(*) into ln_verifica from historico_inasistencia hi
        where hi.cod_trabajador = rc_mae.cod_trabajador and to_number(to_char(hi.fec_movim,'yyyy')) =
              an_periodo and hi.concep in ( select d.concepto_calc from grupo_calculo_det d
                                            where d.grupo_calculo = ls_grp_reinteg ) ;
      if ln_verifica > 0 then
        select sum(nvl(hi.dias_inasist,0)) into ln_dias_reintegro from historico_inasistencia hi
          where hi.cod_trabajador = rc_mae.cod_trabajador and to_number(to_char(hi.fec_movim,'yyyy')) =
                an_periodo and hi.concep in ( select d.concepto_calc from grupo_calculo_det d
                                              where d.grupo_calculo = ls_grp_reinteg ) ;
      end if ;

      ln_verifica := 0 ; ln_dias_inasist := 0 ;
      select count(*) into ln_verifica from historico_inasistencia hi
        where hi.cod_trabajador = rc_mae.cod_trabajador and to_number(to_char(hi.fec_movim,'yyyy')) =
              an_periodo and hi.concep in ( select d.concepto_calc from grupo_calculo_det d
                                            where d.grupo_calculo = ls_grp_inasist ) ;
      if ln_verifica > 0 then
        select sum(nvl(hi.dias_inasist,0)) into ln_dias_inasist from historico_inasistencia hi
          where hi.cod_trabajador = rc_mae.cod_trabajador and to_number(to_char(hi.fec_movim,'yyyy')) =
                an_periodo and hi.concep in ( select d.concepto_calc from grupo_calculo_det d
                                              where d.grupo_calculo = ls_grp_inasist ) ;
      end if ;

      ln_dias_trabaj := nvl(ln_dias_trabaj,0) + nvl(ln_dias_reintegro,0) - nvl(ln_dias_inasist,0) ;

      ln_verifica := 0 ; ln_remun_trabaj := 0 ;
      select count(*) into ln_verifica from historico_calculo hc
        where hc.cod_trabajador = rc_mae.cod_trabajador and to_number(to_char(hc.fec_calc_plan,'yyyy')) =
              an_periodo and hc.concep in ( select d.concepto_calc from grupo_calculo_det d
                                            where d.grupo_calculo = ls_grp_remuner ) ;
      if ln_verifica > 0 then
        select sum(nvl(hc.imp_soles,0)) into ln_remun_trabaj from historico_calculo hc
          where hc.cod_trabajador = rc_mae.cod_trabajador and to_number(to_char(hc.fec_calc_plan,'yyyy')) =
                an_periodo and hc.concep in ( select d.concepto_calc from grupo_calculo_det d
                                              where d.grupo_calculo = ls_grp_remuner ) ;
      end if ;

      ln_verifica := 0 ; ln_remun_extra := 0 ; ln_dias_extra := 0 ;
      select count(*) into ln_verifica from utl_personal_ext p
        where p.periodo = an_periodo and p.cod_relacion = rc_mae.cod_trabajador ;
        
      if ln_verifica > 0 then
        select nvl(p.remun_anual,0), nvl(p.dias_efect_ano,0)
          into ln_remun_extra, ln_dias_extra
          from utl_personal_ext p
          where p.periodo = an_periodo and p.cod_relacion = rc_mae.cod_trabajador ;
          
        ln_remun_trabaj := ln_remun_trabaj + ln_remun_extra ;
        ln_dias_trabaj  := ln_dias_trabaj + ln_dias_extra ;
      end if ;

      insert into tt_personal_utilidades (
        cod_trabajador, porc_jud, imp_remun, imp_dias_efec )
      values (
        rc_mae.cod_trabajador, rc_mae.porc_jud_util, ln_remun_trabaj, ln_dias_trabaj ) ;

    end if ;

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
  where d.periodo = an_periodo ;
  
ln_factor := nvl(ln_imp_dist_dias,0) / nvl(ln_dias_trabaj,0) ;

--  Realiza calculo de distribucion de utilidades por trabajador
for rc_mov in c_movimiento loop

  ls_codigo := rc_mov.cod_trabajador ;

  ln_imp_remun_anual := nvl(ln_imp_dist_remu,0) * nvl(rc_mov.imp_remun,0) /
                        nvl(ln_remun_trabaj,0) ;
  ln_imp_dias_efecti := nvl(rc_mov.imp_dias_efec,0) * nvl(ln_factor,0) ;

  ln_verifica := 0 ; ln_imp_adelantos := 0 ;
  
  select count(*) into ln_verifica from utl_adlt_ext a
    where a.periodo = an_periodo and a.cod_relacion = ls_codigo ;
    
  if ln_verifica > 0 then
    select sum(nvl(a.imp_adelanto,0)) into ln_imp_adelantos from utl_adlt_ext a
      where a.periodo = an_periodo and a.cod_relacion = ls_codigo ;
  end if ;

  ln_imp_reten_jud := 0 ;
  
  if rc_mov.porc_jud > 0 then
    ln_imp_reten_jud := (nvl(ln_imp_remun_anual,0) + nvl(ln_imp_dias_efecti,0) *
                        nvl(rc_mov.porc_jud,0)) / 100 ;
  end if ;

  insert into utl_ext_hist (
    periodo, cod_relacion, remun_anual, imp_utl_remun_anual, dias_efectivos,
    imp_ult_dias_efect, adelantos, reten_jud )
  values (
    an_periodo, ls_codigo, rc_mov.imp_remun, ln_imp_remun_anual, rc_mov.imp_dias_efec,
    ln_imp_dias_efecti, ln_imp_adelantos, ln_imp_reten_jud ) ;

end loop ;

--  Ajuste de pagos de utilidades al ultimo trabajador
ln_remun_trabaj := 0 ; ln_dias_trabaj := 0 ;
select sum(nvl(u.imp_utl_remun_anual,0)), sum(nvl(u.imp_ult_dias_efect,0))
  into ln_remun_trabaj, ln_dias_trabaj
  from utl_ext_hist u where u.periodo = an_periodo ;

if nvl(ln_remun_trabaj,0) <> nvl(ln_imp_dist_remu,0) then
  update utl_ext_hist u
    set u.imp_utl_remun_anual = u.imp_utl_remun_anual + (ln_imp_dist_remu - ln_remun_trabaj)
    where u.periodo = an_periodo and u.cod_relacion = ls_codigo ;
end if ;
if nvl(ln_dias_trabaj,0) <> nvl(ln_imp_dist_dias,0) then
  update utl_ext_hist u
    set u.imp_ult_dias_efect = u.imp_ult_dias_efect + (ln_imp_dist_dias - ln_dias_trabaj)
    where u.periodo = an_periodo and u.cod_relacion = ls_codigo ;
end if ;
*/

end usp_rh_utilidad_calculo;
/
