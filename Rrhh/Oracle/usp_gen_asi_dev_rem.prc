create or replace procedure usp_gen_asi_dev_rem
  ( as_tipo_trabajador  in maestro.tipo_trabajador%type ) is
   
ls_codigo               maestro.cod_trabajador%type ;
ls_cencos               maestro.cencos%type ;

ls_origen               char(2) ;
ln_libro                number(3) ;
ln_nro_prov             number(10) ;
ln_nro_det              number(10) ;
ln_mes_proceso          number(2) ;
ld_fec_proceso          date ;
ln_importe_gen          number(13,2) ;
ln_importe_pag          number(13,2) ;
ln_int_gen_sol          number(13,2) ;
ln_int_gen_dol          number(13,2) ;
ln_int_pag_sol          number(13,2) ;
ln_int_pag_dol          number(13,2) ;
ls_cuenta_deb_gen       char(10) ;
ls_cuenta_hab_gen       char(10) ;
ls_cuenta_deb_pag       char(10) ;
ls_cuenta_hab_pag       char(10) ;
ln_tipo_cambio          number(7,3) ;

ln_sol_gen              number(13,2) ;
ln_sol_pag              number(13,2) ;
ln_dol_gen              number(13,2) ;
ln_dol_pag              number(13,2) ;

ln_registros            integer ;

--  Cursor del maestro con el personal activo
Cursor c_maestro is
  Select m.cod_trabajador, m.cod_labor, m.cencos
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cencos, m.cod_trabajador ;

--  Cursor para generar asientos contables
Cursor c_gratificaciones is
  Select mg.cod_trabajador, mg.imp_int_gen, mg.int_pagado
  from maestro_remun_gratif_dev mg
  where mg.cod_trabajador = ls_codigo and
        to_char(mg.fec_calc_int,'MM') = to_char(ld_fec_proceso,'MM') and
        to_char(mg.fec_calc_int,'YYYY') = to_char(ld_fec_proceso,'YYYY') and
        mg.concep = '1302'
  order by mg.cod_trabajador, mg.fec_pago ;

begin

Select rh.fec_proceso
  into ld_fec_proceso
  from rrhhparam rh
  where rh.reckey = '1' ;
  
ln_mes_proceso := to_number(to_char(ld_fec_proceso,'MM')) ;

--  Asigna numero de asiento para Obreros o Empleados
If as_tipo_trabajador = 'OBR' then
  ls_origen   := 'PR' ;
  ln_libro    := 9 ;
  ln_nro_prov := 9 ;
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
  ls_cuenta_deb_gen := '97291108 ' ; --97291106 grat 97291108 rem
  ls_cuenta_deb_pag := '46600300 ' ; --46600300 grat y rem
  ls_cuenta_hab_gen := '46600300 ' ; --46600300 grat y rem
  ls_cuenta_hab_pag := '41110300 ' ; --41110300 grat y rem
Elsif as_tipo_trabajador = 'EMP' then
  ls_origen   := 'PR' ;
  ln_libro    := 10 ;
  ln_nro_prov := 10 ;
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
  ls_cuenta_deb_gen := '97291107 ' ; -- 97291105 grat 97291107 rem
  ls_cuenta_deb_pag := '46600300 ' ; -- 46600300 grat y rem
  ls_cuenta_hab_gen := '46600300 ' ; -- 46600300 grat y rem
  ls_cuenta_hab_pag := '41110300 ' ; -- 41110300 grat y rem
End if ;

--  Halla tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipo_cambio
  from calendario tc
  where tc.fecha = ld_fec_proceso ;
ln_tipo_cambio := nvl(ln_tipo_cambio,1) ;

ln_sol_gen := 0 ; ln_sol_pag := 0 ;
ln_dol_gen := 0 ; ln_dol_pag := 0 ;
ln_nro_det := 0 ;

