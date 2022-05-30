create or replace procedure usp_rh_adeudo_laboral_org(
   asi_cod_origen in string,
   asi_tipo_trabajador in string,
   aso_ini out string,
   aso_fecha_reporte out string
)is

ls_prov_vac        char(3);
ls_prov_bon        char(3);
ls_concep_prov_vac char(4);
ls_concep_prov_bon char(4);

ln_imp_cts         cnta_crrte_cts.cts_dispon_ant%type ;
ln_disponible      cnta_crrte_cts.cts_dispon_ant%type ;
ln_imp_vac         prov_vac_bonif.importe%type ;
ln_imp_bon         prov_vac_bonif.importe%type ;
ln_imp_gra         sldo_deveng.sldo_gratif_dev%type ;
ln_imp_rem         sldo_deveng.sldo_rem_dev%type ;
ln_imp_rac         sldo_deveng.sldo_racion%type ;
ln_imp_total       number(13,2) ;

ls_codigo          maestro.cod_trabajador%type ;
ln_contador        integer ;

--  Cursor para leer todos los trabajadores seleccionados que estén activos y se les calcule planilla
cursor c_maestro is
   select m.cod_trabajador, m.cencos, m.cod_seccion, m.cod_area
   from maestro m
   where m.flag_estado = '1' 
      and m.flag_cal_plnlla = '1'
      and m.cod_origen = asi_cod_origen
      and m.tipo_trabajador = asi_tipo_trabajador;

--  Saldos por compensacion por tiempo de servicios
cursor c_cts is
   select ccc.imp_prdo_dpsto, ccc.cts_dispon_ant, ccc.int_legales
   from cnta_crrte_cts ccc
   where ccc.cod_trabajador = ls_codigo 
      and ccc.flag_control = '0';

--  Saldos de vacaciones devengadas
cursor c_vacaciones is
   select pvb.concep, pvb.importe
      from prov_vac_bonif pvb
      where pvb.cod_trabajador = ls_codigo 
         and pvb.concep = ls_concep_prov_bon ;

--  Saldos de bonificaciones vacacionales devengadas
cursor c_bonificacion is
   select pvb.concep, pvb.importe
   from prov_vac_bonif pvb
   where pvb.cod_trabajador = ls_codigo 
      and pvb.concep = ls_concep_prov_vac;

-- Impoirte de fonode de retiro
cursor c_fondo_retiro is
   select fd.fec_proceso, nvl(fd.importe,0) as importe
      from fondo_retiro fd
      where fd.cod_trabajador = ls_codigo ;
      

begin
select to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss') into aso_ini from dual;
--  ************************************************************
--  ***   REPORTE DE ADEUDOS LABORALES DE LOS TRABAJADORES   ***
--  ************************************************************

--  Grupos para ganacias fijas para cálculo de vacaciones y ganancias para el álculo de bonificación vacacional
select rc.gan_fij_calc_vacac, rc.gan_bonif_vacacion 
   into ls_prov_vac, ls_prov_bon 
   from rrhhparam_cconcep rc 
   where rc.reckey = '1';

--   Concepto de generación de bonificación vacacional
select gc.concepto_gen 
   into ls_concep_prov_bon 
   from grupo_calculo gc 
   where gc.grupo_calculo = ls_prov_bon;

--  Concepto de generación de ganancias fijas para c{alculo de vacaciones
select gc.concepto_gen 
   into ls_concep_prov_vac 
   from grupo_calculo gc 
   where gc.grupo_calculo = ls_prov_vac;
   
delete from tt_rh_adeudo_laboral;

for rc_mae in c_maestro loop

   ln_imp_cts := 0 ; ln_imp_vac := 0 ; /*ln_imp_fdo_ret := 0 ;*/ ln_imp_rem := 0 ; 
   ln_imp_bon := 0 ; ln_imp_gra := 0 ; ln_imp_rac := 0 ; ls_codigo  := rc_mae.cod_trabajador ;

   --  Halla importe por fondo de retiro
   ln_contador := 0 ; /*ln_imp_fdo_ret := 0 ;*/
   
   for rs_fr in c_fondo_retiro loop

      --  Halla saldos de C.T.S.
      ln_disponible := 0 ; ln_imp_cts := 0 ;
      for rc_cts in c_cts loop
        ln_disponible := ln_disponible + nvl(rc_cts.cts_dispon_ant,0) ;
        ln_imp_cts := nvl(rc_cts.imp_prdo_dpsto,0) + nvl(rc_cts.int_legales,0) ;
      end loop ;
      ln_imp_cts := ln_imp_cts + ln_disponible ;

   --  Halla saldos de vacaciones devengadas
      ln_imp_vac := 0 ;
      for rc_vac in c_vacaciones loop
        ln_imp_vac := nvl(rc_vac.importe,0) ;
      end loop ;

  --  Halla saldos de bonificacion vacacional devengadas
      ln_imp_bon := 0 ;
      for rc_bon in c_bonificacion loop
         ln_imp_bon := nvl(rc_bon.importe,0) ;
      end loop ;

   --  Halla saldos de gratificaciones, remuneraciones y raciones
      ln_contador := 0 ; ln_imp_gra := 0 ; ln_imp_rem := 0 ; ln_imp_rac := 0 ;
     
      select count(*) 
         into ln_contador 
         from sldo_deveng sd
         where sd.cod_trabajador = ls_codigo 
            and trunc(sd.fec_proceso) = trunc(rs_fr.fec_proceso);
         
      if ln_contador > 0 then
         select nvl(sd.sldo_gratif_dev,0), nvl(sd.sldo_rem_dev,0), nvl(sd.sldo_racion,0)
            into ln_imp_gra, ln_imp_rem, ln_imp_rac 
            from sldo_deveng sd
            where sd.cod_trabajador = ls_codigo 
               and trunc(sd.fec_proceso) = trunc(rs_fr.fec_proceso) ;
      end if ;

      ln_imp_total := rs_fr.importe + ln_imp_cts + ln_imp_vac + ln_imp_bon + ln_imp_gra + ln_imp_rem + ln_imp_rac ;
      ln_imp_total := nvl(ln_imp_total,0) ;

  --  Adiciona registros en la tabla temporal tt_rh_adeudo_laboral
     if ln_imp_total <> 0 then
       insert into tt_rh_adeudo_laboral (
         cod_trabajador, fecha, imp_fdoret, imp_cts, imp_vacdev, imp_bondev, imp_gradev, imp_remdev, imp_racazu, imp_total )
       values (
         ls_codigo, rs_fr.fec_proceso, rs_fr.importe, ln_imp_cts, ln_imp_vac, ln_imp_bon, ln_imp_gra, ln_imp_rem, ln_imp_rac, ln_imp_total ) ;
     end if ;
  end loop;

end loop ;

select to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss') 
   into aso_fecha_reporte 
   from dual;
   
end usp_rh_adeudo_laboral_org ;
/
