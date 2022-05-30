create or replace procedure usp_rh_rpt_remun_computable (
  as_tipo_trabajador in char, as_origen in char, ld_fec_desde in date,
  ld_fec_hasta in date ) is

ls_seccion         char(3) ;
ls_descripcion     varchar2(40) ;
ls_codigo          maestro.cod_trabajador%type ;
ls_nombres         varchar2(40) ;
ln_dias            number(5,2) ;
ls_concepto        concepto.concep%type ;
ln_importe         number(13,2) ;
ls_bonif           char(1) ;
ln_contador        number(13) ;
ln_var_acu         number(13,2) ;
ln_var_mes         number(13,2) ;

ln_imp01           number(13,2) ; ln_imp02           number(13,2) ;
ln_imp03           number(13,2) ; ln_imp04           number(13,2) ;
ln_imp05           number(13,2) ; ln_imp06           number(13,2) ;
ln_imp07           number(13,2) ; ln_imp08           number(13,2) ;
ln_imp09           number(13,2) ; ln_imp10           number(13,2) ;
ln_imp11           number(13,2) ; ln_imp12           number(13,2) ;
ln_imp13           number(13,2) ; ln_imp14           number(13,2) ;
ln_imp15           number(13,2) ; ln_imp16           number(13,2) ;
ln_imp17           number(13,2) ; ln_imp18           number(13,2) ;
ln_imp19           number(13,2) ; ln_imp20           number(13,2) ;
ln_imp21           number(13,2) ; ln_imp22           number(13,2) ;

ln_cts01           number(13,2) ; ln_cts02           number(13,2) ;
ln_cts03           number(13,2) ; ln_cts04           number(13,2) ;
ln_cts05           number(13,2) ; ln_cts06           number(13,2) ;

--  Lectura del maestro con trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.bonif_fija_30_25, m.cod_seccion, m.cod_area
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and m.cod_seccion <> '950' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.cod_trabajador ;

--  Cursor de ganancias fijas por trabajador
cursor c_fijos is
  select f.concep, f.imp_gan_desc
  from gan_desct_fijo f
  where f.cod_trabajador = ls_codigo and substr(f.concep,1,2) = '10' and
        f.flag_estado = '1'
  order by f.cod_trabajador, f.concep ;

begin

--  **********************************************************************
--  ***   EMITE REPORTE DE REMUNERACIONES COMPUTABLES POR TRABAJADOR   ***
--  **********************************************************************

delete from tt_rpt_detalle_cts ;
        
