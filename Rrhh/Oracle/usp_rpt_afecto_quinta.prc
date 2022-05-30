create or replace procedure usp_rpt_afecto_quinta
( ad_fec_proceso   in rrhhparam.fec_proceso%type ) is

ls_codigo         maestro.cod_trabajador%type ;
ls_nombres        varchar2(40) ;
ls_seccion        maestro.cod_seccion%type ;
ls_desc_seccion   varchar2(40) ;
ls_cencos         maestro.cencos%type ;
ls_desc_cencos    varchar2(40) ;
ln_importe_afe    historico_calculo.imp_soles%type ;
ln_importe_ret    historico_calculo.imp_soles%type ;
ls_year           char(4) ;

--  Cursor para leer todos los activos del maestro
cursor c_maestro is 
  Select m.cod_trabajador, m.cod_seccion, m.cencos
  from maestro m
  where m.flag_estado     = '1' and
        m.flag_cal_plnlla = '1'
  order by m.cod_seccion, m.cod_trabajador ;

begin

delete from tt_rpt_afecto_quinta ;
ls_year := to_char(ad_fec_proceso,'YYYY') ;

For rc_mae in c_maestro Loop

  ls_codigo   := rc_mae.cod_trabajador ;
  ls_seccion  := rc_mae.cod_seccion ;
  ls_cencos   := rc_mae.cencos ;
  ls_nombres  := usf_nombre_trabajador(ls_codigo) ;
       
  If ls_seccion  is not null Then
    Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
  Else 
    ls_seccion := '0' ;
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
  
  Select sum(hc.imp_soles)
    into ln_importe_afe
    from historico_calculo hc
    where hc.cod_trabajador = ls_codigo and
        hc.flag_t_quinta  = '1' and
        to_char(hc.fec_calc_plan,'YYYY') = ls_year ;
  ln_importe_afe := nvl(ln_importe_afe,0) ;

  Select sum(hc.imp_soles)
    into ln_importe_ret
    from historico_calculo hc
    where hc.cod_trabajador = ls_codigo and
        hc.concep = '2010' and
        to_char(hc.fec_calc_plan,'YYYY') = ls_year ;
  ln_importe_ret := nvl(ln_importe_ret,0) ;

  --  Insertar los Registro en la tabla tt_rpt_afecto_quinta
  If ln_importe_afe <> 0 then
    Insert into tt_rpt_afecto_quinta
      (codigo, nombres, cod_seccion,
       desc_seccion, cencos, desc_cencos,
       importe_afe, importe_ret, fecha_proceso)
    Values
      (ls_codigo, ls_nombres, ls_seccion,
       ls_desc_seccion, ls_cencos, ls_desc_cencos,
       ln_importe_afe, ln_importe_ret, ad_fec_proceso) ;
  End if ;

End loop ;

End usp_rpt_afecto_quinta ;
/
