create or replace procedure usp_rh_rpt_cnta_crrte_cts (
  as_tipo_trabajador in char, as_origen in char ) is

ls_codigo               char(8) ;
ls_cod_trabajador       char(8) ;
ls_nombre               varchar2(100) ;
ls_cod_area             char(1) ;
ls_desc_area            varchar2(30) ;
ls_cod_seccion          char(3) ;
ls_desc_seccion         varchar2(30) ;
ls_cencos               char(10) ;
ls_desc_cencos          varchar2(30) ;
ld_fec_dpsto            date ;
ld_fec_calc             date ;
ln_tasa_interes         number(9,6) ;
ln_imp_dpsto            number(11,2) ;
ln_cts_dpsto_ant        number(11,2) ;
ln_nuevo_saldo          number(11,2) ;
ln_int_legal            number(11,2) ;
ln_capital_interes      number(11,2) ;
ln_nuevo_cap_int        number(11,2) ;
ln_ret50_emp            number(11,2) ;
ln_ret50_tra            number(11,2) ;
ln_saldo_disp_ant       number(11,2) ;
ln_nuevo_saldo_disp     number(11,2) ;
ln_a_cta_cts            number(11,2) ;
ln_saldo_disp_actual    number(11,2) ;
ls_flag_control         char(1) ;

ln_imp_dpsto_a          number(11,2) ;
ln_cts_dpsto_ant_a      number(11,2) ;
ln_int_legal_a          number(11,2) ;
ln_a_cta_cts_a          number(11,2) ;

--  Lectura de trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.flag_estado, m.cencos, m.cod_seccion, m.cod_area
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.cencos ;

--  Cursor para la tabla de cuenta corriente de c.t.s.
cursor c_cnta_crrte_cts is
  select ccc.fec_prdo_dpsto, ccc.fec_calc_int, ccc.cod_trabajador,
         ccc.tasa_interes, ccc.imp_prdo_dpsto, ccc.cts_dispon_ant,
         ccc.int_legales, ccc.a_cnta_cts, ccc.flag_control
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = ls_codigo
  order by ccc.cod_trabajador, ccc.fec_prdo_dpsto ;

begin

--  ****************************************************************
--  ***   REPORTE DE CUENTA CORRIENTE DE C.T.S. POR TRABAJADOR   ***
--  ****************************************************************

delete from tt_cnta_crrte_cts ;

