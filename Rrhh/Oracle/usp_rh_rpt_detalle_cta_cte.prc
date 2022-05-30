create or replace procedure usp_rh_rpt_detalle_cta_cte(
       asi_codigo in maestro.cod_trabajador%TYPE,
       asi_origen in origen.cod_origen%TYPE,
       asi_ttrab  in tipo_trabajador.tipo_trabajador%TYPE 
) is

ls_dolar              logparam.cod_dolares%TYPE ;
ln_sw                 integer ;
ln_total_sol          number(13,2) ;
ln_cuota_sol          number(13,2) ;
ln_saldo_sol          number(13,2) ;
ln_total_dol          number(13,2) ;
ln_cuota_dol          number(13,2) ;
ln_saldo_dol          number(13,2) ;
ln_dscto_sol          number(13,2) ;
ln_dscto_dol          number(13,2) ;

--  Lectura del movimiento de cuenta corriente
cursor c_movimiento is
  select cc.cod_trabajador ,cc.tipo_doc      ,cc.nro_doc    ,cc.flag_estado    ,cc.fec_prestamo  ,
         cc.concep         ,c.desc_concep    ,cc.nro_cuotas ,cc.mont_original  ,cc.mont_cuota    ,
         cc.sldo_prestamo  ,cc.cod_sit_prest ,cc.cod_moneda ,m.tipo_trabajador ,tt.desc_tipo_tra ,
         m.cod_origen      ,o.nombre         ,m.cod_seccion ,s.desc_seccion    ,
         trim(m.apel_paterno)||' '||trim(m.apel_materno)||' '||trim(m.nombre1)||' '||trim(m.nombre2) as nombres
    from cnta_crrte cc, maestro m, concepto c, tipo_trabajador tt, origen o, seccion s
   where (cc.cod_trabajador = m.cod_trabajador   ) and
         (cc.concep         = c.concep           ) and
         (m.tipo_trabajador = tt.tipo_trabajador ) and
         (m.cod_origen      = o.cod_origen       ) and
         (m.cod_area        = s.cod_area         ) and
         (m.cod_seccion     = s.cod_seccion      ) and
         (cc.cod_trabajador like asi_codigo       ) and
         (m.cod_origen      like asi_origen       ) and
         (m.tipo_trabajador like asi_ttrab        ) 
  order by cc.cod_trabajador, cc.fec_prestamo, cc.concep ;

--  Lectural al detallle de los descuentos efectuados
cursor c_detalle (asi_cod_trab maestro.cod_trabajador%type     ,asi_tipo_doc doc_tipo.tipo_doc%type,
                  asi_nro_doc  cnta_crrte_detalle.nro_doc%type ) is
select d.nro_dscto, d.fec_dscto, d.imp_dscto
  from cnta_crrte_detalle d
 where (d.cod_trabajador = asi_cod_trab ) and
       (d.tipo_doc       = asi_tipo_doc ) and
       (d.nro_doc        = asi_nro_doc  )
order by d.cod_trabajador, d.tipo_doc, d.nro_doc, d.fec_dscto ;

begin

--  *********************************************************
--  ***   GENERA REPORTE AL DETALLE DE CUENTA CORRIENTE   ***
--  *********************************************************

delete from tt_detalle_cuenta_corriente ;

select p.cod_dolares into ls_dolar from logparam p  where p.reckey = '1' ;

For rc_mov in c_movimiento Loop


    ln_total_sol := 0 ; ln_cuota_sol := 0 ; ln_saldo_sol := 0 ; ln_sw := 0 ;
    ln_total_dol := 0 ; ln_cuota_dol := 0 ; ln_saldo_dol := 0 ;

    if rc_mov.cod_moneda = ls_dolar then
       ln_total_dol := nvl(rc_mov.mont_original,0) ;
       ln_cuota_dol := nvl(rc_mov.mont_cuota,0) ;
       ln_saldo_dol := nvl(rc_mov.sldo_prestamo,0) ;
       ln_sw        := 1 ;
    else
       ln_total_sol := nvl(rc_mov.mont_original,0) ;
       ln_cuota_sol := nvl(rc_mov.mont_cuota,0) ;
       ln_saldo_sol := nvl(rc_mov.sldo_prestamo,0) ;
    end if ;

    For rc_det in c_detalle(rc_mov.cod_trabajador,rc_mov.tipo_doc,rc_mov.nro_doc) Loop
        ln_dscto_sol := 0 ; ln_dscto_dol := 0 ;

        if ln_sw = 1 then
           ln_dscto_dol := nvl(rc_det.imp_dscto,0) ;
        else
           ln_dscto_sol := nvl(rc_det.imp_dscto,0) ;
        end if ;

        Insert Into tt_detalle_cuenta_corriente
        (flag_estado          ,cod_origen    ,desc_origen      ,tipo_trabajador ,
         desc_tipo_trabajador ,cod_seccion   ,desc_seccion     ,cod_trabajador  ,
         nombres              ,tipo_doc      ,nro_doc          ,fec_prestamo    ,
         concepto             ,desc_concepto ,cod_sit_prestamo ,nro_cuotas      ,
         cod_moneda           ,imp_sol       ,des_sol          ,sal_sol         ,
         imp_dol              ,des_dol       ,sal_dol          ,nro_dscto       ,
         fec_dscto            ,imp_dscto_sol ,imp_dscto_dol )
        Values
        (rc_mov.flag_estado   ,rc_mov.cod_origen  ,rc_mov.nombre        ,rc_mov.tipo_trabajador ,
         rc_mov.desc_tipo_tra ,rc_mov.cod_seccion ,rc_mov.desc_seccion  ,rc_mov.cod_trabajador  ,
         rc_mov.nombres       ,rc_mov.tipo_doc    ,rc_mov.nro_doc       ,rc_mov.fec_prestamo    ,
         rc_mov.concep        ,rc_mov.desc_concep ,rc_mov.cod_sit_prest ,rc_mov.nro_cuotas      ,
         rc_mov.cod_moneda    ,ln_total_sol       ,ln_cuota_sol         ,ln_saldo_sol           ,
         ln_total_dol         ,ln_cuota_dol       ,ln_saldo_dol         ,rc_det.nro_dscto       ,
         rc_det.fec_dscto     ,ln_dscto_sol       ,ln_dscto_dol ) ;

    End Loop ;

End Loop ;

end usp_rh_rpt_detalle_cta_cte ;
/
