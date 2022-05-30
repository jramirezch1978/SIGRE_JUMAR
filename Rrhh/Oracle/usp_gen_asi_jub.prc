create or replace procedure usp_gen_asi_jub (
  as_tipo_pago in char, as_origen in char, as_usuario in char ) is
   
lk_libro_ade           constant number(3) := 001 ;
lk_libro_int           constant number(3) := 002 ;
ln_nro_libro           number(3) ;
lk_tipo_doc            constant char(4) := 'PLAN' ;
ls_nro_doc             char(10) ;

ln_provisional         number(10) ;
ln_item                number(4) ;
ls_desc_libro          varchar2(40) ;
ls_glosa               varchar2(60) ;
ls_cuenta_deb          char(10) ;
ls_cuenta_hab          char(10) ;
ls_cuenta              char(10) ;
ls_flag_dh             char(1) ;
ld_fec_proceso         date ;
ln_contador            integer ;
ln_tipo_cambio         number(7,3) ;
ls_codigo              char(8) ;
ln_secuencia           number(2) ;

ln_importe          number(13,2) ;
ln_importe_sol      number(13,2) ;  ln_importe_dol      number(13,2) ;
ln_total_soles      number(13,2) ;  ln_total_dolar      number(13,2) ;
ln_total_soldeb     number(13,2) ;  ln_total_solhab     number(13,2) ;
ln_total_doldeb     number(13,2) ;  ln_total_dolhab     number(13,2) ;

--  Cursor del maestro de jubilados
cursor c_movimiento is
  select m.cod_jubilado, m.nro_secuencial
  from mov_variable_jubilado m
  where m.flag_estado = '1'
  order by m.cod_jubilado, m.nro_secuencial ;

--  Cursor para generar asientos contables
cursor c_detalle is
  select d.int_mes, d.dscto_adel_mes
  from detalle_deuda_jubilado d
  where d.cod_jubilado = ls_codigo and
        d.sec_herederos = ln_secuencia and
        to_char(d.fec_pago,'MM/YYYY') = to_char(ld_fec_proceso,'MM/YYYY')
  order by d.cod_jubilado, d.sec_herederos, d.concep ;

begin

if as_tipo_pago = 'ADE' then
  ls_cuenta_deb := '46920200  ' ;
  ls_cuenta_hab := '38999000  ' ;
  ln_nro_libro  := lk_libro_ade ;
  ls_desc_libro := 'ADELANTOS GENERADOS EN EL MES - JUBILADOS' ;
elsif as_tipo_pago = 'INT' then
  ls_cuenta_deb := '97210801  ' ;
  ls_cuenta_hab := '46600301  ' ;
  ln_nro_libro  := lk_libro_int ;
  ls_desc_libro := 'INTERESES GENERADOS EN EL MES - JUBILADOS' ;
end if ;

select p.fec_proceso
  into ld_fec_proceso
  from rrhh_param_org p
  where p.origen = as_origen ;

--select rh.fec_proceso
--  into ld_fec_proceso
--  from rrhhparam rh
--  where rh.reckey = '1' ;
  
--  Determina tipo de cambio
ln_contador := 0 ; ln_tipo_cambio := 0 ;
select count(*)
  into ln_contador from calendario cal
  where cal.fecha = ld_fec_proceso ;
if ln_contador > 0 then
  select nvl(cal.vta_dol_prom,1)
    into ln_tipo_cambio from calendario cal
    where cal.fecha = ld_fec_proceso ;
end if ;

--  Elimina movimiento de asiento generado
delete from cntbl_pre_asiento_det ad
where ad.origen = as_origen and ad.nro_libro = ln_nro_libro and
      to_char(ad.fec_cntbl,'DD/MM/YYYY') = to_char(ld_fec_proceso,'DD/MM/YYYY') ;

delete from cntbl_pre_asiento a
where a.origen = as_origen and a.nro_libro = ln_nro_libro and
      to_char(a.fec_cntbl,'DD/MM/YYYY') = to_char(ld_fec_proceso,'DD/MM/YYYY') ;

--  Determina numero provisional
ln_contador := 0 ;
select count(*)
  into ln_contador
  from cntbl_libro l
  where l.nro_libro = ln_nro_libro ;
if ln_contador = 0 then
  ln_provisional := 1 ;
  insert into cntbl_libro ( nro_libro, desc_libro, num_provisional )
  values ( ln_nro_libro, ls_desc_libro, ln_provisional ) ;
else
  select nvl(l.num_provisional,0)
    into ln_provisional
    from cntbl_libro l
    where l.nro_libro = ln_nro_libro ;
  ln_provisional := ln_provisional + 1 ;
end if ;

--  Adiciona registro de cabecera del pre asiento
insert into cntbl_pre_asiento (
  origen, nro_libro, nro_provisional, cod_moneda, tasa_cambio,
  desc_glosa, fec_cntbl, fec_registro, cod_usr, flag_estado,
  tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab )
values (
  as_origen, ln_nro_libro, ln_provisional, 'S/.', ln_tipo_cambio,
  ls_desc_libro, ld_fec_proceso, ld_fec_proceso, as_usuario, '1',
  0, 0, 0, 0 ) ;

--  Lectura para generacion de asientos del maestro
ln_total_soles := 0 ; ln_total_dolar := 0 ; ln_item := 0 ;
ls_nro_doc := 'PLAN'||to_char(ld_fec_proceso,'MMYYYY') ;
for rc_mov in c_movimiento loop

  ls_codigo    := nvl(rc_mov.cod_jubilado,' ') ;
  ln_secuencia := nvl(rc_mov.nro_secuencial,0) ;

  --  Acumula al detalle para generacion de asientos
  ln_importe_sol := 0 ; ln_importe_dol := 0 ;
  for rc_det in c_detalle loop
    if as_tipo_pago = 'ADE' then
      ln_importe := nvl(rc_det.dscto_adel_mes,0) ;
    elsif as_tipo_pago = 'INT' then
      ln_importe := nvl(rc_det.int_mes,0) ;
    End if ;
    ln_importe_sol := ln_importe_sol + ln_importe ;
  end loop ;
    
  if as_tipo_pago = 'ADE' then
    ls_cuenta  := ls_cuenta_deb ;
    ls_flag_dh := 'D' ;
  elsif as_tipo_pago = 'INT' then
    ls_cuenta  := ls_cuenta_hab ;
    ls_flag_dh := 'H' ;
  end if ;
  select substr(cc.desc_cnta,1,60)
    into ls_glosa from cntbl_cnta cc
    where cc.cnta_ctbl = ls_cuenta ;
  ln_importe_dol := ln_importe_sol / ln_tipo_cambio ;

  --  Graba detalle
  if ln_importe_sol > 0 then
    ln_total_soles := ln_total_soles + ln_importe_sol ;
    ln_total_dolar := ln_total_dolar + ln_importe_dol ;
    ln_item := ln_item + 1 ;
    insert into cntbl_pre_asiento_det (
      origen, nro_libro, nro_provisional, item,
      cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
      tipo_docref, nro_docref1, cod_relacion,
      imp_movsol, imp_movdol, imp_movaju )
    values (
      as_origen, ln_nro_libro, ln_provisional, ln_item,
      ls_cuenta, ld_fec_proceso, ls_glosa, ls_flag_dh,
      lk_tipo_doc, ls_nro_doc, ls_codigo,
      ln_importe_sol, ln_importe_dol, 0 ) ;
  end if ;
  
end loop ;  

--  Graba totales
if as_tipo_pago = 'ADE' then
  ls_cuenta  := ls_cuenta_hab ;
  ls_flag_dh := 'H' ;
elsif as_tipo_pago = 'INT' then
  ls_cuenta  := ls_cuenta_deb ;
  ls_flag_dh := 'D' ;
end if ;
select substr(cc.desc_cnta,1,60)
  into ls_glosa from cntbl_cnta cc
  where cc.cnta_ctbl = ls_cuenta ;

if ln_total_soles > 0 then
  ln_item := ln_item + 1 ;
  insert into cntbl_pre_asiento_det (
    origen, nro_libro, nro_provisional, item,
    cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
    tipo_docref, nro_docref1, cod_relacion,
    imp_movsol, imp_movdol, imp_movaju )
  values (
    as_origen, ln_nro_libro, ln_provisional, ln_item,
    ls_cuenta, ld_fec_proceso, ls_glosa, ls_flag_dh,
    lk_tipo_doc, ls_nro_doc, ls_codigo,
    ln_total_soles, ln_total_dolar, 0 ) ;
end if ;

--  Actualiza nuevo numero provisional
update cntbl_libro
  set num_provisional = ln_provisional
  where nro_libro = ln_nro_libro ;

/*
--  Actualiza importes de cabecera
ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
select sum(d.imp_movsol), sum(d.imp_movdol)
  into ln_total_soldeb, ln_total_doldeb
  from cntbl_pre_asiento_det d
  where d.origen = as_origen and d.nro_libro = ln_nro_libro and
        d.nro_provisional = ln_provisional and d.fec_cntbl = ld_fec_proceso and
        d.flag_debhab = 'D' ;
select sum(d.imp_movsol), sum(d.imp_movdol)
  into ln_total_solhab, ln_total_dolhab
  from cntbl_pre_asiento_det d
  where d.origen = as_origen and d.nro_libro = ln_nro_libro and
        d.nro_provisional = ln_provisional and d.fec_cntbl = ld_fec_proceso and
        d.flag_debhab = 'H' ;
  
update cntbl_pre_asiento
  set tot_soldeb = ln_total_soldeb ,
      tot_solhab = ln_total_solhab ,
      tot_doldeb = ln_total_doldeb ,
      tot_dolhab = ln_total_dolhab
  where origen = as_origen and nro_libro = ln_nro_libro and
        nro_provisional = ln_provisional and fec_cntbl = ld_fec_proceso ;
*/  

end usp_gen_asi_jub ;
/