for rc_m in c_maestro loop

  ls_codigo      := rc_m.cod_trabajador ;
  ls_cencos      := rc_m.cencos ;
  ls_cod_seccion := rc_m.cod_seccion ;
  ls_cod_area    := rc_m.cod_area ;
  ls_nombre      := usf_nombre_trabajador (ls_codigo) ;

  if ls_cod_area is not null then
    select a.desc_area into ls_desc_area from area a
      where a.cod_area = ls_cod_area ;
    select s.desc_seccion into ls_desc_seccion from seccion s
      where s.cod_area = ls_cod_area and s.cod_seccion = ls_cod_seccion ;
  end if ;

  if ls_cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = ls_cencos ;
  end if ;

  ln_imp_dpsto_a := 0 ; ln_cts_dpsto_ant_a := 0 ;
  ln_int_legal_a := 0 ; ln_a_cta_cts_a     := 0 ;

  for rc_ccc in c_cnta_crrte_cts loop

    ls_cod_trabajador := rc_ccc.cod_trabajador ;
    ld_fec_dpsto      := rc_ccc.fec_prdo_dpsto ;
    ld_fec_calc       := rc_ccc.fec_calc_int ;
    ln_tasa_interes   := rc_ccc.tasa_interes ;
    ls_flag_control   := nvl(rc_ccc.flag_control,'0') ;

    rc_ccc.imp_prdo_dpsto := nvl(rc_ccc.imp_prdo_dpsto,0) ;
    rc_ccc.cts_dispon_ant := nvl(rc_ccc.cts_dispon_ant,0) ;
    rc_ccc.int_legales    := nvl(rc_ccc.int_legales,0) ;
    rc_ccc.a_cnta_cts      := nvl(rc_ccc.a_cnta_cts,0) ;

    if ls_flag_control = '1' then
      ln_imp_dpsto       := rc_ccc.imp_prdo_dpsto ;
      ln_cts_dpsto_ant   := rc_ccc.cts_dispon_ant ;
      ln_nuevo_saldo     := ln_imp_dpsto + ln_cts_dpsto_ant ;
      ln_int_legal       := rc_ccc.int_legales ;
      ln_capital_interes := ln_nuevo_saldo + ln_int_legal ;
      ln_a_cta_cts       := nvl(rc_ccc.a_cnta_cts,0) ;
      if ln_a_cta_cts > 0 then
        ln_nuevo_cap_int     := ln_capital_interes - ln_cts_dpsto_ant ;
        ln_ret50_emp         := ln_nuevo_cap_int / 2 ;
        ln_ret50_tra         := ln_nuevo_cap_int - ln_ret50_emp ;
        ln_saldo_disp_ant    := ln_cts_dpsto_ant ;
        ln_nuevo_saldo_disp  := ln_ret50_tra + ln_saldo_disp_ant ;
        ln_saldo_disp_actual := ln_nuevo_saldo_disp - ln_a_cta_cts ;
      else
        ln_nuevo_cap_int     := 0 ; ln_ret50_emp         := 0 ;
        ln_ret50_tra         := 0 ; ln_saldo_disp_ant    := 0 ;
        ln_nuevo_saldo_disp  := 0 ; ln_saldo_disp_actual := 0 ;
      end if ;
      --  Inserta registros en la tabla temporal
      insert into tt_cnta_crrte_cts (
       cod_trabajador, nombre, cod_area, desc_area, cod_seccion,
       desc_seccion, cencos, desc_cencos, fec_dpsto, fec_calc,
       tasa_interes, imp_dpsto, cts_dpsto_ant, nuevo_saldo,
       int_legal, capital_interes, nuevo_cap_int, ret50_emp,
       ret50_tra, saldo_disp_ant, nuevo_saldo_disp, a_cta_cts,
       saldo_disp_actual, flag_control )
     values (
       ls_cod_trabajador, ls_nombre, ls_cod_area, ls_desc_area, ls_cod_seccion,
       ls_desc_seccion, ls_cencos, ls_desc_cencos, ld_fec_dpsto, ld_fec_calc,
       ln_tasa_interes, ln_imp_dpsto, ln_cts_dpsto_ant, ln_nuevo_saldo,
       ln_int_legal, ln_capital_interes, ln_nuevo_cap_int, ln_ret50_emp,
       ln_ret50_tra, ln_saldo_disp_ant, ln_nuevo_saldo_disp, ln_a_cta_cts,
       ln_saldo_disp_actual, ls_flag_control ) ;
    else
      ln_imp_dpsto         := rc_ccc.imp_prdo_dpsto ;
      ln_cts_dpsto_ant     := rc_ccc.cts_dispon_ant ;
      ln_nuevo_saldo       := ln_imp_dpsto + ln_cts_dpsto_ant ;
      ln_int_legal         := rc_ccc.int_legales ;
      ln_capital_interes   := ln_nuevo_saldo + ln_int_legal ;
      ln_a_cta_cts         := rc_ccc.a_cnta_cts ;
      ln_nuevo_cap_int     := 0 ; ln_ret50_emp         := 0 ;
      ln_ret50_tra         := 0 ; ln_saldo_disp_ant    := 0 ;
      ln_nuevo_saldo_disp  := 0 ; ln_saldo_disp_actual := 0 ;
    --  Inserta registros en la tabla temporal
    insert into tt_cnta_crrte_cts (
      cod_trabajador, nombre, cod_area, desc_area, cod_seccion,
      desc_seccion, cencos, desc_cencos, fec_dpsto, fec_calc,
      tasa_interes, imp_dpsto, cts_dpsto_ant, nuevo_saldo,
      int_legal, capital_interes, nuevo_cap_int, ret50_emp,
      ret50_tra, saldo_disp_ant, nuevo_saldo_disp, a_cta_cts,
      saldo_disp_actual, flag_control )
    values (
      ls_cod_trabajador, ls_nombre, ls_cod_area, ls_desc_area, ls_cod_seccion,
      ls_desc_seccion, ls_cencos, ls_desc_cencos, ld_fec_dpsto, ld_fec_calc,
      ln_tasa_interes, ln_imp_dpsto, ln_cts_dpsto_ant, ln_nuevo_saldo,
      ln_int_legal, ln_capital_interes, ln_nuevo_cap_int, ln_ret50_emp,
      ln_ret50_tra, ln_saldo_disp_ant, ln_nuevo_saldo_disp, ln_a_cta_cts,
      ln_saldo_disp_actual, ls_flag_control ) ;
      ln_imp_dpsto_a     := ln_imp_dpsto_a + rc_ccc.imp_prdo_dpsto ;
      ln_cts_dpsto_ant_a := ln_cts_dpsto_ant_a + rc_ccc.cts_dispon_ant ;
      ln_int_legal_a     := ln_int_legal_a + rc_ccc.int_legales ;
      ln_a_cta_cts_a     := ln_a_cta_cts_a + rc_ccc.a_cnta_cts ;
    end if ;

  end loop ;

  ln_nuevo_saldo := ln_imp_dpsto_a + ln_cts_dpsto_ant_a ;
  ln_capital_interes := ln_nuevo_saldo + ln_int_legal_a ;
  ln_nuevo_cap_int := ln_capital_interes - ln_cts_dpsto_ant_a ;
  ln_ret50_emp := ln_nuevo_cap_int / 2 ;
  ln_ret50_tra := ln_nuevo_cap_int - ln_ret50_emp ;
  ln_saldo_disp_ant := ln_cts_dpsto_ant_a ;
  ln_nuevo_saldo_disp := ln_ret50_tra + ln_saldo_disp_ant ;
  ln_saldo_disp_actual := ln_nuevo_saldo_disp - ln_a_cta_cts_a ;

  --  Insertar registros en la tabla temporal
  insert into tt_cnta_crrte_cts (
    cod_trabajador, nombre, cod_area, desc_area, cod_seccion,
    desc_seccion, cencos, desc_cencos, fec_dpsto, fec_calc,
    tasa_interes, imp_dpsto, cts_dpsto_ant, nuevo_saldo,
    int_legal, capital_interes, nuevo_cap_int, ret50_emp,
    ret50_tra, saldo_disp_ant, nuevo_saldo_disp, a_cta_cts,
    saldo_disp_actual, flag_control )
  values (
    ls_cod_trabajador, ls_nombre, ls_cod_area, ls_desc_area, ls_cod_seccion,
    ls_desc_seccion, ls_cencos, ls_desc_cencos, ld_fec_dpsto, ld_fec_calc,
    ln_tasa_interes, ln_imp_dpsto_a, ln_cts_dpsto_ant_a, ln_nuevo_saldo,
    ln_int_legal_a, ln_capital_interes, ln_nuevo_cap_int, ln_ret50_emp,
    ln_ret50_tra, ln_saldo_disp_ant, ln_nuevo_saldo_disp, ln_a_cta_cts_a,
    ln_saldo_disp_actual, ls_flag_control ) ;

end loop ;

end usp_rh_rpt_cnta_crrte_cts ;
/
