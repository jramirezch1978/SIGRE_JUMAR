create or replace procedure usp_deuda_laboral
   (as_codtra       in maestro.cod_trabajador%type ,
    ad_fec_proceso  in rrhhparam.fec_proceso%type
   ) is

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

ls_cencos          maestro.cencos%type ;
ls_seccion         maestro.cod_seccion%type ;
ln_contador        integer ;

--  Saldos por compensacion por tiempo de servicios
Cursor c_cts is
  Select ccc.imp_prdo_dpsto, ccc.cts_dispon_ant, ccc.int_legales
  from cnta_crrte_cts ccc
  where ccc.cod_trabajador = as_codtra 
        and ccc.flag_control = '0'
        order by ccc.cod_trabajador, ccc.fec_prdo_dpsto,
                 ccc.fec_calc_int ;

--  Saldos de vacaciones devengadas
Cursor c_vacaciones is
  Select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = as_codtra 
        and pvb.concep in (
        select rhn.concep
        from rrhh_nivel rhn
        where rhn.cod_nivel = lk_prov_vac ) ;
        
--  Saldos de bonificaciones vacacionales devengadas
Cursor c_bonificacion is
  Select pvb.concep, pvb.importe
  from prov_vac_bonif pvb
  where pvb.cod_trabajador = as_codtra 
        and pvb.concep in (
        select rhn.concep
        from rrhh_nivel rhn
        where rhn.cod_nivel = lk_prov_bon ) ;
        
begin
        
--  Halla datos del maestro
Select m.cencos, m.cod_seccion
  into ls_cencos, ls_seccion
  from maestro m
  where m.cod_trabajador = as_codtra ;

--  Halla importe por fondo de retiro
ln_contador := 0 ;
Select count(*)
  into ln_contador
  from fondo_retiro fd
  where fd.cod_trabajador = as_codtra ;
  
If ln_contador > 0 then
Select fd.importe
  into ln_imp_fdo_ret
  from fondo_retiro fd
  where fd.cod_trabajador = as_codtra ;
  ln_imp_fdo_ret := nvl ( ln_imp_fdo_ret, 0 ) ;
End if ;

--  Halla saldos de C.T.S.
ln_disponible := 0 ;
For rc_cts in c_cts Loop
  ln_disponible := ln_disponible + rc_cts.cts_dispon_ant ;
  ln_imp_cts := rc_cts.imp_prdo_dpsto + rc_cts.int_legales ;
End Loop ;
ln_imp_cts := ln_imp_cts + ln_disponible ;
ln_imp_cts := nvl ( ln_imp_cts,0 ) ;

--  Halla saldos de vacaciones devengadas
For rc_vac in c_vacaciones Loop
  ln_imp_vac := rc_vac.importe ;
End Loop ;
ln_imp_vac := nvl ( ln_imp_vac,0 ) ;

--  Halla saldos de bonificacion vacacional devengadas
For rc_bon in c_bonificacion Loop
  ln_imp_bon := rc_bon.importe ;
End Loop ;
ln_imp_bon := nvl ( ln_imp_bon,0 ) ;

--  Halla saldos de gratificaciones, remuneraciones y raciones
ln_contador := 0 ;
Select count(*)
  into ln_contador
  from sldo_deveng sd
  where sd.cod_trabajador = as_codtra ;
  
If ln_contador > 0 then  
Select sd.sldo_gratif_dev, sd.sldo_rem_dev, sd.sldo_racion
  into ln_imp_gra, ln_imp_rem, ln_imp_rac
  from sldo_deveng sd
  where sd.cod_trabajador = as_codtra ;
End if ;

ln_imp_gra := nvl ( ln_imp_gra, 0 ) ;
ln_imp_rem := nvl ( ln_imp_rem, 0 ) ;
ln_imp_rac := nvl ( ln_imp_rac, 0 ) ;

--  Adiciona registros
--  Fondo de retiro
If ln_imp_fdo_ret > 0 then
  Insert into deuda
    ( cod_trabajador, fec_proceso,    cencos,    concep,
        cod_seccion,  flag_estado, importe )
  Values     
    ( as_codtra,      ad_fec_proceso, ls_cencos, '4001',
        ls_seccion,   '1',         ln_imp_fdo_ret ) ;
End if ;

--  Compensacion tiempo de servicio
If ln_imp_cts > 0 then
  Insert into deuda
    ( cod_trabajador, fec_proceso,    cencos,    concep,
        cod_seccion,  flag_estado, importe )
  Values     
    ( as_codtra,      ad_fec_proceso, ls_cencos, '4003',
        ls_seccion,   '1',         ln_imp_cts     ) ;
End if ;

--  Vacaciones devengadas
If ln_imp_vac > 0 then
  Insert into deuda
    ( cod_trabajador, fec_proceso,    cencos,    concep,
        cod_seccion,  flag_estado, importe )
  Values     
    ( as_codtra,      ad_fec_proceso, ls_cencos, '4004',
        ls_seccion,   '1',         ln_imp_vac     ) ;
End if ;        

--  Bonificacion vacacional devengada
If ln_imp_bon > 0 then
  Insert into deuda    
    ( cod_trabajador, fec_proceso,    cencos,    concep,
        cod_seccion,  flag_estado, importe )
  Values     
    ( as_codtra,      ad_fec_proceso, ls_cencos, '4005',
        ls_seccion,   '1',         ln_imp_bon     ) ;
End if ;

--  Gratificaciones devengadas
If ln_imp_gra > 0 then
  Insert into deuda
    ( cod_trabajador, fec_proceso,    cencos,    concep,
        cod_seccion,  flag_estado, importe )
  Values     
    ( as_codtra,      ad_fec_proceso, ls_cencos, '4006',
        ls_seccion,   '1',         ln_imp_gra     ) ;
End if ;

--  Remuneraciones devengadas
If ln_imp_rem > 0 then
  Insert into deuda
    ( cod_trabajador, fec_proceso,    cencos,    concep,
        cod_seccion,  flag_estado, importe )
  Values     
    ( as_codtra,      ad_fec_proceso, ls_cencos, '4007',
        ls_seccion,   '1',         ln_imp_rem     ) ;
End if ;

--  Raciones de Azucar devengadas
If ln_imp_rac > 0 then
  Insert into deuda
    ( cod_trabajador, fec_proceso,    cencos,    concep,
        cod_seccion,  flag_estado, importe )
  Values     
    ( as_codtra,      ad_fec_proceso, ls_cencos, '4008',
        ls_seccion,   '1',         ln_imp_rac     ) ;
End if ;

End usp_deuda_laboral ;
/
