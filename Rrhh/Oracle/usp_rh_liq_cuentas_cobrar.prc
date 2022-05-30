create or replace procedure usp_rh_liq_cuentas_cobrar (
  as_cod_trabajador in char, ad_fec_liquidacion in date ) is

ln_sw                  integer ;
ln_verifica            integer ;
ls_grupo               char(6) ;
ls_sub_grupo           char(6) ;
ls_concepto            char(4) ;

--  Lectura de saldos de cuentas por cobrar
cursor c_saldos is
  select s.concep, s.imp_total
  from rh_liq_saldos_cnta_crrte s
  where s.cod_trabajador = as_cod_trabajador and s.concep <> ls_concepto and
        nvl(s.flag_estado,'0') = '1'
  order by s.item ;
  
begin

--  *****************************************************************
--  ***   DESCUENTOS DE CUENTA CORRIENTE ( CUENTAS POR COBRAR )   ***
--  *****************************************************************

select p.grp_dscto_cta_cte, p.sgrp_cnta_cobrar, p.cncp_comp_dic
  into ls_grupo, ls_sub_grupo, ls_concepto
  from rh_liqparam p where p.reckey = '1' ;

ln_sw := 0 ;
for rc_sal in c_saldos loop

  if ln_sw = 0 then
    ln_sw := 1 ;
    insert into rh_liq_tiempo_efectivo (
      cod_trabajador, cod_grupo, cod_sub_grupo, fec_desde, fec_hasta,
      tm_ef_liq_anos, tm_ef_liq_meses, tm_ef_liq_dias )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo, ad_fec_liquidacion, ad_fec_liquidacion,
      0, 0, 0 ) ;
  end if ;
  
  ln_verifica := 0 ;
  select count(*) into ln_verifica
    from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grupo and
          d.cod_sub_grupo = ls_sub_grupo and d.concep = rc_sal.concep ;
  
  if ln_verifica > 0 then
    update rh_liq_dscto_leyes_aportes d
      set d.importe = d.importe + nvl(rc_sal.imp_total,0)
      where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grupo and
            d.cod_sub_grupo = ls_sub_grupo and d.concep = rc_sal.concep ;
  else
    insert into rh_liq_dscto_leyes_aportes (
      cod_trabajador, cod_grupo, cod_sub_grupo,
      concep, importe )
    values (
      as_cod_trabajador, ls_grupo, ls_sub_grupo,
      rc_sal.concep, nvl(rc_sal.imp_total,0) ) ;
  end if ;

end loop ;

end usp_rh_liq_cuentas_cobrar ;
/
