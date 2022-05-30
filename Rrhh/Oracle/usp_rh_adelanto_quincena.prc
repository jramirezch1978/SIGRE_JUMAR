create or replace procedure usp_rh_adelanto_quincena (
  an_adelanto    in number, an_porcentaje in number,
  as_codigo      in char,
  ad_fec_proceso in date,
  as_sino        in char,
  as_redondeo    in char ) is

lk_quincena          char(4) ;
ls_concepto          char(4) ;
ln_judicial          number(4,2) ;
ls_bonificacion      char(1) ;
ls_cnta_ahorro       char(20) ;
ln_quincena          number(13,2) ;
ln_imp_control       number(4,2) ;
ls_importe           varchar2(20) ;
ln_contador          integer ;
ln_sw                integer ;
ln_tipo_cambio       number(7,3) ;
ln_imp_cuota         number(13,2) ;
ln_imp_acum          number(13,2) ;
ls_dolar             char(3) ;

--  Lectura de movimiento de cuenta corriente para descontar de quincena
cursor c_cuenta_corriente is
  select cc.mont_cuota, cc.cod_moneda, cc.flaq_dscto_quin
  from cnta_crrte cc
  where cc.cod_trabajador = as_codigo and nvl(cc.flag_estado,'0') = '1' and
        nvl(cc.cod_sit_prest,'0') = 'A' and nvl(cc.flaq_dscto_quin,'0') <> '0' and
        nvl(cc.sldo_prestamo,0) > 0
  order by cc.cod_trabajador, cc.concep ;

begin

--  *********************************************************
--  ***   REALIZA CALCULO DE ADELANTO DE REMUNERACIONES   ***
--  *********************************************************

select p.cod_dolares into ls_dolar from logparam p
  where p.reckey = '1' ;

ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*) into ln_contador from calendario c
  where trunc(c.fecha) = trunc(ad_fec_proceso) ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,0) into ln_tipo_cambio from calendario c
    where trunc(c.fecha) = trunc(ad_fec_proceso) ;
else
  raise_application_error( -20000, 'Tipo de cambio al '||to_char(ad_fec_proceso,'dd/mm/yyyy')||
                                   ' no existe. Consulte con Contabilidad') ;
end if ;

select c.adelanto_quincena into lk_quincena from rrhhparam_cconcep c
  where c.reckey = '1' ;

select g.concepto_gen into ls_concepto
  from grupo_calculo g where g.grupo_calculo = lk_quincena ;

select nvl(m.porc_judicial,0), m.bonif_fija_30_25, m.nro_cnta_ahorro
  into ln_judicial, ls_bonificacion, ls_cnta_ahorro
  from maestro m where m.cod_trabajador = as_codigo ;

ln_sw := 0 ;
if as_sino = 'S' then
  if ln_judicial > 0 or ls_cnta_ahorro is null then
    ln_sw := 1 ;
  end if ;
  ln_contador := 0 ;
  select count(*) into ln_contador from diferido d
    where d.cod_trabajador = as_codigo and to_char(d.fec_proceso,'mm/yyyy') =
          to_char(add_months(ad_fec_proceso,-1),'mm/yyyy') ;
  if ln_contador > 0 then
    ln_sw := 1 ;
  end if ;
end if ;

if ln_sw = 0 then

  if an_adelanto > 0 then
    ln_quincena := an_adelanto ;
  else
    ln_quincena := 0 ;
    select sum(nvl(g.imp_gan_desc,0)) into ln_quincena from gan_desct_fijo g
      where g.cod_trabajador = as_codigo and g.flag_estado = '1' and
            g.concep in ( select d.concepto_calc from grupo_calculo_det d
                          where d.grupo_calculo = lk_quincena ) ;

    if ls_bonificacion = '1' then
      ln_quincena := ln_quincena * 1.30 ;
    elsif ls_bonificacion = '2' then
      ln_quincena := ln_quincena * 1.25 ;
    end if ;

    ln_quincena := (ln_quincena * an_porcentaje) / 100 ;

    --  Verifica si tiene prestamo para realizar descuento de la quincena
    ln_imp_cuota := 0 ; ln_imp_acum := 0 ;
    for rc_cta in c_cuenta_corriente loop
      ln_imp_cuota := 0.00 ;
      if rc_cta.cod_moneda = ls_dolar then
        ln_imp_cuota := ln_imp_cuota + (nvl(rc_cta.mont_cuota,0) * ln_tipo_cambio) ;
      else
        ln_imp_cuota := ln_imp_cuota + nvl(rc_cta.mont_cuota,0) ;
      end if ;
      if nvl(rc_cta.flaq_dscto_quin,'0') = '1' then
        ln_imp_acum := ln_imp_acum + (nvl(ln_imp_cuota,0) / 2) ;
      elsif nvl(rc_cta.flaq_dscto_quin,'0') = '2' then
        ln_imp_acum := ln_imp_acum + nvl(ln_imp_cuota,0) ;
      end if ;
    end loop ;
    if nvl(ln_imp_acum,0) > nvl(ln_quincena,0) then
      ln_quincena := 0 ;
    else
      ln_quincena  := nvl(ln_quincena,0) - nvl(ln_imp_acum,0) ;
    end if ;

    --  Calcula redondeo por adelanto de remuneracion
    ls_importe     := to_char(ln_quincena,'999,999,999,999.99') ;

    ln_imp_control := to_number((substr(ls_importe,-5,5)),'99.99') ;

if as_redondeo = 'S' THEN
    if ln_imp_control < 25.00 then
      ln_quincena := ln_quincena - ln_imp_control ;
    elsif ln_imp_control >= 25.00 and ln_imp_control < 75.00 then
      ln_quincena := (ln_quincena - ln_imp_control) + 50.00 ;
    elsif ln_imp_control >= 75.00 then
      ln_quincena := (ln_quincena - ln_imp_control) + 100.00 ;
    end if ;

end if;


  end if ;

  if ln_quincena <> 0 then
    insert into adelanto_quincena (
      cod_trabajador, concep, fec_proceso, imp_adelanto,flag_replicacion )
    values (
      as_codigo, ls_concepto, ad_fec_proceso, ln_quincena, '1' ) ;
  end if ;

end if ;

end usp_rh_adelanto_quincena ;
/
