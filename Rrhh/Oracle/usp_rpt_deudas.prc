create or replace procedure usp_rpt_deudas
  ( ad_fec_proceso  in rrhhparam.fec_proceso%type ) is

lk_prov_vac        constant char(3) := '082' ;
lk_prov_bon        constant char(3) := '085' ;

ln_imp_fdo_ret     fondo_retiro.importe%type ;
ln_imp_cts         cnta_crrte_cts.cts_dispon_ant%type ;
ln_disponible      cnta_crrte_cts.cts_dispon_ant%type ;
ln_imp_vac         prov_vac_bonif.importe%type ;
ln_imp_bon         prov_vac_bonif.importe%type ;
ln_imp_gra         sldo_deveng.sldo_gratif_dev%type ;
ln_imp_rem         sldo_deveng.sldo_rem_dev%type ;
ln_imp_rac         sldo_deveng.sldo_racion%type ;
ln_imp_total       number(13,2) ;

ls_codigo          maestro.cod_trabajador%type ;
ls_cencos          maestro.cencos%type ;
ls_seccion         maestro.cod_seccion%type ;
ls_nombres         varchar2(40) ;
ls_desc_seccion    varchar2(40) ;
ls_desc_cencos     varchar2(40) ;
ln_contador        integer ;

--  Cursor para leer todos los trabajadores activos del maestro
Cursor c_maestro is
  Select m.cod_trabajador, m.cencos, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1'
  order by m.cod_seccion, m.cod_trabajador ;

--  Saldos por compensacion por tiempo de servicios
Cursor c_cts is
  Select ccc.imp_prdo_dpsto, ccc.cts_dispon_ant, ccc.int_legales
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = ls_codigo
        and ccc.flag_control = '0'
  order by ccc.cod_trabajador, ccc.fec_prdo_dpsto,
           ccc.fec_calc_int ;

--  Saldos de vacaciones devengadas
Cursor c_vacaciones is
  Select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = ls_codigo
        and pvb.concep in (
        select rhn.concep
        from rrhh_nivel rhn
        where rhn.cod_nivel = lk_prov_vac ) ;
        
--  Saldos de bonificaciones vacacionales devengadas
Cursor c_bonificacion is
  Select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = ls_codigo
        and pvb.concep in (
        select rhn.concep
        from rrhh_nivel rhn
        where rhn.cod_nivel = lk_prov_bon ) ;
        
begin

delete from tt_rpt_deudas ;
        
For rc_mae in c_maestro Loop

  ln_imp_fdo_ret := 0 ;
  ln_imp_cts     := 0 ;
  ln_imp_vac     := 0 ;
  ln_imp_bon     := 0 ;
  ln_imp_gra     := 0 ;
  ln_imp_rem     := 0 ;
  ln_imp_rac     := 0 ;

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_cencos  := rc_mae.cencos ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_nombres := usf_nombre_trabajador(ls_codigo) ;
       
  If ls_seccion  is not null Then
    Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
  Else 
    ls_seccion := '340' ;
  End if ;
  ls_desc_seccion := nvl(ls_desc_seccion,' ') ;

  If ls_cencos is not null then
    Select cc.desc_cencos
    into ls_desc_cencos
    from centros_costo cc
    where cc.cencos = ls_cencos ;
  Else
    ls_cencos := '0' ;
  End if ;
  ls_desc_cencos := nvl(ls_desc_cencos,' ') ;

  --  Halla importe por fondo de retiro
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from fondo_retiro fd
    where fd.cod_trabajador = ls_codigo and
          fd.fec_proceso = ad_fec_proceso ;
  
  If ln_contador > 0 then
    Select fd.importe
      into ln_imp_fdo_ret
      from fondo_retiro fd
      where fd.cod_trabajador = ls_codigo and
            fd.fec_proceso = ad_fec_proceso ;
      ln_imp_fdo_ret := nvl ( ln_imp_fdo_ret, 0 ) ;
  End if ;

  --  Halla saldos de C.T.S.
  ln_disponible := 0 ;
  For rc_cts in c_cts Loop
    ln_disponible := ln_disponible + rc_cts.cts_dispon_ant ;
    ln_imp_cts := rc_cts.imp_prdo_dpsto + rc_cts.int_legales ;
  End Loop ;
  ln_imp_cts := ln_imp_cts + ln_disponible ;
  ln_imp_cts := nvl(ln_imp_cts,0) ;

  --  Halla saldos de vacaciones devengadas
  For rc_vac in c_vacaciones Loop
    ln_imp_vac := rc_vac.importe ;
  End Loop ;
  ln_imp_vac := nvl(ln_imp_vac,0) ;

  --  Halla saldos de bonificacion vacacional devengadas
  For rc_bon in c_bonificacion Loop
    ln_imp_bon := rc_bon.importe ;
  End Loop ;
  ln_imp_bon := nvl(ln_imp_bon,0) ;

  --  Halla saldos de gratificaciones, remuneraciones y raciones
  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from sldo_deveng sd
    where sd.cod_trabajador = ls_codigo and
          sd.fec_proceso = ad_fec_proceso ;
  
  If ln_contador > 0 then  
  Select sd.sldo_gratif_dev, sd.sldo_rem_dev, sd.sldo_racion
    into ln_imp_gra, ln_imp_rem, ln_imp_rac
    from sldo_deveng sd
    where sd.cod_trabajador = ls_codigo and
          sd.fec_proceso = ad_fec_proceso ;
  End if ;

  ln_imp_gra := nvl(ln_imp_gra,0) ;
  ln_imp_rem := nvl(ln_imp_rem,0) ;
  ln_imp_rac := nvl(ln_imp_rac,0) ;

  ln_imp_total := ln_imp_fdo_ret + ln_imp_cts + ln_imp_vac +
                  ln_imp_bon + ln_imp_gra + ln_imp_rem + ln_imp_rac ;
  ln_imp_total := nvl(ln_imp_total,0) ;

  --  Adiciona registros en la tabla temporal tt_rpt_deudas
  If ln_imp_total <> 0 then
    Insert into tt_rpt_deudas
      (cod_trabajador, nombre, cod_seccion,
       desc_seccion, cencos, desc_cencos,
       fecha, imp_fdoret, imp_cts,
       imp_vacdev, imp_bondev, imp_gradev,
       imp_remdev, imp_racazu, imp_total)
    Values     
      (ls_codigo, ls_nombres, ls_seccion,
       ls_desc_seccion, ls_cencos, ls_desc_cencos,
       ad_fec_proceso, ln_imp_fdo_ret, ln_imp_cts,
       ln_imp_vac, ln_imp_bon, ln_imp_gra,
       ln_imp_rem, ln_imp_rac, ln_imp_total) ;
  End if ;

End loop ;

End usp_rpt_deudas ;
/
