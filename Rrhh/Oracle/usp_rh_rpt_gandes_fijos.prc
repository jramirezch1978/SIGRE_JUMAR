create or replace procedure usp_rh_rpt_gandes_fijos (
  as_tipo_trabajador in char, as_origen in char ) is

lk_bonificacion_25         char(3) ;
lk_bonificacion_30         char(3) ;

ls_codigo                  char(8) ;
ls_nombres                 varchar2(60) ;
ls_bonificacion            char(1) ;
ls_concepto                char(4) ;
ls_desc_concepto           varchar2(60) ;
ls_activo_cesado           char(1) ;
ls_estable_contratado      char(1) ;
ls_seccion                 char(3) ;
ld_fecha_nacimiento        date ;
ld_fecha_ingreso           date ;
ld_fecha_cese              date ;
ls_codigo_afp              char(2) ;
ls_categ_salarial          char(2) ;
ls_cencos                  char(10) ;

ln_importe                 number(13,2) ;
ln_importe_30              number(13,2) ;
ln_importe_25              number(13,2) ;
ln_importe_total           number(13,2) ;

ls_gan_fijas               char(2) ;
ls_des_fijos               char(2) ;
ln_verifica                integer ;

--  Cursor para lectura de los trabajadores seleccionados
cursor c_maestro is 
  select m.cod_trabajador, m.flag_estado, m.fec_ingreso, m.fec_nacimiento,
         m.fec_cese, m.situa_trabaj, m.cod_afp, m.bonif_fija_30_25, m.cencos,
         m.cod_categ_sal, m.cod_seccion
  from maestro m
  where m.tipo_trabajador like as_tipo_trabajador and m.cod_origen = as_origen
  order by m.flag_estado, m.situa_trabaj, m.cod_seccion, m.apel_paterno,
        m.apel_materno, m.nombre1, m.nombre2 ;

--  Cursor de lectura de ganancias fijas
cursor c_ganancias is 
  select gf.concep, gf.imp_gan_desc, c.desc_breve
  from gan_desct_fijo gf, concepto c
  where gf.cod_trabajador = ls_codigo and substr(gf.concep,1,2) = ls_gan_fijas and 
        gf.flag_estado = '1' and nvl(gf.imp_gan_desc,0) <> 0 and
        gf.concep = c.concep
  order by gf.cod_trabajador, gf.concep ;

--  Cursor de lectura de descuentos fijos
cursor c_descuentos is 
  select df.concep, df.imp_gan_desc, c.desc_breve
  from gan_desct_fijo df, concepto c
  where df.cod_trabajador = ls_codigo and substr(df.concep,1,2) = ls_des_fijos and 
        df.flag_estado = '1' and nvl(df.imp_gan_desc,0) <> 0 and
        df.concep = c.concep
  order by df.cod_trabajador, df.concep ;

begin

--  *************************************************************
--  ***  GENERA GANANCIAS Y DESCUENTOS FIJOS POR TRABAJADOR   ***
--  *************************************************************

delete from tt_rpt_gan_descto_fijos ;

select p.grc_gnn_fija, p.grc_dsc_fijo into ls_gan_fijas, ls_des_fijos
  from rrhhparam p where p.reckey = '1' ;
  
select pc.bonificacion25, pc.bonificacion30
  into lk_bonificacion_25, lk_bonificacion_30
  from rrhhparam_cconcep pc where pc.reckey = '1' ;
  
