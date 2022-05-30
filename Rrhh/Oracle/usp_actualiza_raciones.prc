create or replace procedure usp_actualiza_raciones is

ln_contador      integer ;
ls_codigo        char(08) ;
ld_fec_saldo     date ;
ld_fec_proceso   date ;
ln_saldo_racion  number(13,2) ;
ln_pago_mensual  number(13,2) ;
ln_new_saldo     number(13,2) ;
ln_sw            integer ;
ls_origen        char(2) ;

--  Lee maestro de trabajadores
cursor c_maestro is
  select m.cod_trabajador
    from maestro m
    where m.flag_estado = '1' and m.flag_cal_plnlla = '1'
    order by m.cod_trabajador ;

--  Lee maestro de saldos de devengados
cursor c_saldos is
  select s.fec_proceso, s.sldo_racion
    from sldo_deveng s
    where s.cod_trabajador = ls_codigo and
          s.sldo_racion > 0
    order by s.fec_proceso ;
    
begin

select p.cod_origen
  into ls_origen
  from genparam p
  where p.reckey = '1' ;
  
select p.fec_proceso
  into ld_fec_proceso
  from rrhh_param_org p
  where p.origen = ls_origen ;
  
--select rh.fec_proceso
--  into ld_fec_proceso
--  from rrhhparam rh
--  where rh.reckey = '1' ;
  
for rc_mae in c_maestro loop

  ls_codigo := rc_mae.cod_trabajador ;
  ln_sw := 0 ; ln_new_saldo := 0 ; ln_saldo_racion := 0 ;

  for rc_sal in c_saldos loop
    ld_fec_saldo    := rc_sal.fec_proceso ;
    ln_saldo_racion := nvl(rc_sal.sldo_racion,0) ;
  end loop ;

<<x>>

  if ld_fec_saldo <= ld_fec_proceso then

    if ld_fec_saldo < ld_fec_proceso then
      ln_contador := 0 ; ln_pago_mensual := 0 ;
      select count(*)
        into ln_contador
        from historico_calculo hc
        where hc.cod_trabajador = ls_codigo and
              hc.concep = '1303' and
              hc.fec_calc_plan = ld_fec_saldo ;
             
      if ln_contador > 0 then
        select sum(nvl(hc.imp_soles,0))
          into ln_pago_mensual
          from historico_calculo hc
          where hc.cod_trabajador = ls_codigo and
                hc.concep = '1303' and
                hc.fec_calc_plan = ld_fec_saldo ;
      end if ;
    end if ;

    if ld_fec_saldo = ld_fec_proceso then
      ln_contador := 0 ; ln_pago_mensual := 0 ;
      select count(*)
        into ln_contador
        from calculo cal
        where cal.cod_trabajador = ls_codigo and
              cal.concep = '1303' and
              cal.fec_proceso = ld_fec_saldo ;
             
      if ln_contador > 0 then
        select sum(nvl(cal.imp_soles,0))
          into ln_pago_mensual
          from calculo cal
          where cal.cod_trabajador = ls_codigo and
                cal.concep = '1303' and
                cal.fec_proceso = ld_fec_saldo ;
      end if ;
    end if ;

    if ln_sw = 0 then
      ln_new_saldo := ln_saldo_racion - ln_pago_mensual ;
      ln_sw        := 1 ;
    else
      ln_new_saldo := ln_new_saldo - ln_pago_mensual ;
    end if ;

    --  Actualiza o inserta maestro de saldos devengados
    ln_contador := 0 ;
    select count(*)
      into ln_contador
      from sldo_deveng sd
      where sd.cod_trabajador = ls_codigo and
            sd.fec_proceso = ld_fec_saldo ;
    if ln_contador > 0 then
      update sldo_deveng
        set sldo_racion = ln_new_saldo
        where cod_trabajador = ls_codigo and
              fec_proceso = ld_fec_saldo ;
    else
      insert into sldo_deveng (
        cod_trabajador, fec_proceso, sldo_gratif_dev,
        sldo_rem_dev, sldo_racion )
      values (
        ls_codigo, ld_fec_saldo, 0,
        0, ln_new_saldo ) ;
    end if ;
      
    --  Actualiza o inserta racion de azucar devengados
    ln_contador := 0 ;
    select count(*)
      into ln_contador
      from racion_azucar_deveng ra
      where ra.cod_trabajador = ls_codigo and
            ra.fec_proceso = ld_fec_saldo ;
    if ln_contador > 0 then
      update racion_azucar_deveng
        set imp_pag_mes = ln_pago_mensual ,
            sldo_racion = ln_new_saldo
        where cod_trabajador = ls_codigo and
              fec_proceso = ld_fec_saldo ;
    else
      insert into racion_azucar_deveng (
        cod_trabajador, fec_proceso, imp_pag_mes, sldo_racion )
      values (
        ls_codigo, ld_fec_saldo, ln_pago_mensual, ln_new_saldo ) ;
    end if ;
    
    ld_fec_saldo := add_months(ld_fec_saldo, +1) ;
    goto x ;

  end if ;
  
end loop ;

end usp_actualiza_raciones ;
/
