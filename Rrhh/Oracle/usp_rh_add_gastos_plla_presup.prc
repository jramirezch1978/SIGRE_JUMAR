create or replace procedure usp_rh_add_gastos_plla_presup(
       asi_usuario          in usuario.cod_usr%TYPE,
       asi_origen           in origen.cod_origen%TYPE,
       ani_year             in number,
       ani_mes              in number
) is

lk_tipo_doc         constant presupuesto_ejec.tipo_doc_ref%TYPE := 'GPM ' ;
lk_desc_variacion   constant varchar2(100) := 'AMPLIACION AUTOMATICA DE LA PLANILLA' ;

ls_concepto_ing     char(4) ;
ls_concepto_des     char(4) ;
ls_concepto_pag     char(4) ;
ls_concepto_apo     char(4) ;

ls_flag_control     presupuesto_partida.flag_ctrl%type ;
ls_cnta_prsp        presupuesto_ejec.cnta_prsp%type ;
ld_fecha            presupuesto_ejec.fecha%type ;
ls_descripcion      presupuesto_ejec.descripcion%type ;
ln_importe          presupuesto_ejec.importe%type ;

ls_codigo           calculo.cod_trabajador%type ;
ls_concepto         calculo.concep%type ;
ln_contador         integer ;
ln_imp_control      number(13,2) ;
ln_imp_diferencia   number(13,2) ;
ln_nro_var          num_presup_variacion.ult_nro%type ;
lc_nro_var          presup_variacion.nro_variacion%type ;

--  Cursor del movimiento de la planilla mensual
cursor c_calculo is
  select cal.cod_trabajador, cal.concep, cal.imp_dolar, m.tipo_trabajador, m.cencos, 
         m.centro_benef, 
         cal.fec_proceso as fecha
  from calculo cal, 
       maestro m
  where cal.cod_trabajador = m.cod_trabajador
    and m.cod_origen       = asi_origen
    and to_number(to_char(cal.fec_proceso, 'yyyy')) = ani_year
    and to_number(to_char(cal.fec_proceso, 'mm'))   = ani_mes
    and m.cencos is not null
    and cal.concep <> ls_concepto_ing
    and cal.concep <> ls_concepto_des
    and cal.concep <> ls_concepto_pag
    and cal.concep <> ls_concepto_apo
  order by cal.cod_trabajador, cal.concep ;

--  Cursor del movimiento de la planilla acumulada
cursor c_historico is
  select hc.cod_trabajador, hc.concep, hc.imp_dolar,
         decode(hc.cencos, null, m.cencos, hc.cencos) as cencos,
         decode(hc.tipo_trabajador, null, m.tipo_trabajador, hc.tipo_trabajador) as tipo_trabajador,
         decode(hc.centro_benef, null, m.centro_benef, hc.centro_benef) as centro_benef,
         hc.fec_calc_plan as fecha
  from historico_calculo hc, 
       maestro           m
  where hc.cod_trabajador = m.cod_trabajador
    and m.cod_origen      = asi_origen
    and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
    and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes
    and m.cencos is not null
    and hc.concep <> ls_concepto_ing
    and hc.concep <> ls_concepto_des
    and hc.concep <> ls_concepto_pag
    and hc.concep <> ls_concepto_apo
  order by hc.cod_trabajador, hc.concep ;

--  Cursor de gastos por centros de costos y cuenta presupuestal
cursor c_gastos is
  select gm.ano, gm.cencos, gm.cnta_prsp, gm.fecha, gm.COD_TRABAJADOR,
         to_number(to_char(gm.fecha, 'mm')) as mes,
         gm.centro_benef, gm.tipo_trabajador,
         sum(gm.importe) as importe
  from tt_presupuesto_gasto_mes gm
group by   gm.ano, gm.cencos, gm.cnta_prsp, gm.fecha, gm.COD_TRABAJADOR,
         to_number(to_char(gm.fecha, 'mm')),
         gm.centro_benef, gm.tipo_trabajador
  order by gm.cencos, gm.cnta_prsp ;
  
begin

--  *******************************************************************
--  ***   ADICIONA GASTOS MENSUALES DE LA PLANILLA AL PRESUPUESTO   ***
--  *******************************************************************

select p.cnc_total_ing, p.cnc_total_dsct, p.cnc_total_pgd, p.cnc_total_aport
  into ls_concepto_ing, ls_concepto_des, ls_concepto_pag, ls_concepto_apo
  from rrhhparam p
  where p.reckey = '1' ;

--  Elimina movimiento mensual del presupuesto
delete from presupuesto_ejec pe
  where to_number(to_char(pe.fecha, 'yyyy')) = ani_year
    and to_number(to_char(pe.fecha, 'mm'))   = ani_mes
    and pe.tipo_doc_ref                      = lk_tipo_doc
    and pe.cod_origen                        = asi_origen;

delete from tt_presupuesto_gasto_mes ;

--  Adiciona gastos del mes de proceso
for rc_cal in c_calculo loop
  ls_codigo   := rc_cal.cod_trabajador ;
  ls_concepto := rc_cal.concep ;
  ln_importe  := nvl(rc_cal.imp_dolar,0) * -1 ;

  ln_contador := 0 ;

  select count(*)
    into ln_contador
    from concepto_tip_trab_cnta c
    where c.concep          = ls_concepto 
      and c.tipo_trabajador = rc_cal.tipo_trabajador ;

  if ln_contador > 0 then
     select nvl(c.cnta_prsp,' ')
       into ls_cnta_prsp
       from concepto_tip_trab_cnta c
      where c.concep          = ls_concepto
        and c.tipo_trabajador = rc_cal.tipo_trabajador;

    if ls_cnta_prsp <> ' ' and ln_importe <> 0 then

      insert into tt_presupuesto_gasto_mes (
        ano, cencos, cnta_prsp, fecha, importe, cod_trabajador, centro_benef, 
        tipo_trabajador )
      values (
        ani_year, rc_cal.cencos, ls_cnta_prsp, rc_cal.fecha, ln_importe, rc_cal.cod_trabajador, rc_cal.centro_benef, 
        rc_cal.tipo_trabajador ) ;
    end if ;
  end if ;
