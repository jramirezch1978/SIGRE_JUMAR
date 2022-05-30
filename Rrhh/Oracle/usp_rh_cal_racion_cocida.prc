create or replace procedure usp_rh_cal_racion_cocida (
  as_codtra in char, as_codusr in char, ad_fec_proceso in date,
  as_origen in char, an_dias_trabajados in out calculo.dias_trabaj%type,
  an_dias_mes in char, an_dias_racion_cocida in number, an_tipcam in number ) is

lk_racion_cocida      char(3) ;
lk_dias_vacaciones    char(3) ;

ln_chequea            integer ;
ln_contador           integer ;
ln_verifica           integer ;
ls_concepto           char(4) ;
ls_concepto_vac       char(4) ;
ln_imp_soles          number(13,2) ;
ln_imp_dolar          number(13,2) ;
ln_dias_vacacion      number(5,2) ;
ln_diatra             number(4,2) ;
ln_diapag             number(4,2) ;

begin

--  *****************************************************
--  ***   CALCULA IMPORTE POR DIAS DE RACION COCIDA   ***
--  *****************************************************

select c.calculo_racion_cocida, c.gan_fij_calc_vacac
  into lk_racion_cocida, lk_dias_vacaciones
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

ln_chequea := 0 ;
select count(*) into ln_chequea from grupo_calculo g
  where g.grupo_calculo = lk_racion_cocida  ;

if ln_chequea > 0 then

  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_racion_cocida  ;

  ln_contador := 0 ;
  select count(*) into ln_contador from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_codtra and gdf.concep = ls_concepto ;

  if ln_contador > 0 then

    select nvl(gdf.imp_gan_desc,0) into ln_imp_soles from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_codtra and gdf.concep = ls_concepto ;

    select g.concepto_gen into ls_concepto_vac from grupo_calculo g
      where g.grupo_calculo = lk_dias_vacaciones ;

    ln_verifica := 0 ; ln_dias_vacacion := 0 ;
    select count(*) into ln_verifica from inasistencia i
      where i.cod_trabajador = as_codtra and i.concep = ls_concepto_vac ;
    if ln_verifica > 0 then
      select sum(nvl(i.dias_inasist,0)) into ln_dias_vacacion from inasistencia i
        where i.cod_trabajador = as_codtra and i.concep = ls_concepto_vac ;
    end if ;

    ln_dias_vacacion := ln_dias_vacacion + an_dias_trabajados ;

    if ln_dias_vacacion >= an_dias_mes then
      ln_diatra := an_dias_racion_cocida ;
    else
      ln_diapag    := an_dias_racion_cocida - ( an_dias_mes - ln_dias_vacacion ) ;
      ln_imp_soles := ln_imp_soles / an_dias_racion_cocida * ln_diapag ;
      ln_diatra    := ln_diapag ;
    end if ;
    ln_imp_dolar := ln_imp_soles / an_tipcam ;

    if ln_imp_soles > 0 then
      insert into calculo (
        cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
        dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
      values (
        as_codtra, ls_concepto, ad_fec_proceso, 0, 0,
        ln_diatra, ln_imp_soles, ln_imp_dolar, as_origen, '1', 1 ) ;
    end if ;

  end if ;

end if ;

end usp_rh_cal_racion_cocida ;
/
