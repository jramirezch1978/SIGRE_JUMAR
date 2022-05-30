create or replace procedure usp_pla_dev_calculo_gra
   (as_codtra       in maestro.cod_trabajador%type ,
    ad_fec_proceso  in rrhhparam.fec_proceso%type
   ) is

lk_dev_gra         constant char(3) := '005' ;
ls_meses           char(2) ;
ls_years           char(4) ;
ln_contador        integer ;

ln_fac_pago_ant    maestro_remun_gratif_dev.fact_pago%type ;
ln_capital_ant     maestro_remun_gratif_dev.nvo_capital%type ;
ln_interes_ant     maestro_remun_gratif_dev.nvo_interes%type ;

ld_fec_pago        maestro_remun_gratif_dev.fec_pago%type ;
ln_fac_pago_act    maestro_remun_gratif_dev.fact_pago%type ;
ln_fact_emplear    maestro_remun_gratif_dev.fact_emplear%type ;
ln_capital         maestro_remun_gratif_dev.capital%type ;
ln_imp_int_gen     maestro_remun_gratif_dev.imp_int_gen%type ;
ln_imp_int_ant     maestro_remun_gratif_dev.imp_int_ant%type ;
ln_adel_pago       maestro_remun_gratif_dev.adel_pago%type ;
ln_nvo_capital     maestro_remun_gratif_dev.nvo_capital%type ;
ln_nvo_interes     maestro_remun_gratif_dev.nvo_interes%type ;
ln_mont_pagado     maestro_remun_gratif_dev.mont_pagado%type ;
ln_int_pagado      maestro_remun_gratif_dev.int_pagado%type ;

--  Concepto de gratificaciones
Cursor c_gratificacion is
  Select rgd.fec_pago,    rgd.fact_pago,   rgd.fact_emplear,
         rgd.capital,     rgd.imp_int_gen, rgd.imp_int_ant,
         rgd.adel_pago,   rgd.nvo_capital, rgd.nvo_interes,
         rgd.mont_pagado, rgd.int_pagado,  rgd.fec_calc_int
  from maestro_remun_gratif_dev rgd
  where rgd.cod_trabajador = as_codtra 
        and rgd.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = lk_dev_gra )
          order by rgd.cod_trabajador, rgd.fec_calc_int, rgd.fec_pago
          for update ;
        
begin
        
-- Verifica si tiene saldo de gratificaciones para calulo de intereses
ln_contador := 0 ;
Select count(*)
  into ln_contador
  from sldo_deveng sd
  where sd.cod_trabajador = as_codtra and
        sd.fec_proceso = add_months(ad_fec_proceso,-1) and
        sd.sldo_gratif_dev > 0 ;
ln_contador := nvl(ln_contador,0) ;

If ln_contador > 0 then
  
ls_meses := to_char(ad_fec_proceso, 'MM') ;
ls_years := to_char(ad_fec_proceso, 'YYYY') ;

--  Guarda el ultimo registro del mes anterior al mes de proceso
For rc_gra in c_gratificacion Loop

  If to_char(rc_gra.fec_calc_int, 'MM')  <> ls_meses
  or to_char(rc_gra.fec_calc_int, 'YYYY') <> ls_years then
    ln_fac_pago_ant := rc_gra.fact_pago ;
    ln_capital_ant  := rc_gra.nvo_capital ;
    ln_interes_ant  := rc_gra.nvo_interes ;
  End if ;          

End Loop ;

ln_fac_pago_ant := nvl(ln_fac_pago_ant,0) ;
ln_capital_ant  := nvl(ln_capital_ant,0) ;
ln_interes_ant  := nvl(ln_interes_ant,0) ;

