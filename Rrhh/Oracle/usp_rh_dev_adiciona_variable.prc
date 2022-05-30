create or replace procedure usp_rh_dev_adiciona_variable (
  as_codtra in char, ad_fec_proceso in date ) is

lk_dev_gra         char(3) ;
lk_dev_rem         char(3) ;
lk_dev_rac         char(3) ;
ln_contador        integer ;

--  Cursor de pagos de gratificaciones
cursor c_gratificacion is
  select md.concep, md.fec_pago, md.importe
  from mov_devengado md
  where md.cod_trabajador = as_codtra and md.concep in ( select g.concepto_gen
        from grupo_calculo g where g.grupo_calculo = lk_dev_gra ) ;

--  Cursor de pagos de remuneraciones
cursor c_remuneracion is
  select md.concep, md.fec_pago, md.importe
    from mov_devengado md
    where md.cod_trabajador = as_codtra and md.concep in ( select g.concepto_gen
          from grupo_calculo g where g.grupo_calculo = lk_dev_rem ) ;

--  Cursor de pagos por raciones de azucar
cursor c_racion_azucar is
  select md.concep, md.fec_pago, md.importe
    from mov_devengado md
    where md.cod_trabajador = as_codtra and md.concep in ( select g.concepto_gen
          from grupo_calculo g where g.grupo_calculo = lk_dev_rac ) ;

begin

--  **************************************************
--  ***   ADICIONA VARIABLES DE PAGOS DEVENGADOS   ***
--  **************************************************

select c.gratific_deveng, c.remun_deveng, c.rac_azucar_deveng
  into lk_dev_gra, lk_dev_rem, lk_dev_rac
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

for rc_gra in c_gratificacion loop

  ln_contador := 0 ;
  select count(*) into ln_contador from maestro_remun_gratif_dev grd
    where grd.cod_trabajador = as_codtra and grd.fec_calc_int = rc_gra.fec_pago
          and grd.concep in ( select g.concepto_gen from grupo_calculo g
          where g.grupo_calculo = lk_dev_gra ) ;

  if ln_contador > 0 then
    update maestro_remun_gratif_dev
      set adel_pago = adel_pago + nvl(rc_gra.importe,0),
         flag_replicacion = '1'
      where cod_trabajador = as_codtra and fec_calc_int = rc_gra.fec_pago and
            concep in ( select g.concepto_gen from grupo_calculo g
            where g.grupo_calculo = lk_dev_gra ) ;
  else
    insert into maestro_remun_gratif_dev (
      cod_trabajador, fec_calc_int, concep, flag_estado, fec_pago,
      fact_pago, fact_emplear, capital, imp_int_gen, imp_int_ant,
      adel_pago, nvo_capital,  nvo_interes, int_pagado, mont_pagado, flag_replicacion )
    values (
      as_codtra, ad_fec_proceso, rc_gra.concep, '1', rc_gra.fec_pago,
      0, 0, 0, 0, 0,
      rc_gra.importe, 0, 0, 0, 0, '1' ) ;
  end if ;

end loop ;

for rc_rem in c_remuneracion loop

  ln_contador := 0 ;
  select count(*) into ln_contador from maestro_remun_gratif_dev grd
    where grd.cod_trabajador = as_codtra and grd.fec_calc_int = rc_rem.fec_pago
          and grd.concep in ( select g.concepto_gen from grupo_calculo g
          where g.grupo_calculo = lk_dev_rem ) ;

  if ln_contador > 0 then
    update maestro_remun_gratif_dev
      set adel_pago = adel_pago + nvl(rc_rem.importe,0),
         flag_replicacion = '1'
      where cod_trabajador = as_codtra and fec_calc_int = rc_rem.fec_pago and
            concep in ( select g.concepto_gen from grupo_calculo g
            where g.grupo_calculo = lk_dev_rem ) ;
  else
    insert into maestro_remun_gratif_dev (
      cod_trabajador, fec_calc_int, concep, flag_estado, fec_pago,
      fact_pago, fact_emplear, capital, imp_int_gen, imp_int_ant,
      adel_pago, nvo_capital,  nvo_interes, int_pagado, mont_pagado, flag_replicacion )
    values (
      as_codtra, ad_fec_proceso, rc_rem.concep, '1', rc_rem.fec_pago,
      0, 0, 0, 0, 0,
      rc_rem.importe, 0, 0, 0, 0, '1' ) ;
  end if ;

end loop ;

for rc_rac in c_racion_azucar loop

  ln_contador := 0 ;
  select count(*) into ln_contador from mov_devengado md
    where md.cod_trabajador = as_codtra and md.fec_pago = rc_rac.fec_pago and
          md.concep in ( select g.concepto_gen from grupo_calculo g
          where g.grupo_calculo = lk_dev_rac ) ;

  if ln_contador > 0 then
    update racion_azucar_deveng
      set imp_pag_mes = imp_pag_mes + nvl(rc_rac.importe,0),
         flag_replicacion = '1'
      where cod_trabajador = as_codtra and fec_proceso = rc_rac.fec_pago ;
  else
    insert into racion_azucar_deveng (
      cod_trabajador, fec_proceso, imp_pag_mes,flag_replicacion )
    values (
      as_codtra, ad_fec_proceso, rc_rac.importe, '1' ) ;
  end if ;

end loop ;

end usp_rh_dev_adiciona_variable ;
/
