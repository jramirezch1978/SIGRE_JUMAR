create or replace procedure usp_rh_calcula_fondo_retiro (
  as_codtra in char, ad_fec_proceso in date ) is

lk_gan_fij           char(3) ;
lk_nivel             char(3) ;
lk_racion_cocida     char(3) ;
lk_grat_julio        char(3) ;
lk_grat_diciembre    char(3) ;

ln_ano_descto        number(4) ;
ln_mes_descto        number(2) ;
ln_dia_descto        number(2) ;
ln_ano_increm        number(4) ;
ln_mes_increm        number(2) ;
ln_dia_increm        number(2) ;

ln_contador          integer ;
ln_num_mes           integer ;
ls_situacion         char(1) ;
ls_bonificacion      char(1) ;
ls_seccion           char(3) ;
ls_concepto          char(4) ;
ls_year              char(4) ;
ld_fec_ingreso       date ;
ld_ran_ini           date ;
ld_ran_fin           date ;
ld_fec_gratif        date ;

ln_telano            number(2) ;
ln_telmes            number(2) ;
ln_teldia            number(2) ;
ln_imp_soles         number(13,2) ;
ln_imp_racion        number(13,2) ;
ln_imp_variable      number(13,2) ;
ln_acum_sobret       number(13,2) ;
ln_prom_sobret       number(13,2) ;
ln_imp_gratif        number(13,2) ;
ln_imp_soles_ano     number(13,2) ;
ln_imp_soles_mes     number(13,2) ;
ln_imp_soles_dia     number(13,2) ;

--  Lectura de ganancias fijas por trabajador
cursor c_ganancias is
  select gdf.concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
        gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                        where d.grupo_calculo = lk_gan_fij ) ;

--  Lectura de conceptos para promedios de sobretiempos
cursor c_conceptos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = lk_nivel ;

begin

--  *********************************************************************
--  ***   CALCULO DE TIEMPO DE SERVICIO AL 31 DE DICIEMBRE DE 1,994   ***
--  ***      EL CALCULO SE REALIZA SOLO PARA TRABAJADORES SOCIOS      ***
--  *********************************************************************

select p.prom_remun_vacac, p.calculo_racion_cocida, p.grati_medio_ano,
       p.grati_fin_ano, p.ganfij_provision_fond_ret
  into lk_nivel, lk_racion_cocida, lk_grat_julio,
       lk_grat_diciembre, lk_gan_fij
  from rrhhparam_cconcep p where p.reckey = '1' ;

ln_ano_descto    := 0 ; ln_mes_descto    := 0 ; ln_dia_descto    := 0 ;
ln_ano_increm    := 0 ; ln_mes_increm    := 0 ; ln_dia_increm    := 0 ;
ln_imp_soles_ano := 0 ; ln_imp_soles_mes := 0 ; ln_imp_soles_dia := 0 ;

--  Determina datos del maestro de trabajadores
select m.situa_trabaj, nvl(m.bonif_fija_30_25,'0'), m.cod_seccion, m.fec_ingreso
  into ls_situacion, ls_bonificacion, ls_seccion, ld_fec_ingreso
  from maestro m
  where m.cod_trabajador = as_codtra ;

