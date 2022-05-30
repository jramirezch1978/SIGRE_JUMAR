create or replace procedure usp_rh_liq_genera_cronograma (
  as_usuario in char ) is

ln_item             number(2) ;
ln_importe          number(13,2) ;
ln_imp_acum         number(13,2) ;
ln_diferencia       number(13,2) ;
ld_fec_pago         date ;

--  Lectura de liquidaciones para generar cronograma de pago
cursor c_liquidaciones is
  select s.cod_trabajador, s.fec_proceso, s.imp_total, s.forma_pago, s.nro_cuotas,
         s.tipo_doc, s.usuario
  from tt_liq_seleccion_pago s
  where nvl(s.nro_cuotas,0) > 0 and s.forma_pago is not null
  order by s.cod_trabajador ;

begin

--  **************************************************************
--  ***   GENERACION DE CRONOGRAMA DE PAGOS DE LIQUIDACIONES   ***
--  **************************************************************

for rc_liq in c_liquidaciones loop

  ln_item := 0 ;
  if nvl(rc_liq.forma_pago,'0') = '1' then

    ln_item := ln_item + 1 ;
    insert into rh_liq_cnta_crrte_cred_lab (
      cod_trabajador, item, flag_estado, tipo_doc, nro_doc,
      fec_pago, imp_pagado, cod_usr )
    values (
      rc_liq.cod_trabajador, ln_item, '1', rc_liq.tipo_doc, null,
      rc_liq.fec_proceso, nvl(rc_liq.imp_total,0), rc_liq.usuario ) ;

  elsif nvl(rc_liq.forma_pago,'0') = '2' then

    ln_importe  := nvl(rc_liq.imp_total,0) / nvl(rc_liq.nro_cuotas,0) ;
    ld_fec_pago := rc_liq.fec_proceso ;
    ln_imp_acum := 0 ;

    for x in 1 .. nvl(rc_liq.nro_cuotas,0) loop

      ld_fec_pago := add_months(ld_fec_pago, 1) ;
      ln_imp_acum := ln_imp_acum + ln_importe ;
      
      if x = nvl(rc_liq.nro_cuotas,0) then
        if nvl(ln_imp_acum,0) <> nvl(rc_liq.imp_total,0) then
          ln_diferencia := nvl(rc_liq.imp_total,0) - nvl(ln_imp_acum,0) ;
          ln_importe    := ln_importe + ln_diferencia ;
        end if ;
      end if ;

      ln_item := ln_item + 1 ;
      insert into rh_liq_cnta_crrte_cred_lab (
        cod_trabajador, item, flag_estado, tipo_doc, nro_doc,
        fec_pago, imp_pagado, cod_usr )
      values (
        rc_liq.cod_trabajador, ln_item, '1', rc_liq.tipo_doc, null,
        ld_fec_pago, nvl(ln_importe,0), rc_liq.usuario ) ;

    end loop ;

  end if ;
  
  update rh_liq_credito_laboral l
    set l.flag_forma_pago = nvl(rc_liq.forma_pago,'0')
    where l.cod_trabajador = rc_liq.cod_trabajador ;
  
end loop ;

end usp_rh_liq_genera_cronograma ;
/
