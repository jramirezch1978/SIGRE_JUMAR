create or replace procedure usp_rh_rpt_boleta_pago_trab (
  as_cod_trabajador in char, ad_fec_proceso in date, as_tabla in char,
  as_tipo_trabajador in char, as_origen in char ) is

lk_remuneracion_basica    constant char(3) := '054' ;
lk_vacaciones             constant char(3) := '003' ;
lk_nacionalidad           constant varchar2(20) := 'PERUANA' ;

ln_mes_proceso            number(2) ;
ls_codigo                 maestro.cod_trabajador%type ;
ls_nombres                varchar2(40) ;
ln_contador               integer ;
ls_ocupacion              varchar2(40) ;
ls_nombre_afp             varchar2(20) ;
ls_concepto               concepto.concep%type ;
ln_sueldo_basico          number(11,2) ;
ld_fec_salida_vac         date ;
ld_fec_retorno_vac        date ;
ln_nro_horas              number(5,2) ;
ln_nro_dias               number(5,2) ;
ls_desc_concepto          varchar2(40) ;
ls_direcc_calle           varchar2(50) ;
ls_numero                 varchar2(8) ;
ls_direccion              varchar2(50) ;

--  Cursor para leer el trabajador seleccionado
cursor c_maestro is
  select m.cod_trabajador, m.fec_ingreso, m.fec_nacimiento, m.fec_cese,
         m.flag_sexo, m.direccion, m.dni, m.nro_ipss, m.cod_cargo, m.cod_afp,
         m.nro_afp_trabaj, m.cencos, m.cod_categ_sal, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen and
        m.cod_trabajador = as_cod_trabajador ;

--  Cursor de lectura del mes
cursor c_calculo is
  select c.concep, c.dias_trabaj, c.horas_pag, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_cod_trabajador and c.fec_proceso = ad_fec_proceso and
        nvl(c.imp_soles,0) <> 0
  order by c.cod_trabajador, c.concep ;

--  Cursor del lectura del acumulado
cursor c_historico_calculo is
  select hc.concep, hc.dias_trabaj, hc.horas_pagad, hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = as_cod_trabajador and hc.fec_calc_plan = ad_fec_proceso and
        nvl(hc.imp_soles,0) <> 0
  order by hc.cod_trabajador, hc.concep ;

begin

--  ***********************************************
--  ***   EMITE BOLETA DE PAGO POR TRABAJADOR   ***
--  ***********************************************

delete from tt_boleta_pago ;

select o.dir_calle, o.dir_numero into ls_direcc_calle, ls_numero
  from origen o where o.cod_origen = as_origen ;
ls_direccion := ls_direcc_calle||' '||ls_numero ;
ln_mes_proceso := to_number(to_char(ad_fec_proceso,'mm')) ;

