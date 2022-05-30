create or replace procedure usp_rh_liq_rpt_cts (
  as_cod_trabajador in char ) is

ls_grupo              char(6) ;
ls_cod_grupo          char(6) ;
ls_cod_sub_grupo      char(6) ;

--  Lectura de registros por grupos
cursor c_grupos is
  select te.cod_trabajador, te.cod_grupo, te.cod_sub_grupo, te.fec_desde, te.fec_hasta,
         te.tm_ef_liq_anos, te.tm_ef_liq_meses,  te.tm_ef_liq_dias, g.descripcion
  from rh_liq_tiempo_efectivo te, rh_liq_grupo g
  where te.cod_grupo = g.cod_grupo and
        te.cod_trabajador = as_cod_trabajador and te.cod_grupo = ls_grupo and
        nvl(g.flag_estado,'0') = '1'
  order by te.cod_grupo, te.cod_sub_grupo ;

--  Lectura de movimiento de compensacion por tiempo de servicio
cursor c_detalle is
  select c.periodo_ini, c.periodo_fin, c.deposito, c.factor, c.interes
  from rh_liq_cts c
  where c.cod_trabajador = as_cod_trabajador and c.cod_grupo = ls_cod_grupo and
        c.cod_sub_grupo = ls_cod_sub_grupo
  order by c.periodo_ini ;
  
begin

--  ********************************************************
--  ***   TEMPORAL PARA GENERAR LIQUIDACION POR C.T.S.   ***
--  ********************************************************

delete from tt_liq_rpt_cts ;

select p.grp_cts into ls_grupo from rh_liqparam p
  where p.reckey = '1' ;
    
for rc_grp in c_grupos loop

  ls_cod_grupo     := rc_grp.cod_grupo ;
  ls_cod_sub_grupo := rc_grp.cod_sub_grupo ;

  for rc_det in c_detalle loop

    insert into tt_liq_rpt_cts (
      cod_trabajador, cod_grupo, cod_sub_grupo, descripcion,
      fec_desde, fec_hasta, te_anos, te_meses,
      te_dias, prdo_ini, prdo_fin,
      deposito, factor, interes )
    values (
      as_cod_trabajador, ls_cod_grupo, ls_cod_sub_grupo, rc_grp.descripcion,
      rc_grp.fec_desde, rc_grp.fec_hasta, rc_grp.tm_ef_liq_anos, rc_grp.tm_ef_liq_meses,
      rc_grp.tm_ef_liq_dias, rc_det.periodo_ini, rc_det.periodo_fin,
      nvl(rc_det.deposito,0), nvl(rc_det.factor,0), nvl(rc_det.interes,0) ) ;

  end loop ;
  
end loop ;

end usp_rh_liq_rpt_cts ;
/
