create or replace procedure usp_presup_plla_calculo_det (
  an_periodo    in number,   an_asiesc     in number,  as_usuario    in char,
  an_factor_01  in number,   an_factor_02  in number,  an_factor_03  in number,
  an_factor_04  in number,   an_factor_05  in number,  an_factor_06  in number,
  an_factor_07  in number,   an_factor_08  in number,  an_factor_09  in number,
  an_factor_10  in number,   an_factor_11  in number,  an_factor_12  in number,
  an_monfij_01  in number,   an_monfij_02  in number,  an_monfij_03  in number,
  an_monfij_04  in number,   an_monfij_05  in number,  an_monfij_06  in number,
  an_monfij_07  in number,   an_monfij_08  in number,  an_monfij_09  in number,
  an_monfij_10  in number,   an_monfij_11  in number,  an_monfij_12  in number,
  an_tipcam_01  in number,   an_tipcam_02  in number,  an_tipcam_03  in number,
  an_tipcam_04  in number,   an_tipcam_05  in number,  an_tipcam_06  in number,
  an_tipcam_07  in number,   an_tipcam_08  in number,  an_tipcam_09  in number,
  an_tipcam_10  in number,   an_tipcam_11  in number,  an_tipcam_12  in number ) is

--  Variables
lk_promedio         constant char(3) := '003' ;

ld_fec_ingreso      date ;           ld_fec_proceso      date ;
ld_ran_ini          date ;           ld_ran_fin          date ;
ld_fec_quinque      date ;           ld_fec_asiesc       date ;
ls_codigo           char(8) ;        ls_bonificacion     char(1) ;
ls_tipo_trabaj      char(3) ;        ls_cencos           char(10) ;
ls_seccion          char(3) ;        ls_mes_ingreso      char(2) ;
ls_cuenta           char(10) ;       ls_cuenta_obr       char(10) ;
ls_cuenta_emp       char(10) ;       ln_importe          number(13,2) ;
ln_imp_dia          number(13,2) ;   ln_gan_variables    number(13,2) ;
ln_acumulado        number(13,2) ;   ln_gratif_jul       number(13,2) ;
ln_gratif_dic       number(13,2) ;   ln_anios            number(4,2) ;
ln_jornal           number(4,2) ;    ln_factor           number(9,6) ;
ln_nro_meses        integer ;        ln_contador         integer ;
ln_quinquenio       integer ;        ln_bonvac           integer ;

ln_imp01_fij  number(13,2) ;  ln_imp02_fij  number(13,2) ;
ln_imp03_fij  number(13,2) ;  ln_imp04_fij  number(13,2) ;
ln_imp05_fij  number(13,2) ;  ln_imp06_fij  number(13,2) ;
ln_imp07_fij  number(13,2) ;  ln_imp08_fij  number(13,2) ;
ln_imp09_fij  number(13,2) ;  ln_imp10_fij  number(13,2) ;
ln_imp11_fij  number(13,2) ;  ln_imp12_fij  number(13,2) ;

ln_imp01_fix  number(13,2) ;  ln_imp02_fix  number(13,2) ;
ln_imp03_fix  number(13,2) ;  ln_imp04_fix  number(13,2) ;
ln_imp05_fix  number(13,2) ;  ln_imp06_fix  number(13,2) ;
ln_imp07_fix  number(13,2) ;  ln_imp08_fix  number(13,2) ;
ln_imp09_fix  number(13,2) ;  ln_imp10_fix  number(13,2) ;
ln_imp11_fix  number(13,2) ;  ln_imp12_fix  number(13,2) ;

ln_imp01_var  number(13,2) ;  ln_imp02_var  number(13,2) ;
ln_imp03_var  number(13,2) ;  ln_imp04_var  number(13,2) ;
ln_imp05_var  number(13,2) ;  ln_imp06_var  number(13,2) ;
ln_imp07_var  number(13,2) ;  ln_imp08_var  number(13,2) ;
ln_imp09_var  number(13,2) ;  ln_imp10_var  number(13,2) ;
ln_imp11_var  number(13,2) ;  ln_imp12_var  number(13,2) ;

ln_imp01_vax  number(13,2) ;  ln_imp02_vax  number(13,2) ;
ln_imp03_vax  number(13,2) ;  ln_imp04_vax  number(13,2) ;
ln_imp05_vax  number(13,2) ;  ln_imp06_vax  number(13,2) ;
ln_imp07_vax  number(13,2) ;  ln_imp08_vax  number(13,2) ;
ln_imp09_vax  number(13,2) ;  ln_imp10_vax  number(13,2) ;
ln_imp11_vax  number(13,2) ;  ln_imp12_vax  number(13,2) ;

ln_imp01_qui  number(13,2) ;  ln_imp02_qui  number(13,2) ;
ln_imp03_qui  number(13,2) ;  ln_imp04_qui  number(13,2) ;
ln_imp05_qui  number(13,2) ;  ln_imp06_qui  number(13,2) ;
ln_imp07_qui  number(13,2) ;  ln_imp08_qui  number(13,2) ;
ln_imp09_qui  number(13,2) ;  ln_imp10_qui  number(13,2) ;
ln_imp11_qui  number(13,2) ;  ln_imp12_qui  number(13,2) ;

ln_imp01_apo  number(13,2) ;  ln_imp02_apo  number(13,2) ;  
ln_imp03_apo  number(13,2) ;  ln_imp04_apo  number(13,2) ;  
ln_imp05_apo  number(13,2) ;  ln_imp06_apo  number(13,2) ;  
ln_imp07_apo  number(13,2) ;  ln_imp08_apo  number(13,2) ;  
ln_imp09_apo  number(13,2) ;  ln_imp10_apo  number(13,2) ;  
ln_imp11_apo  number(13,2) ;  ln_imp12_apo  number(13,2) ;  

