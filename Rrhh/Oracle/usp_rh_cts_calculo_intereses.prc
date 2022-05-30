create or replace procedure usp_rh_cts_calculo_intereses (
  as_codtra in char, ad_fec_proceso in date ) is

ls_dia              char(2) ;
ls_mes              char(2) ;
ls_ano              char(4) ;

ln_fac_dep          factor_planilla.fact_cts%type ;
ln_fac_pro          factor_planilla.fact_cts%type ;
ln_fac_emp          factor_planilla.fact_cts%type ;
ln_contador         integer ;
ln_num_reg          integer ;
ls_codigo           adel_cnta_cts.cod_trabajador%type ;
ld_fecha            adel_cnta_cts.fec_proceso%type ;
ld_new_fecha        adel_cnta_cts.fec_proceso%type ;
ln_imp_cta          adel_cnta_cts.imp_a_cuenta%type ;
ln_imp_int          adel_cnta_cts.imp_a_cuenta%type ;

ln_periodo          cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_anterior         cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_interes          cnta_crrte_cts.imp_prdo_dpsto%type ;

ln_imp_periodo      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_disp_anteri      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_nuevo_saldo      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_interes_leg      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_capital_int      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_new_cap_int      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_disp_actual      cnta_crrte_cts.imp_prdo_dpsto%type ;

--  Movimento de adelantos a cuenta de C.T.S.
cursor c_adelantos is
  select acc.cod_trabajador, acc.fec_proceso, acc.imp_a_cuenta
  from adel_cnta_cts acc
  where acc.cod_trabajador = as_codtra
  order by acc.cod_trabajador, acc.fec_proceso ;

--  Movimiento de cuenta corriente para C.T.S.
cursor c_ctacte is
  select ccc.cod_trabajador, ccc.fec_prdo_dpsto, ccc.fec_calc_int,
         ccc.tasa_interes, ccc.imp_prdo_dpsto, ccc.cts_dispon_ant,
         ccc.int_legales, ccc.a_cnta_cts, ccc.flag_control
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = as_codtra and nvl(ccc.flag_control,'0') = '0'
  order by ccc.cod_trabajador, ccc.fec_prdo_dpsto
  for update ;

begin

--  *********************************************************
--  ***   CALCULO DE INTERESES PARA LA C.T.S. ACUMULADA   ***
--  *********************************************************

ln_fac_pro := 0 ;
select nvl(fp.fact_cts,0) into ln_fac_pro from factor_planilla fp
  where fp.fec_calc_int = ad_fec_proceso ;

--  Adiciona registros del movimiento por adelantos a cuenta de C.T.S.
ln_contador := 0 ;
for rc_ade in c_adelantos loop
  ln_contador := 1 ;
  ls_codigo  := rc_ade.cod_trabajador ;
  ld_fecha   := rc_ade.fec_proceso ;
  ln_imp_cta := nvl(rc_ade.imp_a_cuenta,0) ;
  ln_num_reg := 0 ;
  select count(*) into ln_num_reg from cnta_crrte_cts ccc
    where ls_codigo = ccc.cod_trabajador and ld_fecha = ccc.fec_prdo_dpsto ;
  if ln_num_reg = 0 then
    insert into cnta_crrte_cts (
      fec_prdo_dpsto, fec_calc_int, cod_trabajador,
      tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
      int_legales, a_cnta_cts, flag_control, flag_replicacion )
    values (
      ld_fecha, ad_fec_proceso, ls_codigo,
      0, 0, 0,
      0, ln_imp_cta, '0', '1' ) ;
  end if ;
end loop ;

if ln_contador = 0 then
  ls_dia := '31' ; ls_mes := '12' ; ls_ano := '1994' ;
  ld_fecha := to_date(ls_dia||'/'||ls_mes||'/'||ls_ano,'dd/mm/yyyy') ;
end if ;

--  Actualiza registros mientras flag de estado sea igual a cero
--  Y adiciona nuevo registro por cada adelanto a cuenta de C.T.S.

ln_imp_periodo := 0 ; ln_disp_anteri := 0 ;
ln_interes_leg := 0 ;

