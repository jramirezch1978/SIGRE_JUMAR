create or replace procedure usp_cal_int_cts
   (as_codtra       in maestro.cod_trabajador%type ,
    ad_fec_proceso  in date
   ) is

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
Cursor c_adelantos is
  Select acc.cod_trabajador, acc.fec_proceso, acc.imp_a_cuenta
  from adel_cnta_cts acc
  where acc.cod_trabajador = as_codtra 
        order by acc.cod_trabajador, acc.fec_proceso ;

--  Movimiento de cuenta corriente para C.T.S.
Cursor c_ctacte is
  Select ccc.cod_trabajador, ccc.fec_prdo_dpsto, ccc.fec_calc_int,
         ccc.tasa_interes, ccc.imp_prdo_dpsto, ccc.cts_dispon_ant,
         ccc.int_legales,  ccc.a_cnta_cts, ccc.flag_control
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = as_codtra 
        and ccc.flag_control = '0'
        order by ccc.cod_trabajador, ccc.fec_prdo_dpsto
        for update ;
        
begin
        
--  Halla factor para la fecha de proceso
Select fp.fact_cts
  into ln_fac_pro
  from factor_planilla fp
  where fp.fec_calc_int = ad_fec_proceso ;
ln_fac_pro := nvl(ln_fac_pro,0) ;

--  Adiciona registros del movimiento por adelantos
--  A cuenta de C.T.S.
ln_contador := 0 ;
For rc_ade in c_adelantos Loop
  Select count(*)
    into ln_contador
    from adel_cnta_cts acc
    where acc.cod_trabajador = as_codtra ;
  If ln_contador > 0 then
    ls_codigo  := rc_ade.cod_trabajador ;
    ld_fecha   := rc_ade.fec_proceso ;
    ln_imp_cta := rc_ade.imp_a_cuenta ;

    Select count(*)
      into ln_num_reg
      from cnta_crrte_cts ccc
      where ls_codigo = ccc.cod_trabajador and
            ld_fecha  = ccc.fec_prdo_dpsto ;
      ln_num_reg := nvl(ln_num_reg,0) ;
            
     If ln_num_reg = 0 then
       Insert into cnta_crrte_cts
         ( fec_prdo_dpsto, fec_calc_int, cod_trabajador,
            tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
            int_legales, a_cnta_cts, flag_control )
       Values
         ( ld_fecha, ad_fec_proceso, ls_codigo,
           0, 0, 0,
           0, ln_imp_cta,'0' ) ;
     End if ;

  End if ;
End Loop ;

If ln_contador = 0 then
  ls_dia   := '31' ;
  ls_mes   := '12' ;
  ls_ano   := '1994' ;
  ld_fecha := to_date(ls_dia||'/'||ls_mes||'/'||ls_ano,'DD/MM/YYYY') ;
End if ;

--  Actualiza registros mientras flag de estado sea igual a cero
--  Y adiciona nuevo registro por cada adelanto a cuenta de C.T.S.

ln_imp_periodo := 0 ;
ln_disp_anteri := 0 ;
ln_interes_leg := 0 ;

