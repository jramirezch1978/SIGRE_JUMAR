create or replace procedure usp_genera_registros is

ln_registro        number(15) ;
ls_codigo          historico_calculo.cod_trabajador%type ;
ls_concepto        historico_calculo.concep%type ;
ld_fecha           historico_calculo.fec_calc_plan%type ;
ls_labor           historico_calculo.cod_labor%type ;
ls_cencos          historico_calculo.cencos%type ;
ls_seccion         historico_calculo.cod_seccion%type ;
ln_hor_trabaj      historico_calculo.horas_trabaj%type ;
ln_hor_pag         historico_calculo.horas_pagad%type ;
ln_dias            historico_calculo.dias_trabaj%type ;
ls_moneda          historico_calculo.cod_moneda%type ;
ln_soles           historico_calculo.imp_soles%type ;
ln_dolares         historico_calculo.imp_dolar%type ;
ls_dato1           historico_calculo.flag_t_snp%type ;
ls_dato2           historico_calculo.flag_t_quinta%type ;
ls_dato3           historico_calculo.flag_t_judicial%type ;
ls_dato4           historico_calculo.flag_t_afp%type ;
ls_dato5           historico_calculo.flag_t_bonif_30%type ;
ls_dato6           historico_calculo.flag_t_bonif_25%type ;
ls_dato7           historico_calculo.flag_t_gratif%type ;
ls_dato8           historico_calculo.flag_t_cts%type ;
ls_dato9           historico_calculo.flag_t_vacacio%type ;
ls_dato10          historico_calculo.flag_t_bonif_vacacio%type ;
ls_dato11          historico_calculo.flag_t_pago_quincena%type ;
ls_dato12          historico_calculo.flag_t_quinquenio%type ;
ls_dato13          historico_calculo.flag_e_essalud%type ;
ls_dato14          historico_calculo.flag_e_agrario%type ;
ls_dato15          historico_calculo.flag_e_essalud_vida%type ;
ls_dato16          historico_calculo.flag_e_ies%type ;
ls_dato17          historico_calculo.flag_e_senati%type ;
ls_dato18          historico_calculo.flag_e_sctr_ipss%type ;
ls_dato19          historico_calculo.flag_e_sctr_onp%type ;

--  Lectura del archivo de historico de calculo
Cursor c_hist_calculo is
  Select hc.cod_trabajador, hc.concep, hc.fec_calc_plan,
         hc.cod_labor, hc.cencos, hc.cod_seccion,
         hc.horas_trabaj, hc.horas_pagad, hc.dias_trabaj,
         hc.cod_moneda, hc.imp_soles, hc.imp_dolar,
         hc.flag_t_snp, hc.flag_t_quinta, hc.flag_t_judicial,
         hc.flag_t_afp, hc.flag_t_bonif_30, hc.flag_t_bonif_25,
         hc.flag_t_gratif, hc.flag_t_cts, hc.flag_t_vacacio,
         hc.flag_t_bonif_vacacio, hc.flag_t_pago_quincena, hc.flag_t_quinquenio,
         hc.flag_e_essalud, hc.flag_e_agrario, hc.flag_e_essalud_vida,
         hc.flag_e_ies, hc.flag_e_senati, hc.flag_e_sctr_ipss,
         hc.flag_e_sctr_onp
  from historico_calculo hc ;

begin

--  Graba registros del historico de calculo
ln_registro := 0 ;
For rc_hc in c_hist_calculo Loop
  ln_registro := ln_registro + 1 ;
  If ln_registro > 400000 then
    ls_codigo     := rc_hc.cod_trabajador ;
    ls_concepto   := rc_hc.concep ;
    ld_fecha      := rc_hc.fec_calc_plan ;
    ls_labor      := rc_hc.cod_labor ;
    ls_cencos     := rc_hc.cencos ;
    ls_seccion    := rc_hc.cod_seccion ;
    ln_hor_trabaj := rc_hc.horas_trabaj ;
    ln_hor_pag    := rc_hc.horas_pagad ;
    ln_dias       := rc_hc.dias_trabaj ;
    ls_moneda     := rc_hc.cod_moneda ;
    ln_soles      := rc_hc.imp_soles ;
    ln_dolares    := rc_hc.imp_dolar ;
    ls_dato1      := rc_hc.flag_t_snp ;
    ls_dato2      := rc_hc.flag_t_quinta ;
    ls_dato3      := rc_hc.flag_t_judicial ;
    ls_dato4      := rc_hc.flag_t_afp ;
    ls_dato5      := rc_hc.flag_t_bonif_30 ;
    ls_dato6      := rc_hc.flag_t_bonif_25 ;
    ls_dato7      := rc_hc.flag_t_gratif ;
    ls_dato8      := rc_hc.flag_t_cts ;
    ls_dato9      := rc_hc.flag_t_vacacio ;
    ls_dato10     := rc_hc.flag_t_bonif_vacacio ;
    ls_dato11     := rc_hc.flag_t_pago_quincena ;
    ls_dato12     := rc_hc.flag_t_quinquenio ;
    ls_dato13     := rc_hc.flag_e_essalud ;
    ls_dato14     := rc_hc.flag_e_agrario ;
    ls_dato15     := rc_hc.flag_e_essalud_vida ;
    ls_dato16     := rc_hc.flag_e_ies ;
    ls_dato17     := rc_hc.flag_e_senati ;
    ls_dato18     := rc_hc.flag_e_sctr_ipss ;
    ls_dato19     := rc_hc.flag_e_sctr_onp ;
    Insert into nuevo_historico (
      cod_trabajador, concep, fec_calc_plan,
      cod_labor, cencos, cod_seccion,
      horas_trabaj, horas_pagad, dias_trabaj,
      cod_moneda, imp_soles, imp_dolar,
      flag_t_snp, flag_t_quinta, flag_t_judicial,
      flag_t_afp, flag_t_bonif_30, flag_t_bonif_25,
      flag_t_gratif, flag_t_cts, flag_t_vacacio,
      flag_t_bonif_vacacio, flag_t_pago_quincena, flag_t_quinquenio,
      flag_e_essalud, flag_e_agrario, flag_e_essalud_vida,
      flag_e_ies, flag_e_senati, flag_e_sctr_ipss,
      flag_e_sctr_onp )
    Values (
      ls_codigo, ls_concepto, ld_fecha, 
      ls_labor, ls_cencos, ls_seccion, 
      ln_hor_trabaj, ln_hor_pag, ln_dias, 
      ls_moneda, ln_soles, ln_dolares, 
      ls_dato1, ls_dato2, ls_dato3, 
      ls_dato4, ls_dato5, ls_dato6, 
      ls_dato7, ls_dato8, ls_dato9, 
      ls_dato10, ls_dato11, ls_dato12, 
      ls_dato13, ls_dato14, ls_dato15, 
      ls_dato16, ls_dato17, ls_dato18, 
      ls_dato19 ) ;
  End if ;
End Loop ;

COMMIT ;

end usp_genera_registros ;
/
