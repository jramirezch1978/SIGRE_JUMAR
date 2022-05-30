create or replace procedure usp_cierre_actualiza_acumulado
 ( as_codtra        in maestro.cod_trabajador%type ,
   ad_fec_proceso   in rrhhparam.fec_proceso%type ,
   ad_fec_desde     in rrhhparam.fec_desde%type ,
   ad_fec_hasta     in rrhhparam.fec_hasta%type )
   is

ln_contador             number(15) ;
--  Variables de la tabla CALCULO
ls_c_codigo             calculo.cod_trabajador%type ;
ls_c_concepto           calculo.concep%type ;
ld_c_fecha              calculo.fec_proceso%type ;
ln_c_horas_tra          calculo.horas_trabaj%type ;
ln_c_horas_pag          calculo.horas_pag%type ;
ln_c_dias_tra           calculo.dias_trabaj%type ;
ln_c_soles              calculo.imp_soles%type ;
ln_c_dolar              calculo.imp_dolar%type ;
ls_c_t_snp              calculo.flag_t_snp%type ;
ls_c_t_quinta           calculo.flag_t_snp%type ;
ls_c_t_judicial         calculo.flag_t_snp%type ;
ls_c_t_afp              calculo.flag_t_snp%type ;
ls_c_t_bonif30          calculo.flag_t_snp%type ;
ls_c_t_bonif25          calculo.flag_t_snp%type ;
ls_c_t_gratif           calculo.flag_t_snp%type ;
ls_c_t_cts              calculo.flag_t_snp%type ;
ls_c_t_vac              calculo.flag_t_snp%type ;
ls_c_t_bon_vac          calculo.flag_t_snp%type ;
ls_c_t_quincena         calculo.flag_t_snp%type ;
ls_c_t_quinquenio       calculo.flag_t_snp%type ;
ls_c_e_essalud          calculo.flag_t_snp%type ;
ls_c_e_agrario          calculo.flag_t_snp%type ;
ls_c_e_essalud_vida     calculo.flag_t_snp%type ;
ls_c_e_ies              calculo.flag_t_snp%type ;
ls_c_e_senati           calculo.flag_t_snp%type ;
ls_c_e_sctr_ipss        calculo.flag_t_snp%type ;
ls_c_e_sctr_onp         calculo.flag_t_snp%type ;

ls_c_cod_labor          maestro.cod_labor%type ;
ls_c_cencos             maestro.cencos%type ;
ls_c_seccion            maestro.cod_seccion%type ;
ls_c_moneda             maestro.cod_moneda%type ;

--  Variables de la tabla SOBRETIEMPO_TURNO
ls_s_codigo             sobretiempo_turno.cod_trabajador%type ;
ld_s_fecha              sobretiempo_turno.fec_movim%type ;
ls_s_concepto           sobretiempo_turno.concep%type ;
ls_s_nro_doc            sobretiempo_turno.nro_doc%type ;
ln_s_horas              sobretiempo_turno.horas_sobret%type ;
ls_s_cencos             sobretiempo_turno.cencos%type ;
ls_s_labor              sobretiempo_turno.cod_labor%type ;
ls_s_usuario            sobretiempo_turno.cod_usr%type ;
ls_s_tipo_doc           sobretiempo_turno.tipo_doc%type ;

--  Variables de la tabla INASISTENCIA
ls_i_codigo             inasistencia.cod_trabajador%type ;
ls_i_concepto           inasistencia.concep%type ;
ld_i_fecha_desde        inasistencia.fec_desde%type ;
ld_i_fecha_hasta        inasistencia.fec_hasta%type ;
ld_i_fecha_movim        inasistencia.fec_movim%type ;
ln_i_dias               inasistencia.dias_inasist%type ;
ls_i_tipo_doc           inasistencia.tipo_doc%type ;
ls_i_nro_doc            inasistencia.nro_doc%type ;
ls_i_cod_usr            inasistencia.cod_usr%type ;

