create or replace procedure usp_pla_pago_sin_cnta_ahorro (
  as_origen in char, as_usuario in char, ad_fec_proceso in date ) is

ln_contador          integer ;
ls_codigo            char(8) ;
ls_tipo_doc          char(4) ;
ls_nro_doc           char(10) ;
ln_tipo_cambio       number(7,3) ;
ln_importe           number(13,2) ;

--  Lectura del personal sin cuenta de ahorro
cursor c_maestro is
  select m.cod_trabajador
    from maestro m
    where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
          (m.nro_cnta_ahorro = ' ' or m.nro_cnta_ahorro = null)
    order by m.cod_trabajador ;

begin

--  Determina tipo de documento del registro de parametros
select nvl(rh.doc_pago_sin_cnta,' ')
  into ls_tipo_doc
  from rrhhparam rh
  where rh.reckey = '1' ;
ls_nro_doc := to_char(ad_fec_proceso,'YYYY/MM/DD') ;

--  Elimina movimiento generado para pagos via cheque
delete from cntas_pagar_det pd
  where pd.tipo_doc = ls_tipo_doc and pd.nro_doc = ls_nro_doc ;
        
delete from cntas_pagar pc
  where pc.tipo_doc = ls_tipo_doc and pc.nro_doc = ls_nro_doc ;
  
--  Determina tipo de cambio del dia
ln_contador := 0 ; ln_tipo_cambio := 0 ;
select count(*)
  into ln_contador
  from calendario c
  where to_char(c.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
if ln_contador > 0 then
  select c.vta_dol_prom
    into ln_tipo_cambio
    from calendario c
    where to_char(c.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
end if ;
  
for rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ln_importe := 0 ;
  
  --  Determina importe a pagar via cheque
  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from calculo cal
    where cal.cod_trabajador = ls_codigo and cal.concep = '2354' and
          to_char(cal.fec_proceso,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY')
          and cal.imp_soles > 0 ;

  if ln_contador > 0 then

    select nvl(cal.imp_soles,0)
      into ln_importe
      from calculo cal
      where cal.cod_trabajador = ls_codigo and cal.concep = '2354' and
            to_char(cal.fec_proceso,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
  
    --  Inserta registro de cabecera
    insert into cntas_pagar (
      cod_relacion, tipo_doc, nro_doc, flag_estado,
      fecha_registro, fecha_emision, vencimiento, cod_moneda,
      tasa_cambio, total_pagar, total_pagado, cod_usr, origen,
      descripcion )
    values (
      ls_codigo, ls_tipo_doc, ls_nro_doc, '1',
      ad_fec_proceso, sysdate, ad_fec_proceso, 'S/.',
      ln_tipo_cambio, ln_importe, 0, as_usuario, as_origen,
      'PAGO AL PERSONAL SIN CUENTA DE AHORRO' ) ;

    --  Inserta registro de detalle
    insert into cntas_pagar_det (
      cod_relacion, tipo_doc, nro_doc, item,
      descripcion, cantidad, importe )
    values (
      ls_codigo, ls_tipo_doc, ls_nro_doc, 1,
      'PAGO AL PERSONAL SIN CUENTA DE AHORRO', 1, ln_importe ) ;

  end if ;
  
end loop ;

end usp_pla_pago_sin_cnta_ahorro ;
/
