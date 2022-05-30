create or replace procedure usp_rpt_gan_descto_fijos (
  as_tipo_trabajador   in maestro.tipo_trabajador%type ) is

--  Variables locales
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
ln_importe                 number(13,2) ;

ls_bonificacion            char(1) ;
ls_flag_30                 char(1) ;
ls_flag_25                 char(1) ;
ln_importe_30              number(13,2) ;
ln_importe_25              number(13,2) ;
ln_importe_total           number(13,2) ;

--  Cursor para lectura de todos los trabajadores
Cursor c_maestro is 
  select m.cod_trabajador, m.flag_estado, m.fec_ingreso,
         m.fec_nacimiento, m.fec_cese, m.situa_trabaj,
         m.cod_afp, m.bonif_fija_30_25, m.cencos,
         m.cod_categ_sal, m.cod_seccion
  from maestro m
  where m.tipo_trabajador = as_tipo_trabajador
  order by m.flag_estado, m.situa_trabaj, m.cod_seccion,
           m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2 ;

--  Cursor de lectura de ganancias fijas
Cursor c_ganancias is 
  select gf.concep, gf.imp_gan_desc
  from gan_desct_fijo gf
  where gf.cod_trabajador = ls_codigo and
        substr(gf.concep,1,2) = '10' and 
        gf.flag_estado = '1' and
        gf.flag_trabaj = '1'
  order by gf.cod_trabajador, gf.concep ;

--  Cursor de lectura de descuentos fijos
Cursor c_descuentos is 
  select df.concep, df.imp_gan_desc
  from gan_desct_fijo df
  where df.cod_trabajador = ls_codigo and
        substr(df.concep,1,2) = '22' and 
        df.flag_estado = '1' and
        df.flag_trabaj = '1'
  order by df.cod_trabajador, df.concep ;

Begin

delete from tt_rpt_gan_descto_fijos ;

--  ******************************************************************
--  ***  LECTURA DEL MAESTRO DE TRABAJADORES ACTIVOS E INACTIVOS   ***
--  ******************************************************************
For rc_mae in c_maestro Loop  

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
  ls_nombres            := usf_nombre_trabajador(ls_codigo) ;
  
  --  *******************************************
  --  ***   LECTURA SOLO DE GANANCIAS FIJAS   ***
  --  *******************************************
  ln_importe_30    := 0 ;
  ln_importe_25    := 0 ;
  ln_importe_total := 0 ;
  For rc_gan in c_ganancias Loop

    ls_concepto := rc_gan.concep ;
    ln_importe  := nvl(rc_gan.imp_gan_desc,0) ;
    Select nvl(c.desc_breve,' '), nvl(c.flag_t_bonif_30,' '),
           nvl(c.flag_t_bonif_25,' ')
      into ls_desc_concepto, ls_flag_30, ls_flag_25
      from concepto c
      where c.concep = ls_concepto ;
    If ls_bonificacion = '1' then
      If ls_flag_30 = '1' then
        ln_importe_30 := ln_importe_30 + ln_importe ;
      End if ;
    Elsif ls_bonificacion = '2' then
      If ls_flag_25 = '1' then
        ln_importe_25 := ln_importe_25 + ln_importe ;
      End if ;
    End if ;
    ln_importe_total := ln_importe_total + ln_importe ;
      
    --  Inserta registros en la tabla temporal
    If ln_importe <> 0 then
      Insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      Values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, ls_concepto,
        ls_desc_concepto, ln_importe ) ;
    End if ;

  End Loop ;

  If ls_bonificacion = '1' then
    ln_importe_30    := ln_importe_30 * 0.30 ;
    ln_importe_total := ln_importe_total + ln_importe_30 ;
    ls_concepto := '1030' ;
    Select nvl(c.desc_breve,' ')
      into ls_desc_concepto
      from concepto c
      where c.concep = ls_concepto ;
    --  Inserta registros en la tabla temporal
    If ln_importe_30 <> 0 then
      Insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      Values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, ls_concepto,
        ls_desc_concepto, ln_importe_30 ) ;
    End if ;
  Elsif ls_bonificacion = '2' then
    ln_importe_25    := ln_importe_25 * 0.25 ;
    ln_importe_total := ln_importe_total + ln_importe_25 ;
    ls_concepto := '1025' ;
    Select nvl(c.desc_breve,' ')
      into ls_desc_concepto
      from concepto c
      where c.concep = ls_concepto ;
    --  Inserta registros en la tabla temporal
    If ln_importe_25 <> 0 then
      Insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      Values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, ls_concepto,
        ls_desc_concepto, ln_importe_25 ) ;
    End if ;
  End if ;

  --  Inserta registros en la tabla temporal
  If ln_importe_total <> 0 then
    Insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion,
      codigo, nombres, fecha_nacimiento,
      fecha_ingreso, fecha_cese, codigo_afp,
      categ_salarial, cencos, concepto,
      desc_concepto, importe )
    Values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion,
      ls_codigo, ls_nombres, ld_fecha_nacimiento,
      ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
      ls_categ_salarial, ls_cencos, '1099',
      'TOTAL GANANCIAS', ln_importe_total ) ;
  End if ;

  --  ********************************************
  --  ***   LECTURA SOLO DE DESCUENTOS FIJOS   ***
  --  ********************************************
  ln_importe_total := 0 ;
  For rc_des in c_descuentos Loop

    ls_concepto := rc_des.concep ;
    ln_importe  := nvl(rc_des.imp_gan_desc,0) ;
    Select nvl(c.desc_breve,' ')
      into ls_desc_concepto
      from concepto c
      where c.concep = ls_concepto ;
    ln_importe_total := ln_importe_total + ln_importe ;
      
    --  Inserta registros en la tabla temporal
    If ln_importe <> 0 then
      Insert into tt_rpt_gan_descto_fijos (
        activo_cesado, estable_contratado, seccion,
        codigo, nombres, fecha_nacimiento,
        fecha_ingreso, fecha_cese, codigo_afp,
        categ_salarial, cencos, concepto,
        desc_concepto, importe )
      Values (
        ls_activo_cesado, ls_estable_contratado, ls_seccion,
        ls_codigo, ls_nombres, ld_fecha_nacimiento,
        ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
        ls_categ_salarial, ls_cencos, ls_concepto,
        ls_desc_concepto, ln_importe ) ;
    End if ;

  End Loop ;

  --  Inserta registros en la tabla temporal
  If ln_importe_total <> 0 then
    Insert into tt_rpt_gan_descto_fijos (
      activo_cesado, estable_contratado, seccion,
      codigo, nombres, fecha_nacimiento,
      fecha_ingreso, fecha_cese, codigo_afp,
      categ_salarial, cencos, concepto,
      desc_concepto, importe )
    Values (
      ls_activo_cesado, ls_estable_contratado, ls_seccion,
      ls_codigo, ls_nombres, ld_fecha_nacimiento,
      ld_fecha_ingreso, ld_fecha_cese, ls_codigo_afp,
      ls_categ_salarial, ls_cencos, '2299',
      'TOTAL DESCUENTOS', ln_importe_total ) ;
  End if ;
  
End Loop ;

End usp_rpt_gan_descto_fijos ;
/
