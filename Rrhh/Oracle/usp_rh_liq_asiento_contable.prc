create or replace procedure usp_rh_liq_asiento_contable (
  as_cod_trabajador in char, as_nombres in char, as_origen in char,
  as_usuario in char, ad_fec_proceso in date ) is

lk_nro_libro              constant number(3)    := 044 ;
lk_descripcion            constant varchar2(60) := 'LIQUIDACION DE CREDITO LABORAL' ;

ln_verifica               integer ;
ln_provisional            number(10) ;
ln_tipo_cambio            number(7,3) ;
ls_soles                  char(3) ;
ln_imp_soles              number(13,2) ;
ln_imp_dolar              number(13,2) ;

ln_total_soldeb           number(13,2) ;
ln_total_solhab           number(13,2) ;
ln_total_doldeb           number(13,2) ;
ln_total_dolhab           number(13,2) ;

--  Lectura de movimiento para generar pre-asientos
cursor c_movimiento is
  select a.fec_liquidacion, a.item, a.cuenta, a.flag_debhab, a.cencos,
         a.cod_relacion, a.tipo_doc, a.nro_doc, a.glosa, a.imp_debe, a.imp_haber
  from tt_liq_rpt_asiento a
  where a.cod_trabajador = as_cod_trabajador
  order by a.cod_trabajador, a.item ;

begin

--  *************************************************************
--  ***   GENERACION DE ASIENTOS CONTABLES DE LIQUIDACIONES   ***
--  *************************************************************

/*
--  Determina fecha de liquidacion del trabajador
select l.fec_liquidacion into ad_fec_proceso
  from rh_liq_credito_laboral l
  where l.cod_trabajador = as_cod_trabajador ;
*/
  
--  Verifica si liquidacion ya existe como pre-asiento
ln_verifica := 0 ;
select count(*) into ln_verifica from cntbl_pre_asiento_det d
  where trunc(d.fec_cntbl) = trunc(ad_fec_proceso) and
        d.cod_relacion = as_cod_trabajador and d.nro_libro = lk_nro_libro ;
if ln_verifica > 0 then
  select max(d.nro_provisional) into ln_provisional from cntbl_pre_asiento_det d
    where trunc(d.fec_cntbl) = trunc(ad_fec_proceso) and
          d.cod_relacion = as_cod_trabajador and d.nro_libro = lk_nro_libro ;
  --  Elimina registros del pre-asiento
  delete cntbl_pre_asiento_det_aux a
    where a.nro_libro = lk_nro_libro and a.nro_provisional = ln_provisional ;
  delete cntbl_pre_asiento_det d
    where d.nro_libro = lk_nro_libro and d.nro_provisional = ln_provisional ;
  delete cntbl_pre_asiento c
    where c.nro_libro = lk_nro_libro and c.nro_provisional = ln_provisional ;
end if ;  

--  Determina tipo de cambio a la fecha de liquidacion
ln_verifica := 0 ; ln_tipo_cambio := 0 ;
select count(*) into ln_verifica from calendario cal
  where trunc(cal.fecha) = trunc(ad_fec_proceso) ;
if ln_verifica > 0 then
  select nvl(cal.vta_dol_prom,0) into ln_tipo_cambio from calendario cal
    where trunc(cal.fecha) = trunc(ad_fec_proceso) ;
end if ;

--  Determina numero provisional para generar pre-asiento
ln_verifica := 0 ; ln_provisional := 0 ;
select count(*) into ln_verifica from cntbl_libro l
  where l.nro_libro = lk_nro_libro ;
if ln_verifica = 0 then
  ln_provisional := 1 ;
  insert into cntbl_libro ( nro_libro, desc_libro, num_provisional )
  values ( lk_nro_libro, substr(lk_descripcion,1,40), ln_provisional ) ;
else
  select nvl(l.num_provisional,0) into ln_provisional from cntbl_libro l
    where l.nro_libro = lk_nro_libro ;
  ln_provisional := nvl(ln_provisional,0) + 1 ;
end if ;

--  Adiciona registro de cabecera al pre-asiento
select p.cod_soles into ls_soles from logparam p where p.reckey = '1' ;
insert into cntbl_pre_asiento (
  origen, nro_libro, nro_provisional, cod_moneda, tasa_cambio,
  desc_glosa, fec_cntbl, fec_registro, cod_usr, flag_estado,
  tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab )
values (
  as_origen, lk_nro_libro, ln_provisional, ls_soles, ln_tipo_cambio,
  lk_descripcion, ad_fec_proceso, ad_fec_proceso, as_usuario, '1',
  0, 0, 0, 0 ) ;

--  Crea archivo temporal para generar asiento contable
usp_rh_liq_rpt_asiento
  ( as_cod_trabajador, as_nombres ) ;

--  Genera registros al pre-asiento de las liquidaciones
for rc_mov in c_movimiento loop

  ln_imp_soles := 0 ; ln_imp_dolar := 0 ;
  if rc_mov.flag_debhab = 'D' then
    ln_imp_soles := nvl(rc_mov.imp_debe,0) ;
  else
    ln_imp_soles := nvl(rc_mov.imp_haber,0) ;
  end if ;
  ln_imp_dolar := nvl(ln_imp_soles,0) / nvl(ln_tipo_cambio,0) ;

  insert into cntbl_pre_asiento_det (
    origen, nro_libro, nro_provisional, cnta_ctbl, fec_cntbl,
    det_glosa, flag_debhab, cencos, tipo_docref, nro_docref1,
    cod_relacion, imp_movsol, imp_movdol, item )
  values (
    as_origen, lk_nro_libro, ln_provisional, rc_mov.cuenta, ad_fec_proceso,
    rc_mov.glosa, rc_mov.flag_debhab, rc_mov.cencos, rc_mov.tipo_doc, rc_mov.nro_doc,
    rc_mov.cod_relacion, ln_imp_soles, ln_imp_dolar, rc_mov.item ) ;

end loop ;

--  Actualiza numero provisional
update cntbl_libro
  set num_provisional = ln_provisional
  where nro_libro = lk_nro_libro ;

--  Actualiza importes del registro de cabebcera
ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
select sum(d.imp_movsol), sum(d.imp_movdol)
  into ln_total_soldeb, ln_total_doldeb
  from cntbl_pre_asiento_det d
  where d.origen = as_origen and d.nro_libro = lk_nro_libro and
        d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
        d.flag_debhab = 'D' ;
select sum(d.imp_movsol), sum(d.imp_movdol)
  into ln_total_solhab, ln_total_dolhab
  from cntbl_pre_asiento_det d
  where d.origen = as_origen and d.nro_libro = lk_nro_libro and
        d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
        d.flag_debhab = 'H' ;
  
update cntbl_pre_asiento
  set tot_soldeb = ln_total_soldeb ,
      tot_solhab = ln_total_solhab ,
      tot_doldeb = ln_total_doldeb ,
      tot_dolhab = ln_total_dolhab
  where origen = as_origen and nro_libro = lk_nro_libro and
        nro_provisional = ln_provisional and fec_cntbl = ad_fec_proceso ;

end usp_rh_liq_asiento_contable ;
/
