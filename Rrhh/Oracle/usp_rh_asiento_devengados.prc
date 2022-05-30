create or replace procedure usp_rh_asiento_devengados (
  as_origen in char, as_usuario in char, ad_fec_proceso in date,
  as_indicador in char ) is

lk_tipo_doc         constant char(4) := 'PLAN' ;

ln_nro_libro        number(3) ;
ls_cuenta_debe      char(10) ;
ls_cuenta_haber     char(10) ;
ls_tipo_trabaja     char(3) ;
ld_fec_inicio       date ;
ln_contador         integer ;
ln_provisional      number(10) ;
ln_tipo_cambio      number(7,3) ;
ls_nro_doc          char(15) ;
ls_desc_libro       varchar2(60) ;
ls_concepto         char(4) ;
ls_codigo           char(8) ;
ls_cencos           char(10) ;
ls_flag_cc          char(1) ;
ls_flag_cr          char(1) ;
ls_ind_cencos       char(10) ;
ls_ind_codigo       char(8) ;
ln_item             number(4) ;
ln_imp_det          number(13,2) ;
ln_imp_det_d        number(13,2) ;
ln_imp_tot          number(13,2) ;
ln_imp_tot_d        number(13,2) ;
ln_total_soldeb     number(13,2) ;
ln_total_solhab     number(13,2) ;
ln_total_doldeb     number(13,2) ;
ln_total_dolhab     number(13,2) ;

--  Lectura del maestro de trabajadores
cursor c_maestro is
  select m.cod_trabajador, m.cencos
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = ls_tipo_trabaja and m.cod_origen = as_origen
  order by m.cencos, m.cod_trabajador ;

--  Lectura del movimiento gratificaciones y remuneraciones
cursor c_devengados is
  select d.imp_int_gen, d.int_pagado, d.mont_pagado
  from maestro_remun_gratif_dev d
  where d.cod_trabajador = ls_codigo and d.concep = ls_concepto and
        to_char(d.fec_pago,'MM/YYYY') = to_char(ad_fec_proceso,'MM/YYYY') and
        ( d.imp_int_gen > 0 or d.int_pagado > 0 or d.mont_pagado > 0 )
  order by d.cod_trabajador, d.fec_pago ;

begin

--  ****************************************************
--  ***   GENERA ASIENTOS CONTABLES POR DEVENGADOS   ***
--  ****************************************************

ls_nro_doc := lk_tipo_doc||to_char(ad_fec_proceso,'MMYYYY') ;

--  Intereses de gratificaciones y remuneraciones
if as_indicador = 'IGE' then
  ln_nro_libro    := 22 ;
  ls_cuenta_debe  := '97291105' ;
  ls_cuenta_haber := '46600300' ;
  ls_tipo_trabaja := 'EMP' ;
  ls_concepto     := '1301' ;
elsif as_indicador = 'IGO' then
  ln_nro_libro    := 26 ;
  ls_cuenta_debe  := '97291106' ;
  ls_cuenta_haber := '46600300' ;
  ls_tipo_trabaja := 'OBR' ;
  ls_concepto     := '1301' ;
elsif as_indicador = 'IRE' then
  ln_nro_libro    := 23 ;
  ls_cuenta_debe  := '97291107' ;
  ls_cuenta_haber := '46600300' ;
  ls_tipo_trabaja := 'EMP' ;
  ls_concepto     := '1302' ;
elsif as_indicador = 'IRO' then
  ln_nro_libro    := 27 ;
  ls_cuenta_debe  := '97291108' ;
  ls_cuenta_haber := '46600300' ;
  ls_tipo_trabaja := 'OBR' ;
  ls_concepto     := '1302' ;
--  Intereses por pagos de gratificaciones y remuneraciones
elsif as_indicador = 'PGE' then
  ln_nro_libro    := 24 ;
  ls_cuenta_debe  := '46600300' ;
  ls_cuenta_haber := '41110300' ;
  ls_tipo_trabaja := 'EMP' ;
  ls_concepto     := '1301' ;
