create or replace procedure usp_cierre_actualiza_mov (
  as_codtra         in maestro.cod_trabajador%type ,
  ad_fec_proceso    in date
  ) is

ls_codigo           cnta_crrte.cod_trabajador%type ;
ls_tipo_doc         cnta_crrte.tipo_doc%type ;
ls_numero_doc       cnta_crrte.nro_doc%type ;
ls_flag_estado      cnta_crrte.flag_estado%type ;
ln_numero_cuota     cnta_crrte.nro_cuotas%type ;
ln_saldo            cnta_crrte.sldo_prestamo%type ;
ls_situacion        cnta_crrte.cod_sit_prest%type ;

ln_nro_descuento    cnta_crrte_detalle.nro_dscto%type ;
ln_imp_descuento    cnta_crrte_detalle.imp_dscto%type ;
ln_registros        integer ;

--  Cursor para actualizar saldos de cuentas corrientes
cursor c_saldos is 
  Select cc.cod_trabajador, cc.tipo_doc, cc.nro_doc,
         cc.flag_estado, cc.nro_cuotas, cc.mont_cuota,
         cc.sldo_prestamo, cc.cod_sit_prest
  from cnta_crrte cc
  where cc.cod_trabajador = as_codtra and
        cc.flag_estado = '1'
  order by cc.cod_trabajador, cc.tipo_doc, cc.nro_doc
  for update ;

begin

For rc_sal in c_saldos Loop  

  ls_codigo       := rc_sal.cod_trabajador ;
  ls_tipo_doc     := rc_sal.tipo_doc ;
  ls_numero_doc   := rc_sal.nro_doc ;
  ls_flag_estado  := rc_sal.flag_estado ;
  ln_numero_cuota := rc_sal.nro_cuotas ;
  ln_saldo        := rc_sal.sldo_prestamo ;
  ls_situacion    := rc_sal.cod_sit_prest ;

  ls_flag_estado  := nvl(ls_flag_estado,'0') ;
  ln_numero_cuota := nvl(ln_numero_cuota,1) ;
  ln_saldo        := nvl(ln_saldo,0) ;
  ls_situacion    := nvl(ls_situacion,'C') ;
  
  ln_registros := 0 ;
  Select count(*)
    into ln_registros
    from cnta_crrte_detalle ccd
    where ccd.cod_trabajador = ls_codigo and
          ccd.tipo_doc       = ls_tipo_doc and
          ccd.nro_doc        = ls_numero_doc and
          ccd.fec_dscto      = ad_fec_proceso ;
  
  If ln_registros > 0 then
    Select ccd.nro_dscto, ccd.imp_dscto
      into ln_nro_descuento, ln_imp_descuento
      from cnta_crrte_detalle ccd
      where ccd.cod_trabajador = ls_codigo and
            ccd.tipo_doc       = ls_tipo_doc and
            ccd.nro_doc        = ls_numero_doc and
            ccd.fec_dscto      = ad_fec_proceso ;
    ln_nro_descuento := nvl(ln_nro_descuento,0) ;
    ln_imp_descuento := nvl(ln_imp_descuento,0) ;

    ln_numero_cuota := ln_nro_descuento ;
    ln_saldo        := ln_saldo - ln_imp_descuento ;
    
    If ln_saldo <= 0 then
      ls_flag_estado := '0' ;
      ls_situacion   := 'C' ;
    End if ;
    
    --  Actualiza registro maestro de cuenta corriente
    Update cnta_crrte
    Set flag_estado   = ls_flag_estado ,
        nro_cuotas    = ln_numero_cuota ,
        sldo_prestamo = ln_saldo ,       
        cod_sit_prest = ls_situacion
    where current of c_saldos ;

  End if ;  
  
End loop ;

end usp_cierre_actualiza_mov ;
/