for rc_ctacte in c_ctacte loop

  select nvl(fp.fact_cts,0) into ln_fac_dep from factor_planilla fp
    where fp.fec_calc_int = (rc_ctacte.fec_prdo_dpsto - 1) ;

  ln_fac_emp := 0 ;
  if to_char(rc_ctacte.fec_prdo_dpsto,'dd/mm/yyyy') = '31/05/1991' then
    ln_fac_emp := ln_fac_pro - 1 ;
  else
    ln_fac_emp := (ln_fac_pro / ln_fac_dep) - 1 ;
  end if ;

  if rc_ctacte.fec_prdo_dpsto <= ld_fecha then

    ln_periodo  := nvl(rc_ctacte.imp_prdo_dpsto,0) ;
    ln_anterior := nvl(rc_ctacte.cts_dispon_ant,0) ;
    ln_interes  := nvl(rc_ctacte.int_legales,0) ;
    ln_imp_cta  := nvl(rc_ctacte.a_cnta_cts,0) ;
    ln_imp_int  := (ln_periodo + ln_anterior) * ln_fac_emp ;

    --  Actualiza registro
    update cnta_crrte_cts
      set fec_calc_int = ad_fec_proceso ,
          tasa_interes = ln_fac_emp ,
          int_legales  = ln_imp_int ,
          flag_control = '1',
          flag_replicacion = '1'
      where current of c_ctacte ;

    ln_imp_periodo := nvl(ln_imp_periodo,0) + nvl(ln_periodo,0) ;
    ln_disp_anteri := nvl(ln_disp_anteri,0) + nvl(ln_anterior,0) ;
    ln_interes_leg := nvl(ln_interes_leg,0) + nvl(ln_interes,0) ;

    if nvl(ln_imp_cta,0) > 0 then
      ln_nuevo_saldo := ln_imp_periodo + ln_disp_anteri ;
      ln_capital_int := ln_nuevo_saldo + ln_interes_leg ;
      ln_new_cap_int := ln_capital_int - ln_disp_anteri ;
      ln_disp_actual := ((ln_new_cap_int / 2) + ln_disp_anteri) - ln_imp_cta ;

      --  Actualiza registro
      update cnta_crrte_cts
        set fec_calc_int   = ad_fec_proceso ,
            tasa_interes   = 0 ,
            imp_prdo_dpsto = ln_imp_periodo ,
            cts_dispon_ant = ln_disp_anteri ,
            int_legales    = ln_interes_leg ,
            flag_control   = '1',
            flag_replicacion = '1'
        where current of c_ctacte ;

      --  Inserta nuevo registro
      ld_new_fecha := rc_ctacte.fec_prdo_dpsto + 1 ;
      select nvl(fp.fact_cts,0) into ln_fac_dep from factor_planilla fp
        where fp.fec_calc_int = (ld_new_fecha - 1) ;

      ln_fac_emp := (ln_fac_pro / ln_fac_dep) - 1 ;
      ln_imp_int := ln_disp_actual * ln_fac_emp ;
      ln_fac_emp := nvl(ln_fac_emp,0) ;
      ln_imp_int := nvl(ln_imp_int,0) ;

      if ld_new_fecha < ld_fecha then
        insert into cnta_crrte_cts (
          fec_prdo_dpsto, fec_calc_int, cod_trabajador,
          tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
          int_legales, a_cnta_cts, flag_control, flag_replicacion )
        values (
          ld_new_fecha, ad_fec_proceso, ls_codigo,
          ln_fac_emp, 0, ln_disp_actual,
          ln_imp_int, 0,'1', '1' ) ;
      end if ;
      if ld_new_fecha > ld_fecha then
        insert into cnta_crrte_cts (
          fec_prdo_dpsto, fec_calc_int, cod_trabajador,
          tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
          int_legales, a_cnta_cts, flag_control, flag_replicacion )
        values (
          ld_new_fecha, ad_fec_proceso, ls_codigo,
          ln_fac_emp, 0, ln_disp_actual,
          ln_imp_int, 0,'0','1' ) ;
      end if ;

      ln_imp_periodo := 0 ; ln_disp_anteri := 0 ; ln_interes_leg := 0 ;
      ln_disp_anteri := ln_disp_anteri + ln_disp_actual ;
      ln_interes_leg := ln_interes_leg + ln_imp_int ;

    end if ;
  else
    ln_imp_periodo := nvl(rc_ctacte.imp_prdo_dpsto,0) ;
    ln_disp_anteri := nvl(rc_ctacte.cts_dispon_ant,0) ;
    ln_imp_int := (ln_imp_periodo + ln_disp_anteri) * ln_fac_emp ;
    ln_imp_int := nvl(ln_imp_int,0) ;

    --  Actualiza registro
    update cnta_crrte_cts
      set fec_calc_int = ad_fec_proceso ,
          tasa_interes = ln_fac_emp ,
          int_legales  = ln_imp_int ,
          flag_control = '0',
          flag_replicacion = '1'
      where current of c_ctacte ;

  end if ;

end loop ;

end usp_rh_cts_calculo_intereses ;


