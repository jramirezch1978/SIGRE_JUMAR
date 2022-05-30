create or replace procedure usp_rpt_jub_liquidacion
(  as_codtra        in maestro.cod_trabajador%type, 
   ad_fec_proceso   in date ) is

ls_codigo                 sldo_deuda_jubilado.cod_jubilado%type ;
ln_secuencia              sldo_deuda_jubilado.sec_herederos%type ;
ls_concepto               sldo_deuda_jubilado.concep%type ;
ld_fecha_actual           sldo_deuda_jubilado.fec_actual%type ;
ls_flag_estado            sldo_deuda_jubilado.flag_estado%type ;
ln_capital                sldo_deuda_jubilado.imp_sldo_capital%type ;
ln_interes                sldo_deuda_jubilado.imp_sldo_interes%type ;
ln_capital_adelanto       sldo_deuda_jubilado.imp_sldo_capital%type ;
ln_interes_adelanto       sldo_deuda_jubilado.imp_sldo_interes%type ;
ln_saldo_capital          sldo_deuda_jubilado.imp_sldo_capital%type ;
ln_saldo_interes          sldo_deuda_jubilado.imp_sldo_interes%type ;
ln_saldo_capital_interes  sldo_deuda_jubilado.imp_sldo_interes%type ;

ls_nombres                varchar2(35) ;
ls_descripcion            varchar2(35) ;
ld_fecha_cese             date ;

--  Cursor para hallar saldos por capital e interes
cursor c_saldos is 
  Select sdj.cod_jubilado, sdj.sec_herederos, sdj.concep,
         sdj.fec_actual, sdj.flag_estado, sdj.imp_original,
         sdj.imp_acum_interes, sdj.imp_acum_adel_capital,
         sdj.imp_acum_adel_interes, sdj.imp_sldo_capital,
         sdj.imp_sldo_interes
  from sldo_deuda_jubilado sdj
  where sdj.cod_jubilado = as_codtra and
        sdj.fec_actual   = ad_fec_proceso
  order by sdj.fec_actual, sdj.cod_jubilado, sdj.sec_herederos,
           sdj.concep ;

begin

delete from tt_rpt_jub_liquidacion ;

Select m.fec_cese
  into ld_fecha_cese
  from maestro m
  where m.cod_trabajador = as_codtra ;
ld_fecha_cese := nvl(ld_fecha_cese,ad_fec_proceso) ;

For rc_sal in c_saldos Loop  

  ls_codigo           := rc_sal.cod_jubilado ;
  ln_secuencia        := rc_sal.sec_herederos ;
  ls_concepto         := rc_sal.concep ;
  ln_capital          := rc_sal.imp_original ;
  ln_interes          := rc_sal.imp_acum_interes ;
  ln_capital_adelanto := rc_sal.imp_acum_adel_capital ;
  ln_interes_adelanto := rc_sal.imp_acum_adel_interes ;
  ln_saldo_capital    := rc_sal.imp_sldo_capital ;
  ln_saldo_interes    := rc_sal.imp_sldo_interes ;

  ln_capital          := nvl(ln_capital,0) ;
  ln_interes          := nvl(ln_interes,0) ;
  ln_capital_adelanto := nvl(ln_capital_adelanto,0) ;
  ln_interes_adelanto := nvl(ln_interes_adelanto,0) ;
  ln_saldo_capital    := nvl(ln_saldo_capital,0) ;
  ln_saldo_interes    := nvl(ln_saldo_interes,0) ;

  ln_saldo_capital_interes := ln_saldo_capital + ln_saldo_interes ;

  Select c.desc_breve
    into ls_descripcion
    from concepto c
    where c.concep = ls_concepto ;
  ls_concepto := nvl(ls_concepto,'    ') ;

  Select rtrim(hj.apel_paterno)||' '||rtrim(hj.apel_materno)||' '||
         nvl(rtrim(hj.nombre1),' ')||' '||nvl(rtrim(hj.nombre2),' ')
    into ls_nombres
    from herederos_jubilados hj
    where hj.cod_jubilado  = ls_codigo and
          hj.sec_herederos = ln_secuencia ;
  ls_nombres := nvl(ls_nombres,' ') ;

  --  Insertar los Registro en la tabla tt_rpt_jub_liquidacion
  Insert into tt_rpt_jub_liquidacion
    (codigo, secuencia, nombres, fecha_cese,
     concepto, descripcion,
     capital_importe, capital_adelanto, capital_saldo,
     interes_importe, interes_adelanto, interes_saldo,
     saldo_capital_interes, fecha_proceso) 
  Values
    (ls_codigo, ln_secuencia, ls_nombres, ld_fecha_cese,
     ls_concepto, ls_descripcion,
     ln_capital, ln_capital_adelanto, ln_saldo_capital,
     ln_interes, ln_interes_adelanto, ln_saldo_interes,
     ln_saldo_capital_interes, ad_fec_proceso) ;
     
End loop ;

End usp_rpt_jub_liquidacion ;
/
