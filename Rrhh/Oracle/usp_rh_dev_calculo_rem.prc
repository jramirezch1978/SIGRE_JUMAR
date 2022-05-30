create or replace procedure usp_rh_dev_calculo_rem (
  as_codtra in char, ad_fec_proceso in date, ad_fec_anterior in date ) is

lk_dev_gra         char(3) ;

ln_verifica        integer ;
ln_contador        integer ;
ls_concepto        char(4) ;

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

--  Cursor de pagos por remuneraciones devengadas
cursor c_remuneracion is
  select rgd.fec_pago, rgd.fact_pago, rgd.fact_emplear, rgd.capital,
         rgd.imp_int_gen, rgd.imp_int_ant, rgd.adel_pago, rgd.nvo_capital,
         rgd.nvo_interes, rgd.mont_pagado, rgd.int_pagado, rgd.fec_calc_int
  from maestro_remun_gratif_dev rgd
  where rgd.cod_trabajador = as_codtra and rgd.concep in ( select g.concepto_gen
          from grupo_calculo g  where g.grupo_calculo = lk_dev_gra )
  order by rgd.cod_trabajador, rgd.fec_calc_int, rgd.fec_pago
  for update ;

begin

--  ********************************************************************
--  ***   CALCULA INTERESES POR PAGOS DE REMUNERACIONES DEVENGADAS   ***
--  ********************************************************************

select c.remun_deveng
  into lk_dev_gra
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

ln_verifica := 0 ;
select count(*) into ln_verifica from sldo_deveng sd
  where sd.cod_trabajador = as_codtra and sd.fec_proceso = ad_fec_anterior
        and nvl(sd.sldo_rem_dev,0) > 0 ;

if ln_contador > 0 then

  for rc_rem in c_remuneracion loop
    if to_char(rc_rem.fec_calc_int,'mm/yyyy') <>
      to_char(ad_fec_proceso,'mm/yyyy') then
      ln_fac_pago_ant := nvl(rc_rem.fact_pago,0) ;
      ln_capital_ant  := nvl(rc_rem.nvo_capital,0) ;
      ln_interes_ant  := nvl(rc_rem.nvo_interes,0) ;
    end if ;
  end loop ;

  if ln_capital_ant > 0 or ln_interes_ant > 0 then

    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_dev_gra ;

    ln_contador := 0 ;
    select count(*) into ln_contador from maestro_remun_gratif_dev rgd
      where rgd.cod_trabajador = as_codtra and to_char(rgd.fec_calc_int,'mm/yyyy') =
            to_char(ad_fec_proceso,'mm/yyyy') and rgd.concep = ls_concepto ;

    if ln_contador = 0 then

      select nvl(fp.fact_interes,0) into ln_fac_pago_act from factor_planilla fp
        where fp.fec_calc_int = ad_fec_proceso ;

      ln_adel_pago    := 0 ;
      ln_fact_emplear := ln_fac_pago_act - ln_fac_pago_ant ;
      ln_capital      := ln_capital_ant ;
      ln_imp_int_ant  := ln_interes_ant ;
      ln_imp_int_gen  := ln_capital * ln_fact_emplear ;
      ln_nvo_interes  := ln_imp_int_ant + ln_imp_int_gen ;
      if ln_capital > 0 then
        ln_nvo_capital := ln_capital - ln_adel_pago ;
        if ln_nvo_capital < 0 then
          ln_nvo_capital := ln_nvo_capital * (-1)  ;
          ln_nvo_interes := ln_imp_int_ant - ln_nvo_capital ;
          ln_nvo_capital := 0 ;
        end if ;
        ln_mont_pagado := ln_adel_pago ;
      else
        ln_nvo_interes := ln_imp_int_ant - ln_adel_pago ;
        if ln_nvo_interes < 0 then
          ln_nvo_interes := 0 ;
        end if ;
        ln_int_pagado := ln_adel_pago ;
      end if ;

      insert into maestro_remun_gratif_dev (
        cod_trabajador, fec_calc_int, concep, flag_estado, fec_pago, fact_pago,
        fact_emplear, capital, imp_int_gen, imp_int_ant, adel_pago,
        nvo_capital,  nvo_interes, int_pagado, mont_pagado, flag_replicacion )
      values (
        as_codtra, ad_fec_proceso, ls_concepto, '1', ad_fec_proceso, ln_fac_pago_act,
        ln_fact_emplear, ln_capital, ln_imp_int_gen, ln_imp_int_ant, ln_adel_pago,
        ln_nvo_capital, ln_nvo_interes, ln_int_pagado, ln_mont_pagado, '1' ) ;

    else

      for rc_rem in c_remuneracion loop

        if to_char(rc_rem.fec_calc_int,'mm/yyyy') =
          to_char(ad_fec_proceso,'mm/yyyy') then

          select nvl(fp.fact_interes,0) into ln_fac_pago_act from factor_planilla fp
            where fp.fec_calc_int = rc_rem.fec_pago ;

          ln_adel_pago    := rc_rem.adel_pago ;
          ln_fact_emplear := ln_fac_pago_act - ln_fac_pago_ant ;
          ln_capital      := ln_capital_ant ;
          ln_imp_int_ant  := ln_interes_ant ;
          ln_imp_int_gen  := ln_capital * ln_fact_emplear ;
          ln_nvo_interes  := ln_imp_int_ant + ln_imp_int_gen ;
          if ln_capital > 0 then
            ln_nvo_capital := ln_capital - ln_adel_pago ;
            if ln_nvo_capital < 0 then
              ln_nvo_capital := ln_nvo_capital * (-1) ;
              ln_nvo_interes := ln_imp_int_ant - ln_nvo_capital ;
              ln_nvo_capital := 0 ;
            end if ;
            ln_mont_pagado := ln_adel_pago ;
          else
            ln_nvo_interes := ln_imp_int_ant - ln_adel_pago ;
            if ln_nvo_interes < 0 then
              ln_nvo_interes := 0 ;
            end if ;
            ln_int_pagado := ln_adel_pago ;
          end if ;

          ln_fac_pago_ant := nvl(ln_fac_pago_act,0) ;
          ln_capital_ant  := nvl(ln_nvo_capital,0) ;
          ln_interes_ant  := nvl(ln_nvo_interes,0) ;

          update maestro_remun_gratif_dev
          set fact_pago    = ln_fac_pago_act ,
              fact_emplear = ln_fact_emplear ,
              capital      = ln_capital ,
              imp_int_gen  = ln_imp_int_gen ,
              imp_int_ant  = ln_imp_int_ant ,
              adel_pago    = ln_adel_pago ,
              nvo_capital  = ln_nvo_capital ,
              nvo_interes  = ln_nvo_interes ,
              int_pagado   = ln_int_pagado ,
              mont_pagado  = ln_mont_pagado,
              flag_replicacion = '1'
          where current of c_remuneracion ;

        end if ;

      end loop ;

    end if ;

  end if ;

end if ;

end usp_rh_dev_calculo_rem ;
/
