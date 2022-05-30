create or replace procedure usp_rh_cal_bonificacion_30_25 (
  as_codtra in char, ad_fec_proceso in date, as_origen in char,
  an_tipcam in number, as_bonificacion in char ) is

lk_bonificacion_25    char(3) ;
lk_bonificacion_30    char(3) ;

ls_concepto           char(4) ;
ln_imp_soles          number(13,2) ;
ln_imp_dolar          number(13,2) ;
ln_factor             number(9,6) ;

begin

--  ***********************************************************************
--  ***   CALCULA BONIFICACION DEL 30% O 25% DE LAS GANANCIAS AFECTAS   ***
--  ***********************************************************************

select c.bonificacion25, c.bonificacion30
  into lk_bonificacion_25, lk_bonificacion_30
  from rrhhparam_cconcep c where c.reckey = '1' ;

if as_bonificacion = '1' or as_bonificacion = '2' then

  ln_imp_soles := 0 ; ln_imp_dolar := 0 ;
  if as_bonificacion = '2' then
    select sum(nvl(c.imp_soles,0)) into ln_imp_soles from calculo c
      where c.cod_trabajador = as_codtra and c.concep in
            ( select d.concepto_calc from grupo_calculo_det d where
              d.grupo_calculo = lk_bonificacion_25 ) ;
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_bonificacion_25 ;
  else
    select sum(nvl(c.imp_soles,0)) into ln_imp_soles from calculo c
      where c.cod_trabajador = as_codtra and c.concep in
            ( select d.concepto_calc from grupo_calculo_det d where
              d.grupo_calculo = lk_bonificacion_30 ) ;
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_bonificacion_30 ;
  end if ;

  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;

  ln_imp_soles := ln_imp_soles * ln_factor ;
  ln_imp_dolar := ln_imp_soles / an_tipcam ;
  insert into calculo (
    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
  values (
    as_codtra, ls_concepto, ad_fec_proceso, 0, 0,
    0, ln_imp_soles, ln_imp_dolar, as_origen, '1', 1 ) ;

end if ;

end usp_rh_cal_bonificacion_30_25 ;
/
