create or replace procedure usp_rh_liq_rpt_pago_remune (
  as_cod_trabajador in char ) is

ln_verifica           integer ;
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
  group by te.cod_trabajador, te.cod_grupo, te.cod_sub_grupo, g.descripcion ;

--  Lectura de movimiento de pagos de remuneraciones pendientes
cursor c_detalle is
  select r.fec_desde, r.fec_hasta, r.tm_ef_liq_anos, d.descripcion
  from rh_liq_remuneracion r, rh_liq_grupo_det d
  where r.cod_grupo = d.cod_grupo and r.cod_sub_grupo = d.cod_sub_grupo and
        r.cod_trabajador = as_cod_trabajador and r.cod_grupo = ls_cod_grupo and
        r.cod_sub_grupo = ls_cod_sub_grupo and nvl(d.flag_estado,'0') = '1'
  order by r.cod_trabajador, r.cod_grupo, r.cod_sub_grupo, r.fec_desde ;
  
begin

--  *********************************************************************
--  ***   TEMPORAL PARA GENERAR PAGOS POR REMUNERACIONES PENDIENTES   ***
--  *********************************************************************

delete from tt_liq_rpt_pago_remune ;

select p.grp_remuneracion into ls_grupo from rh_liqparam p
  where p.reckey = '1' ;
    
for rc_grp in c_grupos loop

  ls_cod_grupo     := rc_grp.cod_grupo ;
  ls_cod_sub_grupo := rc_grp.cod_sub_grupo ;

  for rc_det in c_detalle loop

    insert into tt_liq_rpt_pago_remune (
      cod_trabajador, cod_grupo, cod_sub_grupo, descripcion,
      desc_subgrp, fec_desde, fec_hasta, importe )
    values (
      as_cod_trabajador, ls_cod_grupo, ls_cod_sub_grupo, rc_grp.descripcion,
      rc_det.descripcion, rc_det.fec_desde, rc_det.fec_hasta, nvl(rc_det.tm_ef_liq_anos,0) ) ;

  end loop ;
  
end loop ;
ln_verifica := 0 ;
select count(*)
  into ln_verifica
  from tt_liq_rpt_pago_remune ;
  
end usp_rh_liq_rpt_pago_remune ;
/