elsif as_indicador = 'PGO' then
  ln_nro_libro    := 28 ;
  ls_cuenta_debe  := '46600300' ;
  ls_cuenta_haber := '41110300' ;
  ls_tipo_trabaja := 'OBR' ;
  ls_concepto     := '1301' ;
elsif as_indicador = 'PRE' then
  ln_nro_libro    := 25 ;
  ls_cuenta_debe  := '46600300' ;
  ls_cuenta_haber := '41100300' ;
  ls_tipo_trabaja := 'EMP' ;
  ls_concepto     := '1302' ;
elsif as_indicador = 'PRO' then
  ln_nro_libro    := 29 ;
  ls_cuenta_debe  := '46600300' ;
  ls_cuenta_haber := '41100300' ;
  ls_tipo_trabaja := 'OBR' ;
  ls_concepto     := '1302' ;
end if ;

--  Determina la descripcion del numero de libro
select nvl(cl.desc_libro,' ')
  into ls_desc_libro from cntbl_libro cl
  where cl.nro_libro = ln_nro_libro ;

--  Elimina movimiento de asiento contable generado
ld_fec_inicio := to_date('01'||'/'||to_char(ad_fec_proceso,'MM')||'/'||
                 to_char(ad_fec_proceso,'YYYY'),'DD/MM/YYYY') ;
usp_cnt_borrar_pre_asiento( as_origen, ln_nro_libro, ld_fec_inicio, ad_fec_proceso ) ;

