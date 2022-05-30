create or replace procedure usp_rh_calcula_provision_cts (
  as_codtra in char, ad_fec_proceso in date ,ad_fec_grati_jul in date ,ad_fec_grati_dic in date) is

lk_nivel1              char(3) ;
lk_bonificacion_25     char(3) ;
lk_bonificacion_30     char(3) ;
lk_ganancias_fijas     char(3) ;
lk_gra_julio           char(3) ;
lk_gra_diciembre       char(3) ;
lk_gratificacion       char(3) ;
lk_insist_cts          char(3) ;
lk_reinte_cts          char(3) ;
lk_no_concepto         char(3) ;
lc_grupo_variable      rrhhparam_cconcep.gan_var_ppto%type ;
ls_ttrab               tipo_trabajador.tipo_trabajador%type ;
ls_bonificacion        char(1) ;
ls_cod_seccion         char(3) ;
ls_concepto            char(4) ;
ln_imp_soles           number(13,2) ;
ls_year                char(4) ;
ld_fec_pago            date ;
ld_fec_ingreso         date ;
ln_contador            integer ;
ln_dias_trabaj         number(5,2) ;
ln_dias_inasis         number(5,2) ;
ln_dias_reinte         number(5,2) ;

ln_imp_01              number(13,2) ;
ln_imp_02              number(13,2) ;
ln_imp_03              number(13,2) ;
ln_imp_04              number(13,2) ;
ln_imp_05              number(13,2) ;
ln_imp_06              number(13,2) ;

ld_ran_ini             date ;
ld_ran_fin             date ;
ln_num_reg             number(5) ;
ln_imp_solesv          historico_calculo.imp_soles%type ;
ln_num_mes             integer ;
ln_acu_soles           historico_calculo.imp_soles%type ;
ln_tot_soles           historico_calculo.imp_soles%type ;

--  Cursor de conceptos de ganancias fijas
cursor c_ganancias_fijas is
  select gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
        gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
        where d.grupo_calculo = lk_ganancias_fijas ) ;

--  Cursor para gratificaciones ( Julio o Diciembre )
cursor c_historico_calculo is
  select hc.concep, hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = as_codtra and to_char(hc.fec_calc_plan,'mmyyyy') = to_char(ld_fec_pago,'mmyyyy') and
        hc.concep in ( select g.concepto_gen from grupo_calculo g
        where g.grupo_calculo in (lk_gra_julio, lk_gra_diciembre) ) ;

--  Determina conceptos para aplicar el 30% o 25%
cursor c_concepto ( as_concepto concepto.concep%type ) is
  select c.fact_pago
  from concepto c
  where c.concep = as_concepto ;

--  Conceptos para hallar promedio de los ultimos seis meses
cursor c_concep ( as_nivel in string ) is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = as_nivel ;

BEGIN 

--  *******************************************************************
--  ***   REALIZA CALCULO DE PROVISIONES DE C.T.S. POR TRABAJADOR   ***
--  *******************************************************************

select c.prom_remun_vacac,  c.bonificacion25, c.bonificacion30,
       c.ganfij_provision_cts, c.grati_medio_ano, c.grati_fin_ano,
       c.grp_dias_inasistencia_cts, c.grp_dias_reintegro_cts, c.banda_salarial,
       c.gan_var_ppto
  into lk_nivel1, lk_bonificacion_25, lk_bonificacion_30,
       lk_ganancias_fijas, lk_gra_julio, lk_gra_diciembre,
       lk_insist_cts, lk_reinte_cts, lk_no_concepto,
       lc_grupo_variable
  from rrhhparam_cconcep c where c.reckey = '1' ;

  

  
ln_contador := 0 ; ls_concepto := null ;

-- Lee grupo de banda salarial
select count(*) into ln_contador from grupo_calculo g where g.grupo_calculo = lk_no_concepto ;

if ln_contador > 0 then

   select g.concepto_gen into ls_concepto from grupo_calculo g where g.grupo_calculo = lk_no_concepto ;
   
   ln_contador := 0 ;
   
   select count(*) into ln_contador from gan_desct_fijo g  where g.cod_trabajador = as_codtra and g.concep = ls_concepto ;
   
   if ln_contador > 0 then
      return ;
   end if ;
end if ;


select m.fec_ingreso, nvl(m.bonif_fija_30_25,0), m.cod_seccion,m.tipo_trabajador
  into ld_fec_ingreso, ls_bonificacion, ls_cod_seccion,ls_ttrab
  from maestro m 
 where m.cod_trabajador = as_codtra ;

