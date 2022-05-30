create or replace procedure usp_gen_asi_plla_bak
  ( as_tipo_trabajador  in maestro.tipo_trabajador%type ) is
   
ls_codigo               maestro.cod_trabajador%type ;
ls_cencos               maestro.cencos%type ;
ls_cencos_dis           maestro.cencos%type ;

ls_origen               char(2) ;
ln_libro                number(3) ;
ln_nro_prov             number(10) ;
ln_nro_det              number(10) ;
ln_mes_proceso          number(2) ;
ld_fec_proceso          date ;
ld_fec_desde            date ;
ld_fec_hasta            date ;
ls_glosa                varchar2(50) ;
ls_flag_dh              char(1) ;
ln_imp_soles            number(13,2) ;
ln_imp_dolar            number(13,2) ;
ln_soles_dis            number(13,2) ;
ln_dolar_dis            number(13,2) ;
ls_cuenta_deb           char(10) ;
ls_cuenta_hab           char(10) ;
ln_tipo_cambio          number(7,3) ;

ln_total_soldeb         number(13,2) ;
ln_total_solhab         number(13,2) ;
ln_total_doldeb         number(13,2) ;
ln_total_dolhab         number(13,2) ;

ls_concepto             concepto.concep%type ;
ln_horas_dis            calculo.horas_trabaj%type ;
ln_horas_pag            calculo.horas_pag%type ;
ln_horas_new            calculo.horas_pag%type ;
ln_nro_horas            calculo.horas_pag%type ;

ls_cta_deb_obr          char(10) ;
ls_cta_hab_obr          char(10) ;
ls_cta_deb_emp          char(10) ;
ls_cta_hab_emp          char(10) ;
ln_sw                   number(1) ;
ln_registros            integer ;
ls_cod_rel              char(10) ;
ls_moneda               maestro.cod_moneda%type ;

ln_hay_horas_dis        number(1) ;
ln_concepto_10          number(1) ;

--  Cursor del maestro con el personal activo
Cursor c_maestro is
  Select m.cod_trabajador, m.cencos, m.cod_moneda
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cencos, m.cod_trabajador ;

--  Cursor para generar asientos contables
Cursor c_calculo is
  Select c.cod_trabajador, c.concep, c.fec_proceso,
         c.horas_trabaj, c.horas_pag, c.imp_soles,
         c.imp_dolar
  from calculo c
  where c.cod_trabajador = ls_codigo and
        c.imp_soles <> 0 and
        c.concep <> '1450' and
        c.concep <> '2351' and
        c.concep <> '2352' and
        c.concep <> '3050'
  order by c.cod_trabajador, c.concep ;

--  Cursor para generar asientos de la distribucion contable  
Cursor c_distribucion is
  Select d.cencos, d.nro_horas
  from distribucion_cntble d
  where d.cod_trabajador = ls_codigo and
        d.fec_movimiento between ld_fec_desde and ld_fec_hasta ;
  
begin

--  Selecciona fechas del registro de parametros
Select rh.fec_proceso, rh.fec_desde, rh.fec_hasta
  into ld_fec_proceso, ld_fec_desde, ld_fec_hasta
  from rrhhparam rh
  where rh.reckey = '1' ;

ln_mes_proceso := to_number(to_char(ld_fec_proceso,'MM')) ;

--  Asigna numero de asiento para Obreros o Empleados
If as_tipo_trabajador = 'OBR' then
  ls_origen   := 'PR' ;
  ln_libro    := 1 ;
  ln_nro_prov := 1 ;
  --  Borra informacion del movimiento del mes de proceso
  delete from cntbl_plnlla_mensual_det d
    where d.cod_origen = ls_origen and
          d.nro_libro = ln_libro and
          d.nro_provisional = ln_nro_prov ;
  delete from cntbl_mov_imp_plnlla_mensual c
    where c.origen = ls_origen and
          c.nro_libro = ln_libro and
          c.nro_provisional = ln_nro_prov ;
  --  Inserta registro de cabecera del movimiento mensual
  Insert into cntbl_mov_imp_plnlla_mensual (
    origen, nro_libro, nro_provisional, fec_cntbl )
  Values (
    ls_origen, ln_libro, ln_nro_prov, ld_fec_proceso ) ;