--  Determina tipo de cambio a la fecha de proceso
ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*)
  into ln_contador from calendario cal
  where to_char(cal.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
if ln_contador > 0 then
  select nvl(cal.vta_dol_prom,1)
    into ln_tipo_cambio from calendario cal
    where to_char(cal.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
end if ;

--  Determina numero provisional
ln_contador := 0 ;
select count(*)
  into ln_contador from cntbl_libro l
  where l.nro_libro = ln_nro_libro ;
if ln_contador = 0 then
  ln_provisional := 1 ;
  insert into cntbl_libro ( nro_libro, desc_libro, num_provisional, flag_replicacion )
  values ( ln_nro_libro, substr(ls_desc_libro,1,40), ln_provisional, '1' ) ;
else
  select nvl(l.num_provisional,0)
    into ln_provisional from cntbl_libro l
    where l.nro_libro = ln_nro_libro ;
  ln_provisional := ln_provisional + 1 ;
end if ;

--  Adiciona registro de cabecera del pre asiento
insert into cntbl_pre_asiento (
  origen, nro_libro, nro_provisional, cod_moneda, tasa_cambio,
  desc_glosa, fec_cntbl, fec_registro, cod_usr, flag_estado,
  tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab, flag_replicacion )
values (
  as_origen, ln_nro_libro, ln_provisional, 'S/.', ln_tipo_cambio,
  ls_desc_libro, ad_fec_proceso, ad_fec_proceso, as_usuario, '1',
  0, 0, 0, 0, '1' ) ;

--  ******************************************************************
--  ***   LECTURA DE TRABAJADORES PARA LA GENERACION DEL ASIENTO   ***
--  ******************************************************************
ln_imp_tot := 0 ; ln_imp_tot_d := 0 ; ln_item := 0 ;
for rc_mae in c_maestro loop

  ls_codigo := rc_mae.cod_trabajador ;
  ls_cencos := rc_mae.cencos ;

  --  Lectura del movimiento de devengados
  ln_imp_det := 0 ; ln_imp_det_d := 0 ;
  for rc_dev in c_devengados loop

    if as_indicador = 'IGE' or as_indicador = 'IGO' or
       as_indicador = 'IRE' or as_indicador = 'IRO' then
      ln_imp_det := ln_imp_det + nvl(rc_dev.imp_int_gen,0) ;
    else
      if as_indicador = 'PGE' or as_indicador = 'PGO' or
         as_indicador = 'PRE' or as_indicador = 'PRO' then
        if nvl(rc_dev.int_pagado,0) > 0 then
          ln_imp_det := ln_imp_det + nvl(rc_dev.int_pagado,0) ;
        end if ;
--        if nvl(rc_dev.mont_pagado,0) > 0 then
--          ln_imp_det := ln_imp_det + nvl(rc_dev.mont_pagado,0) ;
--        end if ;
      end if ;
    end if ;

  end loop ;

  if ln_imp_det > 0 then

    ln_imp_det_d := ln_imp_det   / ln_tipo_cambio ;
    ln_imp_tot   := ln_imp_tot   + ln_imp_det ;
    ln_imp_tot_d := ln_imp_tot_d + ln_imp_det_d ;

    select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
      into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
      where cta.cnta_ctbl = ls_cuenta_debe ;
    if ls_flag_cc <> '1' then ls_ind_cencos := null ;
    else ls_ind_cencos := ls_cencos ; end if ;
    if ls_flag_cr <> '1' then ls_ind_codigo := null ;
    else ls_ind_codigo := ls_codigo ; end if ;

    ln_item := ln_item + 1 ;
    insert into cntbl_pre_asiento_det (
      origen, nro_libro, nro_provisional, item,
      cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
      tipo_docref, nro_docref1, cencos, cod_relacion,
      imp_movsol, imp_movdol, flag_replicacion )
    values (
      as_origen, ln_nro_libro, ln_provisional, ln_item,
      ls_cuenta_debe, ad_fec_proceso, ls_desc_libro, 'D',
      lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
      ln_imp_det, ln_imp_det_d, '1' ) ;

  end if ;

end loop ;

--  Graba registro por el total del asiento
if ln_imp_tot > 0 then

  select nvl(cta.flag_cencos,' '), nvl(cta.flag_codrel,' ')
    into ls_flag_cc, ls_flag_cr from cntbl_cnta cta
    where cta.cnta_ctbl = ls_cuenta_haber ;
  if ls_flag_cc <> '1' then ls_ind_cencos := null ;
  else ls_ind_cencos := ls_cencos ; end if ;
  if ls_flag_cr <> '1' then ls_ind_codigo := null ;
  else ls_ind_codigo := ls_codigo ; end if ;

  ln_item := ln_item + 1 ;
  insert into cntbl_pre_asiento_det (
    origen, nro_libro, nro_provisional, item,
    cnta_ctbl, fec_cntbl, det_glosa, flag_debhab,
    tipo_docref, nro_docref1, cencos, cod_relacion,
    imp_movsol, imp_movdol, flag_replicacion )
  values (
    as_origen, ln_nro_libro, ln_provisional, ln_item,
    ls_cuenta_haber, ad_fec_proceso, ls_desc_libro, 'H',
    lk_tipo_doc, ls_nro_doc, ls_ind_cencos, ls_ind_codigo,
    ln_imp_tot, ln_imp_tot_d, '1' ) ;

end if ;

--  Actualiza nuevo numero provisional
update cntbl_libro
  set num_provisional = ln_provisional,
         flag_replicacion = '1'
  where nro_libro = ln_nro_libro ;

--  Actualiza importes del registro de cabebcera
ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
select sum(d.imp_movsol), sum(d.imp_movdol)
  into ln_total_soldeb, ln_total_doldeb
  from cntbl_pre_asiento_det d
  where d.origen = as_origen and d.nro_libro = ln_nro_libro and
        d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
        d.flag_debhab = 'D' ;
select sum(d.imp_movsol), sum(d.imp_movdol)
  into ln_total_solhab, ln_total_dolhab
  from cntbl_pre_asiento_det d
  where d.origen = as_origen and d.nro_libro = ln_nro_libro and
        d.nro_provisional = ln_provisional and d.fec_cntbl = ad_fec_proceso and
        d.flag_debhab = 'H' ;

update cntbl_pre_asiento
  set tot_soldeb = ln_total_soldeb ,
      tot_solhab = ln_total_solhab ,
      tot_doldeb = ln_total_doldeb ,
      tot_dolhab = ln_total_dolhab,
         flag_replicacion = '1'
  where origen = as_origen and nro_libro = ln_nro_libro and
        nro_provisional = ln_provisional and fec_cntbl = ad_fec_proceso ;

end usp_rh_asiento_devengados ;
/
