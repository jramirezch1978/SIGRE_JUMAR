create or replace procedure usp_rh_saldos_dias_vac_bon (
  as_codtra in char, ad_fec_proceso in date ) is

ln_verifica     integer ;
ln_dias         number(2) ;
ln_dias_vac     number(2) ;
ln_dias_act     number(2) ;
ln_dias_bonif   number(2) ;

--  Cursor del movimiento mensual de vacaciones y bonificaciones
cursor c_vacaciones is
  select vb.per_vac_bonif, vb.flag_vac_bonif, vb.fec_desde, vb.fec_hasta
  from  mov_mes_vacac_bonif vb
  where vb.cod_trabajador = as_codtra and to_char(vb.fec_hasta,'mm/yyyy') =
        to_char(ad_fec_proceso,'mm/yyyy') ;

begin

--  *******************************************************************
--  ***   ACTUALIZA SALDOS DE DIAS DE VACACIONES Y BONIFICACIONES   ***
--  *******************************************************************

delete from vacac_bonif_deveng d
  where d.cod_trabajador = as_codtra and ( nvl(d.sldo_dias_vacacio,0) = 0 and
        nvl(d.sldo_dias_bonif,0) = 0 ) ;

for rc_vb in c_vacaciones loop

  ln_dias := to_date(rc_vb.fec_hasta) - to_date(rc_vb.fec_desde) + 1 ;
  ln_verifica := 0 ;
  select count(*) into ln_verifica from vacac_bonif_deveng bd
    where bd.cod_trabajador = as_codtra and bd.periodo = rc_vb.per_vac_bonif ;

  if ln_verifica = 0 then

    if nvl(rc_vb.flag_vac_bonif,'0') = '1' then
      insert into vacac_bonif_deveng (
        cod_trabajador, periodo, flag_estado, sldo_dias_vacacio, sldo_dias_bonif, flag_replicacion )
      values (
        as_codtra, rc_vb.per_vac_bonif, '1', ln_dias, 0, '1' ) ;
      commit ;
    elsif nvl(rc_vb.flag_vac_bonif,'0') = '2' then
      insert into vacac_bonif_deveng (
        cod_trabajador, periodo, flag_estado, sldo_dias_vacacio, sldo_dias_bonif, flag_replicacion )
      values (
        as_codtra, rc_vb.per_vac_bonif, '1', 0, ln_dias, '1' ) ;
      commit ;
    end if ;

  else

    select nvl(bd.sldo_dias_vacacio,0), nvl(bd.sldo_dias_bonif,0)
      into ln_dias_vac, ln_dias_bonif from vacac_bonif_deveng bd
      where bd.cod_trabajador = as_codtra and bd.periodo = rc_vb.per_vac_bonif ;

    if nvl(rc_vb.flag_vac_bonif,'0') = '1' then
      ln_dias_act := ln_dias_vac - ln_dias ;
      if ln_dias_act <= 0 then
        ln_dias_act := 0;
      end if ;
      update vacac_bonif_deveng
        set sldo_dias_vacacio = ln_dias_act,
         flag_replicacion = '1'
        where cod_trabajador = as_codtra and periodo =  rc_vb.per_vac_bonif ;
    elsif nvl(rc_vb.flag_vac_bonif,'0') = '2' then
      ln_dias_act := ln_dias_bonif - ln_dias ;
      if ln_dias_act <= 0 then
        ln_dias_act := 0;
      end if ;
      update vacac_bonif_deveng
        set sldo_dias_bonif = ln_dias_act,
         flag_replicacion = '1'
        where cod_trabajador = as_codtra and periodo =  rc_vb.per_vac_bonif ;
    end if ;

  end if ;

end loop ;

end usp_rh_saldos_dias_vac_bon ;
/
