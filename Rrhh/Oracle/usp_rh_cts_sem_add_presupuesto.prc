create or replace procedure usp_rh_cts_sem_add_presupuesto (
  as_usuario in char, ad_fec_proceso in date, as_origen in char ) is

lk_desc_variacion    constant varchar2(100) := 'AMPLIACION AUTOMATICA DE LA PLANILLA DE C.T.S.' ;
lk_tipo_doc          constant char(04)      := 'GCTS' ;

ls_cnta_prsp_emp     char(10) ;
ls_cnta_prsp_obr     char(10) ;
ls_empleado          char(03) ;
ls_obrero            char(03) ;
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
ls_nro_variacion     char(10) ;
ln_nro_variacion     number(10) ;

--  Lectura del pago de C.T.S. semestral por trabajador
cursor c_movimiento is
  select c.cod_trabajador, (nvl(c.prov_cts_01,0) + nvl(c.prov_cts_02,0) + nvl(c.prov_cts_03,0) +
         nvl(c.prov_cts_04,0) + nvl(c.prov_cts_05,0) + nvl(c.prov_cts_06,0)) as imp_cts,
         m.tipo_trabajador, m.cencos
  from prov_cts_gratif c, maestro m
  where c.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.flag_cal_plnlla = '1' and m.flag_estado = '1' and
        m.cencos is not null
  order by m.cencos, m.tipo_trabajador, c.cod_trabajador ;
rc_mov c_movimiento%rowtype ;

begin

--  ***********************************************************
--  ***  ADICIONA PAGO DE C.T.S. SEMESTRAL AL PRESUPUESTO   ***
--  ***********************************************************

delete from presupuesto_ejec pe
  where to_char(pe.fecha,'dd/mm/yyyy') = to_char(ad_fec_proceso,'dd/mm/yyyy') and
        pe.tipo_doc_ref = lk_tipo_doc ;

select p.tipo_trab_obrero, p.tipo_trab_empleado, p.cnta_prsp_prest_cts_emp, p.cnta_prsp_prest_cts_obr
  into ls_obrero, ls_empleado, ls_cnta_prsp_emp, ls_cnta_prsp_obr
  from rrhhparam p where p.reckey = '1' ;
  
--  Determina el tipo de cambio a la fecha
ln_contador := 0 ; ln_tipo_cambio := 0 ;
select count(*) into ln_contador from calendario c
  where trunc(c.fecha) = trunc(ad_fec_proceso) ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,0) into ln_tipo_cambio from calendario c
    where trunc(c.fecha) = trunc(ad_fec_proceso) ;
else
  raise_application_error( -20000, 'No existe tipo de cambio al '||to_char(ad_fec_proceso,'dd/mm/yyyy') ) ;
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
    ln_importe := ln_importe + nvl(rc_mov.imp_cts,0) ;
    fetch c_movimiento into rc_mov ;
  end loop ;

  ln_importe := ln_importe / ln_tipo_cambio ;

  if ls_tipo_t = ls_empleado then
    ls_cnta_prsp := ls_cnta_prsp_emp ;
  elsif ls_tipo_t = ls_obrero then
    ls_cnta_prsp := ls_cnta_prsp_obr ;
  end if ;

  select nvl(pc.descripcion,' ') into ls_descripcion
    from presupuesto_cuenta pc where pc.cnta_prsp = ls_cnta_prsp ;

  ln_contador := 0 ;
  select count(*) into ln_contador from presupuesto_partida pp
    where pp.ano = ln_ano and pp.cencos = ls_cencos and pp.cnta_prsp = ls_cnta_prsp ;
  if ln_contador = 0 then
    raise_application_error( -20001, 'Para el centro de costo '||ls_cencos||' y cuenta presupuestal '||ls_cnta_prsp||
                                     '  no existe partida presupuestal' ) ;
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
      select nvl(p.ult_nro,0) into ln_nro_variacion from num_presup_variacion p
        where p.origen = as_origen ;
      ln_nro_variacion := ln_nro_variacion + 1 ;
      ls_nro_variacion := as_origen||lpad(to_char(ln_nro_variacion),8,'0') ;
      update num_presup_variacion v
        set v.ult_nro = ln_nro_variacion
        where v.origen = as_origen ;
      commit ;
      insert into presup_variacion (
        ano, cencos_origen, cnta_prsp_origen, mes_origen, fecha,
        flag_automatico, importe, descripcion, cod_usr, tipo_variacion,flag_replicacion,
        nro_variacion )
      values (
        ln_ano, ls_cencos, ls_cnta_prsp, ln_mes, ad_fec_proceso,
        '0', ln_imp_diferencia, lk_desc_variacion, as_usuario, 'A', '1',
        ls_nro_variacion ) ;
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
    ln_importe := ln_importe + nvl(rc_mov.imp_cts,0) ;
    fetch c_movimiento into rc_mov ;
  end loop ;

  ln_importe := ln_importe / ln_tipo_cambio ;
  ln_importe := ln_importe * -1 ;

  if ls_tipo_t = ls_empleado then
    ls_cnta_prsp := ls_cnta_prsp_emp ;
  elsif ls_tipo_t = ls_obrero then
    ls_cnta_prsp := ls_cnta_prsp_obr ;
  end if ;

  select nvl(pc.descripcion,' ') into ls_descripcion
    from presupuesto_cuenta pc where pc.cnta_prsp = ls_cnta_prsp ;

  insert into presupuesto_ejec (
    cod_origen, ano, cencos, cnta_prsp, fecha,
    descripcion, importe, origen_ref, tipo_doc_ref, nro_doc_ref, item_ref, flag_replicacion, cod_usr )
  values (
    as_origen, ln_ano, ls_cencos, ls_cnta_prsp, ad_fec_proceso,
    ls_descripcion, ln_importe, as_origen, lk_tipo_doc, '', 0, '1', as_usuario ) ;

end loop ;

end usp_rh_cts_sem_add_presupuesto ;
/