for rc_mae in c_maestro loop  

  ls_codigo             := rc_mae.cod_trabajador ;
  ls_bonificacion       := nvl(rc_mae.bonif_fija_30_25,' ') ;
  ls_nombres            := usf_rh_nombre_trabajador(ls_codigo) ;
  ls_activo_cesado      := nvl(rc_mae.flag_estado,' ') ;
  ld_fecha_ingreso      := rc_mae.fec_ingreso ;
  ld_fecha_nacimiento   := rc_mae.fec_nacimiento ;
  ld_fecha_cese         := rc_mae.fec_cese ;
  ls_estable_contratado := nvl(rc_mae.situa_trabaj,' ') ;
  ls_codigo_afp         := nvl(rc_mae.cod_afp,' ') ;
  ls_categ_salarial     := nvl(rc_mae.cod_categ_sal,' ') ;
  ls_cencos             := nvl(rc_mae.cencos,' ') ;
  ls_seccion            := nvl(rc_mae.cod_seccion,' ') ;

  --  ***   LECTURA SOLO DE GANANCIAS FIJAS   ***

  ln_importe_30 := 0 ; ln_importe_total := 0 ;
  ln_importe_25 := 0 ;

  for rc_gan in c_ganancias loop

    if ls_bonificacion = '1' then
      ln_verifica := 0 ;
      select count(*) into ln_verifica from grupo_calculo_det d
        where d.grupo_calculo = lk_bonificacion_30 and
              d.concepto_calc = rc_gan.concep ;
      if ln_verifica > 0 then
        ln_importe_30 := ln_importe_30 + nvl(rc_gan.imp_gan_desc,0) ;
      end if ;
    elsif ls_bonificacion = '2' then
      ln_verifica := 0 ;
      select count(*) into ln_verifica from grupo_calculo_det d
        where d.grupo_calculo = lk_bonificacion_25 and
              d.concepto_calc = rc_gan.concep ;
      if ln_verifica > 0 then
        ln_importe_25 := ln_importe_25 + nvl(rc_gan.imp_gan_desc,0) ;
      end if ;
    end if ;

    ln_importe_total := ln_importe_total + nvl(rc_gan.imp_gan_desc,0) ;

    insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion, codigo,
      nombres, fecha_nacimiento, fecha_ingreso, fecha_cese,
      codigo_afp, categ_salarial, cencos, concepto,
      desc_concepto, importe )
    values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion, ls_codigo,
      ls_nombres, ld_fecha_nacimiento, ld_fecha_ingreso, ld_fecha_cese,
      ls_codigo_afp, ls_categ_salarial, ls_cencos, rc_gan.concep,
      rc_gan.desc_breve, nvl(rc_gan.imp_gan_desc,0) ) ;

  end loop ;

  ln_importe := 0 ;
  if ls_bonificacion = '1' then
    ln_importe := ln_importe_30 * 0.30 ;
    select c.concepto_gen into ls_concepto from grupo_calculo c
      where c.grupo_calculo = lk_bonificacion_30 ;
    select nvl(c.desc_breve,' ') into ls_desc_concepto from concepto c
      where c.concep = ls_concepto ;
  elsif ls_bonificacion = '2' then
    ln_importe := ln_importe_25 * 0.25 ;
    select c.concepto_gen into ls_concepto from grupo_calculo c
      where c.grupo_calculo = lk_bonificacion_25 ;
    select nvl(c.desc_breve,' ') into ls_desc_concepto from concepto c
      where c.concep = ls_concepto ;
  end if ;

  ln_importe_total := ln_importe_total + ln_importe ;

  if ln_importe <> 0 then
    insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion, codigo,
      nombres, fecha_nacimiento, fecha_ingreso, fecha_cese,
      codigo_afp, categ_salarial, cencos, concepto,
      desc_concepto, importe )
    values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion, ls_codigo,
      ls_nombres, ld_fecha_nacimiento, ld_fecha_ingreso, ld_fecha_cese,
      ls_codigo_afp, ls_categ_salarial, ls_cencos, ls_concepto,
      ls_desc_concepto, ln_importe ) ;
  end if ;

  if ln_importe_total <> 0 then
    insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion, codigo,
      nombres, fecha_nacimiento, fecha_ingreso, fecha_cese,
      codigo_afp, categ_salarial, cencos, concepto,
      desc_concepto, importe )
    values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion, ls_codigo,
      ls_nombres, ld_fecha_nacimiento, ld_fecha_ingreso, ld_fecha_cese,
      ls_codigo_afp, ls_categ_salarial, ls_cencos, '1099',
      'TOTAL GANANCIAS', ln_importe_total ) ;
  end if ;

  --  ***   LECTURA SOLO DE DESCUENTOS FIJOS   ***

  ln_importe_total := 0 ;

  for rc_des in c_descuentos loop

    ln_importe_total := ln_importe_total + nvl(rc_des.imp_gan_desc,0) ;
    if nvl(rc_des.imp_gan_desc,0) <> 0 then
      insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion, codigo,
        nombres, fecha_nacimiento, fecha_ingreso, fecha_cese,
        codigo_afp, categ_salarial, cencos, concepto,
        desc_concepto, importe )
      values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion, ls_codigo,
        ls_nombres, ld_fecha_nacimiento, ld_fecha_ingreso, ld_fecha_cese,
        ls_codigo_afp, ls_categ_salarial, ls_cencos, rc_des.concep,
        rc_des.desc_breve, nvl(rc_des.imp_gan_desc,0) ) ;
    end if ;

  end loop ;

  if ln_importe_total <> 0 then
    insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion, codigo,
      nombres, fecha_nacimiento, fecha_ingreso, fecha_cese,
      codigo_afp, categ_salarial, cencos, concepto,
      desc_concepto, importe )
    values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion, ls_codigo,
      ls_nombres, ld_fecha_nacimiento, ld_fecha_ingreso, ld_fecha_cese,
      ls_codigo_afp, ls_categ_salarial, ls_cencos, '2299',
      'TOTAL DESCUENTOS', ln_importe_total ) ;
  end if ;

end loop ;

end usp_rh_rpt_gandes_fijos ;
/
