create or replace procedure usp_rh_dev_adiciona (
  as_codtra in char, ad_fec_proceso in date ) is

lk_dev_gra         char(3) ;
lk_dev_rem         char(3) ;
lk_dev_rac         char(3) ;

--  Cursor de pagos por gratificaciones
cursor c_gratificacion is
  select c.concep, c.fec_proceso, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra and c.concep in (
        select g.concepto_gen from grupo_calculo g
        where g.grupo_calculo = lk_dev_gra ) ;

--  Cursor de pagos por remuneraciones
cursor c_remuneracion is
  select c.concep, c.fec_proceso, c.imp_soles
    from calculo c
    where c.cod_trabajador = as_codtra and c.concep in (
          select g.concepto_gen from grupo_calculo g
          where g.grupo_calculo = lk_dev_rem ) ;

--  Cursor de pagos por raciones de azucar
cursor c_racion_azucar is
  select c.imp_soles
    from calculo c
    where c.cod_trabajador = as_codtra and c.concep in (
          select g.concepto_gen from grupo_calculo g
          where g.grupo_calculo = lk_dev_rac ) ;

begin

--  ****************************************************
--  ***   ADICIONA PAGOS DEVENGADOS DE LA PLANILLA   ***
--  ****************************************************

select c.gratific_deveng, c.remun_deveng, c.rac_azucar_deveng
  into lk_dev_gra, lk_dev_rem, lk_dev_rac
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

for rc_gra in c_gratificacion loop
  insert into maestro_remun_gratif_dev (
    cod_trabajador, fec_calc_int, concep, flag_estado, fec_pago,
    fact_pago, fact_emplear, capital, imp_int_gen, imp_int_ant,
    adel_pago, nvo_capital, nvo_interes, int_pagado, mont_pagado, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, rc_gra.concep, '1', rc_gra.fec_proceso,
    0, 0, 0, 0, 0,
    rc_gra.imp_soles, 0, 0, 0, 0, '1' ) ;
end loop ;

for rc_rem in c_remuneracion loop
  insert into maestro_remun_gratif_dev (
    cod_trabajador, fec_calc_int, concep, flag_estado, fec_pago,
    fact_pago, fact_emplear, capital, imp_int_gen, imp_int_ant,
    adel_pago, nvo_capital, nvo_interes, int_pagado, mont_pagado, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, rc_rem.concep, '1', rc_rem.fec_proceso,
    0, 0, 0, 0, 0,
    rc_rem.imp_soles, 0, 0, 0, 0, '1' ) ;
end loop ;

for rc_rac in c_racion_azucar loop
  insert into racion_azucar_deveng (
    cod_trabajador, fec_proceso, imp_pag_mes, flag_replicacion )
  values (
    as_codtra, ad_fec_proceso, rc_rac.imp_soles, '1' ) ;
end loop ;

end usp_rh_dev_adiciona ;
/