end loop ;

-- Adiciona gastos de meses anteriores del historico de calculo
for rc_hc in c_historico loop
  ls_codigo   := rc_hc.cod_trabajador ;
  ls_concepto := rc_hc.concep ;
  ln_importe  := nvl(rc_hc.imp_dolar,0) * -1 ;

  ln_contador := 0 ;
  select count(*) 
    into ln_contador 
    from concepto_tip_trab_cnta c
    where c.concep = ls_concepto 
      and c.tipo_trabajador = rc_hc.tipo_trabajador;
      
  if ln_contador > 0 then
     select nvl(c.cnta_prsp,' ') 
       into ls_cnta_prsp 
       from concepto_tip_trab_cnta c
      where c.concep = ls_concepto 
        and c.tipo_trabajador = rc_hc.tipo_trabajador;
          
    if ls_cnta_prsp <> ' ' and ln_importe <> 0 then
       insert into tt_presupuesto_gasto_mes (
         ano, cencos, cnta_prsp, fecha, importe, cod_trabajador, centro_benef, 
         tipo_trabajador )
       values (
         ani_year, rc_hc.cencos, ls_cnta_prsp, rc_hc.fecha, ln_importe, rc_hc.cod_trabajador, rc_hc.centro_benef,
         rc_hc.tipo_trabajador ) ;
    end if ;
  end if ;
end loop ;


--  *****************************************************************
--  ***   GENERA AMPLIACION SI EL GASTO ES MAYOR AL PRESUPUESTO   ***
--  *****************************************************************
for lc_reg in c_gastos loop
    ln_contador := 0 ;
    select count(*) 
      into ln_contador 
      from presupuesto_partida pp
    where pp.ano       = lc_reg.ano 
      and pp.cencos    = lc_reg.cencos 
      and pp.cnta_prsp = lc_reg.cnta_prsp;
      
  if ln_contador = 0 then
     rollback;
     RAISE_APPLICATION_ERROR(-20000, 'NO EXISTE PARTIDA PRESUPUESTAL, POR FAVOR VERIFIQUE!.'  
                                     || chr(13) || 'Año: '||to_char(lc_reg.ano, '0000')
                                     || chr(13) || 'Centro de Costo: '|| lc_reg.cencos
                                     || chr(13) || 'Cnta. Prsp: '|| lc_reg.cnta_prsp);
  end if;

  select nvl(pp.flag_ctrl,'0')
    into ls_flag_control
    from presupuesto_partida pp
   where pp.ano       = lc_reg.ano
     and pp.cencos    = lc_reg.cencos
     and pp.cnta_prsp = lc_reg.cnta_prsp ;

  if ls_flag_control <> '0' then

    ln_imp_control := 0 ;
    if ls_flag_control = '1' then
      ln_imp_control := usf_pto_acumulado_anual(lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp) ;
    elsif ls_flag_control = '2' then
      ln_imp_control := usf_pto_acumulado_a_la_fecha(lc_reg.mes, lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp) ;
    elsif ls_flag_control = '3' then
      ln_imp_control := usf_pto_acumulado_mensual(lc_reg.mes, lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp) ;
    elsif ls_flag_control = '4' then
      ln_imp_control := usf_pto_acumulado_trimestre(lc_reg.mes, lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp);
    elsif ls_flag_control = '5' then
      ln_imp_control := usf_pto_acumulado_semestral(lc_reg.mes, lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp);
    end if ;

    if ln_importe > lc_reg.importe then
      ln_imp_diferencia := ln_importe - lc_reg.importe ;
      --contador de variacion
      select np.ult_nro
        into ln_nro_var
        from num_presup_variacion np
       where np.origen = asi_origen for update ;

      lc_nro_var := asi_origen||lpad(trim(to_char(ln_nro_var)),8,'0')  ;

      insert into presup_variacion (
        ano, cencos_origen, cnta_prsp_origen, mes_origen, fecha,
        flag_automatico, importe, descripcion, cod_usr, tipo_variacion, flag_replicacion ,
        nro_variacion)
      values (
        lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp, lc_reg.mes, ld_fecha,
        '0', ln_imp_diferencia, lk_desc_variacion, asi_usuario, 'A', '1',
        lc_nro_var ) ;


     --incrementa numerador de variacion
     update num_presup_variacion
        set ult_nro = NVL(ult_nro,0) + 1
      where origen = asi_origen ;

    end if ;
    
  end if ;
  select nvl(pc.descripcion,' ') 
     into ls_descripcion
     from presupuesto_cuenta pc 
    where pc.cnta_prsp = lc_reg.cnta_prsp; 

   insert into presupuesto_ejec (
         cod_origen, ano, cencos, cnta_prsp, fecha, descripcion,
         importe, origen_ref, tipo_doc_ref, item_ref, flag_replicacion, cod_usr, 
         cod_rel_ref, centro_benef, tipo_trabajador )
  values (
          asi_origen, lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp, lc_reg.fecha, ls_descripcion,
         lc_reg.importe, asi_origen, lk_tipo_doc, 0, '1', asi_usuario,
         lc_reg.cod_trabajador, lc_reg.centro_benef, lc_reg.tipo_trabajador ) ;
end loop ;

commit;

end usp_rh_add_gastos_plla_presup ;
/
