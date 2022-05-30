create or replace procedure usp_rh_liq_rpt_fondo_retiro (
  as_cod_trabajador in char ) is

ln_verifica           integer ;
ls_grupo              char(6) ;

ls_cod_grupo          char(6) ;
ls_cod_sub_grupo      char(6) ;

ln_des_ano            number(4) ;
ln_des_mes            number(2) ;
ln_des_dia            number(2) ;
ln_inc_ano            number(4) ;
ln_inc_mes            number(2) ;
ln_inc_dia            number(2) ;
ln_tot_ano            number(4) ;
ln_tot_mes            number(2) ;
ln_tot_dia            number(2) ;

--  Lectura de registros por grupos
cursor c_grupos is
  select te.cod_trabajador, te.cod_grupo, te.cod_sub_grupo, te.fec_desde, te.fec_hasta,
         te.tm_ef_liq_anos, te.tm_ef_liq_meses,  te.tm_ef_liq_dias, g.descripcion
  from rh_liq_tiempo_efectivo te, rh_liq_grupo g
  where te.cod_grupo = g.cod_grupo and
        te.cod_trabajador = as_cod_trabajador and te.cod_grupo = ls_grupo and
        nvl(g.flag_estado,'0') = '1'
  order by te.cod_grupo, te.cod_sub_grupo ;

--  Lectura de movimiento por fondo de retiro
cursor c_detalle is
  select f.concep, f.importe, f.imp_x_liq_anos, f.imp_x_liq_meses, f.imp_x_liq_dias,
         c.desc_concep
  from rh_liq_fondo_retiro f, concepto c
  where f.cod_trabajador = as_cod_trabajador and f.cod_grupo = ls_cod_grupo and
        f.cod_sub_grupo = ls_cod_sub_grupo and f.concep = c.concep
  order by f.concep ;
  
begin

--  *****************************************************************
--  ***   TEMPORAL PARA GENERAR LIQUIDACION POR FONDO DE RETIRO   ***
--  *****************************************************************

delete from tt_liq_rpt_fondo_retiro ;

select p.grp_fondo_retiro into ls_grupo from rh_liqparam p
  where p.reckey = '1' ;
    
for rc_grp in c_grupos loop

  ln_des_ano := 0 ; ln_des_mes := 0 ; ln_des_dia := 0 ;
  select count(*) into ln_verifica from ret_tiempo_servicio r
    where r.cod_trabajador = rc_grp.cod_trabajador and r.flag_tipo_oper = '1' ;
  if ln_verifica > 0 then    
    select sum(nvl(r.ano_retencion,0)), sum(nvl(r.mes_retencion,0)), sum(nvl(r.dias_retencion,0))
      into ln_des_ano, ln_des_mes, ln_des_dia
      from ret_tiempo_servicio r
      where r.cod_trabajador = rc_grp.cod_trabajador and r.flag_tipo_oper = '1' ;
  end if ;

  ln_inc_ano := 0 ; ln_inc_mes := 0 ; ln_inc_dia := 0 ;
  select count(*) into ln_verifica from ret_tiempo_servicio r
    where r.cod_trabajador = rc_grp.cod_trabajador and r.flag_tipo_oper = '2' ;
  if ln_verifica > 0 then    
    select sum(nvl(r.ano_retencion,0)), sum(nvl(r.mes_retencion,0)), sum(nvl(r.dias_retencion,0))
      into ln_inc_ano, ln_inc_mes, ln_inc_dia
      from ret_tiempo_servicio r
      where r.cod_trabajador = rc_grp.cod_trabajador and r.flag_tipo_oper = '2' ;
  end if ;

  --  Determina total de tiempo de servicio por fondo de retiro
  ln_tot_ano := nvl(rc_grp.tm_ef_liq_anos,0)  + nvl(ln_des_ano,0) - nvl(ln_inc_ano,0) ;
  ln_tot_mes := nvl(rc_grp.tm_ef_liq_meses,0) + nvl(ln_des_mes,0) - nvl(ln_inc_mes,0) ;
  ln_tot_dia := nvl(rc_grp.tm_ef_liq_dias,0)  + nvl(ln_des_dia,0) - nvl(ln_inc_dia,0) ;
  if ln_tot_dia > 30 then
    ln_tot_dia := ln_tot_dia - 30 ; ln_tot_mes := ln_tot_mes + 1 ;
  end if ;
  if ln_tot_mes > 12 then
    ln_tot_mes := ln_tot_mes - 12 ; ln_tot_ano := ln_tot_ano + 1 ;
  end if ;

  ls_cod_grupo     := rc_grp.cod_grupo ;
  ls_cod_sub_grupo := rc_grp.cod_sub_grupo ;

  for rc_det in c_detalle loop

    insert into tt_liq_rpt_fondo_retiro (
      cod_trabajador, cod_grupo, cod_sub_grupo, descripcion,
      fec_desde, fec_hasta, te_anos, te_meses,
      te_dias, des_ano, des_mes, des_dia, inc_ano, inc_mes,
      inc_dia, concepto, desc_concepto, importe, imp_ano,
      imp_mes, imp_dia, tot_ano, tot_mes, tot_dia )
    values (
      as_cod_trabajador, ls_cod_grupo, ls_cod_sub_grupo, rc_grp.descripcion,
      rc_grp.fec_desde, rc_grp.fec_hasta, rc_grp.tm_ef_liq_anos, rc_grp.tm_ef_liq_meses,
      rc_grp.tm_ef_liq_dias, ln_des_ano, ln_des_mes, ln_des_dia, ln_inc_ano, ln_inc_mes,
      ln_inc_dia, rc_det.concep, rc_det.desc_concep, rc_det.importe, rc_det.imp_x_liq_anos,
      rc_det.imp_x_liq_meses, rc_det.imp_x_liq_dias, ln_tot_ano, ln_tot_mes, ln_tot_dia ) ;

  end loop ;
  
end loop ;

end usp_rh_liq_rpt_fondo_retiro ;
/