--  Lectura para generacion de asientos del maestro
For rc_mae in c_maestro Loop

  ls_codigo := rc_mae.cod_trabajador ;
  ls_cencos := nvl(rc_mae.cencos,' ') ;
  ln_int_gen_sol := 0 ;  ln_int_pag_sol := 0 ;

  --  Lectura detalle para generacion de asientos ( MAESTRO GRATIFICACIONES )
  For rc_gra in c_gratificaciones loop

    ln_importe_gen := nvl(rc_gra.imp_int_gen,0) ;
    ln_importe_pag := nvl(rc_gra.int_pagado,0) ;
    
    ln_int_gen_sol := ln_int_gen_sol + ln_importe_gen ;
    ln_int_pag_sol := ln_int_pag_sol + ln_importe_pag ;

  End loop ;
    
  ln_int_gen_dol := ln_int_gen_sol / ln_tipo_cambio ;
  ln_int_pag_dol := ln_int_pag_sol / ln_tipo_cambio ;

  If ln_int_gen_sol > 0 then
    ln_sol_gen := ln_sol_gen + ln_int_gen_sol ;
    ln_dol_gen := ln_dol_gen + ln_int_gen_dol ;
    ln_nro_det := ln_nro_det + 1 ;
    Insert into cntbl_plnlla_mensual_det (
      cod_origen, nro_libro, nro_provisional, nro_movdet,
      mes_proceso, fec_cntbl, det_glosa, flag_debhab,
      cencos, cnta_ctbl, nro_docref2, tas_cambio,
      imp_movsol, imp_movdol, imp_movaju )
    Values (
      ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
      ln_mes_proceso, ld_fec_proceso, 'ASIENTO REMUNERACION DEVENGADOS', 'H',
      ls_cencos, ls_cuenta_hab_gen, ls_codigo, ln_tipo_cambio,
      ln_int_gen_sol, ln_int_gen_dol, 0 ) ;
  End if ;
  If ln_int_pag_sol > 0 then
    ln_sol_pag := ln_sol_pag + ln_int_pag_sol ;
    ln_dol_pag := ln_dol_pag + ln_int_pag_dol ;
    ln_nro_det := ln_nro_det + 1 ;
    Insert into cntbl_plnlla_mensual_det (
      cod_origen, nro_libro, nro_provisional, nro_movdet,
      mes_proceso, fec_cntbl, det_glosa, flag_debhab,
      cencos, cnta_ctbl, nro_docref2, tas_cambio,
      imp_movsol, imp_movdol, imp_movaju )
    Values (
      ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
      ln_mes_proceso, ld_fec_proceso, 'ASIENTO REMUNERACION DEVENGADOS', 'H',
      ls_cencos, ls_cuenta_hab_pag, ls_codigo, ln_tipo_cambio,
      ln_int_pag_sol, ln_int_pag_dol, 0 ) ;
  End if ;
  
End loop ;  
  
If ln_sol_gen > 0 then
  ln_nro_det := ln_nro_det + 1 ;
  Insert into cntbl_plnlla_mensual_det (
    cod_origen, nro_libro, nro_provisional, nro_movdet,
    mes_proceso, fec_cntbl, det_glosa, flag_debhab,
    cnta_ctbl, nro_docref2, tas_cambio,
    imp_movsol, imp_movdol, imp_movaju )
  Values (
    ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
    ln_mes_proceso, ld_fec_proceso, 'ASIENTO REMUNERACION DEVENGADOS', 'D',
    ls_cuenta_deb_gen, ' ', ln_tipo_cambio,
    ln_sol_gen, ln_dol_gen, 0 ) ;
End if ;
If ln_sol_pag > 0 then
  ln_nro_det := ln_nro_det + 1 ;
  Insert into cntbl_plnlla_mensual_det (
    cod_origen, nro_libro, nro_provisional, nro_movdet,
    mes_proceso, fec_cntbl, det_glosa, flag_debhab,
    cnta_ctbl, nro_docref2, tas_cambio,
    imp_movsol, imp_movdol, imp_movaju )
  Values (
    ls_origen, ln_libro, ln_nro_prov, ln_nro_det,
    ln_mes_proceso, ld_fec_proceso, 'ASIENTO REMUNERACION DEVENGADOS', 'D',
    ls_cuenta_deb_pag, ' ', ln_tipo_cambio,
    ln_sol_pag, ln_dol_pag, 0 ) ;
End if ;

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
         flag_estado  = '1' ,
         desc_glosa   = 'ASIENTO DE REMUNERACION DEVENGADO' ,
         fec_registro = ld_fec_proceso , 
         tot_soldeb   = ln_sol_gen + ln_sol_pag ,
         tot_solhab   = ln_sol_gen + ln_sol_pag ,
         tot_doldeb   = ln_dol_gen + ln_dol_pag ,
         tot_dolhab   = ln_dol_gen + ln_dol_pag 
     where origen          = ls_origen and
           nro_libro       = ln_libro and
           nro_provisional = ln_nro_prov ;
End if ;        
  
End usp_gen_asi_dev_rem ;
/