--  Lectura del trabajador seleccionado
for rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_nombres := usf_rh_nombre_trabajador(ls_codigo) ;

  --  Determina cargo u ocupacion
  ln_contador := 0 ; ls_ocupacion := null ;
  select count(*) into ln_contador from cargo car
    where car.cod_cargo = rc_mae.cod_cargo ;
  if ln_contador > 0 then
    select car.desc_cargo into ls_ocupacion from cargo car
      where car.cod_cargo = rc_mae.cod_cargo ;
  end if ;

  --  Determina nombre de A.F.P.
  ln_contador := 0 ; ls_nombre_afp := null ;
  select count(*) into ln_contador from admin_afp aa
    where aa.cod_afp = rc_mae.cod_afp ;
  if ln_contador > 0 then
    select aa.desc_afp into ls_nombre_afp from admin_afp aa
      where aa.cod_afp = rc_mae.cod_afp ;
  end if ;

  --  Determina remuneracion basica
  select n.concepto_gen into ls_concepto from grupo_calculo n
    where n.grupo_calculo = lk_remuneracion_basica ;
  ln_contador := 0 ; ln_sueldo_basico := 0 ;
  select count(*) into ln_contador from gan_desct_fijo gdf
    where gdf.cod_trabajador = ls_codigo and gdf.concep = ls_concepto ;
  if ln_contador > 0 then
    select gdf.imp_gan_desc into ln_sueldo_basico from gan_desct_fijo gdf
      where gdf.cod_trabajador = ls_codigo and gdf.concep = ls_concepto ;
  end if ;

  --  Determina fecha de salida y retorno de vacaciones
  select n.concepto_gen into ls_concepto from grupo_calculo n
    where n.grupo_calculo = lk_vacaciones ;
  ln_contador := 0 ; ld_fec_salida_vac := null ; ld_fec_retorno_vac := null ;
  select count(*) into ln_contador from inasistencia i
    where i.cod_trabajador = ls_codigo and i.concep = ls_concepto ;
  if ln_contador = 1 then
    select i.fec_desde, i.fec_hasta into ld_fec_salida_vac, ld_fec_retorno_vac
      from inasistencia i where i.cod_trabajador = ls_codigo and i.concep = ls_concepto ;
  end if ;

  if as_tabla = '1' then

    --  *********************************************************
    --  ***  LECTURA DEL PAGO GENERADO EN EL MES DE PROCESO   ***
    --  *********************************************************
    for rc_cal in c_calculo loop

      ln_nro_dias  := nvl(rc_cal.dias_trabaj,0) ;
      ln_nro_horas := nvl(rc_cal.horas_pag,0) ;
      if ln_nro_dias  = 0 then ln_nro_dias  := null ; end if ;
      if ln_nro_horas = 0 then ln_nro_horas := null ; end if ;

      --  Determina la descripcion del concepto
      ls_desc_concepto := null ;
      select con.desc_breve into ls_desc_concepto from concepto con
        where con.concep = rc_cal.concep ;

      --  Inserta registro para imprimir boletas de pago
      insert into tt_boleta_pago (
        mes_proceso, fecha_proceso, seccion, codigo,
        nombres, fecha_nacimiento, sexo, domicilio,
        nacionalidad, dni, ocupacion, fecha_ingreso,
        fecha_cese, fec_salida_vac, fec_retorno_vac, carnet_ipss,
        carnet_afp, cencos, categoria, nombre_afp,
        sueldo_basico, concepto, desc_concepto, nro_horas,
        nro_dias, importe, direccion )
      values (
        ln_mes_proceso, ad_fec_proceso, rc_mae.cod_seccion, ls_codigo,
        ls_nombres, rc_mae.fec_nacimiento, rc_mae.flag_sexo, rc_mae.direccion,
        lk_nacionalidad, rc_mae.dni, ls_ocupacion, rc_mae.fec_ingreso,
        rc_mae.fec_cese, ld_fec_salida_vac, ld_fec_retorno_vac, rc_mae.nro_ipss,
        rc_mae.nro_afp_trabaj, rc_mae.cencos, rc_mae.cod_categ_sal, ls_nombre_afp,
        ln_sueldo_basico, rc_cal.concep, ls_desc_concepto, ln_nro_horas,
        ln_nro_dias, rc_cal.imp_soles, ls_direccion ) ;

    end loop ;

  elsif as_tabla = '2' then

    --  ********************************************************
    --  ***  LECTURA DEL PAGO GENERADO EN MESES ANTERIORES   ***
    --  ********************************************************
    for rc_his in c_historico_calculo loop

      ln_nro_dias  := nvl(rc_his.dias_trabaj,0) ;
      ln_nro_horas := nvl(rc_his.horas_pagad,0) ;
      if ln_nro_dias  = 0 then ln_nro_dias  := null ; end if ;
      if ln_nro_horas = 0 then ln_nro_horas := null ; end if ;

      --  Determina la descripcion del concepto
      ls_desc_concepto := null ;
      select con.desc_breve into ls_desc_concepto from concepto con
        where con.concep = rc_his.concep ;

      --  Inserta registro para imprimir boletas de pago
      insert into tt_boleta_pago (
        mes_proceso, fecha_proceso, seccion, codigo,
        nombres, fecha_nacimiento, sexo, domicilio,
        nacionalidad, dni, ocupacion, fecha_ingreso,
        fecha_cese, fec_salida_vac, fec_retorno_vac, carnet_ipss,
        carnet_afp, cencos, categoria, nombre_afp,
        sueldo_basico, concepto, desc_concepto, nro_horas,
        nro_dias, importe, direccion )
      values (
        ln_mes_proceso, ad_fec_proceso, rc_mae.cod_seccion, ls_codigo,
        ls_nombres, rc_mae.fec_nacimiento, rc_mae.flag_sexo, rc_mae.direccion,
        lk_nacionalidad, rc_mae.dni, ls_ocupacion, rc_mae.fec_ingreso,
        rc_mae.fec_cese, ld_fec_salida_vac, ld_fec_retorno_vac, rc_mae.nro_ipss,
        rc_mae.nro_afp_trabaj, rc_mae.cencos, rc_mae.cod_categ_sal, ls_nombre_afp,
        ln_sueldo_basico, rc_his.concep, ls_desc_concepto, ln_nro_horas,
        ln_nro_dias, rc_his.imp_soles, ls_direccion ) ;

    end loop ;

  end if ;

end loop ;

end usp_rh_rpt_boleta_pago_trab ;
/
