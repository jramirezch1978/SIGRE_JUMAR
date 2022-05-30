create or replace procedure usp_cntbl_rpt_pre_asientos (
  as_ano in char, as_mes in char, as_origen in char ) is

ln_ano                   number(4) ;
ln_mes                   number(2) ;
ls_mes                   char(2) ;
ls_desc_libro            varchar2(40) ;
ls_cencos_destino        char(10) ;
ls_cnta_prsp             char(10) ;
ls_pre_cuenta            char(1) ;
ln_soles_debe            number(13,2) ;
ln_soles_haber           number(13,2) ;
ln_dolar_debe            number(13,2) ;
ln_dolar_haber           number(13,2) ;
ls_debhab                char(1) ;
ln_contador              integer ;

--  Lectura del detalle de los pre asientos
cursor c_pre_asientos is
  select pa.origen, pa.nro_libro, pa.nro_provisional,
         pa.item, pa.cnta_ctbl, pa.fec_cntbl,
         pa.det_glosa, pa.flag_debhab, pa.cencos,
         pa.tipo_docref, pa.nro_docref1, pa.cod_relacion,
         pa.imp_movsol, pa.imp_movdol, a.descripcion
  from cntbl_pre_asiento_det pa, tt_cntbl_asientos a
  where pa.nro_libro = a.nro_libro and
        to_char(pa.fec_cntbl,'MM') = ls_mes and
        to_char(pa.fec_cntbl,'YYYY') = as_ano and
        pa.origen = as_origen
  order by pa.nro_libro, pa.nro_provisional, pa.item ;

begin

ls_mes := lpad(as_mes,2,'0') ; ln_mes := to_number(ls_mes) ;
ln_ano := to_number(as_ano) ;

delete from tt_cntbl_pre_asientos ;

--  ***********************************************************
--  ***   LECTURA DEL DETALLE DE LOS PRE ASIENTOS DEL MES   ***
--  ***********************************************************
for rc_pre in c_pre_asientos loop

  ls_desc_libro := nvl(rc_pre.descripcion,' ') ;
  ln_soles_debe := 0   ; ln_soles_haber    := 0 ;
  ln_dolar_debe := 0   ; ln_dolar_haber    := 0 ;
  ls_cnta_prsp  := ' ' ; ls_cencos_destino := ' ' ;
  ls_pre_cuenta := ' ' ;

  if rc_pre.flag_debhab = 'D' then
    ln_soles_debe  := nvl(rc_pre.imp_movsol,0) ;
    ln_dolar_debe  := nvl(rc_pre.imp_movdol,0) ;
  elsif rc_pre.flag_debhab = 'H' then
    ln_soles_haber := nvl(rc_pre.imp_movsol,0) ;
    ln_dolar_haber := nvl(rc_pre.imp_movdol,0) ;
  end if ;

  --  Selecciona datos del detalle auxiliar
  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from cntbl_pre_asiento_det_aux da
   where da.origen = rc_pre.origen and
         da.nro_libro = rc_pre.nro_libro and
         da.nro_provisional = rc_pre.nro_provisional and
         da.item = rc_pre.item ;
  if ln_contador > 0 then
     select nvl(da.cnta_prsp,' '), nvl(da.cencos,' '),
            nvl(da.flag_pre_cnta,' ')
       into ls_cnta_prsp, ls_cencos_destino, ls_pre_cuenta
       from cntbl_pre_asiento_det_aux da
      where da.origen = rc_pre.origen and
            da.nro_libro = rc_pre.nro_libro and
            da.nro_provisional = rc_pre.nro_provisional and
            da.item = rc_pre.item ;
  end if ;

  
  --  Inserta registros en la tabla temporal
  insert into tt_cntbl_pre_asientos (
    ano, mes, origen,
    nro_libro, desc_libro, nro_provisional,
    item, fecha, cencos,
    cod_relacion, tipo_doc, nro_doc,
    cnta_cntbl, glosa, cencos_destino,
    cnta_prsp, pre_cuenta, soles_debe,
    soles_haber, dolar_debe, dolar_haber )
  values (
    as_ano, ls_mes, rc_pre.origen,
    rc_pre.nro_libro, ls_desc_libro, rc_pre.nro_provisional,
    rc_pre.item, rc_pre.fec_cntbl, rc_pre.cencos,
    rc_pre.cod_relacion, rc_pre.tipo_docref, rc_pre.nro_docref1,
    rc_pre.cnta_ctbl, rc_pre.det_glosa, ls_cencos_destino,
    ls_cnta_prsp, ls_pre_cuenta, ln_soles_debe,
    ln_soles_haber, ln_dolar_debe, ln_dolar_haber ) ;

end loop ;

end usp_cntbl_rpt_pre_asientos ;
/