ln_imp01_cts  number(13,2) ;  ln_imp02_cts  number(13,2) ;  
ln_imp03_cts  number(13,2) ;  ln_imp04_cts  number(13,2) ;  
ln_imp05_cts  number(13,2) ;  ln_imp06_cts  number(13,2) ;  
ln_imp07_cts  number(13,2) ;  ln_imp08_cts  number(13,2) ;  
ln_imp09_cts  number(13,2) ;  ln_imp10_cts  number(13,2) ;  
ln_imp11_cts  number(13,2) ;  ln_imp12_cts  number(13,2) ;  

--  Lectura de registros del maestro de personal
cursor c_maestro is
  select m.cod_trabajador, m.fec_ingreso, m.bonif_fija_30_25,
         m.tipo_trabajador, m.cencos, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and m.cencos <> ' ' and
       (m.tipo_trabajador = 'EMP' or m.tipo_trabajador = 'OBR')
  order by m.cencos, m.cod_trabajador ;

--  Lectura de ganancias fijas por trabajador
cursor c_ganancias is
  select gdf.concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = ls_codigo and gdf.flag_estado = '1' and
        gdf.flag_trabaj = '1' and substr(gdf.concep,1,2) = '10'
  order by gdf.cod_trabajador, gdf.concep ;

--  Lectura de conceptos variables afectos a promedios
cursor c_concepto is
  select concep
  from rrhh_nivel_detalle rhnd
  where rhnd.cod_nivel = lk_promedio ;
  
--  Lectura de carga familiar por trabajador
cursor c_carga is
  select f.cod_parent, f.fec_nacimiento
  from carga_familiar f
  where f.cod_trabajador = ls_codigo and
        (f.cod_parent = '02' or f.cod_parent = '03')
  order by f.cod_trabajador, f.secuencia ;
  
begin

delete from tt_presupuesto_planilla_det ;

--  Determina fecha de proceso del registro de parametros
select rh.fec_proceso
  into ld_fec_proceso from rrhhparam rh where rh.reckey = '1' ;

