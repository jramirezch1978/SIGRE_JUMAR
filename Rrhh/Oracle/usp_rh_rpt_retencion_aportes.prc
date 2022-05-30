create or replace procedure usp_rh_rpt_retencion_aportes (
  as_tipo_trabajador in char, as_origen in char, as_ano in char ) is

ls_cod_trabajador      maestro.cod_trabajador%type ;
ls_nombre              varchar2(60) ;
ls_dni_le              maestro.dni%type ;
ld_fecha_ingreso       date ;
ls_seccion             maestro.cod_seccion%type ;
ls_desc_seccion        varchar2(30) ;
ls_cod_afp             maestro.cod_afp%type ;
ls_nombre_afp          admin_afp.desc_afp%type ;
ls_nro_afp             maestro.nro_afp_trabaj%type ;
ls_nro_ipss            maestro.nro_ipss%type ;
ls_nombre_mes          char(9) ;
ls_nro_mes             char(2) ;
ln_rem_asegurable      number(13,2) ;
ln_fdo_pensiones       number(13,2) ;
ln_seg_invalidez       number(13,2) ;
ln_apo_comision        number(13,2) ;
ln_aportes_onp         number(13,2) ;
ln_seg_agrario         number(13,2) ;
ln_seg_sctr            number(13,2) ;

ls_concepto            concepto.concep%type ;
ln_importe             historico_calculo.imp_soles%type ;
ls_mes                 char(2) ;

--  Cursor para leer todos los activos del maestro
cursor c_maestro is 
  select m.cod_trabajador, m.fec_ingreso, m.dni, m.nro_ipss, m.cod_afp,
         m.nro_afp_trabaj, m.cod_seccion, m.cod_area
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion ;

--  Cursor para leer aportes al sistema de pensiones
cursor c_historico is 
  select hc.concep, hc.fec_calc_plan, hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = ls_cod_trabajador and to_char(hc.fec_calc_plan,'MM') =
        ls_mes and to_char(hc.fec_calc_plan,'YYYY') = as_ano
  order by hc.cod_trabajador, hc.fec_calc_plan, hc.concep ;

begin

--  ******************************************************************
--  ***   RETENCION DE APORTES AL SISTEMA DE PENSIONES LEY 27606   ***
--  ******************************************************************

delete from tt_retencion_aportes ;

for rc_mae in c_maestro loop

  ls_cod_trabajador := rc_mae.cod_trabajador ;
  ld_fecha_ingreso  := nvl(rc_mae.fec_ingreso,sysdate) ;
  ls_dni_le         := nvl(rc_mae.dni,' ') ;
  ls_nro_ipss       := nvl(rc_mae.nro_ipss,' ') ;
  ls_cod_afp        := nvl(rc_mae.cod_afp,' ') ;
  ls_nro_afp        := nvl(rc_mae.nro_afp_trabaj,' ') ;
  ls_seccion        := nvl(rc_mae.cod_seccion,' ') ;
  ls_nombre         := usf_nombre_trabajador(ls_cod_trabajador) ;
       
  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_mae.cod_area and s.cod_seccion = ls_seccion ;

  if ls_cod_afp <> ' ' then
    select afp.desc_afp into ls_nombre_afp from admin_afp afp
      where afp.cod_afp = ls_cod_afp ;
  end if ;
  ls_nombre_afp := nvl(ls_nombre_afp,' ') ;    
      
  for x in 1 .. 12 loop

    ln_rem_asegurable := 0 ; ln_fdo_pensiones := 0 ;
    ln_seg_invalidez  := 0 ; ln_apo_comision  := 0 ;
    ln_aportes_onp    := 0 ; ln_seg_agrario   := 0 ;
    ln_seg_sctr       := 0 ;

    if x = 1 then
      ls_nombre_mes := 'Enero    ' ;
      ls_nro_mes := '01' ;
    elsif x = 2 then
      ls_nombre_mes := 'Febrero  ' ;
      ls_nro_mes := '02' ;
    elsif x = 3 then
      ls_nombre_mes := 'Marzo    ' ;
      ls_nro_mes := '03' ;
    elsif x = 4 then
      ls_nombre_mes := 'Abril    ' ;
      ls_nro_mes := '04' ;
    elsif x = 5 then
      ls_nombre_mes := 'Mayo     ' ;
      ls_nro_mes := '05' ;
    elsif x = 6 then
      ls_nombre_mes := 'Junio    ' ;
      ls_nro_mes := '06' ;
    elsif x = 7 then
      ls_nombre_mes := 'Julio    ' ;
      ls_nro_mes := '07' ;
    elsif x = 8 then
      ls_nombre_mes := 'Agosto   ' ;
      ls_nro_mes := '08' ;
    elsif x = 9 then
      ls_nombre_mes := 'Setiembre' ;
      ls_nro_mes := '09' ;
    elsif x = 10 then
      ls_nombre_mes := 'Octubre  ' ;
      ls_nro_mes := '10' ;
    elsif x = 11 then
      ls_nombre_mes := 'Noviembre' ;
      ls_nro_mes := '11' ;
    elsif x = 12 then
      ls_nombre_mes := 'Diciembre' ;
      ls_nro_mes := '12' ;
    end if ;
    ls_mes := lpad(rtrim(to_char(x)),2,'0') ;

    for rc_his in c_historico loop

      ls_concepto      := rc_his.concep ;
      ln_importe       := nvl(rc_his.imp_soles,0) ;

      if ls_concepto = '2002' then
        ln_fdo_pensiones  := ln_fdo_pensiones + ln_importe ;
        ln_rem_asegurable := ln_fdo_pensiones / 0.08 ;
      elsif ls_concepto = '2003' then
        ln_seg_invalidez := ln_seg_invalidez + ln_importe ;
      elsif ls_concepto = '2004' then
        ln_apo_comision := ln_apo_comision + ln_importe ;
      elsif ls_concepto = '2001' then
        ln_aportes_onp    := ln_aportes_onp + ln_importe ;
        ln_rem_asegurable := ln_aportes_onp / 0.13 ;
      elsif ls_concepto = '3002' then
        ln_seg_agrario := ln_seg_agrario + ln_importe ;
      elsif ls_concepto = '3004' then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      elsif ls_concepto = '3005' then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      end if ;
      
    end loop ;     

    if ln_rem_asegurable <> 0 then
      insert into tt_retencion_aportes (
        cod_trabajador, nombre, dni_le, 
        fecha_ingreso, seccion, desc_seccion, 
        nombre_afp, nro_afp, nro_ipss, 
        nombre_mes, nro_mes, rem_asegurable, fdo_pensiones, 
        seg_invalidez, apo_comision, aportes_onp, 
        seg_agrario, seg_sctr )
      values (
        ls_cod_trabajador, ls_nombre, ls_dni_le, 
        ld_fecha_ingreso, ls_seccion, ls_desc_seccion, 
        ls_nombre_afp, ls_nro_afp, ls_nro_ipss, 
        ls_nombre_mes, ls_nro_mes, ln_rem_asegurable, ln_fdo_pensiones, 
        ln_seg_invalidez, ln_apo_comision, ln_aportes_onp, 
        ln_seg_agrario, ln_seg_sctr ) ;
    end if ;

  end loop ;

end loop ;

end usp_rh_rpt_retencion_aportes ;
/