Elsif as_tipo_trabajador = 'EMP' then
  ls_origen   := 'PR' ;
  ln_libro    := 2 ;
  ln_nro_prov := 2 ;
  --  Borra informacion del movimiento del mes de proceso
  delete from cntbl_plnlla_mensual_det d
    where d.cod_origen = ls_origen and
          d.nro_libro = ln_libro and
          d.nro_provisional = ln_nro_prov ;
  delete from cntbl_mov_imp_plnlla_mensual c
    where c.origen = ls_origen and
          c.nro_libro = ln_libro and
          c.nro_provisional = ln_nro_prov ;
  --  Inserta registro de cabecera del movimiento mensual
  Insert into cntbl_mov_imp_plnlla_mensual (
    origen, nro_libro, nro_provisional, fec_cntbl )
  Values (
    ls_origen, ln_libro, ln_nro_prov, ld_fec_proceso ) ;
End if ;

--  Halla tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipo_cambio
  from calendario tc
  where tc.fecha = ld_fec_proceso ;
ln_tipo_cambio := nvl(ln_tipo_cambio,1) ;

ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;
ln_nro_det      := 0 ;

--  Lectura para generacion de asientos del maestro
For rc_mae in c_maestro Loop

  ls_codigo   := rc_mae.cod_trabajador ;
  ls_cencos   := rc_mae.cencos ;
  ls_cencos   := nvl(ls_cencos,' ') ;
  ls_moneda   := nvl(rc_mae.cod_moneda,'S/.') ;
  
  --  Verifica si hay horas distribuidas en otros centros de costos
  ln_horas_dis := 0 ; ln_hay_horas_dis := 0 ;
  Select sum( dc.nro_horas )
    into ln_horas_dis
    from distribucion_cntble dc
    where dc.cod_trabajador = ls_codigo and
          dc.fec_movimiento between ld_fec_desde and ld_fec_hasta ;
  ln_horas_dis := nvl(ln_horas_dis,0) ;
  If ln_horas_dis > 0 then
    ln_hay_horas_dis := 1 ;
  End if ;
  
  --  Halla el maximo de horas trabajadas en el mes
  ln_horas_pag := 0 ;
  Select max( cal.horas_trabaj )
    into ln_horas_pag
    from calculo cal
    where cal.cod_trabajador = ls_codigo and
          substr(cal.concep,1,1) = '1' ;
  ln_horas_pag := nvl(ln_horas_pag,0) ;

  If ln_hay_horas_dis = 1 then
    ln_horas_new := ln_horas_pag - ln_horas_dis ;
  End if ;
    
  --  Lectura detalle para generacion de asientos ( CALCULO )
  For rc_cal in c_calculo loop

    ls_concepto    := rc_cal.concep ;
    ln_imp_soles   := nvl(rc_cal.imp_soles,0) ;
    ln_imp_dolar   := nvl(rc_cal.imp_dolar,0) ;
    ln_sw          := 0 ;
    ln_concepto_10 := 0 ;
    
    If substr(ls_concepto,1,2) = '21' then
      ls_cod_rel := ls_codigo ;
    Else
      ls_cod_rel := ' ' ;
    End if ;
       
    If substr(ls_concepto,1,2) = '10' then
      ln_concepto_10 := 1 ;
    Else
      ln_concepto_10 := 0 ;
    End if ;
       
    If ln_imp_soles < 0 and ln_imp_dolar < 0 then
      ln_imp_soles := ln_imp_soles * (-1) ;
      ln_imp_dolar := ln_imp_dolar * (-1) ;
      ln_sw        := 1 ;
    End if ;
      
    --  Selecciona cuentas ( Cargo y Abono )
    ls_cuenta_deb := ' ' ; 
    ls_cuenta_hab := ' ' ;
    ls_flag_dh    := ' ' ;
    
    --  **************************************
    --  ***   GENERA ASIENTOS DE OBREROS   ***
    --  **************************************
    If as_tipo_trabajador = 'OBR' then

      Select nvl(con.cta_haber_obr,' '), nvl(con.cta_debe_obr,' ')
        into ls_cta_hab_obr, ls_cta_deb_obr
        from concepto con
        where con.concep = ls_concepto ;

      --  *******************************************
      --  ***   GENERA ASIENTOS DE DISTRIBUCION   ***
      --  *******************************************
      If ln_hay_horas_dis = 1 and ln_concepto_10 = 1 then
      
        ln_soles_dis := 0 ; ln_dolar_dis := 0 ;
        ln_soles_dis := ( ln_imp_soles / ln_horas_pag ) * ln_horas_new ;
        ln_dolar_dis := ( ln_soles_dis / ln_tipo_cambio ) ;
        If ls_cta_deb_obr <> ' ' then
          ln_nro_det := ln_nro_det + 1 ;
          ls_cuenta_deb := ls_cta_deb_obr ;
          Select substr(cc.desc_cnta,1,50)
            into ls_glosa
            from cntbl_cnta cc
            where cc.cnta_ctbl = ls_cuenta_deb ;
          ls_flag_dh    := 'D' ;
          If ln_sw = 1 then
            ls_flag_dh := 'H' ;
          End if ;
          --  Acumula importes para archivo de cabecera
          If ls_flag_dh = 'D' then
            ln_total_soldeb := ln_total_soldeb + ln_soles_dis ;
            ln_total_doldeb := ln_total_doldeb + ln_dolar_dis ;
          End if ;
          If ls_flag_dh = 'H' then
            ln_total_solhab := ln_total_solhab + ln_soles_dis ;
            ln_total_dolhab := ln_total_dolhab + ln_dolar_dis ;
          End if ;
          --  Inserta registros al detalle - DEBE
          If ls_cuenta_deb <> ' ' then
            Insert into cntbl_plnlla_mensual_det (
              cod_origen, nro_libro, nro_provisional, nro_movdet,
              mes_proceso, fec_cntbl, det_glosa, flag_debhab,
              cencos, cnta_ctbl, cod_moneda, tipo_docref,
              nro_docref2, tas_cambio, imp_movsol, imp_movdol,
              imp_movaju )
            Values (
              ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
              ln_mes_proceso, ld_fec_proceso, ls_glosa, ls_flag_dh,
              ls_cencos, ls_cuenta_deb, ls_moneda, 'PLAN',
              ls_cod_rel, ln_tipo_cambio, ln_soles_dis, ln_dolar_dis,
              0 ) ;
          End if ;
        End if ;

        --  Calcula horas de distribucion contable
        For rc_dis in c_distribucion Loop
        
          ls_cencos_dis := rc_dis.cencos ;
          ln_nro_horas  := rc_dis.nro_horas ;
          ls_cencos_dis := nvl(ls_cencos_dis,' ') ;
          ln_nro_horas  := nvl(ln_nro_horas,0) ;
          
          ln_soles_dis := 0 ; ln_dolar_dis := 0 ;
          ln_soles_dis := ( ln_imp_soles / ln_horas_pag ) * ln_nro_horas ;
          ln_dolar_dis := ( ln_soles_dis / ln_tipo_cambio ) ;

          If ls_cta_deb_obr <> ' ' then
            ln_nro_det := ln_nro_det + 1 ;
            ls_cuenta_deb := ls_cta_deb_obr ;
            Select substr(cc.desc_cnta,1,50)
              into ls_glosa
              from cntbl_cnta cc
              where cc.cnta_ctbl = ls_cuenta_deb ;
            ls_flag_dh    := 'D' ;
            If ln_sw = 1 then
              ls_flag_dh := 'H' ;
            End if ;
            --  Acumula importes para archivo de cabecera
            If ls_flag_dh = 'D' then
              ln_total_soldeb := ln_total_soldeb + ln_soles_dis ;
              ln_total_doldeb := ln_total_doldeb + ln_dolar_dis ;
            End if ;
            If ls_flag_dh = 'H' then
              ln_total_solhab := ln_total_solhab + ln_soles_dis ;
              ln_total_dolhab := ln_total_dolhab + ln_dolar_dis ;
            End if ;
            --  Inserta registros al detalle - DEBE
            If ls_cuenta_deb <> ' ' then
              Insert into cntbl_plnlla_mensual_det (
                cod_origen, nro_libro, nro_provisional, nro_movdet,
                mes_proceso, fec_cntbl, det_glosa, flag_debhab,
                cencos, cnta_ctbl, cod_moneda, tipo_docref,
                nro_docref2, tas_cambio, imp_movsol, imp_movdol,
                imp_movaju )
              Values (
                ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
                ln_mes_proceso, ld_fec_proceso, ls_glosa, ls_flag_dh,
                ls_cencos_dis, ls_cuenta_deb, ls_moneda, 'PLAN',
                ls_cod_rel, ln_tipo_cambio, ln_soles_dis, ln_dolar_dis,
                0 ) ;
            End if ;
          End if ;

        End loop ;

      Else

        If ls_cta_deb_obr <> ' ' then
          ln_nro_det := ln_nro_det + 1 ;
          ls_cuenta_deb := ls_cta_deb_obr ;
          Select substr(cc.desc_cnta,1,50)
            into ls_glosa
            from cntbl_cnta cc
            where cc.cnta_ctbl = ls_cuenta_deb ;
          ls_flag_dh    := 'D' ;
          If ln_sw = 1 then
            ls_flag_dh := 'H' ;
          End if ;
          --  Acumula importes para archivo de cabecera
          If ls_flag_dh = 'D' then
            ln_total_soldeb := ln_total_soldeb + ln_imp_soles ;
            ln_total_doldeb := ln_total_doldeb + ln_imp_dolar ;
          End if ;
          If ls_flag_dh = 'H' then
            ln_total_solhab := ln_total_solhab + ln_imp_soles ;
            ln_total_dolhab := ln_total_dolhab + ln_imp_dolar ;
          End if ;
          --  Inserta registros al detalle - DEBE
          If ls_cuenta_deb <> ' ' then
            Insert into cntbl_plnlla_mensual_det (
              cod_origen, nro_libro, nro_provisional, nro_movdet,
              mes_proceso, fec_cntbl, det_glosa, flag_debhab,
              cencos, cnta_ctbl, cod_moneda, tipo_docref,
              nro_docref2, tas_cambio, imp_movsol, imp_movdol,
              imp_movaju )
            Values (
              ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
              ln_mes_proceso, ld_fec_proceso, ls_glosa, ls_flag_dh,
              ls_cencos, ls_cuenta_deb, ls_moneda, 'PLAN',
              ls_cod_rel, ln_tipo_cambio, ln_imp_soles, ln_imp_dolar,
              0 ) ;
          End if ;
        End if ;
        If ls_cta_hab_obr <> ' ' then
          ln_nro_det := ln_nro_det + 1 ;
          ls_cuenta_hab := ls_cta_hab_obr ;
          Select substr(cc.desc_cnta,1,50)
            into ls_glosa
            from cntbl_cnta cc
            where cc.cnta_ctbl = ls_cuenta_hab ;
          ls_flag_dh    := 'H' ;
          If ln_sw = 1 then
            ls_flag_dh := 'D' ;
          End if ;
          --  Acumula importes para archivo de cabecera
          If ls_flag_dh = 'D' then
            ln_total_soldeb := ln_total_soldeb + ln_imp_soles ;
            ln_total_doldeb := ln_total_doldeb + ln_imp_dolar ;
          End if ;
          If ls_flag_dh = 'H' then
            ln_total_solhab := ln_total_solhab + ln_imp_soles ;
            ln_total_dolhab := ln_total_dolhab + ln_imp_dolar ;
          End if ;
          --  Inserta registros al detalle - HABER
          If ls_cuenta_hab <> ' ' then
            Insert into cntbl_plnlla_mensual_det (
              cod_origen, nro_libro, nro_provisional, nro_movdet,
              mes_proceso, fec_cntbl, det_glosa, flag_debhab,
              cnta_ctbl, cod_moneda, tipo_docref,
              nro_docref2, tas_cambio, imp_movsol, imp_movdol,
              imp_movaju )
            Values (
              ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
              ln_mes_proceso, ld_fec_proceso, ls_glosa, ls_flag_dh,
              ls_cuenta_hab, ls_moneda, 'PLAN',
              ls_cod_rel, ln_tipo_cambio, ln_imp_soles, ln_imp_dolar,
              0 ) ;
          End if ;
        End if ;

      End if ;
    --  ****************************************
    --  ***   GENERA ASIENTOS DE EMPLEADOS   ***
    --  ****************************************
    Elsif as_tipo_trabajador = 'EMP' then

      Select nvl(con.cta_haber_emp,' '), nvl(con.cta_debe_emp,' ')
        into ls_cta_hab_emp, ls_cta_deb_emp
        from concepto con
        where con.concep = ls_concepto ;

      If ls_cta_deb_emp <> ' ' then
        ln_nro_det := ln_nro_det + 1 ;
        ls_cuenta_deb := ls_cta_deb_emp ;
        Select substr(cc.desc_cnta,1,50)
          into ls_glosa
          from cntbl_cnta cc
          where cc.cnta_ctbl = ls_cuenta_deb ;
        ls_flag_dh    := 'D' ;
        If ln_sw = 1 then
          ls_flag_dh := 'H' ;
        End if ;
        --  Acumula importes para archivo de cabecera
        If ls_flag_dh = 'D' then
          ln_total_soldeb := ln_total_soldeb + ln_imp_soles ;
          ln_total_doldeb := ln_total_doldeb + ln_imp_dolar ;
        End if ;
        If ls_flag_dh = 'H' then
          ln_total_solhab := ln_total_solhab + ln_imp_soles ;
          ln_total_dolhab := ln_total_dolhab + ln_imp_dolar ;
        End if ;
        --  Inserta registros al detalle - DEBE
        If ls_cuenta_deb <> ' ' then
          Insert into cntbl_plnlla_mensual_det (
            cod_origen, nro_libro, nro_provisional, nro_movdet,
            mes_proceso, fec_cntbl, det_glosa, flag_debhab,
            cencos, cnta_ctbl, cod_moneda, tipo_docref,
            nro_docref2, tas_cambio, imp_movsol, imp_movdol,
            imp_movaju )
          Values (
            ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
            ln_mes_proceso, ld_fec_proceso, ls_glosa, ls_flag_dh,
            ls_cencos, ls_cuenta_deb, ls_moneda, 'PLAN',
            ls_cod_rel ,ln_tipo_cambio, ln_imp_soles, ln_imp_dolar,
            0 ) ;
        End if ;
      End if ;
      If ls_cta_hab_emp <> ' ' then
        ln_nro_det := ln_nro_det + 1 ;
        ls_cuenta_hab := ls_cta_hab_emp ;
        Select substr(cc.desc_cnta,1,50)
          into ls_glosa
          from cntbl_cnta cc
          where cc.cnta_ctbl = ls_cuenta_hab ;
        ls_flag_dh    := 'H' ;
        If ln_sw = 1 then
          ls_flag_dh := 'D' ;
        End if ;
        --  Acumula importes para archivo de cabecera
        If ls_flag_dh = 'D' then
          ln_total_soldeb := ln_total_soldeb + ln_imp_soles ;
          ln_total_doldeb := ln_total_doldeb + ln_imp_dolar ;
        End if ;
        If ls_flag_dh = 'H' then
          ln_total_solhab := ln_total_solhab + ln_imp_soles ;
          ln_total_dolhab := ln_total_dolhab + ln_imp_dolar ;
        End if ;
        --  Inserta registros al detalle - HABER
        If ls_cuenta_hab <> ' ' then
          Insert into cntbl_plnlla_mensual_det (
            cod_origen, nro_libro, nro_provisional, nro_movdet,
            mes_proceso, fec_cntbl, det_glosa, flag_debhab,
            cnta_ctbl, cod_moneda, tipo_docref,
            nro_docref2, tas_cambio, imp_movsol, imp_movdol,
            imp_movaju )
          Values (
            ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
            ln_mes_proceso, ld_fec_proceso, ls_glosa, ls_flag_dh,
            ls_cuenta_hab, ls_moneda, 'PLAN',
            ls_cod_rel, ln_tipo_cambio, ln_imp_soles, ln_imp_dolar,
            0 ) ;
        End if ;
      End if ;
      
    End if ;    
      
  End loop ;

End loop;

ln_registros := 0 ;
Select count(*)
  into ln_registros
  from cntbl_mov_imp_plnlla_mensual p
  where p.origen = ls_origen and
        p.nro_libro = ln_libro and
        p.nro_provisional = ln_nro_prov ;

If ln_registros > 0 then
  --  Actualiza registro
   Update cntbl_mov_imp_plnlla_mensual
     Set mes_proceso  = ln_mes_proceso , 
         flag_estado  = 1,
         desc_glosa   = 'ASIENTO DE PLANILLA' ,
         fec_registro = ld_fec_proceso , 
         tot_soldeb   = ln_total_soldeb ,
         tot_solhab   = ln_total_solhab ,
         tot_doldeb   = ln_total_doldeb ,
         tot_dolhab   = ln_total_dolhab  
     where origen          = ls_origen and
           nro_libro       = ln_libro and
           nro_provisional = ln_nro_prov and
           fec_cntbl       = ld_fec_proceso ;
End if ;        
  
End usp_gen_asi_plla_bak ;
/
