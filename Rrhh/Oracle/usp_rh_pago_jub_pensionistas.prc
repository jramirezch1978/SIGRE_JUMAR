create or replace procedure usp_rh_pago_jub_pensionistas (
  as_origen in char, as_usuario in char, ad_fec_proceso in date,
  as_tipo_trabaj in char ) is

lk_descripcion       constant varchar2(60) := 'PAGO A JUBILADOS PENSIONISTAS' ;

ln_contador          integer ;
ls_codigo            char(8) ;
ls_tipo_doc          char(4) ;
ls_nro_doc           char(10) ;
ls_cencos            char(10) ;
ln_tipo_cambio       number(7,3) ;
ln_importe           number(13,2) ;
ln_imp_dolar         number(13,2) ;

--  Lectura de los jubilados pensionistas
cursor c_jubilados is
  select j.cod_trabajador, j.importe, m.cencos
  from jubilado_pagos j, maestro m
  where j.cod_trabajador = m.cod_trabajador and j.flag_estado = '1' and
        to_char(j.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy')
        and m.cod_origen = as_origen and m.tipo_trabajador like as_tipo_trabaj
  order by j.cod_trabajador ;

begin

--  ********************************************************
--  ***   GENERA C.E. AL PERSONAL JUBILADO PENSIONISTA   ***
--  ********************************************************

select rh.doc_pago_jubilado into ls_tipo_doc from rrhhparam rh
  where rh.reckey = '1' ;
if ls_tipo_doc is null then
  return ;
end if ;
ls_nro_doc := to_char(ad_fec_proceso,'yyyy/mm/dd') ;

ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*) into ln_contador from calendario c
  where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,0) into ln_tipo_cambio from calendario c
    where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
end if ;

for rc_jub in c_jubilados loop

  delete from cntas_pagar_det pd
    where pd.tipo_doc = ls_tipo_doc and pd.nro_doc = ls_nro_doc and
          pd.cod_relacion = rc_jub.cod_trabajador ;

  delete from cntas_pagar pc
    where pc.tipo_doc = ls_tipo_doc and pc.nro_doc = ls_nro_doc and
          pc.cod_relacion = rc_jub.cod_trabajador ;

  ls_codigo    := rc_jub.cod_trabajador ;
  ln_importe   := nvl(rc_jub.importe,0) ;
  ln_imp_dolar := ln_importe / ln_tipo_cambio ;
  ls_cencos    := rc_jub.cencos ;

  --  Inserta registro de cabecera
  insert into cntas_pagar (
    cod_relacion, tipo_doc, nro_doc, flag_estado, fecha_registro,
    fecha_emision, vencimiento, cod_moneda,  tasa_cambio, flag_provisionado, importe_doc,
    saldo_sol, saldo_dol, cod_usr, origen, descripcion, flag_replicacion )
  values (
    ls_codigo, ls_tipo_doc, ls_nro_doc, '1', ad_fec_proceso,
    sysdate, ad_fec_proceso, 'S/.', ln_tipo_cambio, 'D', ln_importe,
    ln_importe, ln_imp_dolar, as_usuario, as_origen, lk_descripcion, '1' ) ;

  --  Inserta registro de detalle
  insert into cntas_pagar_det (
    cod_relacion, tipo_doc, nro_doc, item, descripcion, cantidad, importe,
    cencos, cnta_prsp, flag_replicacion )
  values (
    ls_codigo, ls_tipo_doc, ls_nro_doc, 1, lk_descripcion, 1, ln_importe,
    '83410', '4040.03.01', '1' ) ;

  update jubilado_pagos
    set flag_estado = '2',
         flag_replicacion = '1'
    where cod_trabajador = ls_codigo and fecha = ad_fec_proceso ;

end loop ;

end usp_rh_pago_jub_pensionistas ;
/