if ls_situacion = 'S' then

  --  Determina retencion por tiempo de servicio
  ln_contador := 0 ;
  select count(*) into ln_contador from ret_tiempo_servicio rts
    where rts.cod_trabajador = as_codtra and rts.flag_tipo_oper = '1' ;
  if ln_contador > 0 then
    select sum(nvl(rts.ano_retencion,0)), sum(nvl(rts.mes_retencion,0)),
           sum(nvl(rts.dias_retencion,0))
      into ln_ano_descto, ln_mes_descto, ln_dia_descto
      from ret_tiempo_servicio rts
      where rts.cod_trabajador = as_codtra and rts.flag_tipo_oper = '1' ;
  end if;
  ln_contador := 0 ;
  select count(*) into ln_contador from ret_tiempo_servicio rts
    where rts.cod_trabajador = as_codtra and rts.flag_tipo_oper = '2' ;
  if ln_contador > 0 then
    select sum(nvl(rts.ano_retencion,0)), sum(nvl(rts.mes_retencion,0)),
           sum(nvl(rts.dias_retencion,0))
      into ln_ano_increm, ln_mes_increm, ln_dia_increm
      from ret_tiempo_servicio rts
      where rts.cod_trabajador = as_codtra and rts.flag_tipo_oper = '2' ;
  end if;

  --  Determina el tiempo efectivo de liquidacion
  ln_telano := 1994 - nvl(to_number(to_char(ld_fec_ingreso,'yyyy')),0) ;
  ln_telmes := 12   - nvl(to_number(to_char(ld_fec_ingreso,'mm')),0) ;
  ln_teldia := 31   - nvl(to_number(to_char(ld_fec_ingreso,'dd')),0) ;
  ln_telano := ln_telano - ln_ano_descto + ln_ano_increm ;
  ln_telmes := ln_telmes - ln_mes_descto + ln_mes_increm ;
  ln_teldia := ln_teldia - ln_dia_descto + ln_dia_increm ;

  --  Calcula ganancias fijas
  ln_imp_soles := 0 ; ln_imp_racion := 0 ;
  for rc_gan in c_ganancias loop
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_racion_cocida ;
    if rc_gan.concep = ls_concepto then
      ln_imp_racion := nvl(rc_gan.imp_gan_desc,0) ;
    else
      ln_imp_soles := ln_imp_soles + nvl(rc_gan.imp_gan_desc,0) ;
    end if ;
  end loop ;

  --  Calcula promedio de sobretiempos de los ultimos seis meses
  ln_prom_sobret := 0 ;
  for rc_con in c_conceptos loop
    ld_ran_ini := add_months(ad_fec_proceso, - 1) ;
    ln_num_mes := 0 ; ln_acum_sobret := 0 ;
    for x in reverse 1 .. 6 loop
      ld_ran_fin := ld_ran_ini ;
      ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
      ln_contador := 0 ; ln_imp_variable := 0 ;
      select count(*)
        into ln_contador from historico_calculo hc
        where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = as_codtra and
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
      if ln_contador > 0 then
        select sum(nvl(hc.imp_soles,0))
          into ln_imp_variable from historico_calculo hc
          where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = as_codtra and
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
  ln_imp_soles := ln_imp_soles + ln_prom_sobret ;

  --  Calcula bonificacion del 30% o 25%
  if ls_bonificacion = '1' then
      ln_imp_soles := ln_imp_soles + (ln_imp_soles * 0.30) ;
  elsif ls_bonificacion = '2' then
      ln_imp_soles := ln_imp_soles + (ln_imp_soles * 0.25) ;
  end if ;
  ln_imp_soles := ln_imp_soles + ln_imp_racion ;

  --  Halla promedio de la ultima gratificacion
  if to_number(to_char(ad_fec_proceso,'mm')) < 07 then
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_grat_diciembre ;
    ls_year := to_char(to_number(to_char(ad_fec_proceso,'yyyy')) - 1) ;
    ld_fec_gratif := to_date('31'||'/'||'12'||'/'||ls_year,'dd/mm/yyyy') ;
  elsif to_number(to_char(ad_fec_proceso,'mm')) = 07 or
        to_number(to_char(ad_fec_proceso,'mm')) < 12 then
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_grat_julio ;
    ls_year := to_char (ad_fec_proceso,'yyyy') ;
    ld_fec_gratif := to_date('31'||'/'||'07'||'/'||ls_year,'dd/mm/yyyy') ;
  elsif to_number(to_char(ad_fec_proceso,'mm')) = 12 then
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_grat_julio ;
    ls_year := to_char(ad_fec_proceso,'yyyy') ;
    ld_fec_gratif := to_date('31'||'/'||'07'||'/'||ls_year,'dd/mm/yyyy') ;
  end if ;
  ln_contador := 0 ; ln_imp_gratif := 0 ;
  select count(*) into ln_contador from historico_calculo hc
    where hc.concep = ls_concepto and hc.cod_trabajador = as_codtra and
          hc.fec_calc_plan = ld_fec_gratif ;
  if ln_contador > 0 then
    select sum(nvl(hc.imp_soles,0)) into ln_imp_gratif from historico_calculo hc
      where hc.concep = ls_concepto and hc.cod_trabajador = as_codtra and
            hc.fec_calc_plan = ld_fec_gratif ;
  end if ;
  ln_imp_soles := ln_imp_soles + (ln_imp_gratif / 6) ;

  --  Calcula fondo de retiro a la fecha
  ln_imp_soles_ano := ln_imp_soles * ln_telano ;
  ln_imp_soles_mes := (ln_imp_soles / 12) * ln_telmes ;
  ln_imp_soles_dia := (ln_imp_soles / 360) * ln_teldia ;
  ln_imp_soles     := ln_imp_soles_ano + ln_imp_soles_mes + ln_imp_soles_dia ;

  --  Graba registro por fondo de retiro
  if ln_imp_soles > 0 then
    insert into fondo_retiro (
      cod_trabajador, fec_proceso, flag_estado, importe, flag_replicacion )
    values (
      as_codtra, ad_fec_proceso, '1', ln_imp_soles, '1' ) ;
  end if ;

end if ;

end usp_rh_calcula_fondo_retiro ;
/