--  ***********************************************************
--  ***   LECTURA DE TRABAJADORES DEL MAESTRO DE PERSONAL   ***
--  ***********************************************************
for rc_mae in c_maestro loop

  ls_codigo       := rc_mae.cod_trabajador ;
  ld_fec_ingreso  := rc_mae.fec_ingreso ;
  ls_bonificacion := nvl(rc_mae.bonif_fija_30_25,' ') ;
  ls_tipo_trabaj  := rc_mae.tipo_trabajador ;
  ls_cencos       := rc_mae.cencos ;
  ls_seccion      := nvl(rc_mae.cod_seccion,' ') ;
  ls_mes_ingreso  := to_char(ld_fec_ingreso,'MM') ;

  ln_imp01_fix := 0 ;  ln_imp02_fix := 0 ;  ln_imp03_fix := 0 ;
  ln_imp04_fix := 0 ;  ln_imp05_fix := 0 ;  ln_imp06_fix := 0 ;
  ln_imp07_fix := 0 ;  ln_imp08_fix := 0 ;  ln_imp09_fix := 0 ;
  ln_imp10_fix := 0 ;  ln_imp11_fix := 0 ;  ln_imp12_fix := 0 ;

  --  **************************************************************
  --  ***   GRABA MONTOS FIJOS - BONIFICACION CIERRE DE PLIEGO   ***
  --  **************************************************************
  ln_imp01_fij := 0 ;  ln_imp02_fij := 0 ;  ln_imp03_fij := 0 ;
  ln_imp04_fij := 0 ;  ln_imp05_fij := 0 ;  ln_imp06_fij := 0 ;
  ln_imp07_fij := 0 ;  ln_imp08_fij := 0 ;  ln_imp09_fij := 0 ;
  ln_imp10_fij := 0 ;  ln_imp11_fij := 0 ;  ln_imp12_fij := 0 ;
  select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
    into ls_cuenta_emp, ls_cuenta_obr
    from concepto c where c.concep = '1431' ;
  if ls_tipo_trabaj = 'EMP' then
    ls_cuenta := ls_cuenta_emp ;
  elsif ls_tipo_trabaj = 'OBR' then
    ls_cuenta := ls_cuenta_obr ;
  end if ;
  if ls_cuenta <> ' ' then
    ln_imp01_fij := nvl(an_monfij_01,0) / an_tipcam_01 ;
    ln_imp02_fij := nvl(an_monfij_02,0) / an_tipcam_02 ;
    ln_imp03_fij := nvl(an_monfij_03,0) / an_tipcam_03 ;
    ln_imp04_fij := nvl(an_monfij_04,0) / an_tipcam_04 ;
    ln_imp05_fij := nvl(an_monfij_05,0) / an_tipcam_05 ;
    ln_imp06_fij := nvl(an_monfij_06,0) / an_tipcam_06 ;
    ln_imp07_fij := nvl(an_monfij_07,0) / an_tipcam_07 ;
    ln_imp08_fij := nvl(an_monfij_08,0) / an_tipcam_08 ;
    ln_imp09_fij := nvl(an_monfij_09,0) / an_tipcam_09 ;
    ln_imp10_fij := nvl(an_monfij_10,0) / an_tipcam_10 ;
    ln_imp11_fij := nvl(an_monfij_11,0) / an_tipcam_11 ;
    ln_imp12_fij := nvl(an_monfij_12,0) / an_tipcam_12 ;
    insert into tt_presupuesto_planilla_det (
      codigo, cencos, cuenta, imp_01, imp_02,
      imp_03, imp_04, imp_05, imp_06, imp_07,
      imp_08, imp_09, imp_10, imp_11, imp_12 )
    values (
      ls_codigo, ls_cencos, ls_cuenta, ln_imp01_fij, ln_imp02_fij,
      ln_imp03_fij, ln_imp04_fij, ln_imp05_fij, ln_imp06_fij, ln_imp07_fij,
      ln_imp08_fij, ln_imp09_fij, ln_imp10_fij, ln_imp11_fij, ln_imp12_fij ) ;
  end if ;

  --  **************************************************
  --  ***   CALCULA GANANCIAS FIJAS POR TRABAJADOR   ***
  --  **************************************************
  ln_imp01_fij := 0 ;  ln_imp02_fij := 0 ;  ln_imp03_fij := 0 ;
  ln_imp04_fij := 0 ;  ln_imp05_fij := 0 ;  ln_imp06_fij := 0 ;
  ln_imp07_fij := 0 ;  ln_imp08_fij := 0 ;  ln_imp09_fij := 0 ;
  ln_imp10_fij := 0 ;  ln_imp11_fij := 0 ;  ln_imp12_fij := 0 ;
  for rc_gan in c_ganancias loop
    ln_importe  := nvl(rc_gan.imp_gan_desc,0) ;
    if ls_bonificacion = '1' then
      ln_importe := ln_importe * 1.30 ;
    elsif ls_bonificacion = '2' then
      ln_importe := ln_importe * 1.25 ;
    end if ;
    select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
      into ls_cuenta_emp, ls_cuenta_obr
      from concepto c where c.concep = rc_gan.concep ;
    if ls_tipo_trabaj = 'EMP' then
      ls_cuenta := ls_cuenta_emp ;
      if ls_cuenta <> ' ' then
        ln_imp01_fij := (ln_importe * nvl(an_factor_01,1)) / an_tipcam_01 ;
        ln_imp02_fij := (ln_importe * nvl(an_factor_02,1)) / an_tipcam_02 ;
        ln_imp03_fij := (ln_importe * nvl(an_factor_03,1)) / an_tipcam_03 ;
        ln_imp04_fij := (ln_importe * nvl(an_factor_04,1)) / an_tipcam_04 ;
        ln_imp05_fij := (ln_importe * nvl(an_factor_05,1)) / an_tipcam_05 ;
        ln_imp06_fij := (ln_importe * nvl(an_factor_06,1)) / an_tipcam_06 ;
        ln_imp07_fij := (ln_importe * nvl(an_factor_07,1)) / an_tipcam_07 ;
        ln_imp08_fij := (ln_importe * nvl(an_factor_08,1)) / an_tipcam_08 ;
        ln_imp09_fij := (ln_importe * nvl(an_factor_09,1)) / an_tipcam_09 ;
        ln_imp10_fij := (ln_importe * nvl(an_factor_10,1)) / an_tipcam_10 ;
        ln_imp11_fij := (ln_importe * nvl(an_factor_11,1)) / an_tipcam_11 ;
        ln_imp12_fij := (ln_importe * nvl(an_factor_12,1)) / an_tipcam_12 ;
        insert into tt_presupuesto_planilla_det (
          codigo, cencos, cuenta, imp_01, imp_02,
          imp_03, imp_04, imp_05, imp_06, imp_07,
          imp_08, imp_09, imp_10, imp_11, imp_12 )
        values (
          ls_codigo, ls_cencos, ls_cuenta, ln_imp01_fij, ln_imp02_fij,
          ln_imp03_fij, ln_imp04_fij, ln_imp05_fij, ln_imp06_fij, ln_imp07_fij,
          ln_imp08_fij, ln_imp09_fij, ln_imp10_fij, ln_imp11_fij, ln_imp12_fij ) ;
      end if ;
    elsif ls_tipo_trabaj = 'OBR' then
      ls_cuenta := ls_cuenta_obr ;
      if ls_cuenta <> ' ' then
        ln_imp_dia   := ln_importe / 30 ;
        ln_imp01_fij := ((ln_importe + ln_imp_dia) * nvl(an_factor_01,1)) / an_tipcam_01 ;
        ln_imp02_fij := (ln_importe * nvl(an_factor_02,1)) / an_tipcam_02 ;
        ln_imp03_fij := ((ln_importe + ln_imp_dia) * nvl(an_factor_03,1)) / an_tipcam_03 ;
        ln_imp04_fij := (ln_importe * nvl(an_factor_04,1)) / an_tipcam_04 ;
        ln_imp05_fij := ((ln_importe + ln_imp_dia) * nvl(an_factor_05,1)) / an_tipcam_05 ;
        ln_imp06_fij := (ln_importe * nvl(an_factor_06,1)) / an_tipcam_06 ;
        ln_imp07_fij := ((ln_importe + ln_imp_dia) * nvl(an_factor_07,1)) / an_tipcam_07 ;
        ln_imp08_fij := ((ln_importe + ln_imp_dia) * nvl(an_factor_08,1)) / an_tipcam_08 ;
        ln_imp09_fij := (ln_importe * nvl(an_factor_09,1)) / an_tipcam_09 ;
        ln_imp10_fij := ((ln_importe + ln_imp_dia) * nvl(an_factor_10,1)) / an_tipcam_10 ;
        ln_imp11_fij := (ln_importe * nvl(an_factor_11,1)) / an_tipcam_11 ;
        ln_imp12_fij := ((ln_importe + ln_imp_dia) * nvl(an_factor_12,1)) / an_tipcam_12 ;
        insert into tt_presupuesto_planilla_det (
          codigo, cencos, cuenta, imp_01, imp_02,
          imp_03, imp_04, imp_05, imp_06, imp_07,
          imp_08, imp_09, imp_10, imp_11, imp_12 )
        values (
          ls_codigo, ls_cencos, ls_cuenta, ln_imp01_fij, ln_imp02_fij,
          ln_imp03_fij, ln_imp04_fij, ln_imp05_fij, ln_imp06_fij, ln_imp07_fij,
          ln_imp08_fij, ln_imp09_fij, ln_imp10_fij, ln_imp11_fij, ln_imp12_fij ) ;
      end if ;
    end if ;
    ln_imp01_fix := ln_imp01_fix + ln_imp01_fij ;
    ln_imp02_fix := ln_imp02_fix + ln_imp02_fij ;
    ln_imp03_fix := ln_imp03_fix + ln_imp03_fij ;
    ln_imp04_fix := ln_imp04_fix + ln_imp04_fij ;
    ln_imp05_fix := ln_imp05_fix + ln_imp05_fij ;
    ln_imp06_fix := ln_imp06_fix + ln_imp06_fij ;
    ln_imp07_fix := ln_imp07_fix + ln_imp07_fij ;
    ln_imp08_fix := ln_imp08_fix + ln_imp08_fij ;
    ln_imp09_fix := ln_imp09_fix + ln_imp09_fij ;
    ln_imp10_fix := ln_imp10_fix + ln_imp10_fij ;
    ln_imp11_fix := ln_imp11_fix + ln_imp11_fij ;
    ln_imp12_fix := ln_imp12_fix + ln_imp12_fij ;
  end loop ;

  --  ******************************************************************
  --  ***   GENERA GANANCIAS VARIABLES APLICANDO PROMEDIOS SIMPLES   ***
  --  ******************************************************************
  ln_imp01_var := 0 ;  ln_imp02_var := 0 ;  ln_imp03_var := 0 ;
  ln_imp04_var := 0 ;  ln_imp05_var := 0 ;  ln_imp06_var := 0 ;
  ln_imp07_var := 0 ;  ln_imp08_var := 0 ;  ln_imp09_var := 0 ;
  ln_imp10_var := 0 ;  ln_imp11_var := 0 ;  ln_imp12_var := 0 ;
  ln_imp01_vax := 0 ;  ln_imp02_vax := 0 ;  ln_imp03_vax := 0 ;
  ln_imp04_vax := 0 ;  ln_imp05_vax := 0 ;  ln_imp06_vax := 0 ;
  ln_imp07_vax := 0 ;  ln_imp08_vax := 0 ;  ln_imp09_vax := 0 ;
  ln_imp10_vax := 0 ;  ln_imp11_vax := 0 ;  ln_imp12_vax := 0 ;
  ln_gan_variables := 0 ;
  for rc_con in c_concepto loop
    ld_ran_ini   := add_months(ld_fec_proceso, - 1) ;
    ln_nro_meses := 0 ; ln_acumulado := 0 ;
    for x in reverse 1 .. 6 loop
      ld_ran_fin := ld_ran_ini ;
      ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
      ln_importe := 0 ; ln_contador := 0 ;
      select count(*)
        into ln_contador
        from historico_calculo hc 
        where hc.concep = rc_con.concep and hc.cod_trabajador = ls_codigo and 
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
      if ln_contador > 0 then 
        select sum( hc.imp_soles)
          into ln_importe
          from historico_calculo hc 
          where hc.concep = rc_con.concep and hc.cod_trabajador = ls_codigo and
                hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
        if rc_con.concep = '1013' then
          if ls_seccion <> '682' or ls_seccion <> '683' then
            ln_importe := 0 ;
          end if ;
        end if ;
        if ln_importe <> 0 then 
          ln_nro_meses := ln_nro_meses + 1 ;
          ln_acumulado := ln_acumulado + ln_importe ;
        end if ; 
      end if ;
      ld_ran_ini := ld_ran_ini - 1 ;
    end loop ;
    if ln_nro_meses > 0 then
      if ln_nro_meses = 6 then
        ln_nro_meses := 9 ;
      end if ;
      ln_importe       := ln_acumulado / ln_nro_meses ;
      ln_gan_variables := ln_gan_variables + ln_importe ;
    end if ;
  end loop ;
  if ln_gan_variables <> 0 then
    if ls_bonificacion = '1' then
      ln_imp01_vax := (ln_gan_variables / an_tipcam_01) * 0.35 ;
      ln_imp02_vax := (ln_gan_variables / an_tipcam_02) * 0.35 ;
      ln_imp03_vax := (ln_gan_variables / an_tipcam_03) * 0.35 ;
      ln_imp04_vax := (ln_gan_variables / an_tipcam_04) * 0.35 ;
      ln_imp05_vax := (ln_gan_variables / an_tipcam_05) * 0.35 ;
      ln_imp06_vax := (ln_gan_variables / an_tipcam_06) * 0.35 ;
      ln_imp07_vax := (ln_gan_variables / an_tipcam_07) * 0.35 ;
      ln_imp08_vax := (ln_gan_variables / an_tipcam_08) * 0.35 ;
      ln_imp09_vax := (ln_gan_variables / an_tipcam_09) * 0.35 ;
      ln_imp10_vax := (ln_gan_variables / an_tipcam_10) * 0.35 ;
      ln_imp11_vax := (ln_gan_variables / an_tipcam_11) * 0.35 ;
      ln_imp12_vax := (ln_gan_variables / an_tipcam_12) * 0.35 ;
      select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
        into ls_cuenta_emp, ls_cuenta_obr
        from concepto c where c.concep = '1001' ;
      if ls_tipo_trabaj = 'EMP' then
        ls_cuenta := ls_cuenta_emp ;
      elsif ls_tipo_trabaj = 'OBR' then
        ls_cuenta := ls_cuenta_obr ;
      end if ;
      if ls_cuenta <> ' ' then
        insert into tt_presupuesto_planilla_det (
          codigo, cencos, cuenta, imp_01, imp_02,
          imp_03, imp_04, imp_05, imp_06, imp_07,
          imp_08, imp_09, imp_10, imp_11, imp_12 )
        values (
          ls_codigo, ls_cencos, ls_cuenta, ln_imp01_vax, ln_imp02_vax,
          ln_imp03_vax, ln_imp04_vax, ln_imp05_vax, ln_imp06_vax, ln_imp07_vax,
          ln_imp08_vax, ln_imp09_vax, ln_imp10_vax, ln_imp11_vax, ln_imp12_vax ) ;
      end if ;
    elsif ls_bonificacion = '2' then
      ln_imp01_vax := (ln_gan_variables / an_tipcam_01) * 0.30 ;
      ln_imp02_vax := (ln_gan_variables / an_tipcam_02) * 0.30 ;
      ln_imp03_vax := (ln_gan_variables / an_tipcam_03) * 0.30 ;
      ln_imp04_vax := (ln_gan_variables / an_tipcam_04) * 0.30 ;
      ln_imp05_vax := (ln_gan_variables / an_tipcam_05) * 0.30 ;
      ln_imp06_vax := (ln_gan_variables / an_tipcam_06) * 0.30 ;
      ln_imp07_vax := (ln_gan_variables / an_tipcam_07) * 0.30 ;
      ln_imp08_vax := (ln_gan_variables / an_tipcam_08) * 0.30 ;
      ln_imp09_vax := (ln_gan_variables / an_tipcam_09) * 0.30 ;
      ln_imp10_vax := (ln_gan_variables / an_tipcam_10) * 0.30 ;
      ln_imp11_vax := (ln_gan_variables / an_tipcam_11) * 0.30 ;
      ln_imp12_vax := (ln_gan_variables / an_tipcam_12) * 0.30 ;
      select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
        into ls_cuenta_emp, ls_cuenta_obr
        from concepto c where c.concep = '1001' ;
      if ls_tipo_trabaj = 'EMP' then
        ls_cuenta := ls_cuenta_emp ;
      elsif ls_tipo_trabaj = 'OBR' then
        ls_cuenta := ls_cuenta_obr ;
      end if ;
      if ls_cuenta <> ' ' then
        insert into tt_presupuesto_planilla_det (
          codigo, cencos, cuenta, imp_01, imp_02,
          imp_03, imp_04, imp_05, imp_06, imp_07,
          imp_08, imp_09, imp_10, imp_11, imp_12 )
        values (
          ls_codigo, ls_cencos, ls_cuenta, ln_imp01_vax, ln_imp02_vax,
          ln_imp03_vax, ln_imp04_vax, ln_imp05_vax, ln_imp06_vax, ln_imp07_vax,
          ln_imp08_vax, ln_imp09_vax, ln_imp10_vax, ln_imp11_vax, ln_imp12_vax ) ;
      end if ;
    end if ;
    select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
      into ls_cuenta_emp, ls_cuenta_obr
      from concepto c where c.concep = '1101' ;
    if ls_tipo_trabaj = 'EMP' then
      ls_cuenta := ls_cuenta_emp ;
    elsif ls_tipo_trabaj = 'OBR' then
      ls_cuenta := ls_cuenta_obr ;
    end if ;
    ln_imp01_var := (ln_gan_variables * nvl(an_factor_01,1)) / an_tipcam_01 ;
    ln_imp02_var := (ln_gan_variables * nvl(an_factor_02,1)) / an_tipcam_02 ;
    ln_imp03_var := (ln_gan_variables * nvl(an_factor_03,1)) / an_tipcam_03 ;
    ln_imp04_var := (ln_gan_variables * nvl(an_factor_04,1)) / an_tipcam_04 ;
    ln_imp05_var := (ln_gan_variables * nvl(an_factor_05,1)) / an_tipcam_05 ;
    ln_imp06_var := (ln_gan_variables * nvl(an_factor_06,1)) / an_tipcam_06 ;
    ln_imp07_var := (ln_gan_variables * nvl(an_factor_07,1)) / an_tipcam_07 ;
    ln_imp08_var := (ln_gan_variables * nvl(an_factor_08,1)) / an_tipcam_08 ;
    ln_imp09_var := (ln_gan_variables * nvl(an_factor_09,1)) / an_tipcam_09 ;
    ln_imp10_var := (ln_gan_variables * nvl(an_factor_10,1)) / an_tipcam_10 ;
    ln_imp11_var := (ln_gan_variables * nvl(an_factor_11,1)) / an_tipcam_11 ;
    ln_imp12_var := (ln_gan_variables * nvl(an_factor_12,1)) / an_tipcam_12 ;
    insert into tt_presupuesto_planilla_det (
      codigo, cencos, cuenta, imp_01, imp_02,
      imp_03, imp_04, imp_05, imp_06, imp_07,
      imp_08, imp_09, imp_10, imp_11, imp_12 )
    values (
      ls_codigo, ls_cencos, ls_cuenta, ln_imp01_var, ln_imp02_var,
      ln_imp03_var, ln_imp04_var, ln_imp05_var, ln_imp06_var, ln_imp07_var,
      ln_imp08_var, ln_imp09_var, ln_imp10_var, ln_imp11_var, ln_imp12_var ) ;
  end if ;

  --  *********************************************************
  --  ***   GENERA GRATIFICACIONES PARA JULIO Y DICIEMBRE   ***
  --  *********************************************************
  if ls_tipo_trabaj = 'EMP' then
    ln_gratif_jul := (ln_imp07_fix + ln_imp07_var) ;
    ln_gratif_dic := (ln_imp12_fix + ln_imp12_var) ;
  elsif ls_tipo_trabaj = 'OBR' then
    ln_gratif_jul := (((ln_imp07_fix / 31) * 30) + ln_imp07_var) ;
    ln_gratif_dic := (((ln_imp12_fix / 31) * 30) + ln_imp12_var) ;
  end if ;
  select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
    into ls_cuenta_emp, ls_cuenta_obr
    from concepto c where c.concep = '1410' ;
  if ls_tipo_trabaj = 'EMP' then
    ls_cuenta := ls_cuenta_emp ;
  elsif ls_tipo_trabaj = 'OBR' then
    ls_cuenta := ls_cuenta_obr ;
  end if ;
  insert into tt_presupuesto_planilla_det (
    codigo, cencos, cuenta, imp_01, imp_02,
    imp_03, imp_04, imp_05, imp_06, imp_07,
    imp_08, imp_09, imp_10, imp_11, imp_12 )
  values (
    ls_codigo, ls_cencos, ls_cuenta, 0, 0,
    0, 0, 0, 0, ln_gratif_jul,
    0, 0, 0, 0, ln_gratif_dic ) ;
  
  --  ***************************************************
  --  ***   CALCULO DE BONIFICACION POR QUINQUENIOS   ***
  --  ***************************************************
  ln_imp01_qui := 0 ;  ln_imp02_qui := 0 ;  ln_imp03_qui := 0 ;
  ln_imp04_qui := 0 ;  ln_imp05_qui := 0 ;  ln_imp06_qui := 0 ;
  ln_imp07_qui := 0 ;  ln_imp08_qui := 0 ;  ln_imp09_qui := 0 ;
  ln_imp10_qui := 0 ;  ln_imp11_qui := 0 ;  ln_imp12_qui := 0 ;
  ld_fec_quinque := to_date(to_char(ld_fec_ingreso,'DD')||'/'||
                    to_char(ld_fec_ingreso,'MM')||'/'||
                    to_char(an_periodo),'DD/MM/YYYY') ;
  ln_anios := months_between(ld_fec_quinque,ld_fec_ingreso) / 12 ;
  if ln_anios > 5 then 
    ln_quinquenio := trunc(ln_anios) ; ln_contador := 0 ;
    select count(*)
      into ln_contador
      from quinquenio q
      where q.quinquenio = ln_quinquenio and
            to_char(ld_fec_ingreso,'MM') = to_char(ld_fec_quinque,'MM') ;
    if ln_contador > 0 then
      select nvl(q.jornal,0)
        into ln_jornal
        from quinquenio q
        where q.quinquenio = ln_quinquenio;
      if ls_mes_ingreso = '01' then
        ln_imp01_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '02' then
        ln_imp02_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '03' then
        ln_imp03_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '04' then
        ln_imp04_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '05' then
        ln_imp05_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '06' then
        ln_imp06_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '07' then
        ln_imp07_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '08' then
        ln_imp08_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '09' then
        ln_imp09_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '10' then
        ln_imp10_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '11' then
        ln_imp11_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      elsif ls_mes_ingreso = '12' then
        ln_imp12_qui := (ln_imp04_fix / 30 * ln_jornal) ;
      end if ;
      select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
        into ls_cuenta_emp, ls_cuenta_obr
        from concepto c where c.concep = '1408' ;
      if ls_tipo_trabaj = 'EMP' then
        ls_cuenta := ls_cuenta_emp ;
      elsif ls_tipo_trabaj = 'OBR' then
        ls_cuenta := ls_cuenta_obr ;
      end if ;
      insert into tt_presupuesto_planilla_det (
        codigo, cencos, cuenta, imp_01, imp_02,
        imp_03, imp_04, imp_05, imp_06, imp_07,
        imp_08, imp_09, imp_10, imp_11, imp_12 )
      values (
        ls_codigo, ls_cencos, ls_cuenta, ln_imp01_qui, ln_imp02_qui,
        ln_imp03_qui, ln_imp04_qui, ln_imp05_qui, ln_imp06_qui, ln_imp07_qui,
        ln_imp08_qui, ln_imp09_qui, ln_imp10_qui, ln_imp11_qui, ln_imp12_qui ) ;
    end if ;
  end if ;
  
  --  **********************************************************
  --  ***   CALCULA ASIGNACION ESCOLAR POR NUMERO DE HIJOS   ***
  --  **********************************************************
  ln_contador := 0 ; ln_importe := 0 ;
  select count(*)
    into ln_contador
    from carga_familiar f
    where f.cod_trabajador = ls_codigo ;
  if ln_contador > 0 then
    ln_nro_meses := 0 ;
    for rc_car in c_carga loop
      ld_fec_asiesc := to_date('31'||'/'||'12'||'/'||
                       to_char(an_periodo),'DD/MM/YYYY') ;
      ln_anios := months_between(ld_fec_asiesc,rc_car.fec_nacimiento) / 12 ;
      if ln_anios >= 3 and ln_anios < 23 then
        ln_nro_meses := ln_nro_meses + 1 ;
      end if;
    end loop ;
    if ln_nro_meses > 0 then
      ln_importe := (an_asiesc / an_tipcam_03) * ln_nro_meses ;
      select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
        into ls_cuenta_emp, ls_cuenta_obr
        from concepto c where c.concep = '1418' ;
      if ls_tipo_trabaj = 'EMP' then
        ls_cuenta := ls_cuenta_emp ;
      elsif ls_tipo_trabaj = 'OBR' then
        ls_cuenta := ls_cuenta_obr ;
      end if ;
      insert into tt_presupuesto_planilla_det (
        codigo, cencos, cuenta, imp_01, imp_02,
        imp_03, imp_04, imp_05, imp_06, imp_07,
        imp_08, imp_09, imp_10, imp_11, imp_12 )
      values (
        ls_codigo, ls_cencos, ls_cuenta, 0, 0,
        ln_importe, 0, 0, 0, 0,
        0, 0, 0, 0, 0 ) ;
    end if ;
  end if;
  
  --  *************************************************************
  --  ***   CALCULA APORTACIONES DE LA EMPRESA POR TRABAJADOR   ***
  --  *************************************************************
  ln_imp01_apo := 0 ;  ln_imp02_apo := 0 ;  ln_imp03_apo := 0 ;
  ln_imp04_apo := 0 ;  ln_imp05_apo := 0 ;  ln_imp06_apo := 0 ;
  ln_imp07_apo := 0 ;  ln_imp08_apo := 0 ;  ln_imp09_apo := 0 ;
  ln_imp10_apo := 0 ;  ln_imp11_apo := 0 ;  ln_imp12_apo := 0 ;
  ln_contador  := 0 ;  ln_bonvac    := 0 ;  ln_importe   := 0 ;
  select count(*)
    into ln_contador
    from vacac_bonif_deveng b
    where b.cod_trabajador = ls_codigo and b.flag_estado = '1' ;
  if ln_contador > 0 then
    select sum(nvl(b.sldo_dias_bonif,0))
      into ln_bonvac
      from vacac_bonif_deveng b
      where b.cod_trabajador = ls_codigo and b.flag_estado = '1' ;
    ln_importe := ln_imp01_fij * (ln_bonvac / 30) ;
  end if ;
  --  Seguro Agrario
  ln_factor := 0 ;
  select nvl(c.fact_pago,0), nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
    into ln_factor, ls_cuenta_emp, ls_cuenta_obr
    from concepto c where c.concep = '3002' ;
  ln_imp01_apo := (ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor ;
  ln_imp02_apo := (ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor ;
  ln_imp03_apo := (ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor ;
  ln_imp04_apo := (ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor ;
  ln_imp05_apo := (ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor ;
  ln_imp06_apo := (ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor ;
  ln_imp07_apo := (ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor ;
  ln_imp08_apo := (ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor ;
  ln_imp09_apo := (ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor ;
  ln_imp10_apo := (ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor ;
  ln_imp11_apo := (ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor ;
  ln_imp12_apo := (ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor ;
  --  SENATI
  if ls_seccion = '700' or ls_seccion = '710' or ls_seccion = '720' or
     ls_seccion = '730' or ls_seccion = '732' or ls_seccion = '740' or
     ls_seccion = '741' or ls_seccion = '743' or ls_seccion = '744' or
     ls_seccion = '745' or ls_seccion = '746' or ls_seccion = '731' then
     select nvl(c.fact_pago,0)
       into ln_factor
       from concepto c where c.concep = '3003' ;
     ln_imp01_apo := ln_imp01_apo + ((ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor) ;
     ln_imp02_apo := ln_imp02_apo + ((ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor) ;
     ln_imp03_apo := ln_imp03_apo + ((ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor) ;
     ln_imp04_apo := ln_imp04_apo + ((ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor) ;
     ln_imp05_apo := ln_imp05_apo + ((ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor) ;
     ln_imp06_apo := ln_imp06_apo + ((ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor) ;
     ln_imp07_apo := ln_imp07_apo + ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor) ;
     ln_imp08_apo := ln_imp08_apo + ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor) ;
     ln_imp09_apo := ln_imp09_apo + ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor) ;
     ln_imp10_apo := ln_imp10_apo + ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor) ;
     ln_imp11_apo := ln_imp11_apo + ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor) ;
     ln_imp12_apo := ln_imp12_apo + ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor) ;
  end if ;
  --  S.C.T.R. I.P.S.S.  
  ln_factor := 0 ;
  select nvl(s.porc_sctr_ipss,0)
    into ln_factor
    from seccion s where s.cod_seccion = ls_seccion ;
  if ln_factor > 0 then
    ln_imp01_apo := ln_imp01_apo + ((ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor / 100) ;
    ln_imp02_apo := ln_imp02_apo + ((ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor / 100) ;
    ln_imp03_apo := ln_imp03_apo + ((ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor / 100) ;
    ln_imp04_apo := ln_imp04_apo + ((ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor / 100) ;
    ln_imp05_apo := ln_imp05_apo + ((ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor / 100) ;
    ln_imp06_apo := ln_imp06_apo + ((ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor / 100) ;
    ln_imp07_apo := ln_imp07_apo + ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor / 100) ;
    ln_imp08_apo := ln_imp08_apo + ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor / 100) ;
    ln_imp09_apo := ln_imp09_apo + ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor / 100) ;
    ln_imp10_apo := ln_imp10_apo + ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor / 100) ;
    ln_imp11_apo := ln_imp11_apo + ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor / 100) ;
    ln_imp12_apo := ln_imp12_apo + ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor / 100) ;
  end if ;
  --  S.C.T.R. O.N.P.
  ln_factor := 0 ;
  select nvl(s.porc_sctr_onp,0)
    into ln_factor
    from seccion s where s.cod_seccion = ls_seccion ;
  if ln_factor > 0 then
    ln_imp01_apo := ln_imp01_apo + ((ln_imp01_fix + ln_importe + ln_imp01_var + ln_imp01_vax + ln_imp01_qui) * ln_factor / 100) ;
    ln_imp02_apo := ln_imp02_apo + ((ln_imp02_fix + ln_imp02_var + ln_imp02_vax + ln_imp02_qui) * ln_factor / 100) ;
    ln_imp03_apo := ln_imp03_apo + ((ln_imp03_fix + ln_imp03_var + ln_imp03_vax + ln_imp03_qui) * ln_factor / 100) ;
    ln_imp04_apo := ln_imp04_apo + ((ln_imp04_fix + ln_imp04_var + ln_imp04_vax + ln_imp04_qui) * ln_factor / 100) ;
    ln_imp05_apo := ln_imp05_apo + ((ln_imp05_fix + ln_imp05_var + ln_imp05_vax + ln_imp05_qui) * ln_factor / 100) ;
    ln_imp06_apo := ln_imp06_apo + ((ln_imp06_fix + ln_imp06_var + ln_imp06_vax + ln_imp06_qui) * ln_factor / 100) ;
    ln_imp07_apo := ln_imp07_apo + ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul + ln_imp07_qui) * ln_factor / 100) ;
    ln_imp08_apo := ln_imp08_apo + ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax + ln_imp08_qui) * ln_factor / 100) ;
    ln_imp09_apo := ln_imp09_apo + ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax + ln_imp09_qui) * ln_factor / 100) ;
    ln_imp10_apo := ln_imp10_apo + ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax + ln_imp10_qui) * ln_factor / 100) ;
    ln_imp11_apo := ln_imp11_apo + ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax + ln_imp11_qui) * ln_factor / 100) ;
    ln_imp12_apo := ln_imp12_apo + ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic + ln_imp12_qui) * ln_factor / 100) ;
  end if ;
  if ls_tipo_trabaj = 'EMP' then
    ls_cuenta := ls_cuenta_emp ;
  elsif ls_tipo_trabaj = 'OBR' then
    ls_cuenta := ls_cuenta_obr ;
  end if ;
  insert into tt_presupuesto_planilla_det (
    codigo, cencos, cuenta, imp_01, imp_02,
    imp_03, imp_04, imp_05, imp_06, imp_07,
    imp_08, imp_09, imp_10, imp_11, imp_12 )
  values (
    ls_codigo, ls_cencos, ls_cuenta, ln_imp01_apo, ln_imp02_apo,
    ln_imp03_apo, ln_imp04_apo, ln_imp05_apo, ln_imp06_apo, ln_imp07_apo,
    ln_imp08_apo, ln_imp09_apo, ln_imp10_apo, ln_imp11_apo, ln_imp12_apo ) ;

  --  ********************************************
  --  ***   CALCULO DE PROVISIONES DE C.T.S.   ***
  --  ********************************************
  ln_imp01_cts := 0 ;  ln_imp02_cts := 0 ;  ln_imp03_cts := 0 ;
  ln_imp04_cts := 0 ;  ln_imp05_cts := 0 ;  ln_imp06_cts := 0 ;
  ln_imp07_cts := 0 ;  ln_imp08_cts := 0 ;  ln_imp09_cts := 0 ;
  ln_imp10_cts := 0 ;  ln_imp11_cts := 0 ;  ln_imp12_cts := 0 ;
  ln_imp01_cts := ((ln_imp01_fix + ln_imp01_var + ln_imp01_vax) * 0.0833) ;
  ln_imp02_cts := ((ln_imp02_fix + ln_imp02_var + ln_imp02_vax) * 0.0833) ;
  ln_imp03_cts := ((ln_imp03_fix + ln_imp03_var + ln_imp03_vax) * 0.0833) ;
  ln_imp04_cts := ((ln_imp04_fix + ln_imp04_var + ln_imp04_vax) * 0.0833) ;
  ln_imp05_cts := ((ln_imp05_fix + ln_imp05_var + ln_imp05_vax) * 0.0833) ;
  ln_imp06_cts := ((ln_imp06_fix + ln_imp06_var + ln_imp06_vax) * 0.0833) ;
  ln_imp07_cts := ((ln_imp07_fix + ln_imp07_var + ln_imp07_vax + ln_gratif_jul) * 0.0833) ;
  ln_imp08_cts := ((ln_imp08_fix + ln_imp08_var + ln_imp08_vax) * 0.0833) ;
  ln_imp09_cts := ((ln_imp09_fix + ln_imp09_var + ln_imp09_vax) * 0.0833) ;
  ln_imp10_cts := ((ln_imp10_fix + ln_imp10_var + ln_imp10_vax) * 0.0833) ;
  ln_imp11_cts := ((ln_imp11_fix + ln_imp11_var + ln_imp11_vax) * 0.0833) ;
  ln_imp12_cts := ((ln_imp12_fix + ln_imp12_var + ln_imp12_vax + ln_gratif_dic) * 0.0833) ;
  select nvl(c.cnta_prsp,' '), nvl(c.cnta_prsp_obr,' ')
    into ls_cuenta_emp, ls_cuenta_obr
    from concepto c where c.concep = '4003' ;
  if ls_tipo_trabaj = 'EMP' then
    ls_cuenta := ls_cuenta_emp ;
  elsif ls_tipo_trabaj = 'OBR' then
    ls_cuenta := ls_cuenta_obr ;
  end if ;
  insert into tt_presupuesto_planilla_det (
    codigo, cencos, cuenta, imp_01, imp_02,
    imp_03, imp_04, imp_05, imp_06, imp_07,
    imp_08, imp_09, imp_10, imp_11, imp_12 )
  values (
    ls_codigo, ls_cencos, ls_cuenta, ln_imp01_cts, ln_imp02_cts,
    ln_imp03_cts, ln_imp04_cts, ln_imp05_cts, ln_imp06_cts, ln_imp07_cts,
    ln_imp08_cts, ln_imp09_cts, ln_imp10_cts, ln_imp11_cts, ln_imp12_cts ) ;

end loop ;

end usp_presup_plla_calculo_det ;
/
