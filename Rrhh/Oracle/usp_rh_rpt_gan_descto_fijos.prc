create or replace procedure usp_rh_rpt_gan_descto_fijos (
  as_tipo_trabajador in char, as_origen in char ) is

lk_bonificacion_25         constant char(3) := '030' ;
lk_bonificacion_30         constant char(3) := '031' ;

ls_activo_cesado           char(1) ;
ls_estable_contratado      char(1) ;
ls_seccion                 char(3) ;
ls_codigo                  char(8) ;
ls_nombres                 varchar2(60) ;
ld_fecha_nacimiento        date ;
ld_fecha_ingreso           date ;
ld_fecha_cese              date ;
ls_codigo_afp              char(2) ;
ls_categ_salarial          char(2) ;
ls_cencos                  char(10) ;
ls_concepto                char(4) ;
ls_desc_concepto           varchar2(60) ;
ls_concepto_gan            char(2) ;
ls_concepto_des            char(2) ;

ls_bonificacion            char(1) ;
ls_flag_30                 char(1) ;
ls_flag_25                 char(1) ;
ln_importe_30              number(13,2) ;
ln_importe_25              number(13,2) ;
ln_importe_total           number(13,2) ;
ln_contador                integer ;

--  Cursor para lectura de todos los trabajadores
cursor c_maestro is
  select m.cod_trabajador, m.flag_estado, m.fec_ingreso, m.fec_nacimiento,
         m.fec_cese, m.situa_trabaj, m.cod_afp, m.bonif_fija_30_25, m.cencos,
         m.cod_categ_sal, m.cod_seccion
  from maestro m
  where m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen and
        m.flag_estado = '1' and m.flag_cal_plnlla = '1'
  order by m.flag_estado, m.situa_trabaj, m.cod_seccion, m.apel_paterno,
           m.apel_materno, m.nombre1, m.nombre2 ;

--  Cursor de lectura de ganancias fijas
cursor c_ganancias is
  select gf.concep, gf.imp_gan_desc
  from gan_desct_fijo gf
  where gf.cod_trabajador = ls_codigo and substr(gf.concep,1,2) = ls_concepto_gan and
        gf.flag_estado = '1'
  order by gf.cod_trabajador, gf.concep ;

--  Cursor de lectura de descuentos fijos
cursor c_descuentos is
  select df.concep, df.imp_gan_desc
  from gan_desct_fijo df
  where df.cod_trabajador = ls_codigo and substr(df.concep,1,2) = ls_concepto_des and
        df.flag_estado = '1'
  order by df.cod_trabajador, df.concep ;

begin

--  ******************************************************************
--  ***   REPORTE DE GANANCIAS Y DESCUENTOS FIJOS POR TRABAJADOR   ***
--  ******************************************************************

delete from tt_rpt_gan_descto_fijos ;

select p.grc_gnn_fija, p.grc_dsc_fijo
  into ls_concepto_gan, ls_concepto_des
  from rrhhparam p where p.reckey = '1' ;
  
