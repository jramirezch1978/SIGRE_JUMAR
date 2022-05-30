create or replace procedure usp_rh_cal_cuenta_corriente (
    asi_codtra         in maestro.cod_trabajador%TYPE,
    adi_fec_proceso    in date,
    ani_tipcam         in number,
    asi_origen         in origen.cod_origen%TYPE,
    asi_cnc_total_ingr in concepto.concep%TYPE,
    asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) is

ln_count                integer ;
lk_cuenta_corriente     grupo_calculo.grupo_calculo%TYPE ;
ls_concepto             concepto.concep%TYPE ;
ln_item                 number(2) ;
ln_id                   cnta_crrte_detalle.nro_dscto%TYPE ;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_soles%TYPE;
ln_imp_dscto            calculo.imp_soles%TYPE;
ln_imp_soles_gan        calculo.imp_soles%TYPE;
ln_imp_dolar_gan        calculo.imp_soles%TYPE;

--  Cursor de lectura de conceptos de cuenta corriente
cursor c_conceptos is
  select d.concepto_calc
    from grupo_calculo_det d
   where d.grupo_calculo = lk_cuenta_corriente
  order by d.grupo_calculo, d.concepto_calc ;

--  Cursor de busqueda de cuenta corriente por trabajador
cursor c_cuenta_corriente is
  select cc.tipo_doc, cc.nro_doc, cc.concep, cc.mont_cuota, cc.sldo_prestamo,
         cc.cod_moneda,nvl(cc.monto_aplicado,0) as monto_aplicado
    from cnta_crrte cc
   where cc.cod_trabajador = asi_codtra
     and cc.concep         = ls_concepto
     and nvl(cc.flag_estado,'0') = '1'
     and nvl(cc.cod_sit_prest,'0') = 'A'
     and nvl(cc.sldo_prestamo,0) > 0
     and nvl(cc.flag_aplic_porc_parcial,' ') <> '1'
  order by cc.cod_trabajador, cc.concep ;


--Cursor cuenta crrte gratificacion
cursor c_cuenta_corriente_gratif is
  select cc.tipo_doc   , cc.nro_doc, cc.concep, cc.monto_aplicado, cc.sldo_prestamo,
         cc.cod_moneda
    from cnta_crrte    cc,
         gratificacion g
   where g.cod_trabajador  = cc.cod_trabajador
     and cc.cod_trabajador = asi_codtra
     and cc.concep         = ls_concepto
     and nvl(cc.flag_estado,'0') = '1'
     and nvl(cc.cod_sit_prest,'0') = 'A'
     and nvl(cc.sldo_prestamo,0) > 0
     and nvl(cc.flag_aplic_porc_parcial,' ') <> '0'
     and cc.flag_tipo_aplic_parcial = 'G'
  order by cc.cod_trabajador, cc.concep ;

begin

--  **************************************************************
--  ***   REALIZA CALCULO DE CUENTA CORRIENTE POR TRABAJADOR   ***
--  **************************************************************

select c.cnta_cnte
  into lk_cuenta_corriente
  from rrhhparam_cconcep c
 where c.reckey = '1' ;

select sum(nvl(c.imp_soles,0)), sum(nvl(c.imp_dolar,0))
  into ln_imp_soles_gan, ln_imp_dolar_gan
  from calculo c
 where c.cod_trabajador = asi_codtra
   and c.concep         = asi_cnc_total_ingr
   and c.tipo_planilla  = asi_tipo_planilla;

--elimino cuenta corriente detalle genrado
delete from cnta_crrte_detalle ccd
 where ccd.cod_trabajador = asi_codtra
 and trunc(ccd.fec_dscto) = trunc(adi_fec_proceso) ;

-- Actualizo el saldo del prestamo
update cnta_crrte cc
   set cc.sldo_prestamo = cc.mont_original - (select NVL(sum(ccd.imp_dscto),0)
                                                from cnta_crrte_detalle ccd
                                               where ccd.cod_trabajador = cc.cod_trabajador
                                                 and ccd.tipo_doc       = cc.tipo_doc
                                                 and ccd.nro_doc        = cc.nro_doc)
  where cc.cod_trabajador = asi_codtra;