--  Verifica si tiene saldos para calcular intereses
If ln_capital_ant > 0 or ln_interes_ant > 0 then

  ln_contador := 0 ;
  Select count(*)
    Into ln_contador
    from maestro_remun_gratif_dev rgd
    where rgd.cod_trabajador = as_codtra
      and to_char(rgd.fec_calc_int, 'MM')   = ls_meses
      and to_char(rgd.fec_calc_int, 'YYYY') = ls_years
      and rgd.concep = '1301' ;

  --  Si no existe registros del mes de proceso
  --  Calcula y adiciona registros
  If ln_contador = 0 then

    --  Halla factor para calculo de intereses
    Select fp.fact_interes
      into ln_fac_pago_act
      from factor_planilla fp
      where fp.fec_calc_int = ad_fec_proceso ;
    ln_fac_pago_act := nvl ( ln_fac_pago_act, 0) ;

    --  Calcula intereses 
    ln_adel_pago    := 0 ;
    ln_fact_emplear := ln_fac_pago_act - ln_fac_pago_ant ;
    ln_capital      := ln_capital_ant ;
    ln_imp_int_ant  := ln_interes_ant ;
    ln_imp_int_gen  := ln_capital * ln_fact_emplear ;
    ln_nvo_interes  := ln_imp_int_ant + ln_imp_int_gen ;
    If ln_capital > 0 then
      ln_nvo_capital := ln_capital - ln_adel_pago ;
      If ln_nvo_capital < 0 then
        ln_nvo_capital := ln_nvo_capital * (-1)  ;
        ln_nvo_interes := ln_imp_int_ant - ln_nvo_capital ;
        ln_nvo_capital := 0 ;
      End if ;
      ln_mont_pagado := ln_adel_pago ;
    Else
      ln_nvo_interes := ln_imp_int_ant - ln_adel_pago ;
      If ln_nvo_interes < 0 then
        ln_nvo_interes := 0 ;
      End if ;
      ln_int_pagado := ln_adel_pago ;
    End if ;

    --  Adiciona registro
    Insert into maestro_remun_gratif_dev
      ( cod_trabajador, fec_calc_int, concep,      flag_estado,
        fec_pago,       tipo_doc,     nro_doc,     fact_pago,
        fact_emplear,   capital,      imp_int_gen, imp_int_ant,
        adel_pago,      nvo_capital,  nvo_interes, int_pagado,
        mont_pagado )
     Values     
      ( as_codtra,       ad_fec_proceso, '1301',         '1',
        ad_fec_proceso,  'auto',         '',             ln_fac_pago_act,
        ln_fact_emplear, ln_capital,     ln_imp_int_gen, ln_imp_int_ant,
        ln_adel_pago,    ln_nvo_capital, ln_nvo_interes, ln_int_pagado,
        ln_mont_pagado ) ;

  --  Si existe registros del mes de proceso
  --  Calcula y actualiza registros
  Else

    For rc_gra in c_gratificacion Loop

      If to_char(rc_gra.fec_calc_int, 'MM') = ls_meses
      and to_char(rc_gra.fec_calc_int, 'YYYY') = ls_years then

        --  Halla factor para calculo de intereses
        Select fp.fact_interes
          into ln_fac_pago_act
          from factor_planilla fp
          where fp.fec_calc_int = rc_gra.fec_pago ;
        ln_fac_pago_act := nvl ( ln_fac_pago_act, 0) ;

        ln_adel_pago    := rc_gra.adel_pago ;      
    
        --  Calcula intereses
        ln_fact_emplear := ln_fac_pago_act - ln_fac_pago_ant ;
        ln_capital      := ln_capital_ant ;
        ln_imp_int_ant  := ln_interes_ant ;
        ln_imp_int_gen  := ln_capital * ln_fact_emplear ;
        ln_nvo_interes  := ln_imp_int_ant + ln_imp_int_gen ;
        If ln_capital > 0 then
          ln_nvo_capital := ln_capital - ln_adel_pago ;
          If ln_nvo_capital < 0 then
            ln_nvo_capital := ln_nvo_capital * (-1)  ;
            ln_nvo_interes := ln_imp_int_ant - ln_nvo_capital ;
            ln_nvo_capital := 0 ;
          End if ;
          ln_mont_pagado := ln_adel_pago ;
        Else
          ln_nvo_interes := ln_imp_int_ant - ln_adel_pago ;
          If ln_nvo_interes < 0 then
            ln_nvo_interes := 0 ;
          End if ;
          ln_int_pagado := ln_adel_pago ;
        End if ;

        ln_fac_pago_ant := ln_fac_pago_act ;
        ln_capital_ant  := ln_nvo_capital ;
        ln_interes_ant  := ln_nvo_interes ;
        ln_fac_pago_ant := nvl(ln_fac_pago_ant,0) ;
        ln_capital_ant  := nvl(ln_capital_ant,0) ;
        ln_interes_ant  := nvl(ln_interes_ant,0) ;
        
        --  Actualiza registro
        Update maestro_remun_gratif_dev
        Set fact_pago    = ln_fac_pago_act ,
            fact_emplear = ln_fact_emplear ,
            capital      = ln_capital ,
            imp_int_gen  = ln_imp_int_gen ,
            imp_int_ant  = ln_imp_int_ant ,
            adel_pago    = ln_adel_pago ,
            nvo_capital  = ln_nvo_capital ,
            nvo_interes  = ln_nvo_interes ,
            int_pagado   = ln_int_pagado ,
            mont_pagado  = ln_mont_pagado
        where current of c_gratificacion ;
  
      End if ;
    
    End Loop ;

  End if ;

End if ;

End if ;

End usp_pla_dev_calculo_gra ;
/
