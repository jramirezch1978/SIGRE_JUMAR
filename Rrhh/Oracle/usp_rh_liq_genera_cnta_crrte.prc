create or replace procedure usp_rh_liq_genera_cnta_crrte (
  as_origen in char, as_usuario in char, ad_fec_proceso in date,
  as_cod_trabajador in char ) is

ln_item            number(3) ;
ln_verifica        integer ;
ld_fec_descto      date ;
ln_imp_saldo       number(13,2) ;
ln_imp_descto      number(13,2) ;

ls_concepto        char(4) ;
ls_tipo_doc        char(4) ;
ls_nro_doc         char(10) ;
ln_impdeb          number(13,2) ;
ln_imphab          number(13,2) ;
ln_saldos          number(13,2) ;

--  Lectura de saldos pendientes de la planilla
cursor c_saldos_planilla is
  select cc.cod_trabajador, cc.tipo_doc, cc.nro_doc, cc.fec_prestamo, cc.concep,
         cc.sldo_prestamo, c.desc_concep
  from cnta_crrte cc, maestro m, concepto c
  where cc.cod_trabajador = m.cod_trabajador and cc.concep = c.concep and
        nvl(cc.sldo_prestamo,0) > 0 and cc.cod_trabajador = as_cod_trabajador and
        nvl(m.flag_estado,'0') = '1' and nvl(m.flag_cal_plnlla,'0') = '1' and
        nvl(cc.flag_estado,'0') = '1' and nvl(cc.cod_sit_prest,'0') = 'A' and
        trunc(cc.fec_prestamo) <= ad_fec_proceso
  order by cc.cod_trabajador, cc.fec_prestamo ;

--  Lectura de saldos pendientes de contabilidad
cursor c_saldos_contables is
  select d.det_glosa, d.flag_debhab, d.tipo_docref1, d.nro_docref1, d.cod_relacion,
         d.imp_movsol, c.fecha_cntbl
  from cntbl_asiento_det d, cntbl_asiento c
  where d.origen = c.origen and d.ano = c.ano and d.mes = c.mes and
        d.nro_libro = c.nro_libro and d.nro_asiento = c.nro_asiento and
        nvl(c.flag_estado,'0') = '1' and d.cod_relacion = as_cod_trabajador and
        c.ano = to_number(to_char(ad_fec_proceso,'yyyy')) and
        (d.tipo_docref1 is not null and d.nro_docref1 is not null)
  order by d.cod_relacion, d.tipo_docref1, d.nro_docref1 ;
rc_cnt c_saldos_contables%rowtype ;

begin

--  **********************************************************
--  ***   GENERA SALDOS DE CUENTA CORRIENTE DE PLANILLAS   *** 
--  **********************************************************

delete from rh_liq_saldos_cnta_crrte s
  where s.cod_trabajador = as_cod_trabajador ;

ln_item := 0 ;
for rc_sal in c_saldos_planilla loop

  ln_imp_saldo := nvl(rc_sal.sldo_prestamo,0) ;
  
  ln_verifica := 0 ; ld_fec_descto := null ; ln_imp_descto := 0 ;
  select count(*) into ln_verifica from cnta_crrte_detalle d
    where d.cod_trabajador = rc_sal.cod_trabajador and d.tipo_doc = rc_sal.tipo_doc and
          d.nro_doc = rc_sal.nro_doc ;
  if ln_verifica > 0 then
    select max(d.fec_dscto) into ld_fec_descto from cnta_crrte_detalle d
      where d.cod_trabajador = rc_sal.cod_trabajador and d.tipo_doc = rc_sal.tipo_doc and
            d.nro_doc = rc_sal.nro_doc ;
    select nvl(d.imp_dscto,0) into ln_imp_descto from cnta_crrte_detalle d
      where d.cod_trabajador = rc_sal.cod_trabajador and d.tipo_doc = rc_sal.tipo_doc and
            d.nro_doc = rc_sal.nro_doc and trunc(d.fec_dscto) = trunc(ld_fec_descto) ;
  end if ;

  ln_verifica := 0 ;
  select count(*) into ln_verifica from historico_calculo h
    where h.cod_trabajador = rc_sal.cod_trabajador and h.concep = rc_sal.concep and
          trunc(h.fec_calc_plan) = trunc(ld_fec_descto) ;
  if ln_verifica = 0 then
    ln_imp_saldo := ln_imp_saldo - ln_imp_descto ;
  end if ;
      
  ln_item := ln_item + 1 ;
  insert into rh_liq_saldos_cnta_crrte (
    cod_trabajador, item, concep, tipo_doc, nro_doc,
    descripcion, fec_registro, flag_estado, proveedor, imp_total,
    imp_aplicado, flag_prd_dscto, flag_forma_reg, matriz, cod_usr )
  values (
    as_cod_trabajador, ln_item, rc_sal.concep, rc_sal.tipo_doc, rc_sal.nro_doc,
    rc_sal.desc_concep, rc_sal.fec_prestamo, '1', null, ln_imp_saldo,
    0, '9', 'G', null, as_usuario ) ;

end loop ;

--  *************************************************************
--  ***   GENERA SALDOS DE CUENTA CORRIENTE DE CONTABILIDAD   *** 
--  *************************************************************

select p.cncp_cnta_cobrar into ls_concepto
  from rh_liqparam p where p.reckey = '1' ;
  
open c_saldos_contables ;
fetch c_saldos_contables into rc_cnt ;

while c_saldos_contables%found loop

  ls_tipo_doc := rc_cnt.tipo_docref1 ;
  ls_nro_doc  := substr(rc_cnt.nro_docref1,1,10) ;

  ln_impdeb := 0 ; ln_imphab := 0 ; ln_saldos := 0 ;
  while rc_cnt.tipo_docref1 = ls_tipo_doc and substr(rc_cnt.nro_docref1,1,10) = ls_nro_doc and
        c_saldos_contables%found loop
    if rc_cnt.flag_debhab = 'D' then
      ln_impdeb := ln_impdeb + nvl(rc_cnt.imp_movsol,0) ;
    else
      ln_imphab := ln_imphab + nvl(rc_cnt.imp_movsol,0) ;
    end if ;
    fetch c_saldos_contables into rc_cnt ;
  end loop ;
  
  ln_saldos := ln_impdeb - ln_imphab ;
  
  if nvl(ln_saldos,0) > 0 then

    ln_verifica := 0 ;
    select count(*) into ln_verifica from rh_liq_saldos_cnta_crrte s
      where s.cod_trabajador = rc_cnt.cod_relacion and s.tipo_doc = ls_tipo_doc and
            s.nro_doc = ls_nro_doc ;

    if ln_verifica = 0 then    
      ln_item := ln_item + 1 ;
      insert into rh_liq_saldos_cnta_crrte (
        cod_trabajador, item, concep, tipo_doc, nro_doc,
        descripcion, fec_registro, flag_estado, proveedor, imp_total,
        imp_aplicado, flag_prd_dscto, flag_forma_reg, matriz, cod_usr )
      values (
        rc_cnt.cod_relacion, ln_item, ls_concepto, ls_tipo_doc, ls_nro_doc,
        rc_cnt.det_glosa, rc_cnt.fecha_cntbl, '1', null, ln_saldos,
        0, '9', 'G', null, as_usuario ) ;
    end if ;

  end if ;

end loop ;

end usp_rh_liq_genera_cnta_crrte ;
/
