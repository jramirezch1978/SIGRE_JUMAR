create or replace procedure usp_rh_liq_comp_adicional (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_concepto            char(4) ;

--  Lectura de pago por compensacion adicional
cursor c_compensacion is
  select s.fec_registro, s.imp_total
  from rh_liq_saldos_cnta_crrte s
  where s.cod_trabajador = as_cod_trabajador and s.concep = ls_concepto
  order by s.cod_trabajador, s.concep ;

begin

--  *************************************************************************
--  ***   LIQUIDACION POR COMPENSACION ADICIONAL - ART.57 D.S.001-97-TR   ***
--  *************************************************************************

select p.cncp_comp_dic into ls_concepto from rh_liqparam p
  where p.reckey = '1' ;
  
for rc_com in c_compensacion loop

  select p.grp_indemnizacion into ls_grupo
    from rh_liqparam p where p.reckey = '1' ;
  select d.cod_sub_grupo into ls_sub_grupo
    from rh_liq_grupo_det d where d.cod_grupo = ls_grupo ;

  insert into rh_liq_tiempo_efectivo (
    cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
    tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo, ad_fec_liquidacion, rc_com.fec_registro,
    0, 0, 0 ) ;

  insert into rh_liq_dscto_leyes_aportes (
    cod_trabajador, cod_grupo, cod_sub_grupo,
    concep, importe )
  values (
    as_cod_trabajador, ls_grupo, ls_sub_grupo,
    ls_concepto, nvl(rc_com.imp_total,0) ) ;
  
end loop ;
  
end usp_rh_liq_comp_adicional ;
/