-- Esta seccion no existe para caso CGSA
if ls_cod_seccion = '950' then
  return ;
end if ;

-- Solo procesa a trabajadores con fecha de ingreso inferior a fecha de proceso
IF trunc(ld_fec_ingreso) > trunc(ad_fec_proceso) then
  return ;
END IF ;

ln_imp_soles := 0 ;
FOR rc_gan IN c_ganancias_fijas LOOP
  ln_imp_soles := ln_imp_soles + nvl(rc_gan.imp_gan_desc,0) ;
END LOOP ;

ln_contador := 0 ;

select count(*) into ln_contador from calculo c
  where c.cod_trabajador = as_codtra and c.fec_proceso = ad_fec_proceso ;
if ln_contador = 0 then
  select count(*) into ln_contador from historico_calculo hc
    where hc.cod_trabajador = as_codtra and hc.fec_calc_plan = ad_fec_proceso ;
  if ln_contador = 0 then
    return ;
  end if ;
end if ;

--  Calcula promedio de los ultimos seis meses
ln_tot_soles := 0 ;
FOR rc_concep IN c_concep ( lk_nivel1 ) LOOP
  ld_ran_ini   := ad_fec_proceso ;
  ln_num_mes   := 0 ; ln_acu_soles := 0 ;
  FOR x IN reverse 1 .. 6 LOOP
    ld_ran_fin := ld_ran_ini ;
    ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
    ln_imp_solesv := 0 ; ln_num_reg := 0 ;
    
    select count(*) into ln_num_reg from historico_calculo hc
      where hc.concep = rc_concep.concepto_calc and hc.cod_trabajador = as_codtra and
            hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
            
    if ln_num_reg > 0 then
      select sum(hc.imp_soles) into ln_imp_solesv from historico_calculo hc
        where hc.concep = rc_concep.concepto_calc and hc.cod_trabajador = as_codtra and
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
    else
      ln_imp_solesv := 0 ; ln_num_reg := 0 ;
      select count(*) into ln_num_reg from calculo c
        where c.cod_trabajador = as_codtra and c.concep = rc_concep.concepto_calc and
              c.fec_proceso = ld_ran_fin ;
      if ln_num_reg > 0 then
        select sum(c.imp_soles) into ln_imp_solesv from calculo c
          where c.cod_trabajador = as_codtra and c.concep = rc_concep.concepto_calc and
                c.fec_proceso = ld_ran_fin ;
      end if ;
    end if ;
    ln_imp_solesv := nvl(ln_imp_solesv,0) ;
    if ln_imp_solesv > 0 then
      ln_num_mes   := ln_num_mes + 1 ;
      ln_acu_soles := ln_acu_soles + ln_imp_solesv ;
    end if ;
    ld_ran_ini := ld_ran_ini - 1 ;
  END LOOP ;
  -- Solo debe considerar aquellos que tienen 03 o mas meses de frecuencia
  if ln_num_mes > 2 then
    ln_tot_soles := ln_tot_soles + (ln_acu_soles / 6 ) ;
  end if ;
END LOOP ;

ln_imp_soles := ln_imp_soles + ln_tot_soles ;


--sobretiempos
--  Calcula promedio de los ultimos seis meses
ln_tot_soles := 0 ;
FOR rc_concep IN c_concep ( lc_grupo_variable ) LOOP
  ld_ran_ini   := ad_fec_proceso ;
  ln_num_mes   := 0 ; ln_acu_soles := 0 ;
  FOR x IN reverse 1 .. 6 LOOP
    ld_ran_fin := ld_ran_ini ;
    ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
    ln_imp_solesv := 0 ; ln_num_reg := 0 ;
    
    select count(*) into ln_num_reg from historico_calculo hc
      where hc.concep = rc_concep.concepto_calc and hc.cod_trabajador = as_codtra and
            hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
            
    if ln_num_reg > 0 then
      select sum(hc.imp_soles) into ln_imp_solesv from historico_calculo hc
        where hc.concep = rc_concep.concepto_calc and hc.cod_trabajador = as_codtra and
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
    else
      ln_imp_solesv := 0 ; ln_num_reg := 0 ;
      select count(*) into ln_num_reg from calculo c
        where c.cod_trabajador = as_codtra and c.concep = rc_concep.concepto_calc and
              c.fec_proceso = ld_ran_fin ;
      if ln_num_reg > 0 then
        select sum(c.imp_soles) into ln_imp_solesv from calculo c
          where c.cod_trabajador = as_codtra and c.concep = rc_concep.concepto_calc and
                c.fec_proceso = ld_ran_fin ;
      end if ;
    end if ;
    ln_imp_solesv := nvl(ln_imp_solesv,0) ;
    if ln_imp_solesv > 0 then
      ln_num_mes   := ln_num_mes + 1 ;
      ln_acu_soles := ln_acu_soles + ln_imp_solesv ;
    end if ;
    ld_ran_ini := ld_ran_ini - 1 ;
  END LOOP ;
  -- Solo debe considerar aquellos que tienen 03 o mas meses de frecuencia
  if ln_num_mes > 2 then
    ln_tot_soles := ln_tot_soles + (ln_acu_soles / 6 ) ;
  end if ;
