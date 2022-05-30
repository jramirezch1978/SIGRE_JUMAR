create or replace procedure usp_rh_calcula_provision_gra (
  as_codtra in char, ad_fec_proceso in date ) is

lk_ganancia_fija     char(3) ;
lk_sobretiempos      char(3) ;
ln_diatra            constant number(5,2) := 30 ;

ls_bonificacion      char(1) ;
ls_cod_seccion       char(3) ;
ls_mes_proceso       char(2) ;
ld_ran_inicio        date ;
ld_ran_final         date ;
ln_nro_meses         integer ;
ln_contador          integer ;
ln_promedio_sob      number(13,2) ;
ln_acum_sob          number(13,2) ;
ln_importe           number(13,2) ;
ln_imp_soles         number(13,2) ;
ln_imp_acumu         number(13,2) ;
ln_prov_mes          number(13,2) ;
ln_meses             number(2) ;

--  Sobretiempos afectos a la provision de gratificacion
cursor c_sobretiempos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = lk_sobretiempos ;

begin

--  *************************************************************
--  ***   REALIZA CALCULO DE PROVISIONES DE GRATIFICACIONES   ***
--  *************************************************************

select c.ganfij_provision_gratif, c.prom_remun_vacac
  into lk_ganancia_fija, lk_sobretiempos
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select nvl(m.bonif_fija_30_25,'0'), m.cod_seccion
  into ls_bonificacion, ls_cod_seccion from maestro m
  where m.cod_trabajador = as_codtra ;

if ls_cod_seccion = '950' then
  return ;
end if ;

--  Acumula ganancias fijas por trabajador
ln_imp_soles := 0 ;
select sum(nvl(gdf.imp_gan_desc,0)) into ln_imp_soles from gan_desct_fijo gdf
  where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
        gdf.concep in ( select d.concepto_calc from grupo_calculo_det d where
                        d.grupo_calculo = lk_ganancia_fija ) ;

--  Acumula promedios de sobretiempos de los ultimos seis meses
ln_promedio_sob := 0 ;
for rc_sob in c_sobretiempos loop
  ld_ran_inicio := add_months(ad_fec_proceso, - 1) ;
  ln_nro_meses  := 0 ; ln_acum_sob := 0 ;
  for x in reverse 1 .. 6 loop
    ld_ran_final  := ld_ran_inicio ;
    ld_ran_inicio := add_months( ld_ran_final, -1 ) + 1 ;
    ln_contador   := 0 ; ln_importe := 0 ;
    select count(*) into ln_contador from historico_calculo hc
      where hc.concep = rc_sob.concepto_calc and hc.cod_trabajador = as_codtra and
            hc.fec_calc_plan between ld_ran_inicio and ld_ran_final ;
    if ln_contador > 0 then
      select sum(nvl(hc.imp_soles,0)) into ln_importe from historico_calculo hc
        where hc.concep = rc_sob.concepto_calc and hc.cod_trabajador = as_codtra and
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

ln_imp_soles := ln_imp_soles + ln_promedio_sob ;

--  Incrementa el 30% o 25% segun condicion
if ls_bonificacion = '1' then
  ln_imp_soles := ln_imp_soles * 1.30 ;
elsif ls_bonificacion = '2' then
  ln_imp_soles := ln_imp_soles * 1.25 ;
end if ;

--  Halla provisiones acumuladas a la fecha
ls_mes_proceso := to_char ( ad_fec_proceso,'mm') ;
ln_meses := to_char ( to_number(ls_mes_proceso) - 1 ) ;
ln_imp_acumu := 0 ;
if ls_mes_proceso = '01' then
  ln_imp_acumu := 0 ;
else
  for x in 1 .. ln_meses loop
    ln_prov_mes := 0 ;
    if x = 1 then
      select nvl(pcg.prov_gratif_01,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 2 then
      select nvl(pcg.prov_gratif_02,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 3 then
      select nvl(pcg.prov_gratif_03,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 4 then
      select nvl(pcg.prov_gratif_04,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 5 then
      select nvl(pcg.prov_gratif_05,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 6 then
      select nvl(pcg.prov_gratif_06,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 7 then
      select nvl(pcg.prov_gratif_07,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 8 then
      select nvl(pcg.prov_gratif_08,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 9 then
      select nvl(pcg.prov_gratif_09,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 10 then
      select nvl(pcg.prov_gratif_10,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 11 then
      select nvl(pcg.prov_gratif_11,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    elsif x = 12 then
      select nvl(pcg.prov_gratif_12,0)
      into ln_prov_mes from prov_cts_gratif pcg
      where pcg.cod_trabajador = as_codtra ;
    end if ;
    ln_imp_acumu := ln_imp_acumu + ln_prov_mes ;
  end loop ;
end if ;
ln_meses := ln_meses + 1 ;
ln_imp_soles := (((ln_imp_soles * 2) / 12) * ln_meses) - ln_imp_acumu ;

ln_contador := 0 ;
select count(*) into ln_contador from prov_cts_gratif p
  where p.cod_trabajador = as_codtra ;

if ln_contador > 0 then
  if ls_mes_proceso = '01' then
    update prov_cts_gratif
      set prov_gratif_01 = ln_imp_soles,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra;
  elsif ls_mes_proceso = '02' then
    update prov_cts_gratif
      set prov_gratif_02 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '03' then
    update prov_cts_gratif
      set prov_gratif_03 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '04' then
    update prov_cts_gratif
      set prov_gratif_04 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '05' then
    update prov_cts_gratif
      set prov_gratif_05 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '06' then
    update prov_cts_gratif
      set prov_gratif_06 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '07' then
    update prov_cts_gratif
      set prov_gratif_07 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '08' then
    update prov_cts_gratif
      set prov_gratif_08 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '09' then
    update prov_cts_gratif
      set prov_gratif_09 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '10' then
    update prov_cts_gratif
      set prov_gratif_10 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '11' then
    update prov_cts_gratif
      set prov_gratif_11 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  elsif ls_mes_proceso = '12' then
    update prov_cts_gratif
      set prov_gratif_12 = ln_imp_soles ,
         flag_replicacion = '1'
      where cod_trabajador = as_codtra ;
  end if ;
else
  if ls_mes_proceso = '01' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_01, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '02' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_02, flag_replicacion  )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '03' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_03, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '04' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_04, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, 1 ) ;
  elsif ls_mes_proceso = '05' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_05, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '06' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_06, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '07' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_07, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '08' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_08, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '09' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_09, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '10' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_10, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '11' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_11, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  elsif ls_mes_proceso = '12' then
    insert into prov_cts_gratif
      ( cod_trabajador, dias_trabaj, flag_estado, prov_gratif_12, flag_replicacion )
    values
      ( as_codtra, ln_diatra, '1', ln_imp_soles, '1' ) ;
  end if ;
end if ;

end usp_rh_calcula_provision_gra ;
/
