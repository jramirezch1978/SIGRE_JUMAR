create or replace procedure usp_rh_liq_diferido (
  as_cod_trabajador in char, ad_fec_liquidacion in date, as_usuario in char ) is

ln_verifica            integer ;
ls_grp_adelan          char(6) ;
ls_grp_ctacob          char(6) ;
ls_grp_judben          char(6) ;
ls_grp_desret          char(6) ;

ln_importe_liq         number(13,2) ;
ln_importe             number(13,2) ;
ln_imp_dif             number(13,2) ;
ln_item                number(2) ;

--  Lectura de descuentos por adenlantos de beneficios sociales
cursor c_adelantos is
  select d.cod_grupo, d.cod_sub_grupo, d.concep, d.importe
  from rh_liq_dscto_leyes_aportes d
  where d.cod_trabajador = as_cod_trabajador and d.cod_sub_grupo = ls_grp_adelan
  order by d.cod_trabajador, d.cod_grupo, d.cod_sub_grupo, d.concep ;
  
--  Lectura de descuentos de cuenta corriente de beneficios sociales
cursor c_cuenta_corriente is
  select d.cod_trabajador, d.cod_grupo, d.cod_sub_grupo, d.concep, d.importe,
         s.flag_prd_dscto
  from rh_liq_dscto_leyes_aportes d, rh_liq_saldos_cnta_crrte s
  where d.cod_trabajador = s.cod_trabajador and d.concep = s.concep and
        d.cod_trabajador = as_cod_trabajador and d.cod_sub_grupo = ls_grp_ctacob
  group by d.cod_trabajador, d.cod_grupo, d.cod_sub_grupo, d.concep, d.importe,
           s.flag_prd_dscto
  order by s.flag_prd_dscto ;
  
--  Lectura de descuentos por judiciales de beneficios sociales
cursor c_judicial_bensoc is
  select d.cod_grupo, d.cod_sub_grupo, d.concep, d.importe
  from rh_liq_dscto_leyes_aportes d
  where d.cod_trabajador = as_cod_trabajador and d.cod_sub_grupo = ls_grp_judben
  order by d.cod_trabajador, d.cod_grupo, d.cod_sub_grupo, d.concep ;
  
--  Lectura de descuentos por retencion judiciales de remuneraciones
cursor c_retencion_judicial is
  select d.cod_grupo, d.cod_sub_grupo, d.concep, d.importe
  from rh_liq_dscto_leyes_aportes d
  where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_desret
  order by d.cod_trabajador, d.cod_grupo, d.cod_sub_grupo, d.concep ;
  
begin

--  *****************************************************************
--  ***   CALCULO DE DIFERIDOS EN CASO LIQUIDACION SEA NEGATIVA   ***
--  *****************************************************************

select p.sgrp_adelanto, p.sgrp_cnta_cobrar, p.sgrp_reten_jud, p.grp_dscto_remun
  into ls_grp_adelan, ls_grp_ctacob, ls_grp_judben, ls_grp_desret
  from rh_liqparam p
  where p.reckey = '1' ;
  
ln_verifica := 0 ; ln_importe_liq := 0 ;
select count(*) into ln_verifica from rh_liq_credito_laboral l
  where l.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then
  select nvl(l.imp_liq_befef_soc,0) + nvl(l.imp_liq_remun,0)
    into ln_importe_liq
    from rh_liq_credito_laboral l
    where l.cod_trabajador = as_cod_trabajador ;
end if ;

ln_verifica := 0 ; ln_item := 0 ;
select count(*) into ln_verifica from rh_liq_cnta_crrte_cred_lab l
  where l.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then
  select max(nvl(l.item,0)) into ln_item from rh_liq_cnta_crrte_cred_lab l
    where l.cod_trabajador = as_cod_trabajador ;
end if ;
  
