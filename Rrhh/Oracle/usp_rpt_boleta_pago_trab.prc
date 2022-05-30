create or replace procedure usp_rpt_boleta_pago_trab
  ( as_cod_trabajador  in maestro.tipo_trabajador%type,
    ad_fec_proceso     in rrhhparam.fec_proceso%type,
    as_tabla           in char ) is

ln_mes_proceso            number(2) ;
ls_seccion                char(3) ;
ls_nombres                varchar2(40) ;
ld_fecha_nacimiento       maestro.fec_nacimiento%type ;
ls_sexo                   char(1) ;
ls_domicilio              varchar2(100) ;
ls_nacionalidad           varchar2(20) ;
ls_dni                    maestro.dni%type ;
ls_ocupacion              varchar2(40) ;
ld_fecha_ingreso          rrhhparam.fec_proceso%type ;
ld_fecha_cese             rrhhparam.fec_proceso%type ;
ld_fec_salida_vac         rrhhparam.fec_proceso%type ;
ld_fec_retorno_vac        rrhhparam.fec_proceso%type ;
ls_carnet_ipss            maestro.nro_ipss%type ;
ls_carnet_afp             maestro.nro_afp_trabaj%type ;
ls_cencos                 maestro.cencos%type ;
ls_categoria              char(2) ;
ls_nombre_afp             varchar2(20) ;
ln_sueldo_basico          number(11,2) ;
ls_concepto               concepto.concep%type ;
ls_desc_concepto          varchar2(40) ;
ln_nro_horas              number(5,2) ;
ln_nro_dias               number(5,2) ;
ln_importe                number(11,2) ;

ls_cod_cargo              maestro.cod_cargo%type ;
ls_cod_afp                maestro.cod_afp%type ;
ln_contador               number(15) ;

--  Cursor para leer el trabajador seleccionado
cursor c_maestro is
  select m.fec_ingreso, m.fec_nacimiento, m.fec_cese,
         m.flag_sexo, m.direccion, m.dni,
         m.nro_ipss, m.cod_cargo, m.cod_afp,
         m.nro_afp_trabaj, m.cencos, m.cod_categ_sal,
         m.cod_seccion
  from maestro m
  where m.flag_cal_plnlla = '1' and
        m.cod_trabajador = as_cod_trabajador ;

--  Cursor de lectura del mes
cursor c_calculo is
  select c.concep, c.dias_trabaj, c.horas_pag,
         c.imp_soles
  from calculo c
  where c.cod_trabajador = as_cod_trabajador and
        c.fec_proceso = ad_fec_proceso and
        c.imp_soles <> 0
  order by c.cod_trabajador, c.concep ;

--  Cursor del lectura del acumulado
cursor c_historico_calculo is
  select hc.concep, hc.dias_trabaj, hc.horas_pagad,
         hc.imp_soles
    from historico_calculo hc
    where hc.cod_trabajador = as_cod_trabajador and
          hc.fec_calc_plan = ad_fec_proceso and
          hc.imp_soles <> 0
    order by hc.cod_trabajador, hc.concep ;

begin

delete from tt_boleta_pago ;
ln_mes_proceso := to_char(ad_fec_proceso,'MM') ;