if ln_imp_soles_gan > 0 or ln_imp_dolar_gan > 0 then

   for rc_c in c_conceptos loop
       ls_concepto := rc_c.concepto_calc ;
       ln_item     := 0 ;

       for rc_cta in c_cuenta_corriente loop

           if nvl(rc_cta.mont_cuota,0) > nvl(rc_cta.sldo_prestamo - rc_cta.monto_aplicado,0) then
              ln_imp_dscto := nvl(rc_cta.sldo_prestamo - rc_cta.monto_aplicado,0) ;
           else
              ln_imp_dscto := nvl(rc_cta.mont_cuota,0) ;
           end if ;

           if Nvl(ln_imp_dscto,0) > 0 then --si deduda es mayor que cero
              if rc_cta.cod_moneda = pkg_logistica.is_dolares then
                 ln_imp_soles := ln_imp_dscto * ani_tipcam ;
                 ln_imp_dolar := ln_imp_dscto ;
              else
                 ln_imp_soles := ln_imp_dscto ;
                 ln_imp_dolar := ln_imp_soles / ani_tipcam ;
             end if ;

             ln_id := 0;

             select count(*)
               into ln_count
               from cnta_crrte_detalle ccd
              where ccd.cod_trabajador = asi_codtra
                and ccd.tipo_doc       = rc_cta.tipo_doc
                and ccd.nro_doc        = rc_cta.nro_doc ;

             if ln_count > 0 then
                select max(nvl(ccd.nro_dscto,0))
                  into ln_id
                  from cnta_crrte_detalle ccd
                 where ccd.cod_trabajador = asi_codtra
                   and ccd.tipo_doc       = rc_cta.tipo_doc
                   and ccd.nro_doc        = rc_cta.nro_doc;
             end if ;

             ln_id := ln_id + 1 ;

             ln_item := ln_item + 1 ;

             Insert into calculo(
                    cod_trabajador ,concep    ,fec_proceso ,horas_trabaj ,horas_pag ,
                    dias_trabaj    ,imp_soles ,imp_dolar   ,cod_origen   ,item      ,
                    tipo_doc_cc    ,nro_doc_cc, tipo_planilla)
             Values(
                    asi_codtra       ,ls_concepto   ,adi_fec_proceso ,0          ,0       ,
                    0                ,ln_imp_soles  ,ln_imp_dolar    ,asi_origen ,ln_item ,
                    rc_cta.tipo_doc  ,rc_cta.nro_doc, asi_tipo_planilla ) ;

             Insert into cnta_crrte_detalle(
                    cod_trabajador ,tipo_doc  ,nro_doc ,nro_dscto ,
                    fec_dscto      ,imp_dscto )
             Values(
                    asi_codtra      ,rc_cta.tipo_doc ,rc_cta.nro_doc ,ln_id ,
                    adi_fec_proceso ,nvl(ln_imp_dscto,0) ) ;

           end if ;
       end loop ;

       --descuentos de gratificacion
       FOR rc_cta_grat IN c_cuenta_corriente_gratif LOOP
           ln_imp_dscto := nvl(rc_cta_grat.monto_aplicado,0) ;

           if rc_cta_grat.cod_moneda = pkg_logistica.is_dolares then
              ln_imp_soles := ln_imp_dscto * ani_tipcam ;
              ln_imp_dolar := ln_imp_dscto ;
           else
              ln_imp_soles := ln_imp_dscto ;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
           end if ;

           ln_id := 0;

           select count(*)
             into ln_count
             from cnta_crrte_detalle ccd
            where ccd.cod_trabajador = asi_codtra
              and ccd.tipo_doc       = rc_cta_grat.tipo_doc
              and ccd.nro_doc        = rc_cta_grat.nro_doc;

           if ln_count > 0 then
              select max(nvl(ccd.nro_dscto,0))
                into ln_id
                from cnta_crrte_detalle ccd
               where ccd.cod_trabajador = asi_codtra
                 and ccd.tipo_doc       = rc_cta_grat.tipo_doc
                 and ccd.nro_doc        = rc_cta_grat.nro_doc;
           end if ;

           ln_id := ln_id + 1 ;

           ln_item := ln_item + 1 ;

           select count(*)
             into ln_count
             from calculo c
            where c.cod_trabajador = asi_codtra
              and c.concep         = ls_concepto
              and c.item           = ln_item
              and c.tipo_planilla  = asi_tipo_planilla;

           -- Valido que el item no se repita, para ello hago un bucle
           while ln_count > 0 loop
             ln_item := ln_item + 1;

             select count(*)
               into ln_count
               from calculo c
              where c.cod_trabajador = asi_codtra
                and c.concep         = ls_concepto
                and c.item           = ln_item
                and c.tipo_planilla  = asi_tipo_planilla;

           end loop;

           Insert into calculo(
                  cod_trabajador ,concep    ,fec_proceso ,horas_trabaj ,horas_pag ,
                  dias_trabaj    ,imp_soles ,imp_dolar   ,cod_origen   ,item      ,
                  tipo_doc_cc    ,nro_doc_cc, tipo_planilla)
           Values(
                  asi_codtra       ,ls_concepto   ,adi_fec_proceso ,0          ,0       ,
                  0                ,ln_imp_soles  ,ln_imp_dolar    ,asi_origen ,ln_item ,
                  rc_cta_grat.tipo_doc ,rc_cta_grat.nro_doc, asi_tipo_planilla ) ;

           Insert into cnta_crrte_detalle(
                  cod_trabajador ,tipo_doc  ,nro_doc ,nro_dscto ,
                  fec_dscto      ,imp_dscto )
           Values(
                  asi_codtra      ,rc_cta_grat.tipo_doc ,rc_cta_grat.nro_doc ,ln_id ,
                  adi_fec_proceso ,nvl(ln_imp_dscto,0) ) ;

       end loop ;
   end loop ;
end if ;

end usp_rh_cal_cuenta_corriente ;
/
