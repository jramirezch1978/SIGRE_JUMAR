create or replace procedure usp_rh_liq_genera_comp_pago (
  as_origen in char ) is

lk_forma_pago       constant char(6) := 'PCON' ;

ls_cnta_prsp        char(10) ;
ls_cod_soles        char(3) ;
ln_verifica         integer ;
ln_tasa_cambio      number(7,3) ;
ls_nro_documento    char(10) ;
ln_nro_documento    number(10) ;
ln_secuencia        number(3) ;
ls_cencos           char(10) ;

--  Lectura de comprobantes de pagos a trabajadores
cursor c_comprobante_pago is
  select p.cod_trabajador, p.item, p.descripcion, p.fec_proceso, p.imp_total,
         p.tipo_doc, p.usuario
  from tt_liq_selec_comp_pago p
  where nvl(p.flag_aprobacion,'0') = '1'
  order by p.cod_trabajador, p.item ;

begin

--  **********************************************************
--  ***   GENERA COMPROBANTES DE PAGOS PARA TRABAJADORES   ***
--  **********************************************************

select p.prsp_pago_liq, p.cencos_liq into ls_cnta_prsp, ls_cencos
  from rh_liqparam p where p.reckey = '1' ;

select l.cod_soles into ls_cod_soles from logparam l
  where l.reckey = '1' ;
  
--  Determina tipo de cambio a la fecha de proceso
ln_verifica := 0 ; ln_tasa_cambio := 0 ;
select count(*) into ln_verifica from calendario c
  where trunc(c.fecha) = trunc(sysdate) ;
if ln_verifica > 0 then
  select nvl(c.vta_dol_prom,0) into ln_tasa_cambio from calendario c
    where trunc(c.fecha) = trunc(sysdate) ;
else
  raise_application_error( -20000, 'No existe tipo de cambio para al  '||
                                   to_char(sysdate,'dd/mm/yyyy') ) ;
end if ;

--  Lectura de trabajadores seleccionados para generar comprobantes
ln_secuencia := 0 ;
for rc_com in c_comprobante_pago loop
  
  --  Determina y actualiza el ultimo numero de documento de la serie
  select nvl(n.ultimo_numero,0) into ln_nro_documento from num_doc_tipo n
    where n.tipo_doc = rc_com.tipo_doc ;
  update num_doc_tipo t
    set t.ultimo_numero = nvl(ln_nro_documento,0) + 1
    where t.tipo_doc = rc_com.tipo_doc ;
  commit ;
  ls_nro_documento := as_origen||lpad(to_char(ln_nro_documento),8,'0') ;

  --  Inserta cuentas por pagar - CABECERA
  insert into cntas_pagar (
    cod_relacion, tipo_doc, nro_doc, flag_estado, fecha_registro,
    fecha_emision, vencimiento, fecha_presentacion, forma_pago,
    cod_moneda, tasa_cambio, cod_usr, origen, descripcion, flag_caja_bancos,
    flag_control_reg, importe_doc, saldo_sol,
    saldo_dol )
  values (
    rc_com.cod_trabajador, rc_com.tipo_doc, ls_nro_documento, '1', sysdate,
    sysdate, rc_com.fec_proceso, sysdate, lk_forma_pago,
    ls_cod_soles, ln_tasa_cambio, rc_com.usuario, as_origen, rc_com.descripcion, '0',
    '0', nvl(rc_com.imp_total,0), nvl(rc_com.imp_total,0),
    (nvl(rc_com.imp_total,0) / nvl(ln_tasa_cambio,0)) ) ;

  --  Inserta cuenta por pagar - DETALLE
  ln_secuencia := ln_secuencia + 1 ;
  insert into cntas_pagar_det (
    cod_relacion, tipo_doc, nro_doc, item,
    descripcion, cantidad, importe, cencos, cnta_prsp )
  values (
    rc_com.cod_trabajador, rc_com.tipo_doc, ls_nro_documento, ln_secuencia,
    rc_com.descripcion, 1, nvl(rc_com.imp_total,0), ls_cencos, ls_cnta_prsp ) ;

  --  Actualiza movimiento seleccionado por trabajador
  update rh_liq_cnta_crrte_cred_lab l
    set l.flag_estado = '2' ,
        l.nro_doc     = ls_nro_documento ,
        l.fec_pago    = rc_com.fec_proceso
    where l.cod_trabajador = rc_com.cod_trabajador and l.item = rc_com.item ;

end loop ;
  
end usp_rh_liq_genera_comp_pago ;
/