--  Lectura del trabajador seleccionado
for rc_mae in c_maestro loop

  ls_seccion          := nvl(rc_mae.cod_seccion,' ') ;
  ld_fecha_nacimiento := rc_mae.fec_nacimiento ;
  ls_sexo             := nvl(rc_mae.flag_sexo,' ') ;
  ls_domicilio        := nvl(rc_mae.direccion,' ') ;
  ls_nacionalidad     := 'PERUANA' ;
  ls_dni              := nvl(rc_mae.dni,' ') ;
  ls_cod_cargo        := nvl(rc_mae.cod_cargo,' ') ;
  ld_fecha_ingreso    := rc_mae.fec_ingreso ;
  ld_fecha_cese       := rc_mae.fec_cese ;
  ls_carnet_ipss      := nvl(rc_mae.nro_ipss,' ') ;
  ls_carnet_afp       := nvl(rc_mae.nro_afp_trabaj,' ') ;
  ls_cod_afp          := nvl(rc_mae.cod_afp,' ') ;
  ls_cencos           := nvl(rc_mae.cencos,' ') ;
  ls_categoria        := nvl(rc_mae.cod_categ_sal,' ') ;
  ls_nombres          := usf_nombre_trabajador(as_cod_trabajador) ;

  --  Determina cargo u ocupacion
  ln_contador := 0 ; ls_ocupacion := ' ' ;
  select count(*)
    into ln_contador
    from cargo car
    where car.cod_cargo = ls_cod_cargo ;
  if ln_contador > 0 then
    select nvl(car.desc_cargo,' ')
      into ls_ocupacion
      from cargo car
      where car.cod_cargo = ls_cod_cargo ;
  end if ;

  --  Determina nombre de A.F.P.
  ln_contador := 0 ; ls_nombre_afp := ' ' ;
  select count(*)
    into ln_contador
    from admin_afp aa
    where aa.cod_afp = ls_cod_afp ;
  if ln_contador > 0 then
    Select nvl(aa.desc_afp,' ')
      into ls_nombre_afp
      from admin_afp aa
      where aa.cod_afp = ls_cod_afp ;
  end if ;

  --  Determina remuneracion basica
  ln_contador := 0 ; ln_sueldo_basico := 0 ;
  select count(*)
    into ln_contador
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = as_cod_trabajador and
          (gdf.concep = '1001' or gdf.concep = '1020') ;
  if ln_contador > 0 then
    select nvl(gdf.imp_gan_desc,0)
      into ln_sueldo_basico
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_cod_trabajador and
            (gdf.concep = '1001' or gdf.concep = '1020') ;
  end if ;

  --  Determina fecha de salida y retorno de vacaciones
  ln_contador := 0 ; ld_fec_salida_vac := null ; ld_fec_retorno_vac := null ;
  select count(*)
    into ln_contador
    from inasistencia i
    where i.cod_trabajador = as_cod_trabajador and
          i.concep = '1413' ;
  if ln_contador = 1 then
    select i.fec_desde, i.fec_hasta
      into ld_fec_salida_vac, ld_fec_retorno_vac
      from inasistencia i
      where i.cod_trabajador = as_cod_trabajador and
            i.concep = '1413' ;
  end if ;

  if as_tabla = '1' then

    --  *********************************************************
    --  ***  LECTURA DEL PAGO GENERADO EN EL MES DE PROCESO   ***
    --  *********************************************************
    for rc_cal in c_calculo loop

      ls_concepto  := nvl(rc_cal.concep,' ') ;
      ln_nro_dias  := nvl(rc_cal.dias_trabaj,0) ;
      ln_nro_horas := nvl(rc_cal.horas_pag,0) ;
      ln_importe   := nvl(rc_cal.imp_soles,0) ;
      if ln_nro_dias = 0 then
        ln_nro_dias := null ;
      end if ;
      if ln_nro_horas = 0 then
        ln_nro_horas := null ;
      end if ;

      --  Halla descripcion del concepto
      ls_desc_concepto := ' ' ;
      select nvl(con.desc_breve,' ')
        into ls_desc_concepto
        from concepto con
        where con.concep = ls_concepto ;

      --  Inserta registro para imprimir boletas de pago
      insert into tt_boleta_pago (
        mes_proceso, fecha_proceso, seccion, codigo,
        nombres, fecha_nacimiento, sexo, domicilio,
        nacionalidad, dni, ocupacion, fecha_ingreso,
        fecha_cese, fec_salida_vac, fec_retorno_vac, carnet_ipss,
        carnet_afp, cencos, categoria, nombre_afp,
        sueldo_basico, concepto, desc_concepto, nro_horas,
        nro_dias, importe )
      values (
        ln_mes_proceso, ad_fec_proceso, ls_seccion, as_cod_trabajador,
        ls_nombres, ld_fecha_nacimiento, ls_sexo, ls_domicilio,
        ls_nacionalidad, ls_dni, ls_ocupacion, ld_fecha_ingreso,
        ld_fecha_cese, ld_fec_salida_vac, ld_fec_retorno_vac, ls_carnet_ipss,
        ls_carnet_afp, ls_cencos, ls_categoria, ls_nombre_afp,
        ln_sueldo_basico, ls_concepto, ls_desc_concepto, ln_nro_horas,
        ln_nro_dias, ln_importe) ;

    end loop ;

  elsif as_tabla = '2' then

    --  ********************************************************
    --  ***  LECTURA DEL PAGO GENERADO EN MESES ANTERIORES   ***
    --  ********************************************************
    for rc_his in c_historico_calculo loop

      ls_concepto  := nvl(rc_his.concep,' ') ;
      ln_nro_dias  := nvl(rc_his.dias_trabaj,0) ;
      ln_nro_horas := nvl(rc_his.horas_pagad,0) ;
      ln_importe   := nvl(rc_his.imp_soles,0) ;
      if ln_nro_dias = 0 then
        ln_nro_dias := null ;
      end if ;
      if ln_nro_horas = 0 then
        ln_nro_horas := null ;
      end if ;

      --  Halla descripcion del concepto
      ls_desc_concepto := ' ' ;
      select nvl(con.desc_breve,' ')
        into ls_desc_concepto
        from concepto con
        where con.concep = ls_concepto ;

      --  Inserta registro para imprimir boletas de pago
      insert into tt_boleta_pago (
        mes_proceso, fecha_proceso, seccion, codigo,
        nombres, fecha_nacimiento, sexo, domicilio,
        nacionalidad, dni, ocupacion, fecha_ingreso,
        fecha_cese, fec_salida_vac, fec_retorno_vac, carnet_ipss,
        carnet_afp, cencos, categoria, nombre_afp,
        sueldo_basico, concepto, desc_concepto, nro_horas,
        nro_dias, importe )
      values (
        ln_mes_proceso, ad_fec_proceso, ls_seccion, as_cod_trabajador,
        ls_nombres, ld_fecha_nacimiento, ls_sexo, ls_domicilio,
        ls_nacionalidad, ls_dni, ls_ocupacion, ld_fecha_ingreso,
        ld_fecha_cese, ld_fec_salida_vac, ld_fec_retorno_vac, ls_carnet_ipss,
        ls_carnet_afp, ls_cencos, ls_categoria, ls_nombre_afp,
        ln_sueldo_basico, ls_concepto, ls_desc_concepto, ln_nro_horas,
        ln_nro_dias, ln_importe) ;

    end loop ;

  end if ;

end loop ;

end usp_rpt_boleta_pago_trab ;
/
