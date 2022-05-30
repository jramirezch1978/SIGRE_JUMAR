create or replace procedure usp_rpt_devengados
  ( ad_fec_proceso  in date ) is

ln_imp_gra         sldo_deveng.sldo_gratif_dev%type ;
ln_imp_rem         sldo_deveng.sldo_rem_dev%type ;
ln_imp_rac         sldo_deveng.sldo_racion%type ;
ln_imp_total       number(13,2) ;

ls_codigo          maestro.cod_trabajador%type ;
ls_seccion         maestro.cod_seccion%type ;
ls_nombres         varchar2(40) ;
ls_desc_seccion    varchar2(40) ;
ln_contador        integer ;

--  Cursor para leer todos los trabajadores activos del maestro
Cursor c_maestro is
  Select m.cod_trabajador, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1'
  order by m.cod_seccion, m.apel_paterno, m.apel_materno,
           m.nombre1, m.nombre2 ;

begin

delete from tt_rpt_devengados ;
        
For rc_mae in c_maestro Loop

  ln_imp_gra := 0 ;
  ln_imp_rem := 0 ;
  ln_imp_rac := 0 ;

  ls_codigo  := rc_mae.cod_trabajador ;
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

  ln_imp_total := ln_imp_gra + ln_imp_rem + ln_imp_rac ;
  ln_imp_total := nvl(ln_imp_total,0) ;

  --  Adiciona registros en la tabla temporal tt_rpt_deudas
  If ln_imp_total <> 0 then
    Insert into tt_rpt_devengados
      (cod_trabajador, nombre, cod_seccion,
       desc_seccion, fecha, imp_gradev,
       imp_remdev, imp_racazu, imp_total)
    Values     
      (ls_codigo, ls_nombres, ls_seccion,
       ls_desc_seccion, ad_fec_proceso, ln_imp_gra,
       ln_imp_rem, ln_imp_rac, ln_imp_total) ;
  End if ;

End loop ;

End usp_rpt_devengados ;
/
