create or replace procedure usp_rh_rpt_adelanto_cuenta_cts (
  as_tipo_trabajador in char, as_origen in char, ad_fec_desde in date,
  ad_fec_hasta in date ) is

ls_codigo            char(8) ;
ls_nombres           varchar2(40) ;
ln_verifica          integer ;
ln_sw                integer ;

ld_min_fecha         date ;
ld_max_fecha         date ;
ln_max_factor        number(9,6) ;
ln_fac_prdo          number(9,6) ;
ln_fac_emplear       number(9,6) ;
ln_deposito          number(13,2) ;
ln_interes           number(13,2) ;
ln_adelantos         number(13,2) ;
ln_int_adel          number(13,2) ;
ln_saldos            number(13,2) ;

--  Lectura del maestro de trabajadores
cursor c_maestro is
  select m.cod_trabajador
  from maestro m
  where m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_origen, m.tipo_trabajador, m.cod_trabajador ;

--  Cursor para halar saldo disponible
cursor c_saldos is
  select c.fec_prdo_dpsto, c.imp_prdo_dpsto
  from cnta_crrte_cts c
  where c.cod_trabajador = ls_codigo
  order by c.cod_trabajador, c.fec_prdo_dpsto ;
  
--  Cursor de adelantos a cuentas de C.T.S.
cursor c_cabecera is
  select a.cod_trabajador, a.nro_convenio, a.fec_proceso, a.imp_a_cuenta
  from adel_cnta_cts a
  where a.cod_trabajador = ls_codigo and nvl(a.imp_a_cuenta,0) <> 0 and
        trunc(a.fec_proceso) between ad_fec_desde and ad_fec_hasta
  order by a.cod_trabajador, a.fec_proceso ;

--  Cursor del detalle de adelantos a cuentas de C.T.S.
cursor c_detalle is
  select a.cod_trabajador, a.nro_convenio, a.fec_proceso, a.imp_a_cuenta
  from adel_cnta_cts a
  where a.cod_trabajador = ls_codigo and trunc(a.fec_proceso) < ad_fec_desde and
        nvl(a.imp_a_cuenta,0) <> 0
  order by a.cod_trabajador, a.fec_proceso ;

--  Lectura de adelantos a cuenta de C.T.S. para calculo de intereses
cursor c_adelantos is
  select a.fec_proceso, a.imp_a_cuenta
  from adel_cnta_cts a
  where a.cod_trabajador = ls_codigo
  order by a.cod_trabajador, a.fec_proceso ;
    
begin

--  *****************************************************
--  ***   ADELANTO A CUENTA DE C.T.S. CON CONVENIOS   ***
--  *****************************************************

delete from tt_rpt_adelanto_cuenta_cts ;

--  Determina factor de C.T.S. a la ultima fecha
ld_max_fecha := null ; ln_max_factor := 0 ;
select max(f.fec_calc_int) into ld_max_fecha from factor_planilla f ;
select nvl(f.fact_cts,0) into ln_max_factor from factor_planilla f
  where trunc(f.fec_calc_int) = trunc(ld_max_fecha) ;

--  Lectura del maestro de trabajadores
for rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_nombres := usf_rh_nombre_trabajador (ls_codigo) ;

  --  Verifica si tiene adelantos a cuenta de C.T.S.
  ln_verifica := 0 ;
  select count(*) into ln_verifica from adel_cnta_cts a
    where a.cod_trabajador = ls_codigo and
          trunc(a.fec_proceso) between ad_fec_desde and ad_fec_hasta ;

  if ln_verifica > 0 then

    ln_sw := 0 ;
    for rc_cab in c_cabecera loop
    
      ln_saldos := 0 ;
      if ln_sw = 0 then

        --  Verifica saldos disponible del 50% del trabajador
        ln_deposito := 0 ; ln_interes := 0 ;
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
          ln_fac_emplear := (nvl(ln_max_factor,0) / nvl(ln_fac_prdo,0)) - 1 ;
          ln_deposito    := ln_deposito + (nvl(rc_s.imp_prdo_dpsto,0) / 2 ) ;
          ln_interes     := ln_interes + (nvl(rc_s.imp_prdo_dpsto,0) / 2 * nvl(ln_fac_emplear,0)) ;
        end loop ;

        --  Determina adelantos a cuenta de C.T.S.
        ln_adelantos := 0 ; ln_int_adel := 0 ;
        for rc_ade in c_adelantos loop
          select nvl(f.fact_cts,0) into ln_fac_prdo from factor_planilla f
            where trunc(f.fec_calc_int) = trunc(rc_ade.fec_proceso) ;
          ln_fac_emplear  := (nvl(ln_max_factor,0) / nvl(ln_fac_prdo,0)) - 1 ;
          ln_adelantos    := ln_adelantos + nvl(rc_ade.imp_a_cuenta,0) ;
          ln_int_adel     := ln_int_adel + (nvl(rc_ade.imp_a_cuenta,0) * nvl(ln_fac_emplear,0)) ;
        end loop ;

        ln_saldos := (ln_deposito + ln_interes) - (ln_adelantos + ln_int_adel) ;
        ln_sw     := 1 ;

      end if ;

      --  Inserta registros con importes a cuenta de C.T.S.
      insert into tt_rpt_adelanto_cuenta_cts (
        flag, cod_trabajador, nro_convenio, nombres, fecha_cab,
        fecha_det, imp_cuenta, adelantos, saldos )
      values (
        '1', ls_codigo, rc_cab.nro_convenio, ls_nombres, rc_cab.fec_proceso,
        null, nvl(rc_cab.imp_a_cuenta,0), 0, nvl(ln_saldos,0) ) ;

    end loop ;
    
    --  Determina si existen adelantos anteriores de C.T.S.
    for rc_det in c_detalle loop

      insert into tt_rpt_adelanto_cuenta_cts (
        flag, cod_trabajador, nro_convenio, nombres, fecha_cab,
        fecha_det, imp_cuenta, adelantos, saldos )
      values (
        '2', ls_codigo, rc_det.nro_convenio, ls_nombres, null,
        rc_det.fec_proceso, 0, nvl(rc_det.imp_a_cuenta,0), 0 ) ;

    end loop ;

  end if ;          

end loop ;

end usp_rh_rpt_adelanto_cuenta_cts ;
/