for rc_mae in c_maestro loop

  ls_codigo             := rc_mae.cod_trabajador ;
  ls_activo_cesado      := nvl(rc_mae.flag_estado,' ') ;
  ld_fecha_ingreso      := rc_mae.fec_ingreso ;
  ld_fecha_nacimiento   := rc_mae.fec_nacimiento ;
  ld_fecha_cese         := rc_mae.fec_cese ;
  ls_estable_contratado := nvl(rc_mae.situa_trabaj,' ') ;
  ls_codigo_afp         := nvl(rc_mae.cod_afp,' ') ;
  ls_bonificacion       := nvl(rc_mae.bonif_fija_30_25,' ') ;
  ls_categ_salarial     := nvl(rc_mae.cod_categ_sal,' ') ;
  ls_cencos             := nvl(rc_mae.cencos,' ') ;
  ls_seccion            := nvl(rc_mae.cod_seccion,' ') ;
  ls_nombres            := usf_rh_nombre_trabajador(ls_codigo) ;

  ln_importe_30 := 0 ; ln_importe_25 := 0 ; ln_importe_total := 0 ;
  for rc_gan in c_ganancias loop
    select nvl(c.desc_breve,' ') into ls_desc_concepto from concepto c
           where c.concep = rc_gan.concep ;
    ln_contador := 0 ; ls_flag_25 := null ;
    select count(*) into ln_contador from grupo_calculo_det d
      where d.grupo_calculo = lk_bonificacion_25 and d.concepto_calc = rc_gan.concep ;
    if ln_contador > 0 then
      ls_flag_25 := '1' ;
    end if ;
    ln_contador := 0 ; ls_flag_30 := null ;
    select count(*) into ln_contador from grupo_calculo_det d
      where d.grupo_calculo = lk_bonificacion_30 and d.concepto_calc = rc_gan.concep ;
    if ln_contador > 0 then
      ls_flag_30 := '1' ;
    end if ;
    if ls_bonificacion = '1' then
      if ls_flag_30 = '1' then
        ln_importe_30 := ln_importe_30 + nvl(rc_gan.imp_gan_desc,0) ;
      end if ;
    elsif ls_bonificacion = '2' then
      if ls_flag_25 = '1' then
        ln_importe_25 := ln_importe_25 + nvl(rc_gan.imp_gan_desc,0) ;
      end if ;
    end if ;
    ln_importe_total := ln_importe_total + nvl(rc_gan.imp_gan_desc,0) ;
    if nvl(rc_gan.imp_gan_desc,0) <> 0 then
      insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, rc_gan.concep,
        ls_desc_concepto, nvl(rc_gan.imp_gan_desc,0) ) ;
    end if ;
  end loop ;

  if ls_bonificacion = '1' then
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_bonificacion_30 ;
    ln_importe_30 := ln_importe_30 * 0.30 ;
    ln_importe_total := ln_importe_total + ln_importe_30 ;
    select nvl(c.desc_breve,' ') into ls_desc_concepto
      from concepto c where c.concep = ls_concepto ;
    if ln_importe_30 <> 0 then
      insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, ls_concepto,
        ls_desc_concepto, ln_importe_30 ) ;
    end if ;
  elsif ls_bonificacion = '2' then
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_bonificacion_25 ;
    ln_importe_25 := ln_importe_25 * 0.25 ;
    ln_importe_total := ln_importe_total + ln_importe_25 ;
    select nvl(c.desc_breve,' ') into ls_desc_concepto
      from concepto c where c.concep = ls_concepto ;
    if ln_importe_25 <> 0 then
      insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, ls_concepto,
        ls_desc_concepto, ln_importe_25 ) ;
    end if ;
  end if ;

  if ln_importe_total <> 0 then
    insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion,
      codigo, nombres, fecha_nacimiento,
      fecha_ingreso, fecha_cese, codigo_afp,
      categ_salarial, cencos, concepto,
      desc_concepto, importe )
    values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion,
      ls_codigo, ls_nombres, ld_fecha_nacimiento,
      ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
      ls_categ_salarial, ls_cencos, '1099',
      'TOTAL GANANCIAS', ln_importe_total ) ;
  end if ;

  ln_importe_total := 0 ;
  for rc_des in c_descuentos loop
    select nvl(c.desc_breve,' ') into ls_desc_concepto
      from concepto c where c.concep = rc_des.concep ;
    ln_importe_total := ln_importe_total + nvl(rc_des.imp_gan_desc,0) ;
    if nvl(rc_des.imp_gan_desc,0) <> 0 then
      insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, rc_des.concep,
        ls_desc_concepto, nvl(rc_des.imp_gan_desc,0) ) ;
    end if ;
  end loop ;

  --  Inserta registros en la tabla temporal
  if ln_importe_total <> 0 then
    insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion,
      codigo, nombres, fecha_nacimiento,
      fecha_ingreso, fecha_cese, codigo_afp,
      categ_salarial, cencos, concepto,
      desc_concepto, importe )
    values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion,
      ls_codigo, ls_nombres, ld_fecha_nacimiento,
      ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
      ls_categ_salarial, ls_cencos, '2299',
      'TOTAL DESCUENTOS', ln_importe_total ) ;
  end if ;

end loop ;

end usp_rh_rpt_gan_descto_fijos ;
/
