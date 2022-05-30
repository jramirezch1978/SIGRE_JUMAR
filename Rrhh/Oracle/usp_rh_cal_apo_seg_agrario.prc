create or replace procedure usp_rh_cal_apo_seg_agrario (
  as_codtra in char, ad_fec_proceso in date, an_tipcam in number,
  as_origen in char ) is

lk_seguro_agrario         char(3) ;

ln_verifica               integer ;
ls_concepto               char(4) ;
ln_factor                 number(9,6) ;
ln_imp_soles              number(13,2) ;
ln_imp_dolar              number(13,2) ;

begin

--  ************************************************************
--  ***   REALIZA CALCULO DE SEGURO AGRARIO POR TRABAJADOR   ***
--  ************************************************************

select c.concep_seguro_agrario into lk_seguro_agrario
  from rrhhparam_cconcep c where c.reckey = '1' ;

ln_verifica := 0 ;
select count(*) into ln_verifica from grupo_calculo g
  where g.grupo_calculo = lk_seguro_agrario ;

if ln_verifica > 0 then

  select g.concepto_gen, nvl(c.fact_pago,0) into ls_concepto, ln_factor
    from grupo_calculo g, concepto c
    where g.concepto_gen = c.concep and g.grupo_calculo = lk_seguro_agrario ;

  select sum(nvl(c.imp_soles,0)) into ln_imp_soles from calculo c
  where c.cod_trabajador = as_codtra and c.concep in ( select d.concepto_calc
        from grupo_calculo_det d where d.grupo_calculo = lk_seguro_agrario ) ;

  if ln_imp_soles > 0 then
    ln_imp_soles := ln_imp_soles * ln_factor ;
    ln_imp_dolar := ln_imp_soles / an_tipcam ;
    insert into calculo (
      cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
      dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
    values (
      as_codtra, ls_concepto, ad_fec_proceso, 0, 0,
      0, ln_imp_soles, ln_imp_dolar, as_origen, '1', 1 ) ;
  end if ;

end if ;

end usp_rh_cal_apo_seg_agrario ;
/