--  Variables de la tabla GANANCIAS Y DESCUENTOS VARIABLES
ls_v_codigo             gan_desct_variable.cod_trabajador%type ;
ld_v_fecha_movim        gan_desct_variable.fec_movim%type ;
ls_v_concepto           gan_desct_variable.concep%type ;
ls_v_nro_doc            gan_desct_variable.nro_doc%type ;
ln_v_importe            gan_desct_variable.imp_var%type ;
ls_v_cencos             gan_desct_variable.cencos%type ;
ls_v_labor              gan_desct_variable.cod_labor%type ;
ls_v_usuario            gan_desct_variable.cod_usr%type ;
ls_v_proveedor          gan_desct_variable.proveedor%type ;
ls_v_tipo_doc           gan_desct_variable.tipo_doc%type ;

--  Cursor para actualizar HISTORICO DE CALCULO
cursor c_calculo is
  Select c.cod_trabajador, c.concep, c.fec_proceso,
         c.horas_trabaj, c.horas_pag, c.dias_trabaj,
         c.imp_soles, c.imp_dolar,
         c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
         c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
         c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio,
         c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, c.flag_t_quinquenio,
         c.flag_e_essalud, c.flag_e_agrario, c.flag_e_essalud_vida,
         c.flag_e_ies, c.flag_e_senati, c.flag_e_sctr_ipss,
         c.flag_e_sctr_onp
  from calculo c
  where c.cod_trabajador = as_codtra and
        c.fec_proceso    = ad_fec_proceso
  order by c.cod_trabajador, c.concep ;

--  Cursor para actualizar HISTORICO DE SOBRETIEMPO
cursor c_sobretiempo is
  Select st.cod_trabajador, st.fec_movim, st.concep,
         st.nro_doc, st.horas_sobret, st.cencos,
         st.cod_labor, st.cod_usr, st.tipo_doc
  from sobretiempo_turno st
  where st.cod_trabajador = as_codtra and
        st.fec_movim between ad_fec_desde and ad_fec_hasta
  order by st.cod_trabajador, st.concep
  for Update ;

--  Cursor para actualizar HISTORICO DE INASISTENCIA
cursor c_inasistencia is
  Select i.cod_trabajador, i.concep, i.fec_desde,
         i.fec_hasta, i.fec_movim, i.dias_inasist,
         i.tipo_doc, i.nro_doc, i.cod_usr
  from inasistencia i
  where i.cod_trabajador = as_codtra and
        i.fec_movim between ad_fec_desde and ad_fec_hasta
  order by i.cod_trabajador, i.concep
  for Update ;

--  Cursor para actualizar HISTORICO DE VARIABLES
cursor c_variables is
  Select gdv.cod_trabajador, gdv.fec_movim, gdv.concep,
         gdv.nro_doc, gdv.imp_var, gdv.cencos,
         gdv.cod_labor, gdv.cod_usr, gdv.proveedor,
         gdv.tipo_doc
  from gan_desct_variable gdv
  where gdv.cod_trabajador = as_codtra and
        gdv.fec_movim between ad_fec_desde and ad_fec_proceso
  order by gdv.cod_trabajador, gdv.concep
  for Update ;

begin

--  Proceso de acumulado al HISTORICO DE CALCULO
For rc_cal in c_calculo Loop

  ls_c_codigo         := rc_cal.cod_trabajador ;
  ls_c_concepto       := rc_cal.concep ;
  ld_c_fecha          := rc_cal.fec_proceso ;
  ln_c_horas_tra      := rc_cal.horas_trabaj ;
  ln_c_horas_pag      := rc_cal.horas_pag ;
  ln_c_dias_tra       := rc_cal.dias_trabaj ;
  ln_c_soles          := rc_cal.imp_soles ;
  ln_c_dolar          := rc_cal.imp_dolar ;
  ls_c_t_snp          := rc_cal.flag_t_snp ;
  ls_c_t_quinta       := rc_cal.flag_t_quinta ;
  ls_c_t_judicial     := rc_cal.flag_t_judicial ;
  ls_c_t_afp          := rc_cal.flag_t_afp ;
  ls_c_t_bonif30      := rc_cal.flag_t_bonif_30 ;
  ls_c_t_bonif25      := rc_cal.flag_t_bonif_25 ;
  ls_c_t_gratif       := rc_cal.flag_t_gratif ;
  ls_c_t_cts          := rc_cal.flag_t_cts ;
  ls_c_t_vac          := rc_cal.flag_t_vacacio ;
  ls_c_t_bon_vac      := rc_cal.flag_t_bonif_vacacio ;
  ls_c_t_quincena     := rc_cal.flag_t_pago_quincena ;
  ls_c_t_quinquenio   := rc_cal.flag_t_quinquenio ;
  ls_c_e_essalud      := rc_cal.flag_e_essalud ;
  ls_c_e_agrario      := rc_cal.flag_e_agrario ;
  ls_c_e_essalud_vida := rc_cal.flag_e_essalud_vida ;
  ls_c_e_ies          := rc_cal.flag_e_ies ;
  ls_c_e_senati       := rc_cal.flag_e_senati ;
  ls_c_e_sctr_ipss    := rc_cal.flag_e_sctr_ipss ;
  ls_c_e_sctr_onp     := rc_cal.flag_e_sctr_onp ;

  Select m.cod_moneda, m.cod_labor, m.cencos, m.cod_seccion
    into ls_c_moneda, ls_c_cod_labor, ls_c_cencos, ls_c_seccion
    from maestro m
    where m.cod_trabajador = as_codtra ;
  ls_c_moneda    := nvl(ls_c_moneda,' ') ;
