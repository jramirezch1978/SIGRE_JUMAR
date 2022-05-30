create or replace procedure usp_rh_cierre_cuenta_corriente (
  as_codtra in char, ad_fec_proceso in date ) is

ls_flag_estado      cnta_crrte.flag_estado%type ;
ln_saldo            cnta_crrte.sldo_prestamo%type ;
ls_situacion        cnta_crrte.cod_sit_prest%type ;

ln_nro_descuento    cnta_crrte_detalle.nro_dscto%type ;
ln_imp_descuento    cnta_crrte_detalle.imp_dscto%type ;
ln_registros        integer ;

--  Cursor para actualizar saldos de cuentas corrientes
cursor c_saldos is
  select cc.cod_trabajador, cc.tipo_doc, cc.nro_doc, cc.flag_estado,
         cc.nro_cuotas, cc.mont_cuota, cc.sldo_prestamo, cc.cod_sit_prest
  from cnta_crrte cc
  where cc.cod_trabajador = as_codtra and cc.flag_estado = '1'
  order by cc.cod_trabajador, cc.tipo_doc, cc.nro_doc
  for update ;

begin

--  ***************************************************************
--  ***   ACTUALIZA SALDOS DE CUENTA CORRIENTE POR TRABAJADOR   ***
--  ***************************************************************

for rc_sal in c_saldos loop

  ls_flag_estado := nvl(rc_sal.flag_estado,'0') ;
  ls_situacion   := nvl(rc_sal.cod_sit_prest,'C') ;

  ln_registros := 0 ;
  select count(*) into ln_registros from cnta_crrte_detalle ccd
    where ccd.cod_trabajador = rc_sal.cod_trabajador and ccd.tipo_doc = rc_sal.tipo_doc and
          ccd.nro_doc = rc_sal.nro_doc and ccd.fec_dscto = ad_fec_proceso ;

  if ln_registros > 0 then

    select nvl(ccd.nro_dscto,0), nvl(ccd.imp_dscto,0)
      into ln_nro_descuento, ln_imp_descuento
      from cnta_crrte_detalle ccd
      where ccd.cod_trabajador = rc_sal.cod_trabajador and ccd.tipo_doc = rc_sal.tipo_doc and
            ccd.nro_doc = rc_sal.nro_doc and ccd.fec_dscto = ad_fec_proceso ;

    ln_saldo := nvl(rc_sal.sldo_prestamo,0) - ln_imp_descuento ;

    if ln_saldo <= 0 then
      ls_flag_estado := '0' ; ls_situacion := 'C' ;
    end if ;

    --  Actualiza registro maestro de cuenta corriente
    update cnta_crrte
    set flag_estado      = ls_flag_estado ,
        nro_cuotas       = ln_nro_descuento ,
        sldo_prestamo    = ln_saldo ,
        cod_sit_prest    = ls_situacion,
        flag_replicacion = '1'
    where current of c_saldos ;

  end if ;

end loop ;

end usp_rh_cierre_cuenta_corriente ;
/
