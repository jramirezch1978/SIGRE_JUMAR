create or replace procedure usp_rh_liq_descuento_leyes (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_verifica            integer ;
ls_snp                 char(3) ;
ls_jub                 char(3) ;
ls_inv                 char(3) ;
ls_com                 char(3) ;

ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_ind_vaca            char(6) ;
ls_cod_afp             char(2) ;

ls_concepto            char(4) ;
ls_concep_jub          char(4) ;
ls_concep_inv          char(4) ;
ls_concep_com          char(4) ;

ln_imp_remune          number(13,2) ;
ln_importe             number(13,2) ;
ln_imp_jub             number(13,2) ;
ln_imp_inv             number(13,2) ;
ln_imp_com             number(13,2) ;
ln_tope_inv            number(13,2) ;

ln_factor              number(9,6) ;
ln_fact_jub            number(4,2) ;
ln_fact_inv            number(4,2) ;
ln_fact_com            number(4,2) ;

ls_flag_comision_afp   maestro.flag_comision_afp%TYPE;

begin

--  ********************************************************
--  ***   LIQUIDACION POR DESCUENTOS DE LEYES SOCIALES   ***
--  ********************************************************

select p.grp_dscto_leyes, p.sgrp_indem_vac into ls_grupo, ls_ind_vaca
 from rh_liqparam p 
where p.reckey = '1' ;

select d.cod_sub_grupo into ls_sub_grupo 
from rh_liq_grupo_det d
  where d.cod_grupo = ls_grupo ;

ln_verifica := 0 ; ln_imp_remune := 0 ;
select count(*) into ln_verifica from rh_liq_remuneracion r
  where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo not in ls_ind_vaca ;
if ln_verifica > 0 then
  select sum(nvl(r.tm_ef_liq_anos,0)) into ln_imp_remune from rh_liq_remuneracion r
    where r.cod_trabajador = as_cod_trabajador and r.cod_sub_grupo not in ls_ind_vaca ;
end if ;

if nvl(ln_imp_remune,0) > 0 then

  select nvl(m.cod_afp,'00'), m.flag_comision_afp
    into ls_cod_afp, ls_flag_comision_afp
    from maestro m
    where m.cod_trabajador = as_cod_trabajador ;

  --  Realiza calculos por el Sistema Nacional de Pensiones
  if ls_cod_afp = '00' then

    select g.snp into ls_snp from rrhhparam_cconcep g
      where g.reckey = '1' ;
    select c.concepto_gen into ls_concepto from grupo_calculo c
      where c.grupo_calculo = ls_snp ;
    select nvl(c.fact_pago,0) into ln_factor from concepto c
      where c.concep = ls_concepto ;

    ln_importe := nvl(ln_imp_remune,0) * ln_factor ;

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
      ls_concepto, nvl(ln_importe,0) ) ;

  --  Realiza calculos de Administradora de Fondos de Pensiones
  else

    select p.afp_jubilacion, p.afp_invalidez, p.afp_comision
      into ls_jub, ls_inv, ls_com
      from rrhhparam_cconcep p where p.reckey = '1' ;

    select c.concepto_gen into ls_concep_jub from grupo_calculo c
      where c.grupo_calculo = ls_jub ;
    select c.concepto_gen into ls_concep_inv from grupo_calculo c
      where c.grupo_calculo = ls_inv ;
    select c.concepto_gen into ls_concep_com from grupo_calculo c
      where c.grupo_calculo = ls_com ;

    select nvl(a.porc_jubilac,0), nvl(a.porc_invalidez,0), DECODE(ls_flag_comision_afp, '1', nvl(a.porc_comision1,0), nvl(a.porc_comision2,0)),
           nvl(a.imp_tope_invalidez,0)
      into ln_fact_jub, ln_fact_inv, ln_fact_com,
           ln_tope_inv
      from admin_afp a where a.cod_afp = ls_cod_afp ;

    ln_imp_jub := nvl(ln_imp_remune,0) * ln_fact_jub / 100 ;
    if nvl(ln_imp_remune,0) > nvl(ln_tope_inv,0) then
      ln_imp_inv := nvl(ln_tope_inv,0) * ln_fact_inv / 100 ;
    else
      ln_imp_inv := nvl(ln_imp_remune,0) * ln_fact_inv / 100 ;
    end if ;
    ln_imp_com := nvl(ln_imp_remune,0) * ln_fact_com / 100 ;

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
      ls_concep_jub, nvl(ln_imp_jub,0) ) ;
    insert into rh_liq_dscto_leyes_aportes (
      cod_trabajador, cod_grupo, cod_sub_grupo,
      concep, importe )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo,
      ls_concep_inv, nvl(ln_imp_inv,0) ) ;
    insert into rh_liq_dscto_leyes_aportes (
      cod_trabajador, cod_grupo, cod_sub_grupo,
      concep, importe )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo,
      ls_concep_com, nvl(ln_imp_com,0) ) ;

  end if ;

end if ;

end usp_rh_liq_descuento_leyes ;
/
