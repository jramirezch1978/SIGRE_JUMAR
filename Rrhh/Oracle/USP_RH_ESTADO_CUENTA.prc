create or replace procedure usp_rh_estado_cuenta (
  as_cod_trabajador in string ) is

ln_verifica             integer ;
ln_dias                 integer ;
ls_grupo                char(2) ;
ln_dias_vac             number(5) ;
ln_ano                  number(4) ;
ld_fec_actual           date ;
ld_fec_anterior         date ;
ln_imp_ganancias        number(8,2) ;
ln_imp_cts              number(8,2) ;
ln_imp_fdoret           number(8,2) ;
ln_imp_gratif           number(8,2) ;
ln_imp_remun            number(8,2) ;
ln_imp_racion           number(8,2) ;
ln_imp_vacdev           number(8,2) ;
ln_imp_vacacion         number(8,2) ;
ls_nivel                char(3) ;
ld_fec_promedio         date ;
ln_prom_sobret          number(8,2) ;
ls_concepto             char(4) ;
ld_fec_proceso          date ;
ln_num_mes              integer ;
ln_acum_sobret          number(8,2) ;
ld_ran_ini              date ;
ld_ran_fin              date ;
ln_imp_variable         number(8,2) ;

--  Lectura del trabajador seleccionado para generar temporal
cursor c_maestro is
  select m.cod_trabajador, m.porc_judicial, m.fec_ingreso
  from maestro m
  where m.cod_trabajador = as_cod_trabajador and nvl(m.flag_estado,'0') = '1' and
        nvl(m.flag_cal_plnlla,'0') = '1' ;

--  Lectura de conceptos para promedios de sobretiempos
cursor c_conceptos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = ls_nivel ;

begin

--  ******************************************************************
--  ***   DETERMINA ESTADO DE CUENTA DEL TRABAJADOR SELECCIONADO   ***
--  ******************************************************************

delete from tt_rh_estado_cuenta ;

select p.grc_gnn_fija into ls_grupo from rrhhparam p
  where p.reckey = '1' ;
  
select p.prom_remun_vacac into ls_nivel from rrhhparam_cconcep p
  where p.reckey = '1' ;

if ls_grupo is null then
  raise_application_error( -20000, 'Grupo para conceptos de ganancias fijas, no existe') ;
end if ;

--  ***
--  ***   Lectura del codigo de trabajador seleccionado
--  ***

