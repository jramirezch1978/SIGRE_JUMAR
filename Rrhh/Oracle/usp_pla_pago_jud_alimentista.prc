create or replace procedure usp_pla_pago_jud_alimentista (
  as_origen in char, as_usuario in char, ad_fec_proceso in date ) is

ln_contador          integer ;
ls_codigo            char(8) ;
ls_tipo_doc          char(4) ;
ls_nro_doc           char(10) ;
ln_tipo_cambio       number(7,3) ;
ln_importe           number(13,2) ;

--  Lectura de alimentistas por descuento judicial
cursor c_judicial is
  select j.importe, j.cod_alimentista
    from judicial j, calculo c
    where (j.cod_trabajador = c.cod_trabajador and j.concep = c.concep) and
          j.flag_estado = '1' and j.importe <> 0.00 and
          (j.cod_alimentista <> ' ' or j.cod_alimentista is not null)
    order by j.cod_alimentista ;

begin

--  Determina tipo de documento del registro de parametros
select nvl(rh.doc_pago_alimentista,' ')
  into ls_tipo_doc
  from rrhhparam rh
  where rh.reckey = '1' ;
ls_nro_doc := to_char(ad_fec_proceso,'YYYY/MM/DD') ;

--  Elimina movimiento generado para pagos via cheque
delete from cntas_pagar_det pd
  where substr(pd.tipo_doc,1,2) = substr(ls_tipo_doc,1,2) and
        pd.nro_doc = ls_nro_doc ;
        
delete from cntas_pagar pc
  where substr(pc.tipo_doc,1,2) = substr(ls_tipo_doc,1,2) and
        pc.nro_doc = ls_nro_doc ;

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
  
for rc_jud in c_judicial loop

  ls_codigo  := rc_jud.cod_alimentista ;
  ln_importe := nvl(rc_jud.importe,0) ;
  
  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from cntas_pagar cp
    where cp.cod_relacion = ls_codigo and cp.tipo_doc = ls_tipo_doc and
          cp.nro_doc = ls_nro_doc ;
  if ln_contador > 0 then
    update cntas_pagar
      set total_pagar = total_pagar + ln_importe
    where cod_relacion = ls_codigo and tipo_doc = ls_tipo_doc and
          nro_doc = ls_nro_doc ;
  else
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
      'PAGO AL PERSONAL JUDICIAL ALIMENTISTA' ) ;
  end if ;
  
  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from cntas_pagar_det cpd
    where cpd.cod_relacion = ls_codigo and cpd.tipo_doc = ls_tipo_doc and
          cpd.nro_doc = ls_nro_doc ;
  if ln_contador > 0 then
    update cntas_pagar_det
      set importe = importe + ln_importe
    where cod_relacion = ls_codigo and tipo_doc = ls_tipo_doc and
          nro_doc = ls_nro_doc ;
  else
    --  Inserta registro de detalle
    insert into cntas_pagar_det (
      cod_relacion, tipo_doc, nro_doc, item,
      descripcion, cantidad, importe )
    values (
      ls_codigo, ls_tipo_doc, ls_nro_doc, 1,
      'PAGO AL PERSONAL JUDICIAL ALIMENTISTA', 1, ln_importe ) ;
  end if ;
  
end loop ;

end usp_pla_pago_jud_alimentista ;
/