For rc_ctacte in c_ctacte Loop

  --  Halla factor para la fecha de deposito
  Select fp.fact_cts
    into ln_fac_dep
    from factor_planilla fp
    where fp.fec_calc_int = (rc_ctacte.fec_prdo_dpsto - 1) ;
  ln_fac_dep := nvl(ln_fac_dep,0) ;    

  ln_fac_emp := 0 ;
  If to_char(rc_ctacte.fec_prdo_dpsto, 'DD/MM/YYYY') = '31/05/1991' then
    ln_fac_emp := ln_fac_pro - 1 ;
  Else  
    ln_fac_emp := (ln_fac_pro / ln_fac_dep) - 1 ;
  End if ;

  If rc_ctacte.fec_prdo_dpsto <= ld_fecha then

    ln_periodo  := rc_ctacte.imp_prdo_dpsto ;
    ln_anterior := rc_ctacte.cts_dispon_ant ;
    ln_interes  := rc_ctacte.int_legales ;
    ln_imp_cta  := rc_ctacte.a_cnta_cts ;
    ln_periodo  := nvl(ln_periodo,0) ;
    ln_anterior := nvl(ln_anterior,0) ;
    ln_interes  := nvl(ln_interes,0) ;
    ln_imp_cta  := nvl(ln_imp_cta,0) ;
    
    ln_imp_int  := (ln_periodo + ln_anterior) * ln_fac_emp ;
    ln_imp_int  := nvl(ln_imp_int,0) ;

    --  Actualiza registro
    Update cnta_crrte_cts
        Set fec_calc_int = ad_fec_proceso ,
            tasa_interes = ln_fac_emp ,
            int_legales  = ln_imp_int ,
            flag_control = '1'
        where current of c_ctacte ;
    
    ln_imp_periodo := ln_imp_periodo + ln_periodo ;
    ln_disp_anteri := ln_disp_anteri + ln_anterior ;
    ln_interes_leg := ln_interes_leg + ln_interes ;
    ln_imp_periodo := nvl(ln_imp_periodo,0) ;
    ln_disp_anteri := nvl(ln_disp_anteri,0) ;
    ln_interes_leg := nvl(ln_interes_leg,0) ;
        
    If ln_imp_cta > 0 then
      ln_nuevo_saldo := ln_imp_periodo + ln_disp_anteri ;
      ln_capital_int := ln_nuevo_saldo + ln_interes_leg ;
      ln_new_cap_int := ln_capital_int - ln_disp_anteri ;
      ln_disp_actual := ((ln_new_cap_int / 2) + ln_disp_anteri) - 
                        ln_imp_cta ;

      --  Actualiza registro                  
      Update cnta_crrte_cts
          Set fec_calc_int   = ad_fec_proceso ,
              tasa_interes   = 0 ,
              imp_prdo_dpsto = ln_imp_periodo ,
              cts_dispon_ant = ln_disp_anteri ,
              int_legales    = ln_interes_leg ,
              flag_control   = '1'
          where current of c_ctacte ;

      --  Inserta nuevo registro
      ld_new_fecha := rc_ctacte.fec_prdo_dpsto + 1 ;
      Select fp.fact_cts
        into ln_fac_dep
        from factor_planilla fp
        where fp.fec_calc_int = (ld_new_fecha - 1) ;
      ln_fac_dep := nvl(ln_fac_dep,0) ;    
  
      ln_fac_emp := (ln_fac_pro / ln_fac_dep) - 1 ;
      ln_imp_int := ln_disp_actual * ln_fac_emp ;
      ln_fac_emp := nvl(ln_fac_emp,0) ;
      ln_imp_int := nvl(ln_imp_int,0) ;
      
      If ld_new_fecha < ld_fecha then
        Insert into cnta_crrte_cts
          ( fec_prdo_dpsto, fec_calc_int, cod_trabajador,
            tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
            int_legales, a_cnta_cts, flag_control )
        Values
          ( ld_new_fecha, ad_fec_proceso, ls_codigo,
            ln_fac_emp, 0, ln_disp_actual,
            ln_imp_int, 0,'1' ) ;
      End if ;
      If ld_new_fecha > ld_fecha then
        Insert into cnta_crrte_cts
          ( fec_prdo_dpsto, fec_calc_int, cod_trabajador,
            tasa_interes, imp_prdo_dpsto, cts_dispon_ant,
            int_legales, a_cnta_cts, flag_control )
        Values
          ( ld_new_fecha, ad_fec_proceso, ls_codigo,
            ln_fac_emp, 0, ln_disp_actual,
            ln_imp_int, 0,'0' ) ;
      End if ;

      ln_imp_periodo := 0 ;
      ln_disp_anteri := 0 ;
      ln_interes_leg := 0 ;
      ln_disp_anteri := ln_disp_anteri + ln_disp_actual ;
      ln_interes_leg := ln_interes_leg + ln_imp_int ;
                              
    End if; 
  Else
    ln_imp_periodo := rc_ctacte.imp_prdo_dpsto ;
    ln_disp_anteri := rc_ctacte.cts_dispon_ant ;
    ln_imp_periodo := nvl(ln_imp_periodo,0) ;
    ln_disp_anteri := nvl(ln_disp_anteri,0) ;
    ln_imp_int := (ln_imp_periodo + ln_disp_anteri) * ln_fac_emp ;
    ln_imp_int := nvl(ln_imp_int,0) ;
    
    --  Actualiza registro
    Update cnta_crrte_cts
        Set fec_calc_int = ad_fec_proceso ,
            tasa_interes = ln_fac_emp ,
            int_legales  = ln_imp_int ,
            flag_control = '0'
        where current of c_ctacte ;
  
  End if ;
  
End Loop ;  

End usp_cal_int_cts ;
/
