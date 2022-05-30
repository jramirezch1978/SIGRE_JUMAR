create or replace procedure usp_rh_rpt_planilla_aipsa (
  as_tipo_trabajador in char, as_origen in char, ad_fecha in date ) is

lk_remuneracion_basica    char(3) ;
lk_vacaciones             char(3) ;

ld_fecha_proceso          date ;
ls_seccion                char(3) ;
ls_desc_seccion           varchar2(40) ;
ls_codigo                 maestro.cod_trabajador%type ;
ls_nombres                varchar2(40) ;
ls_ocupacion              varchar2(40) ;
ld_fecha_ingreso          maestro.fec_ingreso%type ;
ls_carnet_ipss            maestro.nro_ipss%type ;
ls_nombre_afp             varchar2(20) ;
ls_carnet_afp             maestro.nro_afp_trabaj%type ;
ls_dni                    maestro.dni%type ;
ld_fecha_cese             date ;
ln_sueldo_basico          number(11,2) ;
ld_fec_salida_vac         date ;
ld_fec_retorno_vac        date ;
ls_sobreti                char(2) ;

ls_cod_cargo              maestro.cod_cargo%type ;
ls_cod_afp                maestro.cod_afp%type ;
ln_contador               number(15) ;
ln_importe                number(11,2) ;
ln_codniv                 number(3) ;
ls_codniv                 char(3) ;
ls_concepto               char(4) ;
ln_sw                     integer ;
ln_total                  number(13,2) ;

ln_gan_01  number(11,2) ; ln_gan_02  number(11,2) ; ln_gan_03  number(11,2) ;
ln_gan_04  number(11,2) ; ln_gan_05  number(11,2) ; ln_gan_06  number(11,2) ;
ln_gan_07  number(11,2) ; ln_gan_08  number(11,2) ; ln_gan_09  number(11,2) ;
ln_gan_10  number(11,2) ; ln_gan_11  number(11,2) ; ln_gan_12  number(11,2) ;
ln_gan_13  number(11,2) ; ln_gan_14  number(11,2) ; ln_gan_15  number(11,2) ;
ln_gan_16  number(11,2) ; ln_gan_17  number(11,2) ; ln_gan_18  number(11,2) ;
ln_gan_19  number(11,2) ; ln_gan_20  number(11,2) ; ln_gan_21  number(11,2) ;
ln_gan_22  number(11,2) ; ln_gan_23  number(11,2) ; ln_gan_24  number(11,2) ;
ln_gan_25  number(11,2) ; ln_gan_26  number(11,2) ; ln_gan_27  number(11,2) ;
ln_gan_28  number(11,2) ; ln_gan_29  number(11,2) ; ln_gan_30  number(11,2) ;
ln_gan_31  number(11,2) ; ln_gan_32  number(11,2) ; ln_gan_33  number(11,2) ;
ln_gan_34  number(11,2) ; ln_gan_35  number(11,2) ; ln_gan_36  number(11,2) ;
ln_gan_37  number(11,2) ; ln_gan_38  number(11,2) ; ln_gan_39  number(11,2) ;
ln_gan_40  number(11,2) ; ln_gan_41  number(11,2) ; ln_gan_42  number(11,2) ;
ln_gan_43  number(11,2) ; ln_gan_44  number(11,2) ; ln_gan_45  number(11,2) ;
ln_gan_46  number(11,2) ; ln_gan_47  number(11,2) ; ln_gan_48  number(11,2) ;
ln_gan_49  number(11,2) ; ln_gan_50  number(11,2) ; ln_gan_51  number(11,2) ;
ln_gan_52  number(11,2) ; ln_des_01  number(11,2) ; ln_des_02  number(11,2) ;
ln_des_03  number(11,2) ; ln_des_04  number(11,2) ; ln_des_05  number(11,2) ;
ln_des_06  number(11,2) ; ln_des_07  number(11,2) ; ln_des_08  number(11,2) ;
ln_des_09  number(11,2) ; ln_des_10  number(11,2) ; ln_des_11  number(11,2) ;
ln_des_12  number(11,2) ; ln_des_13  number(11,2) ; ln_des_14  number(11,2) ;
ln_des_15  number(11,2) ; ln_des_16  number(11,2) ; ln_des_17  number(11,2) ;
ln_des_18  number(11,2) ; ln_des_19  number(11,2) ; ln_des_20  number(11,2) ;
ln_des_21  number(11,2) ; ln_des_22  number(11,2) ; ln_des_23  number(11,2) ;
ln_des_24  number(11,2) ; ln_des_25  number(11,2) ; ln_des_26  number(11,2) ;
ln_apo_01  number(11,2) ; ln_apo_02  number(11,2) ; ln_apo_03  number(11,2) ;
ln_apo_04  number(11,2) ; ln_apo_05  number(11,2) ; ln_apo_06  number(11,2) ;
ln_apo_07  number(11,2) ; ln_apo_08  number(11,2) ; ln_apo_09  number(11,2) ;
ln_apo_10  number(11,2) ; ln_apo_11  number(11,2) ; ln_apo_12  number(11,2) ;
ln_apo_13  number(11,2) ; ln_var_01  number(11,2) ; ln_var_02  number(11,2) ;
ln_var_03  number(11,2) ; ln_var_04  number(11,2) ; ln_var_05  number(11,2) ;
ln_var_06  number(11,2) ; ln_var_07  number(11,2) ; ln_var_08  number(11,2) ;
ln_var_09  number(11,2) ; ln_var_10  number(11,2) ; ln_var_11  number(11,2) ;
ln_var_12  number(11,2) ; ln_var_13  number(11,2) ;

