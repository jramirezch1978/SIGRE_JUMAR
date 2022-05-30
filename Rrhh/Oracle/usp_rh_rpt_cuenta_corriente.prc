create or replace procedure usp_rh_rpt_cuenta_corriente (
  as_tipo_trabajador in char, as_origen in char, as_codigo in char,
  as_seccion in char, ad_fec_proceso in date ) is

ls_nombres            varchar2(60) ;
ls_dolar              char(3) ;
ln_imp_sol            number(13,2) ;
ln_des_sol            number(13,2) ;
ln_sal_sol            number(13,2) ;
ln_imp_dol            number(13,2) ;
ln_des_dol            number(13,2) ;
ln_sal_dol            number(13,2) ;

--  Lectura del movimiento de cuenta corriente
cursor c_movimiento is
  select cc.cod_trabajador, cc.tipo_doc, cc.nro_doc, cc.fec_prestamo, cc.concep,
         c.desc_concep, cc.nro_cuotas, cc.mont_original, cc.mont_cuota, cc.sldo_prestamo,
         cc.cod_sit_prest, cc.cod_moneda, m.tipo_trabajador, tt.desc_tipo_tra,
         m.cod_origen, o.nombre, m.cod_seccion, s.desc_seccion
  from cnta_crrte cc, maestro m, concepto c, tipo_trabajador tt, origen o, seccion s
  where cc.cod_trabajador = m.cod_trabajador and cc.concep = c.concep and
        m.tipo_trabajador = tt.tipo_trabajador and m.cod_origen = o.cod_origen and
        (m.cod_area = s.cod_area and m.cod_seccion = s.cod_seccion) and
        m.cod_trabajador like as_codigo and m.cod_seccion like as_seccion and
        m.tipo_trabajador like as_tipo_trabajador and m.cod_origen like as_origen and
        nvl(cc.flag_estado,'0') = '1' and nvl(cc.sldo_prestamo,0) > 0 and
        nvl(m.flag_estado,'0') = '1' and trunc(cc.fec_prestamo) <= ad_fec_proceso
  order by cc.cod_trabajador, cc.fec_prestamo, cc.concep ;

begin

--  ***********************************************************
--  ***   GENERA MOVIMIENTO DE SALDOS DE CUENTA CORRIENTE   ***
--  ***********************************************************

delete from tt_saldos_cuenta_corriente ;

select p.cod_dolares into ls_dolar from logparam p
  where p.reckey = '1' ;
  
for rc_mov in c_movimiento loop

  ls_nombres := usf_rh_nombre_trabajador(rc_mov.cod_trabajador) ;

  ln_imp_sol := 0 ; ln_des_sol := 0 ; ln_sal_sol := 0 ;
  ln_imp_dol := 0 ; ln_des_dol := 0 ; ln_sal_dol := 0 ;
  if rc_mov.cod_moneda = ls_dolar then
    ln_imp_dol := nvl(rc_mov.mont_original,0) ;
    ln_des_dol := nvl(rc_mov.mont_cuota,0) ;
    ln_sal_dol := nvl(rc_mov.sldo_prestamo,0) ;
  else
    ln_imp_sol := nvl(rc_mov.mont_original,0) ;
    ln_des_sol := nvl(rc_mov.mont_cuota,0) ;
    ln_sal_sol := nvl(rc_mov.sldo_prestamo,0) ;
  end if ;
  
  insert into tt_saldos_cuenta_corriente (
    fec_proceso, cod_origen, desc_origen, tipo_trabajador,
    desc_tipo_trabajador, cod_seccion, desc_seccion,
    cod_trabajador, nombres, dato, tipo_doc, nro_doc, fec_prestamo,
    concepto, desc_concepto, cod_sit_prestamo, nro_cuotas,
    cod_moneda, imp_sol, des_sol, sal_sol, imp_dol, des_dol,
    sal_dol )
  values (
    ad_fec_proceso, rc_mov.cod_origen, rc_mov.nombre, rc_mov.tipo_trabajador,
    rc_mov.desc_tipo_tra, rc_mov.cod_seccion, rc_mov.desc_seccion,
    rc_mov.cod_trabajador, ls_nombres, '1', rc_mov.tipo_doc, rc_mov.nro_doc, rc_mov.fec_prestamo,
    rc_mov.concep, rc_mov.desc_concep, rc_mov.cod_sit_prest, rc_mov.nro_cuotas,
    rc_mov.cod_moneda, ln_imp_sol, ln_des_sol, ln_sal_sol, ln_imp_dol, ln_des_dol,
    ln_sal_dol ) ;

end loop ;

end usp_rh_rpt_cuenta_corriente ;
/
