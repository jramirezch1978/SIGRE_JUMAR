create or replace procedure usp_rh_cierre_acumulados (
  as_codtra in char, ad_fec_proceso in date, ad_fec_desde in date,
  ad_fec_hasta in date ) is

ln_contador             integer ;
ls_c_cencos             maestro.cencos%type ;
ls_c_seccion            maestro.cod_seccion%type ;
ls_c_moneda             maestro.cod_moneda%type ;

--  Cursor para actualizar HISTORICO DE CALCULO
cursor c_calculo is
  select c.cod_trabajador, c.concep, c.fec_proceso, c.horas_trabaj, c.horas_pag,
         c.dias_trabaj, c.imp_soles, c.imp_dolar, c.cod_origen, c.item,
         c.tipo_doc_cc, c.nro_doc_cc
  from calculo c
  where c.cod_trabajador = as_codtra and trunc(c.fec_proceso) = ad_fec_proceso
  order by c.cod_trabajador, c.concep ;

--  Cursor para actualizar HISTORICO DE SOBRETIEMPO
cursor c_sobretiempo is
  select st.cod_trabajador, st.fec_movim, st.concep, st.nro_doc, st.horas_sobret,
         st.cencos, st.cod_labor, st.cod_usr, st.tipo_doc
  from sobretiempo_turno st
  where st.cod_trabajador = as_codtra and trunc(st.fec_movim) between ad_fec_desde and
        ad_fec_hasta
  order by st.cod_trabajador, st.concep
  for update ;

--  Cursor para actualizar HISTORICO DE INASISTENCIA
cursor c_inasistencia is
  select i.cod_trabajador, i.concep, i.fec_desde, i.fec_hasta, i.fec_movim,
         i.dias_inasist, i.tipo_doc, i.nro_doc, i.cod_usr
  from inasistencia i
  where i.cod_trabajador = as_codtra and trunc(i.fec_movim) between ad_fec_desde and
        ad_fec_hasta
  order by i.cod_trabajador, i.concep
  for update ;

--  Cursor para actualizar HISTORICO DE VARIABLES
cursor c_variables is
  select gdv.cod_trabajador, gdv.fec_movim, gdv.concep, gdv.nro_doc, gdv.imp_var,
         gdv.cencos, gdv.cod_labor, gdv.cod_usr, gdv.proveedor, gdv.tipo_doc
  from gan_desct_variable gdv
  where gdv.cod_trabajador = as_codtra and trunc(gdv.fec_movim) between ad_fec_desde and
        ad_fec_proceso
  order by gdv.cod_trabajador, gdv.concep
  for update ;

begin

--  ***********************************************************
--  ***   ADICIONA MOVIMIENTO DE CALCULO A LOS HISTORICOS   ***
--  ***********************************************************

--  Proceso de acumulado al HISTORICO DE CALCULO
for rc_cal in c_calculo loop

  select m.cod_moneda, m.cencos, m.cod_seccion
    into ls_c_moneda, ls_c_cencos, ls_c_seccion
    from maestro m
    where m.cod_trabajador = as_codtra ;

  insert into historico_calculo (
    cod_trabajador, concep, fec_calc_plan, cencos,
    cod_seccion, horas_trabaj, horas_pagad, dias_trabaj,
    cod_moneda, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
    tipo_doc_cc, nro_doc_cc )
  values (
    rc_cal.cod_trabajador, rc_cal.concep, rc_cal.fec_proceso, ls_c_cencos,
    ls_c_seccion, rc_cal.horas_trabaj, rc_cal.horas_pag, rc_cal.dias_trabaj,
    ls_c_moneda, rc_cal.imp_soles, rc_cal.imp_dolar, rc_cal.cod_origen, '1', rc_cal.item,
    rc_cal.tipo_doc_cc, rc_cal.nro_doc_cc ) ;

end loop ;

--  Proceso de acumula al HISTORICO DE SOBRETIEMPO
for rc_sob in c_sobretiempo loop

  ln_contador := 0 ;
  select count(*) into ln_contador from historico_sobretiempo hs
    where hs.cod_trabajador = rc_sob.cod_trabajador and hs.fec_movim =
          rc_sob.fec_movim and hs.concep = rc_sob.concep ;

  if ln_contador > 0 then
    update historico_sobretiempo
      set horas_sobret = horas_sobret + rc_sob.horas_sobret,
         flag_replicacion = '1'
      where current of c_sobretiempo ;
  else
    insert into historico_sobretiempo (
      cod_trabajador, fec_movim, concep, cencos,
      cod_labor, tipo_doc, nro_doc, horas_sobret,
      cod_usr, flag_replicacion )
    values (
      rc_sob.cod_trabajador, rc_sob.fec_movim, rc_sob.concep, rc_sob.cencos,
      rc_sob.cod_labor, rc_sob.tipo_doc, rc_sob.nro_doc, rc_sob.horas_sobret,
      rc_sob.cod_usr, '1' ) ;
  end if ;

end loop ;

--  Proceso de acumulado al HISTORICO DE INASISTENCIA
for rc_ina in c_inasistencia loop

  ln_contador := 0 ;
  select count(*) into ln_contador from historico_inasistencia hi
    where hi.cod_trabajador = rc_ina.cod_trabajador and hi.concep =
          rc_ina.concep and hi.fec_desde = rc_ina.fec_desde ;

  if ln_contador > 0 then
    update historico_inasistencia
      set dias_inasist = dias_inasist + rc_ina.dias_inasist,
         flag_replicacion = '1'
      where current of c_inasistencia ;
  else
    insert into historico_inasistencia (
      cod_trabajador, concep, fec_desde, fec_hasta,
      fec_movim, dias_inasist, tipo_doc, nro_doc,
      cod_usr, flag_replicacion )
    values (
      rc_ina.cod_trabajador, rc_ina.concep, rc_ina.fec_desde, rc_ina.fec_hasta,
      rc_ina.fec_movim, rc_ina.dias_inasist, rc_ina.tipo_doc, rc_ina.nro_doc,
      rc_ina.cod_usr, '1' ) ;
  end if ;

end loop ;

--  Proceso de acumulado al HISTORICO DE VARIABLES
for rc_var in c_variables loop

  ln_contador := 0 ;
  select count(*) into ln_contador
    from historico_variable hv
    where hv.cod_trabajador = rc_var.cod_trabajador and hv.fec_movim =
          rc_var.fec_movim and hv.concep = rc_var.concep ;

  if ln_contador > 0 then
    update historico_variable hv
      set hv.imp_var = nvl(hv.imp_var,0) + rc_var.imp_var,
         hv.flag_replicacion = '1'
    where current of c_variables ;
  else
    insert into historico_variable (
      cod_trabajador, fec_movim, concep, proveedor,
      cencos, cod_labor, tipo_doc, nro_doc,
      imp_var, cod_usr, flag_replicacion )
    values (
      rc_var.cod_trabajador, rc_var.fec_movim, rc_var.concep, rc_var.proveedor,
      rc_var.cencos, rc_var.cod_labor, rc_var.tipo_doc, rc_var.nro_doc,
      rc_var.imp_var, rc_var.cod_usr, '1' ) ;
  end if ;

end loop ;

end usp_rh_cierre_acumulados ;
/
