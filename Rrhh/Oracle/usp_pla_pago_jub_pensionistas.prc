create or replace procedure usp_pla_pago_jub_pensionistas (
  as_origen in char, as_usuario in char, ad_fec_proceso in date ) is

ln_contador          integer ;
ls_codigo            char(8) ;
ls_tipo_doc          char(4) ;
ls_nro_doc           char(10) ;
ln_tipo_cambio       number(7,3) ;
ln_importe           number(13,2) ;

--  Lectura de los jubilados pensionistas
cursor c_jubilados is
  select j.cod_trabajador, j.importe
    from jubilado_pagos j
    where j.flag_estado = '1' and
          to_char(j.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY')
    order by j.cod_trabajador ;

begin

--  Determina tipo de documento del registro de parametros
select nvl(rh.doc_pago_jubilado,' ')
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
  
for rc_jub in c_jubilados loop

  ls_codigo  := rc_jub.cod_trabajador ;
  ln_importe := nvl(rc_jub.importe,0) ;
  
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
    'PAGO A JUBILADOS PENSIONISTAS' ) ;

  --  Inserta registro de detalle
  insert into cntas_pagar_det (
    cod_relacion, tipo_doc, nro_doc, item,
    descripcion, cantidad, importe )
  values (
    ls_codigo, ls_tipo_doc, ls_nro_doc, 1,
    'PAGO A JUBILADOS PENSIONISTAS', 1, ln_importe ) ;

  update jubilado_pagos
    set flag_estado = '2'
    where cod_trabajador = ls_codigo and fecha = ad_fec_proceso ;
    
end loop ;

end usp_pla_pago_jub_pensionistas ;
/
