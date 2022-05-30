create or replace procedure usp_rh_rpt_retencion_quinta (
  as_tipo_trabajador in char, as_origen in char, ad_fec_proceso in date ) is

lk_quinta_categoria     char(3) ;

ln_verifica             integer ;
ln_sw                   integer ;
ls_concepto             char(4) ;
ls_codigo               maestro.cod_trabajador%type ;
ls_nombres              varchar2(40) ;
ls_seccion              maestro.cod_seccion%type ;
ls_desc_seccion         varchar2(40) ;
ls_cencos               maestro.cencos%type ;
ls_desc_cencos          varchar2(40) ;
ln_importe_afe          historico_calculo.imp_soles%type ;
ln_importe_ret          historico_calculo.imp_soles%type ;

--  Lectura de trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.cod_seccion, m.cod_area, m.cencos
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.cod_trabajador ;

begin

--  ***************************************************************
--  ***   ACUMULADO DE RETENCIONES AFECTOS A QUINTA CATEGORIA   ***
--  ***************************************************************

delete from tt_rpt_afecto_quinta ;

ln_verifica := 0 ; ln_sw := 0 ;
select count(*) into ln_verifica from calculo c
  where trunc(c.fec_proceso) = ad_fec_proceso ;
if ln_verifica > 0 then
  ln_sw := 1 ;
end if ;
  
select p.quinta_cat_proyecta into lk_quinta_categoria
  from rrhhparam_cconcep p where p.reckey = '1' ;
  
select gc.concepto_gen into ls_concepto from grupo_calculo gc
  where gc.grupo_calculo = lk_quinta_categoria ;

for rc_mae in c_maestro loop

  ls_codigo   := rc_mae.cod_trabajador ;
  ls_seccion  := rc_mae.cod_seccion ;
  ls_cencos   := rc_mae.cencos ;
  ls_nombres  := usf_rh_nombre_trabajador(ls_codigo) ;

  select s.desc_seccion into ls_desc_seccion from seccion s
    where s.cod_area = rc_mae.cod_area and s.cod_seccion = ls_seccion ;

  if ls_cencos is not null then
    select cc.desc_cencos into ls_desc_cencos from centros_costo cc
      where cc.cencos = ls_cencos ;
  end if ;

  if ln_sw = 1 then
  
    select sum(c.imp_soles) into ln_importe_afe from calculo c
      where c.cod_trabajador = ls_codigo and
            trunc(c.fec_proceso) = ad_fec_proceso and
            c.concep in ( select d.concepto_calc from grupo_calculo_det d where
                          d.grupo_calculo = lk_quinta_categoria ) ;
    ln_importe_afe := nvl(ln_importe_afe,0) ;

    select sum(c.imp_soles) into ln_importe_ret from calculo c
      where c.cod_trabajador = ls_codigo and c.concep = ls_concepto and
            trunc(c.fec_proceso) = ad_fec_proceso ;
    ln_importe_ret := nvl(ln_importe_ret,0) ;

  else

    select sum(hc.imp_soles) into ln_importe_afe from historico_calculo hc
      where hc.cod_trabajador = ls_codigo and
            trunc(hc.fec_calc_plan) = ad_fec_proceso and
            hc.concep in ( select d.concepto_calc from grupo_calculo_det d where
                           d.grupo_calculo = lk_quinta_categoria ) ;
    ln_importe_afe := nvl(ln_importe_afe,0) ;

    select sum(hc.imp_soles) into ln_importe_ret from historico_calculo hc
      where hc.cod_trabajador = ls_codigo and hc.concep = ls_concepto and
            trunc(hc.fec_calc_plan) = ad_fec_proceso ;
    ln_importe_ret := nvl(ln_importe_ret,0) ;

  end  if ;
  
  if ln_importe_afe <> 0 then
    insert into tt_rpt_afecto_quinta (
      codigo, nombres, cod_seccion, desc_seccion, cencos,
      desc_cencos, importe_afe, importe_ret, fecha_proceso )
    values (
      ls_codigo, ls_nombres, ls_seccion, ls_desc_seccion, ls_cencos,
      ls_desc_cencos, ln_importe_afe, ln_importe_ret, ad_fec_proceso ) ;
  end if ;

end loop ;

end usp_rh_rpt_retencion_quinta ;
/