END LOOP ;

ln_imp_soles := ln_imp_soles + ln_tot_soles ;

-----sobretiempos
ls_concepto := null ;
if ls_bonificacion = '1' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_bonificacion_30 ;
  FOR rc_c IN c_concepto ( ls_concepto ) LOOP
    ln_imp_soles := ln_imp_soles + ( ln_imp_soles * nvl(rc_c.fact_pago,0) ) ;
  END LOOP ;
elsif ls_bonificacion = '2' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_bonificacion_25 ;
  FOR rc_c IN c_concepto ( ls_concepto ) LOOP
    ln_imp_soles := ln_imp_soles + ( ln_imp_soles * nvl(rc_c.fact_pago,0) ) ;
  END LOOP ;
end if ;

if to_char(ad_fec_proceso,'mm') = '01' or
   to_char(ad_fec_proceso,'mm') = '02' or
   to_char(ad_fec_proceso,'mm') = '03' or
   to_char(ad_fec_proceso,'mm') = '04' or
   to_char(ad_fec_proceso,'mm') = '05' or
   to_char(ad_fec_proceso,'mm') = '06' then
   
  ld_fec_pago := ad_fec_grati_dic ;
  lk_gratificacion := lk_gra_diciembre ;
elsif to_char(ad_fec_proceso,'mm') = '07' or
      to_char(ad_fec_proceso,'mm') = '08' or
      to_char(ad_fec_proceso,'mm') = '09' or
      to_char(ad_fec_proceso,'mm') = '10' or
      to_char(ad_fec_proceso,'mm') = '11' or
      to_char(ad_fec_proceso,'mm') = '12' then

  ld_fec_pago := ad_fec_grati_jul ;
  lk_gratificacion := lk_gra_julio ;
end if ;

for rc_gra in c_historico_calculo loop
  ln_imp_soles := ln_imp_soles + ( nvl(rc_gra.imp_soles,0) / 6 ) ;
end loop ;

ln_imp_soles := (ln_imp_soles / 2) / 6 ;

ln_imp_01 := 0 ; ln_imp_02 := 0 ; ln_imp_03 := 0 ;
ln_imp_04 := 0 ; ln_imp_05 := 0 ; ln_imp_06 := 0 ;

if to_char(ad_fec_proceso,'mm') = '05' or to_char(ad_fec_proceso,'mm') = '11' then
  ln_imp_01 := ln_imp_soles ;
elsif to_char(ad_fec_proceso,'mm') = '06' or to_char(ad_fec_proceso,'mm') = '12' then
  ln_imp_02 := ln_imp_soles ;
elsif to_char(ad_fec_proceso,'mm') = '07' or to_char(ad_fec_proceso,'mm') = '01' then
  ln_imp_03 := ln_imp_soles ;
elsif to_char(ad_fec_proceso,'mm') = '08' or to_char(ad_fec_proceso,'mm') = '02' then
  ln_imp_04 := ln_imp_soles ;
elsif to_char(ad_fec_proceso,'mm') = '09' or to_char(ad_fec_proceso,'mm') = '03' then
  ln_imp_05 := ln_imp_soles ;
elsif to_char(ad_fec_proceso,'mm') = '10' or to_char(ad_fec_proceso,'mm') = '04' then
  ln_imp_06 := ln_imp_soles ;
end if ;

