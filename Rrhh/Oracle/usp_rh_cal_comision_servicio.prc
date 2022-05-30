create or replace procedure usp_rh_cal_comision_servicio (
  as_codtra in char, ad_fec_proceso in date, as_origen in char,
  an_tipcam in number ) is

lk_ganancias_fijas      char(3) ;

ln_chequea              integer ;
ln_contador             integer ;
ls_concepto             char(4) ;
ln_dias                 number(5,2) ;
ln_imp_soles            number(13,2) ;
ln_imp_dolar            number(13,2) ;

begin

--  *************************************************************
--  ***   REALIZA CALCULO POR DIAS DE COMISION DE SERVICIOS   ***
--  *************************************************************

select c.comision_servicio into lk_ganancias_fijas
  from rrhhparam_cconcep c where c.reckey = '1' ;

ln_chequea := 0 ;
select count(*) into ln_chequea from grupo_calculo g
  where g.grupo_calculo = lk_ganancias_fijas ;

if ln_chequea > 0 then

  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_ganancias_fijas ;

  ln_contador := 0 ; ln_dias := 0 ;
  select count(*) into ln_contador from inasistencia i
    where i.cod_trabajador = as_codtra and i.concep = ls_concepto ;

  if ln_contador > 0 then

    select sum(nvl(i.dias_inasist,0)) into ln_dias from inasistencia i
      where i.cod_trabajador = as_codtra and i.concep = ls_concepto ;

    select sum(nvl(gdf.imp_gan_desc,0)) into ln_imp_soles from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
            gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                            where d.grupo_calculo = lk_ganancias_fijas ) ;

    ln_imp_soles := (ln_imp_soles / 30) * ln_dias ;
    ln_imp_dolar := ln_imp_soles / an_tipcam ;

    insert into calculo (
      cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
      dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
    values (
      as_codtra, ls_concepto, ad_fec_proceso, 0, 0,
      ln_dias, ln_imp_soles, ln_imp_dolar, as_origen, '1', 1 ) ;

  end if ;

end if ;

end usp_rh_cal_comision_servicio ;
/
