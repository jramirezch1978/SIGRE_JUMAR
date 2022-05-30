create or replace procedure usp_rh_pago_sin_cnta_ahorro (
  as_origen in char, as_usuario in char, ad_fec_proceso in date,
  as_tipo_trabaj in char ) is

lk_descripcion       constant varchar2(60) := 'PAGO AL PERSONAL SIN CUENTA DE AHORRO' ;

ln_contador          integer ;
ln_verifica          integer ;
ls_concepto          char(4) ;
ls_tipo_doc          char(4) ;
ls_nro_doc           char(10) ;
ln_tipo_cambio       number(7,3) ;
ln_importe           number(13,2) ;
ln_imp_dolar         number(13,2) ;

--  Lectura del personal sin cuenta de ahorro
cursor c_maestro is
  select m.cod_trabajador, m.cencos
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        (m.nro_cnta_ahorro = ' ' or m.nro_cnta_ahorro is null) and
        m.cod_origen = as_origen and m.tipo_trabajador like as_tipo_trabaj
  order by m.cod_trabajador ;

begin

--  ********************************************************
--  ***   GENERA C.E. AL PERSONAL SIN CUENTA DE AHORRO   ***
--  ********************************************************

select rh.doc_pago_sin_cnta, rh.cnc_total_pgd
  into ls_tipo_doc, ls_concepto from rrhhparam rh
  where rh.reckey = '1' ;
if ls_tipo_doc is null then
  return ;
end if ;
ls_nro_doc := to_char(ad_fec_proceso,'yyyy/mm/dd') ;

ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*) into ln_contador from calendario c
  where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,1) into ln_tipo_cambio from calendario c
    where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
end if ;

for rc_mae in c_maestro loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica from cntas_pagar pd
    where pd.tipo_doc = ls_tipo_doc and pd.nro_doc = ls_nro_doc and
          pd.cod_relacion = rc_mae.cod_trabajador and pd.flag_estado = '1' ;
    
  if ln_verifica = 0 then
  
    delete from cntas_pagar_det pd
      where pd.tipo_doc = ls_tipo_doc and pd.nro_doc = ls_nro_doc and
            pd.cod_relacion = rc_mae.cod_trabajador ;

    delete from cntas_pagar pc
      where pc.tipo_doc = ls_tipo_doc and pc.nro_doc = ls_nro_doc and
            pc.cod_relacion = rc_mae.cod_trabajador ;

  end if ;
  
  ln_contador := 0 ;
  select count(*) into ln_contador from calculo cal
    where cal.cod_trabajador = rc_mae.cod_trabajador and cal.concep = ls_concepto and
          to_char(cal.fec_proceso,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy')
          and nvl(cal.imp_soles,0) > 0 ;

  if ln_contador > 0 and ln_verifica = 0 then

    select nvl(cal.imp_soles,0) into ln_importe from calculo cal
      where cal.cod_trabajador = rc_mae.cod_trabajador and cal.concep = ls_concepto and
            to_char(cal.fec_proceso,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;

    --  Inserta registro de cabecera
    insert into cntas_pagar (
      cod_relacion, tipo_doc, nro_doc, flag_estado, fecha_registro, fecha_emision,
      vencimiento, cod_moneda, tasa_cambio, flag_provisionado, importe_doc,
      saldo_sol, saldo_dol, cod_usr, origen, descripcion, flag_replicacion )
    values (
      rc_mae.cod_trabajador, ls_tipo_doc, ls_nro_doc, '1', ad_fec_proceso, sysdate,
      ad_fec_proceso, 'S/.', ln_tipo_cambio, 'D', ln_importe,
      ln_importe, ln_imp_dolar, as_usuario, as_origen, lk_descripcion, '1' ) ;

    --  Inserta registro de detalle
    insert into cntas_pagar_det (
      cod_relacion, tipo_doc, nro_doc, item, descripcion, cantidad, importe,
      cencos, cnta_prsp, flag_replicacion )
    values (
      rc_mae.cod_trabajador, ls_tipo_doc, ls_nro_doc, 1, lk_descripcion, 1, ln_importe,
      '83410', '4040.03.01', '1' ) ;

  end if ;

end loop ;

end usp_rh_pago_sin_cnta_ahorro ;
/