ln_contador := 0 ; ln_dias_inasis := 0 ;
select count(*) into ln_contador from inasistencia i
  where i.cod_trabajador = as_codtra and
        to_char(i.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
        i.concep in ( select g.concepto_calc from grupo_calculo_det g
                      where g.grupo_calculo = lk_insist_cts ) ;
if ln_contador > 0 then
  select sum(nvl(i.dias_inasist,0)) into ln_dias_inasis from inasistencia i
    where i.cod_trabajador = as_codtra and
          to_char(i.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
          i.concep in ( select g.concepto_calc from grupo_calculo_det g
                        where g.grupo_calculo = lk_insist_cts ) ;
else
  ln_contador := 0 ; ln_dias_inasis := 0 ;
  select count(*) into ln_contador from historico_inasistencia hi
    where hi.cod_trabajador = as_codtra and
          to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
          hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                        where g.grupo_calculo = lk_insist_cts ) ;
  if ln_contador > 0 then
    select sum(nvl(hi.dias_inasist,0)) into ln_dias_inasis from historico_inasistencia hi
      where hi.cod_trabajador = as_codtra and
            to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
            hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                          where g.grupo_calculo = lk_insist_cts ) ;
  end if ;
end if ;

ln_contador := 0 ; ln_dias_reinte := 0 ;
select count(*) into ln_contador from inasistencia i
  where i.cod_trabajador = as_codtra and
        to_char(i.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
        i.concep in ( select g.concepto_calc from grupo_calculo_det g
                      where g.grupo_calculo = lk_reinte_cts ) ;
if ln_contador > 0 then
  select sum(nvl(i.dias_inasist,0)) into ln_dias_reinte from inasistencia i
    where i.cod_trabajador = as_codtra and
          to_char(i.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
          i.concep in ( select g.concepto_calc from grupo_calculo_det g
                        where g.grupo_calculo = lk_reinte_cts ) ;
else
  ln_contador := 0 ; ln_dias_reinte := 0 ;
  select count(*) into ln_contador from historico_inasistencia hi
    where hi.cod_trabajador = as_codtra and
          to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
          hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                        where g.grupo_calculo = lk_reinte_cts ) ;
  if ln_contador > 0 then
    select sum(nvl(hi.dias_inasist,0)) into ln_dias_reinte from historico_inasistencia hi
      where hi.cod_trabajador = as_codtra and
            to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fec_proceso,'mm/yyyy') and
            hi.concep in ( select g.concepto_calc from grupo_calculo_det g
                          where g.grupo_calculo = lk_reinte_cts ) ;
  end if ;
end if ;




--if to_char(trunc(ld_fec_ingreso),'yyyymm') =  to_char(trunc(ad_fec_proceso),'yyyymm') then
   
--   ln_dias_trabaj := (30 -  to_number(to_char(ld_fec_ingreso,'dd')) + 1) - nvl(ln_dias_inasis,0) + nvl(ln_dias_reinte,0) ;
   
--else
   ln_dias_trabaj := 30 - nvl(ln_dias_inasis,0) + nvl(ln_dias_reinte,0) ;   
--end if ;


ln_contador := 0 ;

select count(*) into ln_contador from prov_cts_gratif p
  where p.cod_trabajador = as_codtra ;
  
if ln_contador > 0 then
  update prov_cts_gratif
  set dias_trabaj = nvl(dias_trabaj,0) + nvl(ln_dias_trabaj,0) ,
      flag_estado = '1' ,
      prov_cts_01 = nvl(prov_cts_01,0) + nvl(ln_imp_01,0) ,
      prov_cts_02 = nvl(prov_cts_02,0) + nvl(ln_imp_02,0) ,
      prov_cts_03 = nvl(prov_cts_03,0) + nvl(ln_imp_03,0) , 
      prov_cts_04 = nvl(prov_cts_04,0) + nvl(ln_imp_04,0) ,
      prov_cts_05 = nvl(prov_cts_05,0) + nvl(ln_imp_05,0) ,
      prov_cts_06 = nvl(prov_cts_06,0) + nvl(ln_imp_06,0) ,
      flag_replicacion = '1'
  where cod_trabajador = as_codtra ;
else
  insert into prov_cts_gratif (
    cod_trabajador, dias_trabaj, flag_estado, prov_cts_01, prov_cts_02,
    prov_cts_03, prov_cts_04, prov_cts_05, prov_cts_06, flag_replicacion )
  values (
    as_codtra, ln_dias_trabaj, '1', nvl(ln_imp_01,0), nvl(ln_imp_02,0),
    nvl(ln_imp_03,0), nvl(ln_imp_04,0), nvl(ln_imp_05,0), nvl(ln_imp_06,0), '1' ) ;
end if ;

end usp_rh_calcula_provision_cts ;
/
