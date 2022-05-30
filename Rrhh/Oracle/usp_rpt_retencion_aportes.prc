create or replace procedure usp_rpt_retencion_aportes
( as_ano_proceso      in concepto.concep%type,
  as_tipo_trabajador  in maestro.tipo_trabajador%type ) is

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
  Select m.cod_trabajador, m.fec_ingreso, m.dni,
         m.nro_ipss, m.cod_afp, m.nro_afp_trabaj,
         m.cod_seccion
  from maestro m
  where m.flag_estado     = '1' and
        m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_seccion ;

--  Cursor para leer aportes al sistema de pensiones
cursor c_historico is 
  Select hc.concep, hc.fec_calc_plan, hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = ls_cod_trabajador and
        to_char(hc.fec_calc_plan,'MM') = ls_mes and
        to_char(hc.fec_calc_plan,'YYYY') = as_ano_proceso
  order by hc.cod_trabajador, hc.fec_calc_plan, hc.concep ;

begin

delete from tt_retencion_aportes ;

--  Lectura del maestro de trabajadores
For rc_mae in c_maestro Loop

  ls_cod_trabajador := rc_mae.cod_trabajador ;
  ld_fecha_ingreso  := nvl(rc_mae.fec_ingreso,sysdate) ;
  ls_dni_le         := nvl(rc_mae.dni,' ') ;
  ls_nro_ipss       := nvl(rc_mae.nro_ipss,' ') ;
  ls_cod_afp        := nvl(rc_mae.cod_afp,' ') ;
  ls_nro_afp        := nvl(rc_mae.nro_afp_trabaj,' ') ;
  ls_seccion        := nvl(rc_mae.cod_seccion,' ') ;
  ls_nombre         := usf_nombre_trabajador(ls_cod_trabajador) ;
       
  Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
  ls_desc_seccion := nvl(ls_desc_seccion,' ') ;

  ls_nombre_afp := null ;
  If ls_cod_afp <> ' ' then
    Select nvl(afp.desc_afp,' ')
      into ls_nombre_afp
      from admin_afp afp
      where afp.cod_afp = ls_cod_afp ;
  End if ;
      
  --  Lectura de registros anuales
  For x in 1 .. 12 Loop

    ln_rem_asegurable := 0 ; ln_fdo_pensiones := 0 ;
    ln_seg_invalidez  := 0 ; ln_apo_comision  := 0 ;
    ln_aportes_onp    := 0 ; ln_seg_agrario   := 0 ;
    ln_seg_sctr       := 0 ;

    If x = 1 then
      ls_nombre_mes := 'Enero    ' ;
      ls_nro_mes := '01' ;
    Elsif x = 2 then
      ls_nombre_mes := 'Febrero  ' ;
      ls_nro_mes := '02' ;
    Elsif x = 3 then
      ls_nombre_mes := 'Marzo    ' ;
      ls_nro_mes := '03' ;
    Elsif x = 4 then
      ls_nombre_mes := 'Abril    ' ;
      ls_nro_mes := '04' ;
    Elsif x = 5 then
      ls_nombre_mes := 'Mayo     ' ;
      ls_nro_mes := '05' ;
    Elsif x = 6 then
      ls_nombre_mes := 'Junio    ' ;
      ls_nro_mes := '06' ;
    Elsif x = 7 then
      ls_nombre_mes := 'Julio    ' ;
      ls_nro_mes := '07' ;
    Elsif x = 8 then
      ls_nombre_mes := 'Agosto   ' ;
      ls_nro_mes := '08' ;
    Elsif x = 9 then
      ls_nombre_mes := 'Setiembre' ;
      ls_nro_mes := '09' ;
    Elsif x = 10 then
      ls_nombre_mes := 'Octubre  ' ;
      ls_nro_mes := '10' ;
    Elsif x = 11 then
      ls_nombre_mes := 'Noviembre' ;
      ls_nro_mes := '11' ;
    Elsif x = 12 then
      ls_nombre_mes := 'Diciembre' ;
      ls_nro_mes := '12' ;
    End if ;
    ls_mes := lpad(rtrim(to_char(x)),2,'0') ;

    --  Lectura de registros mensuales
    For rc_his in c_historico Loop

      ls_concepto      := rc_his.concep ;
      ln_importe       := nvl(rc_his.imp_soles,0) ;

      If ls_concepto = '2002' then
        ln_fdo_pensiones  := ln_fdo_pensiones + ln_importe ;
        ln_rem_asegurable := ln_fdo_pensiones / 0.08 ;
      Elsif ls_concepto = '2003' then
        ln_seg_invalidez := ln_seg_invalidez + ln_importe ;
      Elsif ls_concepto = '2004' then
        ln_apo_comision := ln_apo_comision + ln_importe ;
      Elsif ls_concepto = '2001' then
        ln_aportes_onp    := ln_aportes_onp + ln_importe ;
        ln_rem_asegurable := ln_aportes_onp / 0.13 ;
      Elsif ls_concepto = '3002' then
        ln_seg_agrario := ln_seg_agrario + ln_importe ;
      Elsif ls_concepto = '3004' then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      Elsif ls_concepto = '3005' then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      End if ;
      
    End loop ;     

    --  Graba registros para emision de reporte
    If ln_rem_asegurable <> 0 then
      Insert into tt_retencion_aportes (
        cod_trabajador, nombre, dni_le, 
        fecha_ingreso, seccion, desc_seccion, 
        nombre_afp, nro_afp, nro_ipss, 
        nombre_mes, nro_mes, rem_asegurable, fdo_pensiones, 
        seg_invalidez, apo_comision, aportes_onp, 
        seg_agrario, seg_sctr )
      Values (
        ls_cod_trabajador, ls_nombre, ls_dni_le, 
        ld_fecha_ingreso, ls_seccion, ls_desc_seccion, 
        ls_nombre_afp, ls_nro_afp, ls_nro_ipss, 
        ls_nombre_mes, ls_nro_mes, ln_rem_asegurable, ln_fdo_pensiones, 
        ln_seg_invalidez, ln_apo_comision, ln_aportes_onp, 
        ln_seg_agrario, ln_seg_sctr ) ;
    End if ;

  End Loop ;

End loop ;

End usp_rpt_retencion_aportes ;
/
