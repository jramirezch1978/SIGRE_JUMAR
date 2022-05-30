create or replace procedure usp_rh_liq_rpt_liquidaciones (
  ad_fec_desde in date, ad_fec_hasta in date ) is

ln_verifica           integer ;
ls_cod_trabajador     char(8) ;
ls_nombres            varchar2(60) ;
ls_tipo_tra           char(3) ;
ls_desc_tiptra        varchar2(30) ;
ls_cencos             char(10) ;
ls_desc_cencos        varchar2(40) ;
ls_grp_reten          char(6) ;
ls_sgrp_reten         char(6) ;
ls_concepto           char(4) ;
ln_imp_pagado         number(13,2) ;
ln_imp_saldo          number(13,2) ;
ln_imp_diferido       number(13,2) ;
ln_imp_aplicado       number(13,2) ;
ln_imp_ret_jud        number(13,2) ;
ln_imp_comp_adi       number(13,2) ;
ln_imp_benef_soc      number(13,2) ;

--  Lectura de liquidaciones de creditos laborales
cursor c_liquidaciones is
  select c.cod_trabajador, c.nro_liquidacion, c.fec_liquidacion, c.tm_anos, c.tm_meses,
         c.tm_dias, c.imp_liq_befef_soc, c.imp_liq_remun, (nvl(c.imp_liq_befef_soc,0) +
         nvl(c.imp_liq_remun,0)) as imp_total, c.flag_juicio, c.flag_reposicion,
         c.flag_forma_pago
  from rh_liq_credito_laboral c
  where nvl(c.flag_estado,'0') = '2' and
        trunc(c.fec_liquidacion) between ad_fec_desde and ad_fec_hasta
  order by c.nro_liquidacion ;

--  Lectura de cronograma de pagos por trabajador
cursor c_cronograma is
  select c.flag_estado, c.imp_pagado
  from rh_liq_cnta_crrte_cred_lab c
  where c.cod_trabajador = ls_cod_trabajador and nvl(c.flag_estado,'0') <> '0'
  order by c.cod_trabajador, c.fec_pago ;
  
begin

--  *************************************************************
--  ***   TEMPORAL PARA GENERAR ESTADO DE LAS LIQUIDACIONES   ***
--  *************************************************************

delete from tt_liq_rpt_liquidaciones ;

select p.grp_reten_jud, p.sgrp_reten_jud, p.cncp_comp_dic
  into ls_grp_reten, ls_sgrp_reten, ls_concepto
  from rh_liqparam p where p.reckey = '1' ;
  
for rc_liq in c_liquidaciones loop

  ls_cod_trabajador := rc_liq.cod_trabajador ;
  ls_nombres := usf_rh_nombre_trabajador(ls_cod_trabajador) ;

  --  Determina tipo de trabajador y centro de costo
  select m.tipo_trabajador, tt.desc_tipo_tra, m.cencos, cc.desc_cencos
    into ls_tipo_tra, ls_desc_tiptra, ls_cencos, ls_desc_cencos
    from maestro m, tipo_trabajador tt, centros_costo cc
    where m.cod_trabajador = ls_cod_trabajador and m.tipo_trabajador = tt.tipo_trabajador and
          m.cencos = cc.cencos ;
    
  --  Determina pagos, saldos y diferidos de liquidaciones
  ln_imp_pagado := 0 ; ln_imp_saldo := 0 ; ln_imp_diferido := 0 ;
  for rc_cro in c_cronograma loop
    if nvl(rc_cro.flag_estado,'0') = '1' then
      ln_imp_saldo := ln_imp_saldo + nvl(rc_cro.imp_pagado,0) ;
    elsif nvl(rc_cro.flag_estado,'0') = '2' then
      ln_imp_pagado := ln_imp_pagado + nvl(rc_cro.imp_pagado,0) ;
    elsif nvl(rc_cro.flag_estado,'0') = '3' then
      ln_imp_diferido := ln_imp_diferido + nvl(rc_cro.imp_pagado,0) ;
    end if ;
  end loop ;
  
  --  Determina montos de pagos a entidades externas
  ln_verifica := 0 ; ln_imp_aplicado := 0 ;
  select count(*) into ln_verifica from rh_liq_saldos_cnta_crrte s
    where s.cod_trabajador = ls_cod_trabajador and nvl(s.flag_estado,'0') = '1' and
          nvl(s.imp_aplicado,0) <> 0 ;
  if ln_verifica > 0 then
    select sum(nvl(s.imp_aplicado,0)) into ln_imp_aplicado from rh_liq_saldos_cnta_crrte s
      where s.cod_trabajador = ls_cod_trabajador and nvl(s.flag_estado,'0') = '1' and
            nvl(s.imp_aplicado,0) <> 0 ;
  end if ;    

  --  Determina importe por retencion judicial de beneficios sociales
  ln_verifica := 0 ; ln_imp_ret_jud := 0 ;
  select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = ls_cod_trabajador and d.cod_grupo = ls_grp_reten and
          d.cod_sub_grupo = ls_sgrp_reten ;
  if ln_verifica > 0 then
    select sum(nvl(d.importe,0)) into ln_imp_ret_jud from rh_liq_dscto_leyes_aportes d
      where d.cod_trabajador = ls_cod_trabajador and d.cod_grupo = ls_grp_reten and
            d.cod_sub_grupo = ls_sgrp_reten ;
  end if ;    

  --  Determina pago por compensacion adicional
  ln_verifica := 0 ; ln_imp_comp_adi := 0 ;
  select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = ls_cod_trabajador and d.concep = ls_concepto ;
  if ln_verifica > 0 then
    select sum(nvl(d.importe,0)) into ln_imp_comp_adi from rh_liq_dscto_leyes_aportes d
      where d.cod_trabajador = ls_cod_trabajador and d.concep = ls_concepto ;
  end if ;    

  --  Rebaja beneficios sociales por compensacion adicional
  ln_imp_benef_soc := 0 ;
  if nvl(ln_imp_comp_adi,0) > 0 then
    ln_imp_benef_soc := rc_liq.imp_liq_befef_soc - ln_imp_comp_adi ;
  else
    ln_imp_benef_soc := rc_liq.imp_liq_befef_soc ;
  end if ;

  --  Inserta movimiento para generar reporte
  insert into tt_liq_rpt_liquidaciones (
    tipo_tra, desc_tiptra, cencos, desc_cencos,
    fec_desde, fec_hasta, nro_liquidacion, cod_trabajador, nombres,
    fec_liquidacion, ts_anos, ts_meses, ts_dias,
    imp_liq_bensoc, imp_liq_remune, imp_liq_total, flag_forma_pago,
    imp_pagado, imp_saldo, imp_diferido, imp_aplicado,
    flag_juicio, flag_reposicion, imp_comp_adi, imp_ret_jud )
  values (
    ls_tipo_tra, ls_desc_tiptra, ls_cencos, ls_desc_cencos,
    ad_fec_desde, ad_fec_hasta, rc_liq.nro_liquidacion, ls_cod_trabajador, ls_nombres,
    rc_liq.fec_liquidacion, rc_liq.tm_anos, rc_liq.tm_meses, rc_liq.tm_dias,
    ln_imp_benef_soc, rc_liq.imp_liq_remun, rc_liq.imp_total, rc_liq.flag_forma_pago,
    ln_imp_pagado, ln_imp_saldo, ln_imp_diferido, ln_imp_aplicado,
    rc_liq.flag_juicio, rc_liq.flag_reposicion, ln_imp_comp_adi, ln_imp_ret_jud ) ;

end loop ;

end usp_rh_liq_rpt_liquidaciones ;
/
