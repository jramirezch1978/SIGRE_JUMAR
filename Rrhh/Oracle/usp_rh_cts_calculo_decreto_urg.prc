create or replace procedure usp_rh_cts_calculo_decreto_urg (
  as_codtra in char, ad_fec_proceso in date ) is

lk_remun_basica    char(3) ;
lk_afecto_cts      char(3) ;

ls_concepto_bas    char(4) ;
ls_concepto        calculo.concep%type ;
ln_factor          concepto.fact_pago%type ;
ln_remuneracion    number(13,2) ;
ln_liquidacion     number(13,2) ;
ln_contador        integer ;

--  Cursor de trabajadores solamente activos
cursor c_maestro is
  select m.cod_trabajador
  from maestro m
  where m.cod_trabajador = as_codtra ;

begin

--  ****************************************************************
--  ***   REALIZA CALCULO DE C.T.S. POR EL DECRETO DE URGENCIA   ***
--  ****************************************************************

select c.remunerac_basica, c.afecto_pago_cts_urgencia
  into lk_remun_basica, lk_afecto_cts
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select p.cnc_total_ing into ls_concepto from rrhhparam p
  where p.reckey = '1' ;

select nvl(c.fact_pago,0) into ln_factor from concepto c
  where c.concep = ls_concepto ;

select g.concepto_gen into ls_concepto_bas from grupo_calculo g
  where g.grupo_calculo = lk_remun_basica ;

for rc_mae in c_maestro loop

  ln_remuneracion := 0 ; ln_liquidacion  := 0 ;
  ln_contador := 0 ;
  select count(*) into ln_contador from gan_desct_fijo f
    where f.cod_trabajador = rc_mae.cod_trabajador and f.concep = ls_concepto_bas ;

  if ln_contador > 0 then

    ln_contador := 0 ;
    select count(*) into ln_contador from calculo c
      where c.cod_trabajador = rc_mae.cod_trabajador and c.concep in
            ( select d.concepto_calc from grupo_calculo_det d where
              d.grupo_calculo = lk_afecto_cts ) ;
    if ln_contador > 0 then
      select sum(c.imp_soles) into ln_remuneracion from calculo c
        where c.cod_trabajador = rc_mae.cod_trabajador and c.concep in
              ( select d.concepto_calc from grupo_calculo_det d where
                d.grupo_calculo = lk_afecto_cts ) ;
      ln_liquidacion := ln_remuneracion * ln_factor ;
      insert into cts_decreto_urgencia (
        cod_trabajador, fec_proceso, remuneracion, liquidacion, flag_replicacion )
      values (
        rc_mae.cod_trabajador, ad_fec_proceso, ln_remuneracion, ln_liquidacion, '1' ) ;
    end if ;

  end if ;

end loop ;

end usp_rh_cts_calculo_decreto_urg ;
/