/*
create or replace procedure usp_rh_cts_calculo_intereses (
  as_codtra in char, ad_fec_proceso in date ) is

ls_dia              char(2) ;
ls_mes              char(2) ;
ls_ano              char(4) ;

ln_fac_dep          factor_planilla.fact_cts%type ;
ln_fac_pro          factor_planilla.fact_cts%type ;
ln_fac_emp          factor_planilla.fact_cts%type ;
ln_contador         integer ;
ln_num_reg          integer ;
ls_codigo           adel_cnta_cts.cod_trabajador%type ;
ld_fecha            adel_cnta_cts.fec_proceso%type ;
ld_new_fecha        adel_cnta_cts.fec_proceso%type ;
ln_imp_cta          adel_cnta_cts.imp_a_cuenta%type ;
ln_imp_int          adel_cnta_cts.imp_a_cuenta%type ;

ln_periodo          cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_anterior         cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_interes          cnta_crrte_cts.imp_prdo_dpsto%type ;

ln_imp_periodo      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_disp_anteri      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_nuevo_saldo      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_interes_leg      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_capital_int      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_new_cap_int      cnta_crrte_cts.imp_prdo_dpsto%type ;
ln_disp_actual      cnta_crrte_cts.imp_prdo_dpsto%type ;

--  Movimento de adelantos a cuenta de C.T.S.
cursor c_adelantos is
  select acc.cod_trabajador, acc.fec_proceso, acc.imp_a_cuenta
  from adel_cnta_cts acc
  where acc.cod_trabajador = as_codtra
  order by acc.cod_trabajador, acc.fec_proceso ;

--  Movimiento de cuenta corriente para C.T.S.
cursor c_ctacte is
  select ccc.cod_trabajador, ccc.fec_prdo_dpsto, ccc.fec_calc_int,
         ccc.tasa_interes, ccc.imp_prdo_dpsto, ccc.cts_dispon_ant,
         ccc.int_legales, ccc.a_cnta_cts, ccc.flag_control
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = as_codtra and ccc.flag_control = '0'
  order by ccc.cod_trabajador, ccc.fec_prdo_dpsto
  for update ;

begin

--  *********************************************************
--  ***   CALCULO DE INTERESES PARA LA C.T.S. ACUMULADA   ***
--  *********************************************************

ln_fac_pro := 0 ;
select nvl(fp.fact_cts,0) into ln_fac_pro from factor_planilla fp
  where fp.fec_calc_int = ad_fec_proceso ;

--  Adiciona registros del movimiento por adelantos a cuenta de C.T.S.
ln_contador := 0 ;
for rc_ade in c_adelantos loop
  select count(*) into ln_contador from adel_cnta_cts acc
    where acc.cod_trabajador = as_codtra ;
  if ln_contador > 0 then
    ls_codigo  := rc_ade.cod_trabajador ;
    ld_fecha   := rc_ade.fec_proceso ;
    ln_imp_cta := nvl(rc_ade.imp_a_cuenta,0) ;
    ln_num_reg := 0 ;
    select count(*) into ln_num_reg from cnta_crrte_cts ccc
      where ls_codigo = ccc.cod_trabajador and ld_fecha = ccc.fec_prdo_dpsto ;
    if ln_num_reg = 0 then
      insert into cnta_crrte_cts (
        fec_prdo_dpsto, fec_calc_int, cod_trabajador,
        tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
        int_legales, a_cnta_cts, flag_control, flag_replicacion )
      values (
        ld_fecha, ad_fec_proceso, ls_codigo,
        0, 0, 0,
        0, ln_imp_cta,'0', '1' ) ;
    end if ;
  end if ;
end loop ;

if ln_contador = 0 then
  ls_dia := '31' ; ls_mes := '12' ; ls_ano := '1994' ;
  ld_fecha := to_date(ls_dia||'/'||ls_mes||'/'||ls_ano,'dd/mm/yyyy') ;
end if ;

--  Actualiza registros mientras flag de estado sea igual a cero
--  Y adiciona nuevo registro por cada adelanto a cuenta de C.T.S.

ln_imp_periodo := 0 ; ln_disp_anteri := 0 ;
ln_interes_leg := 0 ;

for rc_ctacte in c_ctacte loop

  select nvl(fp.fact_cts,0) into ln_fac_dep from factor_planilla fp
    where fp.fec_calc_int = (rc_ctacte.fec_prdo_dpsto - 1) ;

  ln_fac_emp := 0 ;
  if to_char(rc_ctacte.fec_prdo_dpsto,'dd/mm/yyyy') = '31/05/1991' then
    ln_fac_emp := ln_fac_pro - 1 ;
  else
    ln_fac_emp := (ln_fac_pro / ln_fac_dep) - 1 ;
  end if ;

  if rc_ctacte.fec_prdo_dpsto <= ld_fecha then

    ln_periodo  := nvl(rc_ctacte.imp_prdo_dpsto,0) ;
    ln_anterior := nvl(rc_ctacte.cts_dispon_ant,0) ;
    ln_interes  := nvl(rc_ctacte.int_legales,0) ;
    ln_imp_cta  := nvl(rc_ctacte.a_cnta_cts,0) ;
    ln_imp_int  := (ln_periodo + ln_anterior) * ln_fac_emp ;

    --  Actualiza registro
    update cnta_crrte_cts
      set fec_calc_int = ad_fec_proceso ,
          tasa_interes = ln_fac_emp ,
          int_legales  = ln_imp_int ,
          flag_control = '1',
          flag_replicacion = '1'
      where current of c_ctacte ;

    ln_imp_periodo := nvl(ln_imp_periodo,0) + nvl(ln_periodo,0) ;
    ln_disp_anteri := nvl(ln_disp_anteri,0) + nvl(ln_anterior,0) ;
    ln_interes_leg := nvl(ln_interes_leg,0) + nvl(ln_interes,0) ;

    if ln_imp_cta > 0 then
      ln_nuevo_saldo := ln_imp_periodo + ln_disp_anteri ;
      ln_capital_int := ln_nuevo_saldo + ln_interes_leg ;
      ln_new_cap_int := ln_capital_int - ln_disp_anteri ;
      ln_disp_actual := ((ln_new_cap_int / 2) + ln_disp_anteri) - ln_imp_cta ;

      --  Actualiza registro
      update cnta_crrte_cts
        set fec_calc_int   = ad_fec_proceso ,
            tasa_interes   = 0 ,
            imp_prdo_dpsto = ln_imp_periodo ,
            cts_dispon_ant = ln_disp_anteri ,
            int_legales    = ln_interes_leg ,
            flag_control   = '1',
            flag_replicacion = '1'
        where current of c_ctacte ;

      --  Inserta nuevo registro
      ld_new_fecha := rc_ctacte.fec_prdo_dpsto + 1 ;
      select nvl(fp.fact_cts,0) into ln_fac_dep from factor_planilla fp
        where fp.fec_calc_int = (ld_new_fecha - 1) ;

      ln_fac_emp := (ln_fac_pro / ln_fac_dep) - 1 ;
      ln_imp_int := ln_disp_actual * ln_fac_emp ;
      ln_fac_emp := nvl(ln_fac_emp,0) ;
      ln_imp_int := nvl(ln_imp_int,0) ;

      if ld_new_fecha < ld_fecha then
        insert into cnta_crrte_cts (
          fec_prdo_dpsto, fec_calc_int, cod_trabajador,
          tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
          int_legales, a_cnta_cts, flag_control, flag_replicacion )
        values (
          ld_new_fecha, ad_fec_proceso, ls_codigo,
          ln_fac_emp, 0, ln_disp_actual,
          ln_imp_int, 0,'1', '1' ) ;
      end if ;
      if ld_new_fecha > ld_fecha then
        insert into cnta_crrte_cts (
          fec_prdo_dpsto, fec_calc_int, cod_trabajador,
          tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
          int_legales, a_cnta_cts, flag_control, flag_replicacion )
        values (
          ld_new_fecha, ad_fec_proceso, ls_codigo,
          ln_fac_emp, 0, ln_disp_actual,
          ln_imp_int, 0,'0','1' ) ;
      end if ;

      ln_imp_periodo := 0 ; ln_disp_anteri := 0 ; ln_interes_leg := 0 ;
      ln_disp_anteri := ln_disp_anteri + ln_disp_actual ;
      ln_interes_leg := ln_interes_leg + ln_imp_int ;

    end if ;
  else
    ln_imp_periodo := nvl(rc_ctacte.imp_prdo_dpsto,0) ;
    ln_disp_anteri := nvl(rc_ctacte.cts_dispon_ant,0) ;
    ln_imp_int := (ln_imp_periodo + ln_disp_anteri) * ln_fac_emp ;
    ln_imp_int := nvl(ln_imp_int,0) ;

    --  Actualiza registro
    update cnta_crrte_cts
      set fec_calc_int = ad_fec_proceso ,
          tasa_interes = ln_fac_emp ,
          int_legales  = ln_imp_int ,
          flag_control = '0',
          flag_replicacion = '1'
      where current of c_ctacte ;

  end if ;

end loop ;

end usp_rh_cts_calculo_intereses ;
*/
/