if nvl(ln_importe_liq,0) < 0 then

  ln_importe_liq := nvl(ln_importe_liq,0) * -1 ;

  --  Salda informacion de adelantos de beneficios sociales
  for rc_ade in c_adelantos loop
  
    if nvl(ln_importe_liq,0) > 0 then
    
      if nvl(rc_ade.importe,0) >= nvl(ln_importe_liq,0) then
        ln_importe     := nvl(rc_ade.importe,0) - nvl(ln_importe_liq,0) ;
        ln_imp_dif     := nvl(ln_importe_liq,0) ;
        ln_importe_liq := 0 ;
      else
        ln_importe     := 0 ;
        ln_imp_dif     := nvl(rc_ade.importe,0) ;
        ln_importe_liq := nvl(ln_importe_liq,0) - nvl(rc_ade.importe,0) ;
      end if ;
    
      update rh_liq_credito_laboral l
        set l.imp_liq_befef_soc = nvl(l.imp_liq_befef_soc,0) + nvl(ln_imp_dif,0)
        where l.cod_trabajador = as_cod_trabajador ;
              
      update rh_liq_dscto_leyes_aportes d
        set d.importe = nvl(ln_importe,0)
        where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = rc_ade.cod_grupo and
              d.cod_sub_grupo = rc_ade.cod_sub_grupo and d.concep = rc_ade.concep ;
              
      ln_item := ln_item + 1 ;
      insert into rh_liq_cnta_crrte_cred_lab (
        cod_trabajador, item, flag_estado, tipo_doc, nro_doc, fec_pago,
        imp_pagado, cod_usr )
      values (
        as_cod_trabajador, ln_item, '3', null, rc_ade.concep, ad_fec_liquidacion,
        nvl(ln_imp_dif,0), as_usuario ) ;

    end if ;
    
  end loop ;

  --  Salda informacion de cuenta corriente de beneficios sociales
  for rc_cta in c_cuenta_corriente loop
  
    if nvl(ln_importe_liq,0) > 0 then
    
      if nvl(rc_cta.importe,0) >= nvl(ln_importe_liq,0) then
        ln_importe     := nvl(rc_cta.importe,0) - nvl(ln_importe_liq,0) ;
        ln_imp_dif     := nvl(ln_importe_liq,0) ;
        ln_importe_liq := 0 ;
      else
        ln_importe     := 0 ;
        ln_imp_dif     := nvl(rc_cta.importe,0) ;
        ln_importe_liq := nvl(ln_importe_liq,0) - nvl(rc_cta.importe,0) ;
      end if ;
    
      update rh_liq_credito_laboral l
        set l.imp_liq_befef_soc = nvl(l.imp_liq_befef_soc,0) + nvl(ln_imp_dif,0)
        where l.cod_trabajador = as_cod_trabajador ;
              
      update rh_liq_dscto_leyes_aportes d
        set d.importe = nvl(ln_importe,0)
        where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = rc_cta.cod_grupo and
              d.cod_sub_grupo = rc_cta.cod_sub_grupo and d.concep = rc_cta.concep ;
              
      ln_item := ln_item + 1 ;
      insert into rh_liq_cnta_crrte_cred_lab (
        cod_trabajador, item, flag_estado, tipo_doc, nro_doc, fec_pago,
        imp_pagado, cod_usr )
      values (
        as_cod_trabajador, ln_item, '3', null, rc_cta.concep, ad_fec_liquidacion,
        nvl(ln_imp_dif,0), as_usuario ) ;

    end if ;
    
  end loop ;

  --  Salda informacion de judiciales de beneficios sociales
  for rc_jud in c_judicial_bensoc loop
  
    if nvl(ln_importe_liq,0) > 0 then
    
      if nvl(rc_jud.importe,0) >= nvl(ln_importe_liq,0) then
        ln_importe     := nvl(rc_jud.importe,0) - nvl(ln_importe_liq,0) ;
        ln_imp_dif     := nvl(ln_importe_liq,0) ;
        ln_importe_liq := 0 ;
      else
        ln_importe     := 0 ;
        ln_imp_dif     := nvl(rc_jud.importe,0) ;
        ln_importe_liq := nvl(ln_importe_liq,0) - nvl(rc_jud.importe,0) ;
      end if ;
    
      update rh_liq_credito_laboral l
        set l.imp_liq_befef_soc = nvl(l.imp_liq_befef_soc,0) + nvl(ln_imp_dif,0)
        where l.cod_trabajador = as_cod_trabajador ;
              
      update rh_liq_dscto_leyes_aportes d
        set d.importe = nvl(ln_importe,0)
        where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = rc_jud.cod_grupo and
              d.cod_sub_grupo = rc_jud.cod_sub_grupo and d.concep = rc_jud.concep ;
              
      ln_item := ln_item + 1 ;
      insert into rh_liq_cnta_crrte_cred_lab (
        cod_trabajador, item, flag_estado, tipo_doc, nro_doc, fec_pago,
        imp_pagado, cod_usr )
      values (
        as_cod_trabajador, ln_item, '3', null, rc_jud.concep, ad_fec_liquidacion,
        nvl(ln_imp_dif,0), as_usuario ) ;

    end if ;
    
  end loop ;

  --  Salda informacion de retencion judicial por remuneraciones
  for rc_ret in c_retencion_judicial loop
  
    if nvl(ln_importe_liq,0) > 0 then
    
      if nvl(rc_ret.importe,0) >= nvl(ln_importe_liq,0) then
        ln_importe     := nvl(rc_ret.importe,0) - nvl(ln_importe_liq,0) ;
        ln_imp_dif     := nvl(ln_importe_liq,0) ;
        ln_importe_liq := 0 ;
      else
        ln_importe     := 0 ;
        ln_imp_dif     := nvl(rc_ret.importe,0) ;
        ln_importe_liq := nvl(ln_importe_liq,0) - nvl(rc_ret.importe,0) ;
      end if ;
    
      update rh_liq_credito_laboral l
        set l.imp_liq_befef_soc = nvl(l.imp_liq_befef_soc,0) + nvl(ln_imp_dif,0)
        where l.cod_trabajador = as_cod_trabajador ;
              
      update rh_liq_dscto_leyes_aportes d
        set d.importe = nvl(ln_importe,0)
        where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = rc_ret.cod_grupo and
              d.cod_sub_grupo = rc_ret.cod_sub_grupo and d.concep = rc_ret.concep ;
              
      ln_item := ln_item + 1 ;
      insert into rh_liq_cnta_crrte_cred_lab (
        cod_trabajador, item, flag_estado, tipo_doc, nro_doc, fec_pago,
        imp_pagado, cod_usr )
      values (
        as_cod_trabajador, ln_item, '3', null, rc_ret.concep, ad_fec_liquidacion,
        nvl(ln_imp_dif,0), as_usuario ) ;

    end if ;
    
  end loop ;

end if ;

end usp_rh_liq_diferido ;
/