--  ls_c_cod_labor := nvl(ls_c_cod_labor,'PLANIL') ;
  ls_c_cod_labor := ls_c_cod_labor ;
  ls_c_cencos    := nvl(ls_c_cencos,' ') ;
  ls_c_seccion   := nvl(ls_c_seccion,' ') ;

  --  Inserta registros a la tabla HISTORICO_CALCULO
  Insert into historico_calculo
    ( cod_trabajador, concep, fec_calc_plan,
      cod_labor, cencos, cod_seccion,
      horas_trabaj, horas_pagad, dias_trabaj,
      cod_moneda, imp_soles, imp_dolar,
      flag_t_snp, flag_t_quinta, flag_t_judicial,
      flag_t_afp, flag_t_bonif_30, flag_t_bonif_25,
      flag_t_gratif, flag_t_cts, flag_t_vacacio,
      flag_t_bonif_vacacio, flag_t_pago_quincena, flag_t_quinquenio,
      flag_e_essalud, flag_e_agrario, flag_e_essalud_vida,
      flag_e_ies, flag_e_senati, flag_e_sctr_ipss,
      flag_e_sctr_onp )
  Values
    ( ls_c_codigo, ls_c_concepto, ld_c_fecha,
      ls_c_cod_labor, ls_c_cencos, ls_c_seccion,
      ln_c_horas_tra, ln_c_horas_pag, ln_c_dias_tra,
      ls_c_moneda, ln_c_soles, ln_c_dolar,
      ls_c_t_snp, ls_c_t_quinta, ls_c_t_judicial,
      ls_c_t_afp , ls_c_t_bonif30, ls_c_t_bonif25,
      ls_c_t_gratif, ls_c_t_cts, ls_c_t_vac,
      ls_c_t_bon_vac, ls_c_t_quincena, ls_c_t_quinquenio,
      ls_c_e_essalud, ls_c_e_agrario, ls_c_e_essalud_vida,
      ls_c_e_ies, ls_c_e_senati, ls_c_e_sctr_ipss,
      ls_c_e_sctr_onp ) ;

End loop ;

--  Proceso de acumula al HISTORICO DE SOBRETIEMPO
For rc_sob in c_sobretiempo Loop

  ls_s_codigo    := rc_sob.cod_trabajador ;
  ld_s_fecha     := rc_sob.fec_movim ;
  ls_s_concepto  := rc_sob.concep ;
  ls_s_nro_doc   := rc_sob.nro_doc ;
  ln_s_horas     := rc_sob.horas_sobret ;
  ls_s_cencos    := rc_sob.cencos ;
  ls_s_labor     := rc_sob.cod_labor ;
  ls_s_usuario   := rc_sob.cod_usr ;
  ls_s_tipo_doc  := rc_sob.tipo_doc ;

  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from historico_sobretiempo hs
    where hs.cod_trabajador = ls_s_codigo and
          hs.fec_movim = ld_s_fecha and
          hs.concep = ls_s_concepto ;
  ln_contador := nvl(ln_contador,0) ;

  If ln_contador > 0 then
    --  Actualiza registro
    Update historico_sobretiempo
    Set horas_sobret = horas_sobret + ln_s_horas
      where current of c_sobretiempo ;
  Else
    --  Inserta registros a la tabla HISTORICO_SOBRETIEMPO
    Insert into historico_sobretiempo
      ( cod_trabajador, fec_movim, concep,
        cencos, cod_labor, tipo_doc,
        nro_doc, horas_sobret, cod_usr )
    Values
      ( ls_s_codigo, ld_s_fecha, ls_s_concepto,
        ls_s_cencos, ls_s_labor, ls_s_tipo_doc,
        ls_s_nro_doc, ln_s_horas, ls_s_usuario ) ;
  End if ;