for rc_mae in c_maestro loop

  ln_imp01 := 0 ; ln_imp02 := 0 ; ln_imp03 := 0 ; ln_imp04 := 0 ;
  ln_imp05 := 0 ; ln_imp06 := 0 ; ln_imp07 := 0 ; ln_imp08 := 0 ;
  ln_imp09 := 0 ; ln_imp10 := 0 ; ln_imp11 := 0 ; ln_imp12 := 0 ;
  ln_imp13 := 0 ; ln_imp14 := 0 ; ln_imp15 := 0 ; ln_imp16 := 0 ;
  ln_imp17 := 0 ; ln_imp18 := 0 ; ln_imp19 := 0 ; ln_imp20 := 0 ;
  ln_imp21 := 0 ; ln_imp22 := 0 ;

  ln_var_acu := 0 ; ln_var_mes := 0 ; ln_dias := 0 ;

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_bonif   := nvl(rc_mae.bonif_fija_30_25,'0') ;
  ls_nombres := usf_rh_nombre_trabajador(ls_codigo) ;
       
  select s.desc_seccion into ls_descripcion from seccion s
    where s.cod_area = rc_mae.cod_area and s.cod_seccion = ls_seccion ;

  for rc_fij in c_fijos loop

    ls_concepto := rc_fij.concep ;
    ln_importe  := nvl(rc_fij.imp_gan_desc,0) ;
    
    if ls_concepto = '1001' then
      ln_imp01 := ln_importe ;
    elsif ls_concepto = '1002' then
      ln_imp02 := ln_importe;
    elsif ls_concepto = '1003' then
      ln_imp03 := ln_importe;
    elsif ls_concepto = '1004' then
      ln_imp04 := ln_importe;
    elsif ls_concepto = '1005' then
      ln_imp05 := ln_importe;
    elsif ls_concepto = '1006' then
      ln_imp06 := ln_importe;
    elsif ls_concepto = '1007' then
      ln_imp07 := ln_importe;
    elsif ls_concepto = '1008' then
      ln_imp08 := ln_importe;
    elsif ls_concepto = '1009' then
      ln_imp09 := ln_importe;
    elsif ls_concepto = '1010' then
      ln_imp10 := ln_importe;
    elsif ls_concepto = '1011' then
      ln_imp11 := ln_importe;
    elsif ls_concepto = '1012' then
      ln_imp12 := ln_importe;
    elsif ls_concepto = '1013' then
      ln_imp13 := ln_importe;
    elsif ls_concepto = '1014' then
      ln_imp14 := ln_importe;
    elsif ls_concepto = '1015' then
      ln_imp15 := ln_importe;
    elsif ls_concepto = '1016' then
      ln_imp16 := ln_importe;
    end if ;
    
  end loop ;

  --  Suma ganancias variables del periodo semestral
  ln_contador := 0 ;
  select count(*) into ln_contador from historico_calculo hc
  where hc.cod_trabajador = ls_codigo and substr(hc.concep,1,2) = '14' and
        hc.fec_calc_plan between ld_fec_desde and ld_fec_hasta and
        hc.concep <> '1407' and hc.concep <> '1410' and hc.concep <> '1411' and
        hc.concep <> '1412' and hc.concep <> '1450' ;
  if ln_contador > 0 then
    select sum(hc.imp_soles) into ln_var_acu from historico_calculo hc
    where hc.cod_trabajador = ls_codigo and substr(hc.concep,1,2) = '14' and
          hc.fec_calc_plan between ld_fec_desde and ld_fec_hasta and
          hc.concep <> '1407' and hc.concep <> '1410' and hc.concep <> '1411' and
          hc.concep <> '1412' and hc.concep <> '1450' 
    order by hc.cod_trabajador, hc.concep ;
    ln_var_acu := nvl(ln_var_acu,0) ;
  end if ;
  
  --  Suma ganancias variables del mes
  ln_contador := 0 ;
  select count(*) into ln_contador from calculo c
  where c.cod_trabajador = ls_codigo and substr(c.concep,1,2) = '14' and
        c.fec_proceso = ld_fec_hasta and c.concep <> '1407' and
        c.concep <> '1410' and c.concep <> '1411' and c.concep <> '1412' and
        c.concep <> '1450' ;
  if ln_contador > 0 then
    select sum(c.imp_soles) into ln_var_mes from calculo c
    where c.cod_trabajador = ls_codigo and substr(c.concep,1,2) = '14' and
          c.fec_proceso = ld_fec_hasta and c.concep <> '1407' and
          c.concep <> '1410' and c.concep <> '1411' and c.concep <> '1412' and
          c.concep <> '1450' 
    order by c.cod_trabajador, c.concep ;
    ln_var_mes := nvl(ln_var_mes,0) ;
  end if ;
  
  ln_imp17 := (ln_var_acu + ln_var_mes) / 6 ;

  ln_imp21 := ln_imp01 + ln_imp02 + ln_imp03 + ln_imp04 + ln_imp05 + ln_imp06 +
              ln_imp07 + ln_imp08 + ln_imp09 + ln_imp10 + ln_imp11 + ln_imp12 +
              ln_imp13 + ln_imp14 + ln_imp15 + ln_imp16 + ln_imp17 ;

  --  Calcula bonificacion 25% o 30%
  if ls_bonif = '2' then
    ln_imp18 := ln_imp21 * 0.25 ;
    ln_imp21 := ln_imp21 + ln_imp18 ;
  elsif ls_bonif = '1' then
    ln_imp19 := ln_imp21 * 0.30 ;
    ln_imp21 := ln_imp21 + ln_imp19 ;
  end if ;
  
  --  Halla ultimo pago de gratificacion
  ln_contador := 0 ;
  select count(*) into ln_contador from gratificacion g
    where g.cod_trabajador = ls_codigo ;
  if ln_contador > 0 then
    select g.imp_bruto into ln_imp20 from gratificacion g
      where g.cod_trabajador = ls_codigo ;
    ln_imp20 := nvl(ln_imp20,0) ;
    ln_imp21 := ln_imp21 + ln_imp20 ;
  end if ;
  
  --  Halla numero de dias y deposito del semestre
  ln_contador := 0 ;
  select count(*) into ln_contador from prov_cts_gratif pcg
    where pcg.cod_trabajador = ls_codigo and pcg.flag_estado = '1' ;
  if ln_contador > 0 then
    select pcg.dias_trabaj , pcg.prov_cts_01, pcg.prov_cts_02, pcg.prov_cts_03,
           pcg.prov_cts_04, pcg.prov_cts_05, pcg.prov_cts_06
      into ln_dias, ln_cts01, ln_cts02, ln_cts03, ln_cts04, ln_cts05, ln_cts06
      from prov_cts_gratif pcg
      where pcg.cod_trabajador = ls_codigo and pcg.flag_estado = '1' ;
    ln_cts01 := nvl(ln_cts01,0) ; ln_cts02 := nvl(ln_cts02,0) ;
    ln_cts03 := nvl(ln_cts03,0) ; ln_cts04 := nvl(ln_cts04,0) ;
    ln_cts05 := nvl(ln_cts05,0) ; ln_cts06 := nvl(ln_cts06,0) ;
    ln_dias  := nvl(ln_dias,0) ;
    ln_imp22 := ln_cts01 + ln_cts02 + ln_cts03 + ln_cts04 + ln_cts05 + ln_cts06 ;
  end if ;
                  
  --  Adiciona registros en la tabla temporal
  if ln_imp21 <> 0 then
    insert into tt_rpt_detalle_cts (
      seccion, descripcion, codigo, nombres, dias, fec_desde,
      fec_hasta, imp_01, imp_02, imp_03, imp_04, imp_05, imp_06,
      imp_07, imp_08, imp_09, imp_10, imp_11, imp_12, imp_13,
      imp_14, imp_15, imp_16, imp_17, imp_18, imp_19, imp_20,
      imp_21, imp_22 )
    values (
      ls_seccion, ls_descripcion, ls_codigo, ls_nombres, ln_dias, ld_fec_desde,
      ld_fec_hasta, ln_imp01, ln_imp02, ln_imp03, ln_imp04, ln_imp05, ln_imp06,
      ln_imp07, ln_imp08, ln_imp09, ln_imp10, ln_imp11, ln_imp12, ln_imp13,
      ln_imp14, ln_imp15, ln_imp16, ln_imp17, ln_imp18, ln_imp19, ln_imp20,
      ln_imp21, ln_imp22 ) ;
  end if ;

end loop ;

end usp_rh_rpt_remun_computable ;
/
