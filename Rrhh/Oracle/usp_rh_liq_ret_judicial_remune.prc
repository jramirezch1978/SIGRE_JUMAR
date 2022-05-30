create or replace procedure usp_rh_liq_ret_judicial_remune (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_verifica            integer ;
ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_grp_calculo         char(3) ;
ls_grp_leysoc          char(6) ;
ls_concepto            char(4) ;
ln_retencion           number(5,2) ;
ln_imp_judicial        number(13,2) ;
ln_importe             number(13,2) ;
ln_imp_leyes           number(13,2) ;

begin

--  ***************************************************************
--  ***   DESCUENTOS POR RETENCION JUDICIAL DE REMUNERACIONES   ***
--  ***************************************************************

select p.grp_dscto_remun, p.grp_dscto_leyes into ls_grupo, ls_grp_leysoc
  from rh_liqparam p where p.reckey = '1' ;
select d.cod_sub_grupo into ls_sub_grupo from rh_liq_grupo_det d
  where d.cod_grupo = ls_grupo ;
  
select c.calc_judic into ls_grp_calculo from rrhhparam_cconcep c
  where c.reckey = '1' ;
select c.concepto_gen into ls_concepto from grupo_calculo c
  where c.grupo_calculo = ls_grp_calculo ;

ln_verifica := 0 ; ln_retencion := 0 ;
select count(*) into ln_verifica from rh_liq_retencion_judicial j
  where j.cod_trabajador = as_cod_trabajador and
        (nvl(j.flag_reten_jud,'0') = '2' or nvl(j.flag_reten_jud,'0') = '3') ;
if ln_verifica > 0 then
  select nvl(j.reten_jud,0) into ln_retencion from rh_liq_retencion_judicial j
    where j.cod_trabajador = as_cod_trabajador and
          (nvl(j.flag_reten_jud,'0') = '2' or nvl(j.flag_reten_jud,'0') = '3') ;
else
  ln_verifica := 0 ; ln_retencion := 0 ;
  select count(*) into ln_verifica from maestro m
    where m.cod_trabajador = as_cod_trabajador ;
  if ln_verifica > 0 then
    select nvl(m.porc_judicial,0) into ln_retencion from maestro m
      where m.cod_trabajador = as_cod_trabajador ;
  end if ;
end if ;

if nvl(ln_retencion,0) > 0 then

  ln_verifica := 0 ; ln_importe := 0 ; ln_imp_leyes := 0 ;
  select count(*) into ln_verifica from rh_liq_remuneracion r
    where r.cod_trabajador = as_cod_trabajador ;

  if ln_verifica > 0 then

    select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe
      from rh_liq_remuneracion r where r.cod_trabajador = as_cod_trabajador ;
    
    select sum(nvl(d.importe,0)) into ln_imp_leyes
      from rh_liq_dscto_leyes_aportes d
      where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_leysoc ;

    ln_imp_judicial := (ln_importe - ln_imp_leyes) * nvl(ln_retencion,0) / 100 ;
  
    if nvl(ln_imp_judicial,0) > 0 then
      insert into rh_liq_tiempo_efectivo (
        cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
        tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
      values (
        as_cod_trabajador, ls_grupo, ls_sub_grupo, ad_fec_liquidacion, ad_fec_liquidacion,
        0, 0, 0 ) ;
      insert into rh_liq_dscto_leyes_aportes (
        cod_trabajador, cod_grupo, cod_sub_grupo,
        concep, importe )
      values (
        as_cod_trabajador, ls_grupo, ls_sub_grupo,
        ls_concepto, nvl(ln_imp_judicial,0) ) ;
    end if ;

  end if ;

end if ;
  
end usp_rh_liq_ret_judicial_remune ;
/
