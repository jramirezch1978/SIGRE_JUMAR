create or replace procedure usp_rh_pago_jud_alimentista (
  as_origen in char, as_usuario in char, ad_fec_proceso in date,
  as_tipo_trabaj in char ) is

lk_descripcion       constant varchar2(60) := 'PAGO AL PERSONAL JUDICIAL ALIMENTISTA' ;
lk_cencos            constant char(10) := '80601' ;

ln_contador          integer ;
ls_codigo            char(8) ;
ls_tipo_doc          char(4) ;
ls_nro_doc           char(10) ;
ls_cencos            char(10) ;
ln_tipo_cambio       number(7,3) ;
ln_importe           number(13,2) ;
ln_imp_dolar         number(13,2) ;
ls_fec_doc           char(6) ;

--  Lectura de alimentistas por descuento judicial
cursor c_judicial is
  select j.importe, j.cod_alimentista, m.cod_trabajador, m.cencos
  from judicial j, maestro m, calculo c
  where j.cod_trabajador = m.cod_trabajador and
        (j.cod_trabajador = c.cod_trabajador and j.concep = c.concep) and
        j.flag_estado = '1' and nvl(j.importe,0) <> 0.00 and
        (j.cod_alimentista <> ' ' or j.cod_alimentista is not null) and
        (nvl(j.nro_cnta_ahorro,' ') = ' ' ) and
        m.cod_origen = as_origen and m.tipo_trabajador like as_tipo_trabaj
  order by j.cod_alimentista ;

begin

--  ****************************************************************
--  ***   GENERA C.E. AL PERSONAL QUE TIENE DESCUENTO JUDICIAL   ***
--  ****************************************************************

select rh.doc_pago_alimentista into ls_tipo_doc from rrhhparam rh
  where rh.reckey = '1' ;
if ls_tipo_doc is null then
  return ;
end if ;

ls_fec_doc := substr(to_char(ad_fec_proceso,'yyyy'),3,2)||to_char(ad_fec_proceso,'mmdd') ;

delete from cntas_pagar_det d
  where d.tipo_doc = ls_tipo_doc and substr(d.nro_doc,5,6) = ls_fec_doc ;

delete from cntas_pagar p
  where p.tipo_doc = ls_tipo_doc and substr(p.nro_doc,5,6) = ls_fec_doc ;

ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*) into ln_contador from calendario c
  where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,1) into ln_tipo_cambio from calendario c
    where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
end if ;

for rc_jud in c_judicial loop

  ls_codigo    := rc_jud.cod_alimentista ;
  ln_importe   := nvl(rc_jud.importe,0) ;
  ln_imp_dolar := ln_importe / ln_tipo_cambio ;
  ls_cencos    := rc_jud.cencos ;
  ls_nro_doc   := substr(rc_jud.cod_trabajador,5,4)||
                  substr(to_char(ad_fec_proceso,'yyyy'),3,2)||
                  to_char(ad_fec_proceso,'mmdd') ;

  ln_contador := 0 ;
  select count(*) into ln_contador from cntas_pagar cp
    where cp.cod_relacion = ls_codigo and cp.tipo_doc = ls_tipo_doc and
          cp.nro_doc = ls_nro_doc ;
  if ln_contador > 0 then
    update cntas_pagar
      set importe_doc = importe_doc + ln_importe ,
          saldo_sol   = saldo_sol + ln_importe ,
          saldo_dol   = saldo_dol + ln_imp_dolar,
          flag_replicacion = '1'
    where cod_relacion = ls_codigo and tipo_doc = ls_tipo_doc and
          nro_doc = ls_nro_doc ;
  else
    --  Inserta registro de cabecera
    insert into cntas_pagar (
      cod_relacion, tipo_doc, nro_doc, flag_estado, fecha_registro,
      fecha_emision, vencimiento, cod_moneda, tasa_cambio,flag_provisionado,
      importe_doc, saldo_sol, saldo_dol, cod_usr, origen, descripcion, flag_replicacion )
    values (
      ls_codigo, ls_tipo_doc, ls_nro_doc, '1', ad_fec_proceso,
      sysdate, ad_fec_proceso, 'S/.', ln_tipo_cambio, 'D',
      ln_importe, ln_importe, ln_imp_dolar, as_usuario, as_origen, lk_descripcion, '0' ) ;
  end if ;

  ln_contador := 0 ;
  select count(*) into ln_contador from cntas_pagar_det cpd
    where cpd.cod_relacion = ls_codigo and cpd.tipo_doc = ls_tipo_doc and
          cpd.nro_doc = ls_nro_doc ;
  if ln_contador > 0 then
    update cntas_pagar_det
      set importe = importe + ln_importe,
         flag_replicacion = '1'
    where cod_relacion = ls_codigo and tipo_doc = ls_tipo_doc and
          nro_doc = ls_nro_doc ;
  else
    --  Inserta registro de detalle
    insert into cntas_pagar_det (
      cod_relacion, tipo_doc, nro_doc, item, descripcion, cantidad, importe,
      cencos, cnta_prsp, flag_replicacion )
    values (
      ls_codigo, ls_tipo_doc, ls_nro_doc, 1, lk_descripcion, 1, ln_importe,
      lk_cencos, '4010.00.04', '1' ) ;
  end if ;

end loop ;

end usp_rh_pago_jud_alimentista ;
/