for rc_mae in c_maestro loop

  --  Determina ganancias fijas del trabajador
  ln_verifica := 0 ; ln_imp_ganancias := 0 ;
  select count(*) into ln_verifica from gan_desct_fijo gf 
    where gf.cod_trabajador = rc_mae.cod_trabajador and nvl(gf.flag_estado,'0') = '1' and
          substr(gf.concep,1,2) = ls_grupo ;
  if ln_verifica > 0 then
    select sum(nvl(gf.imp_gan_desc,0)) into ln_imp_ganancias from gan_desct_fijo gf 
      where gf.cod_trabajador = rc_mae.cod_trabajador and nvl(gf.flag_estado,'0') = '1' and
            substr(gf.concep,1,2) = ls_grupo ;
  end if ;

  --  Determina importe de provisiones de C.T.S.
  ln_verifica := 0 ; ln_imp_cts := 0 ;
  select count(*) into ln_verifica from prov_cts_gratif cts
    where cts.cod_trabajador = rc_mae.cod_trabajador ;
  if ln_verifica > 0 then
    select sum( nvl(cts.prov_cts_01,0) + nvl(cts.prov_cts_02,0) + nvl(cts.prov_cts_03,0) +
                nvl(cts.prov_cts_04,0) + nvl(cts.prov_cts_05,0) + nvl(cts.prov_cts_06,0) )
      into ln_imp_cts from prov_cts_gratif cts where cts.cod_trabajador = rc_mae.cod_trabajador ;
  end if ;

  --  Determina importe por compensacion por fondo de retiro
  ln_verifica := 0 ; ln_imp_fdoret := 0 ;
  select count(*) into ln_verifica from fondo_retiro fr
   where fr.cod_trabajador = rc_mae.cod_trabajador and
         trunc(fr.fec_proceso) = ( select max(trunc(fec_proceso)) from fondo_retiro
                                   where cod_trabajador = rc_mae.cod_trabajador
                                   group by cod_trabajador ) ;
  if ln_verifica > 0 then
    select fr.importe into ln_imp_fdoret from fondo_retiro fr 
      where fr.cod_trabajador = rc_mae.cod_trabajador and
            trunc(fr.fec_proceso) = ( select max(trunc(fec_proceso)) from fondo_retiro
                                      where cod_trabajador = rc_mae.cod_trabajador
                                      group by cod_trabajador ) ;
  end if ;

  --  Determina saldos de devengados, Gratificaciones, Remuneraciones y Raciones de Azucar
  ln_verifica := 0 ; ln_imp_gratif := 0 ; ln_imp_remun := 0 ; ln_imp_racion := 0 ;
  select count(*) into ln_verifica from sldo_deveng d
    where d.cod_trabajador = rc_mae.cod_trabajador and
          d.fec_proceso = ( select max(trunc(fec_proceso)) from sldo_deveng
                            where cod_trabajador = rc_mae.cod_trabajador
                            group by cod_trabajador ) ;
  if ln_verifica > 0 then
    select nvl(d.sldo_gratif_dev,0), nvl(d.sldo_rem_dev,0), nvl(d.sldo_racion,0)
      into ln_imp_gratif, ln_imp_remun, ln_imp_racion
      from sldo_deveng d
      where d.cod_trabajador = rc_mae.cod_trabajador and
            d.fec_proceso = ( select max(trunc(fec_proceso)) from sldo_deveng
                              where cod_trabajador = rc_mae.cod_trabajador
                              group by cod_trabajador ) ;
  end if ;    

  --  Determina importes por dias de vacaciones devengadas
  ln_verifica := 0 ; ln_dias_vac := 0 ; ln_imp_vacdev := 0 ;
  select count(*) into ln_verifica from vacac_bonif_deveng v
    where v.cod_trabajador = rc_mae.cod_trabajador and nvl(v.flag_estado,'0') = '1' ;
  if ln_verifica > 0 then
    select sum(nvl(v.sldo_dias_vacacio,0)) + sum(nvl(v.sldo_dias_bonif,0))
      into ln_dias_vac
      from vacac_bonif_deveng v
      where v.cod_trabajador = rc_mae.cod_trabajador and nvl(v.flag_estado,'0') = '1' ;
    ln_imp_vacdev := nvl(ln_imp_ganancias,0) / 30 * nvl(ln_dias_vac,0) ;
  end if ;    

  --  Determina saldos por vacaciones
  ln_imp_vacacion := 0 ;
  ln_ano := to_number(to_char(sysdate,'yyyy')) ;
  ld_fec_actual   := to_date(to_char(rc_mae.fec_ingreso,'dd/mm')||to_char(ln_ano),'dd/mm/yyyy') ;    
  ld_fec_anterior := to_date(to_char(rc_mae.fec_ingreso,'dd/mm')||to_char(ln_ano-1),'dd/mm/yyyy') ;
  if trunc(sysdate ) < trunc(ld_fec_actual) then
     ln_dias := trunc(sysdate) - trunc(ld_fec_anterior) ;
  else
     ln_dias := trunc(sysdate) - trunc(ld_fec_actual) ;
  end if ;
  if nvl(ln_dias,0) > 0 then
    ln_imp_vacacion := nvl(ln_imp_ganancias,0) / 360 * nvl(ln_dias,0) ;
  end if ;

  --  Calcula promedio de sobretiempos de los ultimos seis meses
  ln_verifica := 0 ; ld_fec_promedio := null ;
  select count(*) into ln_verifica from calculo c
    where to_char(c.fec_proceso,'mm/yyyy') = to_char(sysdate,'mm/yyyy') ;
  if ln_verifica > 0 then
    ld_fec_promedio := sysdate ;
  else
    select max(c.fec_proceso) into ld_fec_promedio from calculo c ;
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
        where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = rc_mae.cod_trabajador and
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
      if ln_verifica > 0 then
        select sum(nvl(hc.imp_soles,0))
          into ln_imp_variable from historico_calculo hc
          where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = rc_mae.cod_trabajador and
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

  --  Inserta informacion en la tabla tempoeral
  insert into tt_rh_estado_cuenta (
    cod_trabajador, porc_judicial, fec_ingreso, ganan_fija,
    cts, t_servicio, vacaciones, sldo_grati, sldo_rem,
    sldo_racion, sldo_vaca_deve, ganan_variable )
  values (
    rc_mae.cod_trabajador, rc_mae.porc_judicial, rc_mae.fec_ingreso, ln_imp_ganancias,
    ln_imp_cts, ln_imp_fdoret, ln_imp_vacacion, ln_imp_gratif, ln_imp_remun,
    ln_imp_racion, ln_imp_vacdev, ln_prom_sobret ) ;

