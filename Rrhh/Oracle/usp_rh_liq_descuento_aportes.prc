create or replace procedure usp_rh_liq_descuento_aportes (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_verifica            integer ;
ls_seg_agrario         char(3) ;
ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_concepto            char(4) ;
ln_imp_remune          number(13,2) ;
ln_importe             number(13,2) ;
ln_factor              number(9,6) ;

begin

--  ************************************************
--  ***   LIQUIDACION DE APORTACIONES SOCIALES   ***
--  ************************************************

select p.grp_aportacion into ls_grupo from rh_liqparam p 
  where p.reckey = '1' ;
select d.cod_sub_grupo into ls_sub_grupo from rh_liq_grupo_det d
  where d.cod_grupo = ls_grupo ;
  
ln_verifica := 0 ; ln_imp_remune := 0 ;
select count(*) into ln_verifica from rh_liq_remuneracion r
  where r.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then
  select sum(nvl(r.tm_ef_liq_anos,0)) into ln_imp_remune from rh_liq_remuneracion r
    where r.cod_trabajador = as_cod_trabajador ;
end if ;  

if nvl(ln_imp_remune,0) > 0 then

  select g.concep_seguro_agrario into ls_seg_agrario from rrhhparam_cconcep g 
    where g.reckey = '1' ;
  select c.concepto_gen into ls_concepto from grupo_calculo c
    where c.grupo_calculo = ls_seg_agrario ;
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

end if ;
  
end usp_rh_liq_descuento_aportes ;
/
