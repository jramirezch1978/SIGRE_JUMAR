create or replace procedure usp_rh_liq_rpt_comp_adicional (
  as_cod_trabajador in char ) is

ls_grupo              char(6) ;
ls_cod_grupo          char(6) ;
ls_cod_sub_grupo      char(6) ;

--  Lectura de registros por grupos
cursor c_grupos is
  select te.cod_trabajador, te.cod_grupo, te.cod_sub_grupo, g.descripcion
  from rh_liq_tiempo_efectivo te, rh_liq_grupo g
  where te.cod_grupo = g.cod_grupo and
        te.cod_trabajador = as_cod_trabajador and te.cod_grupo = ls_grupo and
        nvl(g.flag_estado,'0') = '1'
  order by te.cod_grupo, te.cod_sub_grupo ;

--  Lectura de movimiento de compensacion adicional
cursor c_detalle is
  select l.concep, l.importe, c.desc_concep
  from rh_liq_dscto_leyes_aportes l, concepto c
  where l.cod_trabajador = as_cod_trabajador and l.cod_grupo = ls_cod_grupo and
        l.cod_sub_grupo = ls_cod_sub_grupo and l.concep = c.concep
  order by l.concep ;
  
begin

--  ************************************************************************
--  ***   TEMPORAL PARA GENERAR LIQUIDACION POR COMPENSACION ADICIONAL   ***
--  ************************************************************************

delete from tt_liq_rpt_comp_adicional ;

select p.grp_indemnizacion into ls_grupo from rh_liqparam p
  where p.reckey = '1' ;
    
for rc_grp in c_grupos loop

  ls_cod_grupo     := rc_grp.cod_grupo ;
  ls_cod_sub_grupo := rc_grp.cod_sub_grupo ;

  for rc_det in c_detalle loop

    insert into tt_liq_rpt_comp_adicional (
      cod_trabajador, cod_grupo, cod_sub_grupo, descripcion,
      concepto, desc_concepto, importe )
    values (
      as_cod_trabajador, ls_cod_grupo, ls_cod_sub_grupo, rc_grp.descripcion,
      rc_det.concep, rc_det.desc_concep, nvl(rc_det.importe,0) ) ;

  end loop ;
  
end loop ;

end usp_rh_liq_rpt_comp_adicional ;
/