end loop ;

end usp_rh_estado_cuenta ;



/*
create or replace procedure USP_RH_ESTADO_CUENTA
(as_cod_trabajador in String ) is

ls_grupo            char(2)       ;
ln_sueldo           number(8,2)   ;
ln_dias_deve        integer       ;
ln_vaca_deve        number(8,2)   ;
ld_ingreso          date          ;
ld_ano_actual       date          ;
ln_ano_anterior     integer       ;
ld_fecha_actual     date          ;    
ld_fecha_anterior   date          ;
ln_resultado        integer       ;
ln_gana_vari        number(8,2)   ;
ln_vacaciones       number(8,2)   ;
ln_mes              integer       ;
ln_dias             integer       ;
ln_sueldo_mes       number(8,2)   ;
ln_sueldo_dias      number(8,2)   ;
lc_concepto_gen     char(5)       ;
ln_concepto_gen     number(8,2)   ;
ln_existe_concepto  integer       ;
ln_existe           integer       ;
ln_sum_concep       number(8,2)   ; 
ln_sum_variable     NUMBER(8,2)   ; 


CURSOR c_varia is 
SELECT concepto as concepto
  FROM tt_rh_ganancia_variable ;

begin
delete from TT_RH_ESTADO_CUENTA ;
delete from tt_rh_ganancia_variable ;
select p.grc_gnn_fija into ls_grupo from rrhhparam p
  where p.reckey = '1' ;
  
if ls_grupo is null then
  raise_application_error( -20000, 'Concepto NO Existe Grupo para ganancias Fijas') ;
end if ;

INSERT INTO  TT_RH_ESTADO_CUENTA (
             COD_TRABAJADOR ,
             PORC_JUDICIAL  ,
             FEC_INGRESO    ,
             GANAN_FIJA     ,
             CTS            ,
             T_SERVICIO      )

select ma.cod_trabajador, ma.porc_judicial,ma.fec_ingreso,
       (select sum(gf.imp_gan_desc) from gan_desct_fijo gf 
       where gf.cod_trabajador = as_cod_trabajador
         and substr(gf.concep,1,2) = ls_grupo) , 
       (select sum(cts.prov_cts_01+cts.prov_cts_02+cts.prov_cts_03+cts.prov_cts_04+cts.prov_cts_05+ cts.prov_cts_06)
       from prov_cts_gratif cts where cts.cod_trabajador = as_cod_trabajador) ,  
       (select fr.importe from fondo_retiro fr where  fr.cod_trabajador =as_cod_trabajador
        and fr.fec_proceso = (select max(trunc(fec_proceso)) from fondo_retiro
                               where cod_trabajador = as_cod_trabajador
                               group by cod_trabajador))
from  maestro ma
where ma.cod_trabajador = as_cod_trabajador
and  ma.flag_estado='1' 
and  flag_cal_plnlla = '1'

GROUP BY ma.cod_trabajador,ma.fec_ingreso,ma.porc_judicial ;

---- Calculo de Gratificación
update TT_RH_ESTADO_CUENTA
set SLDO_GRATI =  (select sldo_gratif_dev from sldo_deveng
                   where cod_trabajador=as_cod_trabajador
                   and fec_proceso = (select max(trunc(fec_proceso))
                                      from sldo_deveng
                                      where cod_trabajador=as_cod_trabajador
                                      group by cod_trabajador) )
where cod_trabajador = as_cod_trabajador ;

----- Calculo remuneración devengada
update TT_RH_ESTADO_CUENTA
set  SLDO_REM  =  ( select sldo_rem_dev  from sldo_deveng
                   where cod_trabajador = as_cod_trabajador
                   and fec_proceso = (select max(trunc(fec_proceso))
                                      from sldo_deveng
                                      where cod_trabajador=as_cod_trabajador
                                      GROUP BY cod_trabajador) )
where cod_trabajador = as_cod_trabajador ;

------ Calculo de Racion devengada
update TT_RH_ESTADO_CUENTA
set  SLDO_RACION  =  ( select sldo_racion  from sldo_deveng
                   where cod_trabajador = as_cod_trabajador
                   and fec_proceso = (select max(trunc(fec_proceso))
                                      from sldo_deveng
                                      where cod_trabajador=as_cod_trabajador
                                      GROUP BY cod_trabajador) )
where cod_trabajador = as_cod_trabajador ;

----- Calcula la ganacia fija
select sum(gf.imp_gan_desc) into ln_sueldo from gan_desct_fijo gf 
 where gf.cod_trabajador = as_cod_trabajador and substr(gf.concep,1,2) = ls_grupo ; 
 
----- Calculode dias vacaciones devengadas
select (sum( sldo_dias_vacacio) + sum(sldo_dias_bonif)) into ln_dias_deve from vacac_bonif_deveng
 where cod_trabajador = as_cod_trabajador and flag_estado = '1'  ;
ln_vaca_deve := ( ln_sueldo / 30) * ln_dias_deve ;

update TT_RH_ESTADO_CUENTA
set  sldo_vaca_deve  = ln_vaca_deve
where cod_trabajador = as_cod_trabajador ;

----- Captura la fecha de ingreso del trabajador
select ma.fec_ingreso into ld_ingreso from  maestro ma
where ma.cod_trabajador = as_cod_trabajador and 
      ma.flag_estado='1' and  flag_cal_plnlla = '1';


ld_ano_actual     := to_date(to_char( sysdate ,'yyyy'),'yyyy') ;
ln_ano_anterior   := to_number(to_char(ld_ano_actual,'yyyy')) - 1 ;
ld_fecha_actual   := to_date(to_char(ld_ingreso,'dd/mm')||to_char(ld_ano_actual,'yyyy'),'dd/mm/yyyy') ;    
ld_fecha_anterior := to_date(to_char(ld_ingreso,'dd/mm')||to_char(ln_ano_anterior),'dd/mm/yyyy') ;

if trunc(sysdate ) < trunc(ld_fecha_actual) then
   ln_resultado := trunc(sysdate ) - trunc(ld_fecha_anterior) ;
else
   ln_resultado := trunc(sysdate ) - trunc(ld_fecha_actual) ;
end if ;
   
ln_mes := (ln_resultado / 30) ;
ln_dias:= ln_resultado -(ln_mes * 30) ;
ln_sueldo_mes :=  (ln_sueldo / 12) ;
ln_sueldo_dias:=  (ln_sueldo / 360) ;

ln_vacaciones :=  (ln_mes * ln_sueldo_mes) + ln_dias * ln_sueldo_dias ;

update TT_RH_ESTADO_CUENTA 
set vacaciones =  ln_vacaciones
where cod_trabajador = as_cod_trabajador ;

---- Captura el concepto 1441
select concepto_gen into lc_concepto_gen from grupo_calculo where grupo_calculo = '083' ;

select count(*) into ln_existe_concepto from historico_calculo
where concep = lc_concepto_gen  and 
      cod_trabajador= as_cod_trabajador and
      fec_calc_plan >= add_months(sysdate, -6) ;

if ln_existe_concepto > 0 then

select sum(imp_soles) into ln_concepto_gen from historico_calculo
where concep = lc_concepto_gen  and 
      cod_trabajador= as_cod_trabajador and
      fec_calc_plan >= add_months(sysdate, -6) ;
else
ln_concepto_gen := 0 ;
end if ;

----- Calcular Ganacia Variable
  insert into tt_rh_ganancia_variable (concepto)
  select concepto_calc from grupo_calculo_det where grupo_calculo = '002' ;

For c_gan in c_varia loop
  
select count(*) into ln_existe from historico_calculo
 where concep = c_gan.concepto and 
       cod_trabajador = as_cod_trabajador and 
       fec_calc_plan >= add_months(sysdate, -6);
       
    if ln_existe > 2 then
       select sum(imp_soles) into ln_sum_concep from historico_calculo
        where concep = c_gan.concepto and 
              cod_trabajador = as_cod_trabajador and 
              fec_calc_plan >= add_months(sysdate, -6);
       update tt_rh_ganancia_variable
          set monto = ln_sum_concep, veces = ln_existe 
        where concepto = c_gan.concepto ;
    end if;
end loop;


select sum(monto) into ln_sum_variable  from tt_rh_ganancia_variable;
if ln_sum_variable is null then
   ln_sum_variable :=(ln_concepto_gen / 6) ;
   update TT_RH_ESTADO_CUENTA
   set ganan_variable = ln_sum_variable
   where cod_trabajador = as_cod_trabajador ;
else
   ln_sum_variable :=(ln_concepto_gen / 6) + (ln_sum_variable / 6 ) ;
   update TT_RH_ESTADO_CUENTA
   set ganan_variable = ln_sum_variable 
   where cod_trabajador = as_cod_trabajador ;
end if ;
  
end USP_RH_ESTADO_CUENTA ;
*/
/