--  Cursor para leer los trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.fec_ingreso, m.fec_cese, m.dni, m.nro_ipss,
         m.cod_cargo, m.cod_afp, m.nro_afp_trabaj, m.cod_seccion
  from maestro m
--  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
  where m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.cod_trabajador ;

begin

--  ********************************************************************
--  ***   EMITE REPORTE DE PLANILLA PARA LOS TRABAJADORES DE AIPSA   ***
--  ********************************************************************

delete from tt_planilla ;

select p.fec_proceso into ld_fecha_proceso from rrhh_param_org p
  where p.origen = as_origen ;
  
select rh.grc_sobret_grd into ls_sobreti
  from rrhhparam rh where rh.reckey = '1' ;

ln_sw := 0 ;
if ld_fecha_proceso = ad_fecha then
  ln_sw := 1 ;
end if ;

for rc_mae in c_maestro loop

  ln_gan_01 := 0 ; ln_gan_02 := 0 ; ln_gan_03 := 0 ; ln_gan_04 := 0 ;
  ln_gan_05 := 0 ; ln_gan_06 := 0 ; ln_gan_07 := 0 ; ln_gan_08 := 0 ;
  ln_gan_09 := 0 ; ln_gan_10 := 0 ; ln_gan_11 := 0 ; ln_gan_12 := 0 ;
  ln_gan_13 := 0 ; ln_gan_14 := 0 ; ln_gan_15 := 0 ; ln_gan_16 := 0 ;
  ln_gan_17 := 0 ; ln_gan_18 := 0 ; ln_gan_19 := 0 ; ln_gan_20 := 0 ;
  ln_gan_21 := 0 ; ln_gan_22 := 0 ; ln_gan_23 := 0 ; ln_gan_24 := 0 ;
  ln_gan_25 := 0 ; ln_gan_26 := 0 ; ln_gan_27 := 0 ; ln_gan_28 := 0 ;
  ln_gan_29 := 0 ; ln_gan_30 := 0 ; ln_gan_31 := 0 ; ln_gan_32 := 0 ;
  ln_gan_33 := 0 ; ln_gan_34 := 0 ; ln_gan_35 := 0 ; ln_gan_36 := 0 ;
  ln_gan_37 := 0 ; ln_gan_38 := 0 ; ln_gan_39 := 0 ; ln_gan_40 := 0 ;
  ln_gan_41 := 0 ; ln_gan_42 := 0 ; ln_gan_43 := 0 ; ln_gan_44 := 0 ;
  ln_gan_45 := 0 ; ln_gan_46 := 0 ; ln_gan_47 := 0 ; ln_gan_48 := 0 ;
  ln_gan_49 := 0 ; ln_gan_50 := 0 ; ln_gan_51 := 0 ; ln_gan_52 := 0 ;
  ln_des_01 := 0 ; ln_des_02 := 0 ; ln_des_03 := 0 ; ln_des_04 := 0 ;
  ln_des_05 := 0 ; ln_des_06 := 0 ; ln_des_07 := 0 ; ln_des_08 := 0 ;
  ln_des_09 := 0 ; ln_des_10 := 0 ; ln_des_11 := 0 ; ln_des_12 := 0 ;
  ln_des_13 := 0 ; ln_des_14 := 0 ; ln_des_15 := 0 ; ln_des_16 := 0 ;
  ln_des_17 := 0 ; ln_des_18 := 0 ; ln_des_19 := 0 ; ln_des_20 := 0 ;
  ln_des_21 := 0 ; ln_des_22 := 0 ; ln_des_23 := 0 ; ln_des_24 := 0 ;
  ln_des_25 := 0 ; ln_des_26 := 0 ; ln_apo_01 := 0 ; ln_apo_02 := 0 ;
  ln_apo_03 := 0 ; ln_apo_04 := 0 ; ln_apo_05 := 0 ; ln_apo_06 := 0 ;
  ln_apo_07 := 0 ; ln_apo_08 := 0 ; ln_apo_09 := 0 ; ln_apo_10 := 0 ;
  ln_apo_11 := 0 ; ln_apo_12 := 0 ; ln_apo_13 := 0 ; ln_var_01 := 0 ;
  ln_var_02 := 0 ; ln_var_03 := 0 ; ln_var_04 := 0 ; ln_var_05 := 0 ;
  ln_var_06 := 0 ; ln_var_07 := 0 ; ln_var_08 := 0 ; ln_var_09 := 0 ;
  ln_var_10 := 0 ; ln_var_11 := 0 ; ln_var_12 := 0 ; ln_var_13 := 0 ;

  ls_seccion       := rc_mae.cod_seccion ;
  ls_codigo        := rc_mae.cod_trabajador ;
  ls_dni           := rc_mae.dni ;
  ls_cod_cargo     := rc_mae.cod_cargo ;
  ld_fecha_ingreso := rc_mae.fec_ingreso ;
  ld_fecha_cese    := rc_mae.fec_cese ;
  ls_carnet_ipss   := rc_mae.nro_ipss ;
  ls_carnet_afp    := rc_mae.nro_afp_trabaj ;
  ls_cod_afp       := rc_mae.cod_afp ;
  ls_nombres       := usf_rh_nombre_trabajador(ls_codigo) ;

  --  Determina cargo u ocupacion
  ln_contador := 0 ; ls_ocupacion := null ;
  select count(*) into ln_contador from cargo car
    where car.cod_cargo = ls_cod_cargo ;
  if ln_contador > 0 then
    select car.desc_cargo into ls_ocupacion from cargo car
      where car.cod_cargo = ls_cod_cargo ;
  end if ;

  --  Determina nombre de A.F.P.
  ln_contador := 0 ; ls_nombre_afp := null ;
  select count(*) into ln_contador from admin_afp aa
    where aa.cod_afp = ls_cod_afp ;
  if ln_contador > 0 then
    select aa.desc_afp into ls_nombre_afp from admin_afp aa
      where aa.cod_afp = ls_cod_afp ;
  end if ;

  select p.remunerac_basica, p.gan_fij_calc_vacac
    into lk_remuneracion_basica, lk_vacaciones
    from rrhhparam_cconcep p where p.reckey = '1' ;

  --  Determina remuneracion basica
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_remuneracion_basica ;
  ln_contador := 0 ; ln_sueldo_basico := 0 ;
  select count(*) into ln_contador from gan_desct_fijo gdf
    where gdf.cod_trabajador = ls_codigo and gdf.concep = ls_concepto ;
  if ln_contador > 0 then
    select gdf.imp_gan_desc into ln_sueldo_basico from gan_desct_fijo gdf
      where gdf.cod_trabajador = ls_codigo and gdf.concep = ls_concepto ;
  end if ;

  --  Halla dias trabajados y horas trabajadas
  ln_contador := 0 ;
  select count(*) into ln_contador from calculo cal
    where cal.cod_trabajador = ls_codigo and cal.concep = ls_concepto ;
  if ln_contador > 0 then
    select nvl(cal.dias_trabaj,0), nvl(cal.horas_trabaj,0)
      into ln_var_01, ln_var_02 from calculo cal
      where cal.cod_trabajador = ls_codigo and cal.concep = ls_concepto ;
  end if ;

  --  Determina fecha de salida y retorno de vacaciones
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = lk_vacaciones ;
  ln_contador := 0 ; ld_fec_salida_vac := null ; ld_fec_retorno_vac := null ;
  select count(*) into ln_contador from inasistencia i
    where i.cod_trabajador = ls_codigo and i.concep = ls_concepto ;
  if ln_contador = 1 then
    select i.fec_desde, i.fec_hasta into ld_fec_salida_vac, ld_fec_retorno_vac
      from inasistencia i where i.cod_trabajador = ls_codigo and
           i.concep = ls_concepto ;
  else
    ln_contador := 0 ;
    select count(*) into ln_contador from historico_inasistencia hi
      where hi.cod_trabajador = ls_codigo and hi.concep = ls_concepto and
            to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fecha,'mm/yyyy') ;
    if ln_contador = 1 then
      select hi.fec_desde, hi.fec_hasta into ld_fec_salida_vac, ld_fec_retorno_vac
        from historico_inasistencia hi
        where hi.cod_trabajador = ls_codigo and hi.concep = ls_concepto and
              to_char(hi.fec_movim,'mm/yyyy') = to_char(ad_fecha,'mm/yyyy') ;
    end if ;
  end if ;

  --  Halla horas extras
  ln_contador := 0 ;
  select count(*) into ln_contador from calculo cal
    where cal.cod_trabajador = ls_codigo and substr(cal.concep,1,2) = ls_sobreti ;
  if ln_contador > 0 then
    select sum(cal.horas_trabaj) into ln_var_03 from calculo cal
      where cal.cod_trabajador = ls_codigo and substr(cal.concep,1,2) = ls_sobreti ;
    ln_var_03 := nvl(ln_var_03,0) ;
  end if ;

  --  ****************************************************
  --  ***  Lectura de detalle del pago del trabajador  ***
  --  ****************************************************

  --  Ganancias
  for ln_codniv in 501 .. 552 loop

    ls_codniv := to_char(ln_codniv) ;
    if ln_sw = 1 then
      select sum(c.imp_soles) into ln_importe
        from calculo c, grupo_calculo_det d
        where c.cod_trabajador = ls_codigo and d.grupo_calculo = ls_codniv and
              d.concepto_calc = c.concep ;
    else
      select sum(hc.imp_soles) into ln_importe
        from historico_calculo hc, grupo_calculo_det d
        where hc.cod_trabajador = ls_codigo and d.grupo_calculo = ls_codniv and
              d.concepto_calc = hc.concep and hc.fec_calc_plan = ad_fecha ;
      select max(h.cod_seccion) into ls_seccion from historico_calculo h
        where h.cod_trabajador = ls_codigo and h.fec_calc_plan = ad_fecha ;
    end if ;
    ln_importe := nvl(ln_importe,0) ;

    if ln_importe <> 0 then
      if ls_codniv = '501' then
        ln_gan_01 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '502' then
        ln_gan_02 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '503' then
        ln_gan_03 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '504' then
        ln_gan_04 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '505' then
        ln_gan_05 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '506' then
        ln_gan_06 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '507' then
        ln_gan_07 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '508' then
        ln_gan_08 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '509' then
        ln_gan_09 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '510' then
        ln_gan_10 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '511' then
        ln_gan_11 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '512' then
         ln_gan_12 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '513' then
        ln_gan_13 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '514' then
        ln_gan_14 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '515' then
        ln_gan_15 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '516' then
        ln_gan_16 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '517' then
        ln_gan_17 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '518' then
        ln_gan_18 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '519' then
        ln_gan_19 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '520' then
        ln_gan_20 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '521' then
        ln_gan_21 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '522' then
        ln_gan_22 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '523' then
        ln_gan_23 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '524' then
        ln_gan_24 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '525' then
        ln_gan_25 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '526' then
        ln_gan_26 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '527' then
        ln_gan_27 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '528' then
        ln_gan_28 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '529' then
        ln_gan_29 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '530' then
        ln_gan_30 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '531' then
        ln_gan_31 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '532' then
        ln_gan_32 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '533' then
        ln_gan_33 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '534' then
        ln_gan_34 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '535' then
        ln_gan_35 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '536' then
        ln_gan_36 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '537' then
        ln_gan_37 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '538' then
        ln_gan_38 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '539' then
        ln_gan_39 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '540' then
        ln_gan_40 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '541' then
        ln_gan_41 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '542' then
        ln_gan_42 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '543' then
        ln_gan_43 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '544' then
        ln_gan_44 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '545' then
        ln_gan_45 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '546' then
        ln_gan_46 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '547' then
        ln_gan_47 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '548' then
        ln_gan_48 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '549' then
        ln_gan_49 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '550' then
        ln_gan_50 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '551' then
        ln_gan_51 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '552' then
        ln_gan_52 := ln_importe ; ln_importe := 0 ;
      end if ;
    end if ;

  end loop ;

  --  Descuentos
  for ln_codniv in 601 .. 626 loop

    ls_codniv := to_char(ln_codniv) ;
    if ln_sw = 1 then
      select sum(c.imp_soles) into ln_importe
        from calculo c, grupo_calculo_det d
        where c.cod_trabajador = ls_codigo and d.grupo_calculo = ls_codniv and
              d.concepto_calc = c.concep ;
    else
      select sum(hc.imp_soles) into ln_importe
        from historico_calculo hc, grupo_calculo_det d
        where hc.cod_trabajador = ls_codigo and d.grupo_calculo = ls_codniv and
              d.concepto_calc = hc.concep and hc.fec_calc_plan = ad_fecha ;
      select max(h.cod_seccion) into ls_seccion from historico_calculo h
        where h.cod_trabajador = ls_codigo and h.fec_calc_plan = ad_fecha ;
    end if ;
    ln_importe := nvl(ln_importe,0) ;

    if ln_importe <> 0 then
      if ls_codniv = '601' then
        ln_des_01 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '602' then
        ln_des_02 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '603' then
        ln_des_03 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '604' then
        ln_des_04 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '605' then
        ln_des_05 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '606' then
        ln_des_06 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '607' then
        ln_des_07 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '608' then
        ln_des_08 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '609' then
        ln_des_09 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '610' then
        ln_des_10 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '611' then
        ln_des_11 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '612' then
        ln_des_12 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '613' then
        ln_des_13 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '614' then
        ln_des_14 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '615' then
        ln_des_15 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '616' then
        ln_des_16 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '617' then
        ln_des_17 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '618' then
        ln_des_18 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '619' then
        ln_des_19 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '620' then
        ln_des_20 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '621' then
        ln_des_21 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '622' then
        ln_des_22 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '623' then
        ln_des_23 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '624' then
        ln_des_24 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '625' then
        ln_des_25 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '626' then
        ln_des_26 := ln_importe ; ln_importe := 0 ;
      end if ;
    end if ;

  end loop ;

  --  Aportes
  for ln_codniv in 701 .. 713 loop

    ls_codniv := to_char(ln_codniv) ;
    if ln_sw = 1 then
      select sum(c.imp_soles) into ln_importe
        from calculo c, grupo_calculo_det d
        where c.cod_trabajador = ls_codigo and d.grupo_calculo = ls_codniv and
              d.concepto_calc = c.concep ;
    else
      select sum(hc.imp_soles) into ln_importe
        from historico_calculo hc, grupo_calculo_det d
        where hc.cod_trabajador = ls_codigo and d.grupo_calculo = ls_codniv and
              d.concepto_calc = hc.concep and hc.fec_calc_plan = ad_fecha ;
      select max(h.cod_seccion) into ls_seccion from historico_calculo h
        where h.cod_trabajador = ls_codigo and h.fec_calc_plan = ad_fecha ;
    end if ;
    ln_importe := nvl(ln_importe,0) ;

    if ln_importe <> 0 then
      if ls_codniv = '701' then
        ln_apo_01 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '702' then
        ln_apo_02 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '703' then
        ln_apo_03 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '704' then
        ln_apo_04 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '705' then
        ln_apo_05 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '706' then
        ln_apo_06 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '707' then
        ln_apo_07 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '708' then
        ln_apo_08 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '709' then
        ln_apo_09 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '710' then
        ln_apo_10 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '711' then
        ln_apo_11 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '712' then
        ln_apo_12 := ln_importe ; ln_importe := 0 ;
      elsif ls_codniv = '713' then
        ln_apo_13 := ln_importe ; ln_importe := 0 ;
      end if ;
    end if ;

  end loop ;

  ln_total := 0 ;
  ln_total := nvl(ln_gan_52,0) + nvl(ln_des_26,0) + nvl(ln_apo_13,0) ;
  
  if ln_total <> 0 then
  
    --  Determina la descripcion de la seccion
    ls_desc_seccion := null ;
    ln_contador := 0 ;
    select count(*) into ln_contador from seccion sec
      where sec.cod_area = substr(ls_seccion,1,1) and sec.cod_seccion = ls_seccion ;
    if ln_contador > 0 then
      select sec.desc_seccion into ls_desc_seccion from seccion sec
        where sec.cod_area = substr(ls_seccion,1,1) and sec.cod_seccion = ls_seccion ;
    end if ;

    --  Inserta registro para imprimir planilla de pagos
    insert into tt_planilla (
      fecha_proceso, seccion, desc_seccion, codigo,
      nombres, ocupacion, fecha_ingreso, carnet_ipss,
      nombre_afp, carnet_afp, dni, fecha_cese,
      sueldo_basico, fec_salida_vac, fec_retorno_vac,
      gan_01, gan_02, gan_03, gan_04, gan_05, gan_06, gan_07, gan_08,
      gan_09, gan_10, gan_11, gan_12, gan_13, gan_14, gan_15, gan_16,
      gan_17, gan_18, gan_19, gan_20, gan_21, gan_22, gan_23, gan_24,
      gan_25, gan_26, gan_27, gan_28, gan_29, gan_30, gan_31, gan_32,
      gan_33, gan_34, gan_35, gan_36, gan_37, gan_38, gan_39, gan_40,
      gan_41, gan_42, gan_43, gan_44, gan_45, gan_46, gan_47, gan_48,
      gan_49, gan_50, gan_51, gan_52, des_01, des_02, des_03, des_04,
      des_05, des_06, des_07, des_08, des_09, des_10, des_11, des_12,
      des_13, des_14, des_15, des_16, des_17, des_18, des_19, des_20,
      des_21, des_22, des_23, des_24, des_25, des_26, apo_01, apo_02,
      apo_03, apo_04, apo_05, apo_06, apo_07, apo_08, apo_09, apo_10,
      apo_11, apo_12, apo_13, var_01, var_02, var_03, var_04, var_05,
      var_06, var_07, var_08, var_09, var_10, var_11, var_12, var_13 )
    values (
      ad_fecha, ls_seccion, ls_desc_seccion, ls_codigo,
      ls_nombres, ls_ocupacion, ld_fecha_ingreso, ls_carnet_ipss,
      ls_nombre_afp, ls_carnet_afp, ls_dni, ld_fecha_cese,
      ln_sueldo_basico, ld_fec_salida_vac, ld_fec_retorno_vac,
      ln_gan_01, ln_gan_02, ln_gan_03, ln_gan_04, ln_gan_05, ln_gan_06, ln_gan_07, ln_gan_08,
      ln_gan_09, ln_gan_10, ln_gan_11, ln_gan_12, ln_gan_13, ln_gan_14, ln_gan_15, ln_gan_16,
      ln_gan_17, ln_gan_18, ln_gan_19, ln_gan_20, ln_gan_21, ln_gan_22, ln_gan_23, ln_gan_24,
      ln_gan_25, ln_gan_26, ln_gan_27, ln_gan_28, ln_gan_29, ln_gan_30, ln_gan_31, ln_gan_32,
      ln_gan_33, ln_gan_34, ln_gan_35, ln_gan_36, ln_gan_37, ln_gan_38, ln_gan_39, ln_gan_40,
      ln_gan_41, ln_gan_42, ln_gan_43, ln_gan_44, ln_gan_45, ln_gan_46, ln_gan_47, ln_gan_48,
      ln_gan_49, ln_gan_50, ln_gan_51, ln_gan_52, ln_des_01, ln_des_02, ln_des_03, ln_des_04,
      ln_des_05, ln_des_06, ln_des_07, ln_des_08, ln_des_09, ln_des_10, ln_des_11, ln_des_12,
      ln_des_13, ln_des_14, ln_des_15, ln_des_16, ln_des_17, ln_des_18, ln_des_19, ln_des_20,
      ln_des_21, ln_des_22, ln_des_23, ln_des_24, ln_des_25, ln_des_26, ln_apo_01, ln_apo_02,
      ln_apo_03, ln_apo_04, ln_apo_05, ln_apo_06, ln_apo_07, ln_apo_08, ln_apo_09, ln_apo_10,
      ln_apo_11, ln_apo_12, ln_apo_13, ln_var_01, ln_var_02, ln_var_03, ln_var_04, ln_var_05,
      ln_var_06, ln_var_07, ln_var_08, ln_var_09, ln_var_10, ln_var_11, ln_var_12, ln_var_13 ) ;

  end if ;

end loop ;

end usp_rh_rpt_planilla_aipsa ;
/