End loop ;

--  Proceso de acumulado al HISTORICO DE INASISTENCIA
For rc_ina in c_inasistencia Loop

  ls_i_codigo      := rc_ina.cod_trabajador ;
  ls_i_concepto    := rc_ina.concep ;
  ld_i_fecha_desde := rc_ina.fec_desde ;
  ld_i_fecha_hasta := rc_ina.fec_hasta ;
  ld_i_fecha_movim := rc_ina.fec_movim ;
  ln_i_dias        := rc_ina.dias_inasist ;
  ls_i_tipo_doc    := rc_ina.tipo_doc ;
  ls_i_nro_doc     := rc_ina.nro_doc ;
  ls_i_cod_usr     := rc_ina.cod_usr ;

  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from historico_inasistencia hi
    where hi.cod_trabajador = ls_i_codigo and
          hi.concep = ls_i_concepto and
          hi.fec_desde = ld_i_fecha_desde ;
  ln_contador := nvl(ln_contador,0) ;

  If ln_contador > 0 then
    --  Actualiza registro
    Update historico_inasistencia
    Set dias_inasist = dias_inasist + ln_i_dias
      where current of c_inasistencia ;
  Else
    --  Inserta registros a la tabla HISTORICO_INASISTENCIA
    Insert into historico_inasistencia
      ( cod_trabajador, concep, fec_desde,
        fec_hasta, fec_movim, dias_inasist,
        tipo_doc, nro_doc, cod_usr )
    Values
      ( ls_i_codigo, ls_i_concepto, ld_i_fecha_desde,
        ld_i_fecha_hasta, ld_i_fecha_movim, ln_i_dias,
        ls_i_tipo_doc, ls_i_nro_doc, ls_i_cod_usr ) ;
  End if ;

End loop ;

--  Proceso de acumulado al HISTORICO DE VARIABLES
For rc_var in c_variables Loop

  ls_v_codigo      := rc_var.cod_trabajador ;
  ld_v_fecha_movim := rc_var.fec_movim ;
  ls_v_concepto    := rc_var.concep ;
  ls_v_nro_doc     := rc_var.nro_doc ;
  ln_v_importe     := rc_var.imp_var ;
  ls_v_cencos      := rc_var.cencos ;
  ls_v_labor       := rc_var.cod_labor ;
  ls_v_usuario     := rc_var.cod_usr ;
  ls_v_proveedor   := rc_var.proveedor ;
  ls_v_tipo_doc    := rc_var.tipo_doc ;

  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from historico_variable hv
    where hv.cod_trabajador = ls_v_codigo and
          hv.fec_movim = ld_v_fecha_movim and
          hv.concep = ls_v_concepto ;
  ln_contador := nvl(ln_contador,0) ;

  If ln_contador > 0 then
    --  Actualiza registro
    Update historico_variable
    Set imp_var = imp_var + ln_v_importe
      where current of c_inasistencia ;
  Else
    --  Inserta registros a la tabla HISTORICO_VARIABLE
    Insert into historico_variable
      ( cod_trabajador, fec_movim, concep,
        proveedor, cencos, cod_labor,
        tipo_doc, nro_doc, imp_var, cod_usr )
    Values
      ( ls_v_codigo, ld_v_fecha_movim, ls_v_concepto,
        ls_v_proveedor, ls_v_cencos, ls_v_labor,
        ls_v_tipo_doc, ls_v_nro_doc, ln_v_importe, ls_v_usuario ) ;
  End if ;

End loop ;

end usp_cierre_actualiza_acumulado ;
/
