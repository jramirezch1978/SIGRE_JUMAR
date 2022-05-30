create or replace procedure usp_rh_cts_add_presupuesto (
  as_usuario in char, ad_fec_proceso in date, as_origen in char,
  ad_mensaje in out char ) is

lk_desc_variacion    constant varchar2(100) := 'AMPLIACION AUTOMATICA DE LA PLANILLA DE C.T.S.' ;
lk_cnta_prsp_emp     constant char(10) := '2070.01.06' ;
lk_cnta_prsp_obr     constant char(10) := '2070.01.07' ;
lk_empleado          constant char(03) := 'EMP' ;
lk_obrero            constant char(03) := 'OBR' ;
lk_tipo_doc          constant char(04) := 'GCTS' ;

ls_flag_control      presupuesto_partida.flag_ctrl%type ;
ln_contador          integer ;
ls_cnta_prsp         char(10) ;
ls_cencos            char(10) ;
ls_tipo_t            char(03) ;
ln_importe           number(13,2) ;
ln_imp_control       number(13,2) ;
ln_imp_diferencia    number(13,2) ;
ln_tipo_cambio       number(07,3) ;
ln_ano               number(04) ;
ln_mes               number(02) ;
ls_descripcion       varchar2(100) ;

--  Lectura de C.T.S. decreto de urgencia mensual
cursor c_movimiento is
  select du.cod_trabajador, du.liquidacion, m.tipo_trabajador, m.cencos
  from cts_decreto_urgencia du, maestro m
  where du.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        to_char(du.fec_proceso,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy')
  order by m.cencos, m.tipo_trabajador, du.cod_trabajador ;
rc_mov c_movimiento%rowtype ;

begin

--  *************************************************************
--  ***  ADICIONA C.T.S. DECRETO DE URGENCIA AL PRESUPUESTO   ***
--  *************************************************************

delete from presupuesto_ejec pe
  where to_char(pe.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') and
        pe.tipo_doc_ref = lk_tipo_doc ;

--  Determina el tipo de cambio a la fecha
ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*) into ln_contador from calendario c
  where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,1) into ln_tipo_cambio from calendario c
    where to_char(c.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') ;
end if ;

ln_ano := to_number(to_char(ad_fec_proceso,'yyyy')) ;
ln_mes := to_number(to_char(ad_fec_proceso,'mm')) ;

--  *****************************************************************
--  ***   GENERA AMPLIACION SI EL GASTO ES MAYOR AL PRESUPUESTO   ***
--  *****************************************************************
open c_movimiento ;
fetch c_movimiento into rc_mov ;

while c_movimiento%found loop

  ls_cencos := rc_mov.cencos ;
  ls_tipo_t := rc_mov.tipo_trabajador ;

  ln_importe := 0 ;
  while rc_mov.cencos = ls_cencos and rc_mov.tipo_trabajador = ls_tipo_t and
        c_movimiento%found loop
    ln_importe := ln_importe + nvl(rc_mov.liquidacion,0) ;
    fetch c_movimiento into rc_mov ;
  end loop ;

  ln_importe := ln_importe / ln_tipo_cambio ;

  if ls_tipo_t = lk_empleado then
    ls_cnta_prsp := lk_cnta_prsp_emp ;
  elsif ls_tipo_t = lk_obrero then
    ls_cnta_prsp := lk_cnta_prsp_obr ;
  end if ;

  select nvl(pc.descripcion,' ') into ls_descripcion
    from presupuesto_cuenta pc where pc.cnta_prsp = ls_cnta_prsp ;

  ln_contador := 0 ;
  select count(*) into ln_contador from presupuesto_partida pp
    where pp.ano = ln_ano and pp.cencos = ls_cencos and pp.cnta_prsp = ls_cnta_prsp ;
  if ln_contador = 0 then
    ad_mensaje := 'Centro de Costo '||ls_cencos||'Cnta. Prsp. '||ls_cnta_prsp||'  No Existe Partida Presupuestal' ;
    return ;
  else
    select nvl(pp.flag_ctrl,'0') into ls_flag_control from presupuesto_partida pp
      where pp.ano = ln_ano and pp.cencos = ls_cencos and pp.cnta_prsp = ls_cnta_prsp ;
  end if ;

  if ls_flag_control <> '0' then

    ln_imp_control := 0 ;
    if ls_flag_control = '1' then
      ln_imp_control := usf_pto_acumulado_anual(ln_ano, ls_cencos, ls_cnta_prsp) ;
    elsif ls_flag_control = '2' then
      ln_imp_control := usf_pto_acumulado_a_la_fecha(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp) ;
    elsif ls_flag_control = '3' then
      ln_imp_control := usf_pto_acumulado_mensual(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp) ;
    elsif ls_flag_control = '4' then
      ln_imp_control := usf_pto_acumulado_trimestre(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp) ;
    elsif ls_flag_control = '5' then
      ln_imp_control := usf_pto_acum_trim_centrado(ln_mes, ln_ano, ls_cencos, ls_cnta_prsp) ;
    end if ;

    if ln_importe > ln_imp_control then
      ln_imp_diferencia := ln_importe - ln_imp_control ;
      insert into presup_variacion (
        ano, cencos_origen, cnta_prsp_origen, mes_origen, fecha,
        flag_automatico, importe, descripcion, cod_usr, tipo_variacion,flag_replicacion )
      values (
        ln_ano, ls_cencos, ls_cnta_prsp, ln_mes, ad_fec_proceso,
        '0', ln_imp_diferencia, lk_desc_variacion, as_usuario, 'A', '1' ) ;
    end if ;

  end if ;

end loop ;
close c_movimiento ;

--  **************************************************************
--  ***   ADICIONA C.T.S. AL PRESUPUESTO POR CENTRO DE COSTO   ***
--  **************************************************************
open c_movimiento ;
fetch c_movimiento into rc_mov ;

while c_movimiento%found loop

  ls_cencos := rc_mov.cencos ;
  ls_tipo_t := rc_mov.tipo_trabajador ;

  ln_importe := 0 ;
  while rc_mov.cencos = ls_cencos and rc_mov.tipo_trabajador = ls_tipo_t and
        c_movimiento%found loop
    ln_importe := ln_importe + nvl(rc_mov.liquidacion,0) ;
    fetch c_movimiento into rc_mov ;
  end loop ;

  ln_importe := ln_importe / ln_tipo_cambio ;
  ln_importe := ln_importe * -1 ;

  if ls_tipo_t = lk_empleado then
    ls_cnta_prsp := lk_cnta_prsp_emp ;
  elsif ls_tipo_t = lk_obrero then
    ls_cnta_prsp := lk_cnta_prsp_obr ;
  end if ;

  select nvl(pc.descripcion,' ') into ls_descripcion
    from presupuesto_cuenta pc where pc.cnta_prsp = ls_cnta_prsp ;

  insert into presupuesto_ejec (
    cod_origen, ano, cencos, cnta_prsp, fecha,
    descripcion, importe, origen_ref, tipo_doc_ref, nro_doc_ref, item_ref, flag_replicacion )
  values (
    as_origen, ln_ano, ls_cencos, ls_cnta_prsp, ad_fec_proceso,
    ls_descripcion, ln_importe, as_origen, lk_tipo_doc, '', 0, '1' ) ;

end loop ;

end usp_rh_cts_add_presupuesto ;
/
