create or replace procedure usp_rh_rpt_saldos_cts (
  ad_fec_proceso in date ) is

ln_sw                integer ;
ln_verifica          integer ;
ln_fac_proceso       number(9,6) ;
ls_codigo            char(8) ;
ls_nombres           varchar2(60) ;
ld_min_fecha         date ;
ln_fac_prdo          number(9,6) ;
ln_fac_emplear       number(9,6) ;
ln_deposito          number(13,2) ;
ln_deposito_50       number(13,2) ;
ln_interes           number(13,2) ;
ln_interes_50        number(13,2) ;
ln_adelantos         number(13,2) ;
ln_int_adel          number(13,2) ;
ln_saldos            number(13,2) ;
ln_saldos_50         number(13,2) ;

--  Lectura del maestro de trabajadores
cursor c_maestro is
  select m.cod_trabajador, m.flag_estado, m.fec_cese, m.cencos, cc.desc_cencos,
         m.cod_seccion, s.desc_seccion
  from maestro m, centros_costo cc, seccion s
  where m.cencos = cc.cencos and m.cod_area = s.cod_area and
        m.cod_seccion = s.cod_seccion
  order by m.cod_trabajador ;

--  Cursor para halar saldo disponible
cursor c_saldos is
  select c.fec_prdo_dpsto, c.imp_prdo_dpsto
  from cnta_crrte_cts c
  where c.cod_trabajador = ls_codigo
  order by c.cod_trabajador, c.fec_prdo_dpsto ;
  
--  Lectura de adelantos a cuenta de C.T.S. para calculo de intereses
cursor c_adelantos is
  select a.fec_proceso, a.imp_a_cuenta
  from adel_cnta_cts a
  where a.cod_trabajador = ls_codigo
  order by a.cod_trabajador, a.fec_proceso ;

begin

--  ********************************************************************
--  ***   REPORTE DE SALDOS DE COMPENSACION POR TIEMPO DE SERVICIO   ***
--  ********************************************************************

delete from tt_rh_rpt_saldos_cts ;

--  Determina factor de C.T.S. a la fecha de proceso
ln_verifica := 0 ; ln_fac_proceso := 0 ;
select count(*) into ln_verifica from factor_planilla f
  where trunc(f.fec_calc_int) = trunc(ad_fec_proceso) ;
if ln_verifica > 0 then
  select nvl(f.fact_cts,0) into ln_fac_proceso from factor_planilla f
    where trunc(f.fec_calc_int) = trunc(ad_fec_proceso) ;
else
  raise_application_error( -20000, 'No existe factor de C.T.S. al '||
                                   to_char(ad_fec_proceso,'dd/mm/yyyy') ) ;
end if ;

--  Lectura del personal activo o con fecha de cese menor a fecha de proceso
for rc_mae in c_maestro loop

  ln_sw := 0 ;
  if nvl(rc_mae.flag_estado,'0') = '0' then
    if trunc(ad_fec_proceso) > trunc(rc_mae.fec_cese) then
      ln_sw := 1 ;
    end if ;
  end if ;
  
  if ln_sw = 0 then

    ls_codigo  := rc_mae.cod_trabajador ;
    ls_nombres := usf_nombre_trabajador(ls_codigo) ;

    --  Verifica saldos disponible del 50% del trabajador
    ln_deposito    := 0 ; ln_interes    := 0 ;
    ln_deposito_50 := 0 ; ln_interes_50 := 0 ;
    for rc_s in c_saldos loop
      ln_verifica := 0 ;
      select count(*) into ln_verifica from factor_planilla f
        where trunc(f.fec_calc_int) = (trunc(rc_s.fec_prdo_dpsto) - 1) ;
      if ln_verifica > 0 then
        select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
          where trunc(f.fec_calc_int) = (trunc(rc_s.fec_prdo_dpsto) - 1) ;
      else
        select min(f.fec_calc_int) into ld_min_fecha from factor_planilla f ;
        select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
          where trunc(f.fec_calc_int) = trunc(ld_min_fecha) ;
      end if ;
      ln_fac_emplear := (nvl(ln_fac_proceso,0) / nvl(ln_fac_prdo,0)) - 1 ;
      ln_deposito    := ln_deposito + nvl(rc_s.imp_prdo_dpsto,0) ;
      ln_interes     := ln_interes + (nvl(rc_s.imp_prdo_dpsto,0) * nvl(ln_fac_emplear,0)) ;
      ln_deposito_50 := ln_deposito_50 + (nvl(rc_s.imp_prdo_dpsto,0) / 2 ) ;
      ln_interes_50  := ln_interes_50 + (nvl(rc_s.imp_prdo_dpsto,0) / 2 * nvl(ln_fac_emplear,0)) ;
    end loop ;

    --  Determina adelantos a cuenta de C.T.S.
    ln_adelantos := 0 ; ln_int_adel := 0 ;
    for rc_ade in c_adelantos loop
      select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
        where trunc(f.fec_calc_int) = trunc(rc_ade.fec_proceso) ;
      ln_fac_emplear  := (nvl(ln_fac_proceso,0) / nvl(ln_fac_prdo,0)) - 1 ;
      ln_adelantos    := ln_adelantos + nvl(rc_ade.imp_a_cuenta,0) ;
      ln_int_adel     := ln_int_adel + (nvl(rc_ade.imp_a_cuenta,0) * nvl(ln_fac_emplear,0)) ;
    end loop ;

    --  Determina saldos de C.T.S.
    ln_saldos    := (ln_deposito + ln_interes) - (ln_adelantos + ln_int_adel) ;
    ln_saldos_50 := (ln_deposito_50 + ln_interes_50) - (ln_adelantos + ln_int_adel) ;

    --  Genera saldos de C.T.S. por trabajador para emitir reporte
    if nvl(ln_saldos,0) <> 0 then
      insert into tt_rh_rpt_saldos_cts (
        fec_proceso, codigo, nombres, cencos, desc_cencos,
        seccion, desc_seccion, deposito, interes, adelanto,
        int_adelanto, saldo, saldo_50 )
      values (
        ad_fec_proceso, ls_codigo, ls_nombres, rc_mae.cencos, rc_mae.desc_cencos,
        rc_mae.cod_seccion, rc_mae.desc_seccion, ln_deposito, ln_interes, ln_adelantos,
        ln_int_adel, ln_saldos, ln_saldos_50 ) ;
    end if ;
      
  end if ;

end loop ;

end usp_rh_rpt_saldos_cts ;
/
