create or replace procedure usp_rh_cal_bonificaciones (
  as_codtra in char, ad_fec_proceso in date, as_origen in char,
  an_tipcam in number, as_bonificacion in char ) is

lk_ganancias_fijas      char(3) ;
lk_ganancias_fijas_25   char(3) ;
lk_ganancias_fijas_30   char(3) ;

ln_chequea              integer ;
ln_contador             integer ;
ln_sw                   integer ;
ls_concepto             char(4) ;
ln_dias_vacaciones      number(5,2) ;
ln_imp_soles            number(13,2) ;
ln_imp_dolar            number(13,2) ;
ln_factor               number(9,6) ;

begin

--  **********************************************************
--  ***   REALIZA CALCULO DE BONIFICACIONES VACACIONALES   ***
--  **********************************************************

select c.gan_bonif_vacacion, c.bonif_vacacion25, c.bonif_vacacion30
  into lk_ganancias_fijas, lk_ganancias_fijas_25, lk_ganancias_fijas_30
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

ln_chequea := 0 ;
select count(*) into ln_chequea from grupo_calculo g
  where g.grupo_calculo = lk_ganancias_fijas ;

if ln_chequea > 0 then

  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_ganancias_fijas ;

  ln_contador := 0 ; ln_dias_vacaciones := 0 ;
  select count(*) into ln_contador from inasistencia i
    where i.cod_trabajador = as_codtra and i.concep = ls_concepto ;

  if ln_contador > 0 then

    select sum(nvl(i.dias_inasist,0)) into ln_dias_vacaciones from inasistencia i
      where i.cod_trabajador = as_codtra and i.concep = ls_concepto ;

    select sum(nvl(gdf.imp_gan_desc,0)) into ln_imp_soles from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
          gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
          where d.grupo_calculo = lk_ganancias_fijas ) ;

    ln_imp_soles := (ln_imp_soles / 30) * ln_dias_vacaciones ;
    ln_imp_dolar := ln_imp_soles / an_tipcam ;

    insert into calculo (
      cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
      dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
    values (
      as_codtra, ls_concepto, ad_fec_proceso, 0, 0,
      ln_dias_vacaciones, ln_imp_soles, ln_imp_dolar, as_origen, '1', 1 ) ;

    ln_sw := 0 ;
    if as_bonificacion = '1' then
      select g.concepto_gen into ls_concepto from grupo_calculo g
        where g.grupo_calculo = lk_ganancias_fijas_30 ;
      ln_sw := 1 ;
    elsif as_bonificacion = '2' then
      select g.concepto_gen into ls_concepto from grupo_calculo g
        where g.grupo_calculo = lk_ganancias_fijas_25 ;
      ln_sw := 1 ;
    end if ;

    if ln_sw = 1 then
      select nvl(c.fact_pago,0) into ln_factor from concepto c
        where c.concep = ls_concepto ;
      ln_imp_soles := ln_imp_soles * ln_factor ;
      ln_imp_dolar := ln_imp_soles / an_tipcam ;
      insert into calculo (
        cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
        dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
      values (
        as_codtra, ls_concepto, ad_fec_proceso, 0, 0,
        ln_dias_vacaciones, ln_imp_soles, ln_imp_dolar, as_origen, '1', 1 ) ;
    end if ;

  end if ;

end if ;

end usp_rh_cal_bonificaciones ;
/
