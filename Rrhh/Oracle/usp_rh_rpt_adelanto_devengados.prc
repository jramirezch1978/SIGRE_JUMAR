create or replace procedure usp_rh_rpt_adelanto_devengados (
  as_tipo_trabajador in char, as_origen in char ) is

lk_gratificaciones    char(3) ;
lk_remuneraciones     char(3) ;
lk_racion_azucar      char(3) ;

ls_concepto_gra       char(4) ;
ls_concepto_rem       char(4) ;
ls_concepto_rac       char(4) ;

ls_codigo             maestro.cod_trabajador%type ;
ls_nombres            varchar2(40) ;
ls_seccion            maestro.cod_seccion%type ;
ls_desc_seccion       varchar2(40) ;
ld_fecha              date ;
ln_imp_1              number(13,2) ;
ln_imp_2              number(13,2) ;
ln_imp_3              number(13,2) ;
ln_imp_t              number(13,2) ;

--  Cursor para leer los trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.cod_area, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.cod_trabajador ;

--  Cursor para leer pagos por devengados
cursor c_calculo is
  select c.concep, c.fec_proceso, c.imp_soles
  from calculo c
  where (c.cod_trabajador = ls_codigo and c.concep = ls_concepto_gra) or
        (c.cod_trabajador = ls_codigo and c.concep = ls_concepto_rem) or
        (c.cod_trabajador = ls_codigo and c.concep = ls_concepto_rac) ;

begin

--  *******************************************************
--  ***   REPORTE DE ADELANTOS A CUENTA DE DEVENGADOS   ***
--  *******************************************************

select c.gratific_deveng, c.remun_deveng, c.rac_azucar_deveng
  into lk_gratificaciones, lk_remuneraciones, lk_racion_azucar
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

delete from tt_devengado_mes ;

select g.concepto_gen into ls_concepto_gra from grupo_calculo g
  where g.grupo_calculo = lk_gratificaciones ;
select g.concepto_gen into ls_concepto_rem from grupo_calculo g
  where g.grupo_calculo = lk_remuneraciones ;
select g.concepto_gen into ls_concepto_rac from grupo_calculo g
  where g.grupo_calculo = lk_racion_azucar ;

for rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_nombres := usf_rh_nombre_trabajador(ls_codigo) ;

  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_mae.cod_area and s.cod_seccion = ls_seccion ;

  ln_imp_1 := 0 ; ln_imp_2 := 0 ; ln_imp_3 := 0 ; ln_imp_t := 0 ;
  for rc_cal in c_calculo loop
    ld_fecha := rc_cal.fec_proceso ;
    if rc_cal.concep = ls_concepto_gra then
      ln_imp_1 := nvl(rc_cal.imp_soles,0) ;
    elsif rc_cal.concep = ls_concepto_rem then
      ln_imp_2 := nvl(rc_cal.imp_soles,0) ;
    elsif rc_cal.concep = ls_concepto_rac then
      ln_imp_3 := nvl(rc_cal.imp_soles,0) ;
    end if ;
  end loop ;
  ln_imp_t := ln_imp_1 + ln_imp_2 + ln_imp_3 ;

  if ln_imp_t <> 0 then
    insert into tt_devengado_mes (
      cod_trabajador, nombre, cod_seccion, desc_seccion,
      fec_hasta, importe1, importe2, importe3, importet )
    values (
      ls_codigo, ls_nombres, ls_seccion, ls_desc_seccion,
      ld_fecha, ln_imp_1, ln_imp_2, ln_imp_3, ln_imp_t ) ;
  end if ;

end loop ;

end usp_rh_rpt_adelanto_devengados ;
/
