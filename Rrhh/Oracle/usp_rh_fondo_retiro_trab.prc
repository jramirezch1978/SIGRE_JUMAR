create or replace procedure usp_rh_fondo_retiro_trab (
  asi_fec_proceso in string,
  asi_cod_trabajador in string
) is


ld_fec_ingreso       date;
ld_fec_proceso       date;

ls_gan_fij           char(4);
ls_prom_rem_vac      char(4);

ln_ano_descto        number(4) ;  ln_mes_descto        number(2) ;
ln_dia_descto        number(2) ;  ln_ano_increm        number(4) ;
ln_mes_increm        number(2) ;  ln_dia_increm        number(2) ;

ln_contador          integer ;
ln_num_mes           integer ;
ln_cuenta            integer;

ls_codigo            char(8) ;
ls_nombres           varchar2(50) ;
ls_concepto          char(4) ;
ls_year              char(4) ;
ls_bonif_30_25       char(1);
ls_cod_seccion       char(3);
ls_desc_seccion      varchar2(100);
ls_cod_area          char(1);
ls_desc_area         varchar2(100);
ls_cod_origen        char(2);
ls_nombre_origen     varchar2(100);
ls_tipo_trabajador   char(3);
ls_desc_trabajador   varchar2(100);

ld_ran_ini           date ;
ld_ran_fin           date ;
ld_fec_gratif        date ;

ln_telano            number(2) ;
ln_telmes            number(2) ;
ln_teldia            number(2) ;
ln_imp_soles         number(13,2) ;
ln_imp_racion        number(13,2) ;
ln_imp_variable      number(13,2) ;
ln_acum_sobret       number(13,2) ;
ln_prom_sobret       number(13,2) ;
ln_imp_gratif        number(13,2) ;
ln_imp_soles_ano     number(13,2) ;
ln_imp_soles_mes     number(13,2) ;
ln_imp_soles_dia     number(13,2) ;

ln_imp_01            number(13,2) ;  ln_imp_02            number(13,2) ;
ln_imp_03            number(13,2) ;  ln_imp_04            number(13,2) ;
ln_imp_05            number(13,2) ;  ln_imp_06            number(13,2) ;
ln_imp_07            number(13,2) ;  ln_imp_08            number(13,2) ;
ln_imp_09            number(13,2) ;  ln_imp_10            number(13,2) ;
ln_imp_11            number(13,2) ;  ln_imp_12            number(13,2) ;
ln_imp_13            number(13,2) ;  ln_imp_14            number(13,2) ;
ln_imp_15            number(13,2) ;  ln_imp_16            number(13,2) ;
ln_imp_17            number(13,2) ;  ln_imp_18            number(13,2) ;
ln_imp_19            number(13,2) ;  ln_imp_20            number(13,2) ;
ln_imp_21            number(13,2) ;  ln_imp_22            number(13,2) ;
ln_imp_23            number(13,2) ;  ln_imp_24            number(13,2) ;

--  Lectura del maestro de trabajadores
cursor c_maestro is
  select m.cod_trabajador, m.bonif_fija_30_25, m.cod_seccion, m.fec_ingreso
  from maestro m
  where m.flag_cal_plnlla = '1' and m.flag_estado = '1' and
        m.situa_trabaj = 'S' 
        and m.cod_trabajador = asi_cod_trabajador;

--  Lectura de ganancias fijas por trabajador
cursor c_ganancias is
  select gdf.concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = ls_codigo 
     and gdf.flag_estado = '1' 
     and gdf.flag_trabaj = '1' 
     and gdf.concep in (select gcd.concepto_calc from grupo_calculo_det gcd where gcd.grupo_calculo = (select rhc.ganfij_provision_fond_ret from rrhhparam_cconcep rhc where rhc.reckey = '1'));

--  Lectura de conceptos para promedios de sobretiempos
cursor c_conceptos is
   select gcd.concepto_calc
      from grupo_calculo_det gcd
      where gcd.grupo_calculo = (select rhc.prom_remun_vacac from rrhhparam_cconcep rhc where rhc.reckey = '1');
--      where gcd.grupo_calculo = (select rhc.ganfij_provision_fond_ret from rrhhparam_cconcep rhc where rhc.reckey = '1');

begin

--  *********************************************************************
--  ***   CALCULO DE TIEMPO DE SERVICIO AL 31 DE DICIEMBRE DE 1,994   ***
--  ***      EL CALCULO SE REALIZA SOLO PARA TRABAJADORES SOCIOS      ***
--  *********************************************************************
   ld_fec_proceso := to_date(asi_fec_proceso, 'dd/mm/yyyy');

   delete 
      from tt_rh_fonret_relac t 
      where t.codigo = asi_cod_trabajador;
   
   select count(*)
      into ln_cuenta
      from maestro m 
         inner join tipo_trabajador tt on tt.tipo_trabajador = m.tipo_trabajador
         inner join origen o on m.cod_origen = o.cod_origen
         inner join seccion s on m.cod_seccion = s.cod_seccion and m.cod_area = s.cod_area
         inner join area a on m.cod_area = a.cod_area
      where m.cod_trabajador = asi_cod_trabajador
         and m.flag_cal_plnlla = '1' 
         and m.flag_estado = '1' 
         and m.situa_trabaj = 'S' ;
   
   if ln_cuenta <> 1 then
      return;
   end if;
   
   select gc.concepto_gen 
      into ls_gan_fij
      from grupo_calculo gc 
      where gc.grupo_calculo = (select rhc.deuda_laboral_fond_ret from rrhhparam_cconcep rhc where rhc.reckey = '1');
   
   select m.fec_ingreso, m.bonif_fija_30_25, m.cod_seccion, s.desc_seccion, m.cod_area, a.desc_area, m.cod_origen, o.nombre, m.tipo_trabajador, tt.desc_tipo_tra
      into ld_fec_ingreso, ls_bonif_30_25, ls_cod_seccion, ls_desc_seccion, ls_cod_area, ls_desc_area, ls_cod_origen, ls_nombre_origen, ls_tipo_trabajador, ls_desc_trabajador 
      from maestro m 
         inner join tipo_trabajador tt on tt.tipo_trabajador = m.tipo_trabajador
         inner join origen o on m.cod_origen = o.cod_origen
         inner join seccion s on m.cod_seccion = s.cod_seccion and m.cod_area = s.cod_area
         inner join area a on m.cod_area = a.cod_area
      where m.cod_trabajador = asi_cod_trabajador
         and m.flag_cal_plnlla = '1' 
         and m.flag_estado = '1' 
         and m.situa_trabaj = 'S' ;

  ln_imp_01 := 0 ; ln_imp_02 := 0 ; ln_imp_03 := 0 ;
  ln_imp_04 := 0 ; ln_imp_05 := 0 ; ln_imp_06 := 0 ;
  ln_imp_07 := 0 ; ln_imp_08 := 0 ; ln_imp_09 := 0 ;
  ln_imp_10 := 0 ; ln_imp_11 := 0 ; ln_imp_12 := 0 ;
  ln_imp_13 := 0 ; ln_imp_14 := 0 ; ln_imp_15 := 0 ;
  ln_imp_16 := 0 ; ln_imp_17 := 0 ; ln_imp_18 := 0 ;
  ln_imp_19 := 0 ; ln_imp_20 := 0 ; ln_imp_21 := 0 ;
  ln_imp_22 := 0 ; ln_imp_23 := 0 ; ln_imp_24 := 0 ;

  ln_ano_descto    := 0 ; ln_mes_descto    := 0 ; ln_dia_descto    := 0 ;
  ln_ano_increm    := 0 ; ln_mes_increm    := 0 ; ln_dia_increm    := 0 ;
  ln_imp_soles_ano := 0 ; ln_imp_soles_mes := 0 ; ln_imp_soles_dia := 0 ;

  ls_codigo  := asi_cod_trabajador ;
  ls_nombres := usf_rh_nombre_trabajador(ls_codigo) ;

  --  Determina retencion por tiempo de servicio
  ln_contador := 0 ;
  select count(*) into ln_contador from ret_tiempo_servicio rts
    where rts.cod_trabajador = ls_codigo and rts.flag_tipo_oper = '1' ;
  if ln_contador > 0 then
    select sum(nvl(rts.ano_retencion,0)), sum(nvl(rts.mes_retencion,0)),
           sum(nvl(rts.dias_retencion,0))
      into ln_ano_descto, ln_mes_descto, ln_dia_descto
      from ret_tiempo_servicio rts
      where rts.cod_trabajador = ls_codigo and rts.flag_tipo_oper = '1' ;
  end if ;
  ln_contador := 0 ;
  select count(*) into ln_contador from ret_tiempo_servicio rts
    where rts.cod_trabajador = ls_codigo and rts.flag_tipo_oper = '2' ;
  if ln_contador > 0 then
    select sum(nvl(rts.ano_retencion,0)), sum(nvl(rts.mes_retencion,0)),
           sum(nvl(rts.dias_retencion,0))
      into ln_ano_increm, ln_mes_increm, ln_dia_increm
      from ret_tiempo_servicio rts
      where rts.cod_trabajador = ls_codigo and rts.flag_tipo_oper = '2' ;
  end if ;

  --  Determina el tiempo efectivo de liquidacion
  ln_telano := 1994 - nvl(to_number(to_char(ld_fec_ingreso,'YYYY')),0) ;
  ln_telmes := 12   - nvl(to_number(to_char(ld_fec_ingreso,'MM')),0) ;
  ln_teldia := 31   - nvl(to_number(to_char(ld_fec_ingreso,'DD')),0) ;
  ln_telano := ln_telano - ln_ano_descto + ln_ano_increm ;
  ln_telmes := ln_telmes - ln_mes_descto + ln_mes_increm ;
  ln_teldia := ln_teldia - ln_dia_descto + ln_dia_increm ;

  --  Calcula ganancias fijas
  ln_imp_soles := 0 ; ln_imp_racion := 0 ;
  for rc_gan in c_ganancias loop
    if rc_gan.concep = '1013' then
      ln_imp_racion := nvl(rc_gan.imp_gan_desc,0) ;
    else
      ln_imp_soles := ln_imp_soles + nvl(rc_gan.imp_gan_desc,0) ;
    end if ;
    --  Determina ganancia por concepto
    if rc_gan.concep = '1001' then
      ln_imp_01 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1002' then
      ln_imp_02 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1003' then
      ln_imp_03 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1004' then
      ln_imp_04 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1005' then
      ln_imp_05 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1006' then
      ln_imp_06 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1007' then
      ln_imp_07 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1008' then
      ln_imp_08 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1009' then
      ln_imp_09 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1010' then
      ln_imp_10 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1011' then
      ln_imp_11 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1012' then
      ln_imp_12 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1013' then
      ln_imp_13 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1014' then
      ln_imp_14 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1015' then
      ln_imp_15 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1016' then
      ln_imp_16 := nvl(rc_gan.imp_gan_desc,0) ;
    elsif rc_gan.concep = '1017' then
      ln_imp_17 := nvl(rc_gan.imp_gan_desc,0) ;
    end if ;
  end loop ;

  --  Calcula promedio de sobretiempos de los ultimos seis meses
  ln_prom_sobret := 0 ;
  for rc_con in c_conceptos loop
    ld_ran_ini := add_months(ld_fec_proceso, - 1) ;
    ln_num_mes := 0 ; ln_acum_sobret := 0 ;
    for x in reverse 1 .. 6 loop
      ld_ran_fin := ld_ran_ini ;
      ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
      ln_contador := 0 ; ln_imp_variable := 0 ;
      select count(*)
        into ln_contador from historico_calculo hc
        where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = ls_codigo and
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
      if ln_contador > 0 then
        select sum(nvl(hc.imp_soles,0))
          into ln_imp_variable from historico_calculo hc
          where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = ls_codigo and
                hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
      end if ;
      if ln_imp_variable <> 0 then
        ln_num_mes := ln_num_mes + 1 ;
        ln_acum_sobret := ln_acum_sobret + ln_imp_variable ;
      end if ;
      ld_ran_ini := ld_ran_ini - 1 ;
    end loop ;
    if ln_num_mes > 2 then
      ln_prom_sobret := ln_prom_sobret + (ln_acum_sobret / 6 ) ;
    end if ;
  end loop ;
  ln_imp_18    := ln_prom_sobret ;
  ln_imp_soles := ln_imp_soles + ln_prom_sobret ;

  --  Calcula bonificacion del 30% o 25%
  if ls_bonif_30_25 = '1' then
    ln_imp_19 := ln_imp_soles * 0.30 ;
    ln_imp_soles := ln_imp_soles + (ln_imp_soles * 0.30) ;
  elsif ls_bonif_30_25 = '2' then
    ln_imp_19 := ln_imp_soles * 0.25 ;
    ln_imp_soles := ln_imp_soles + (ln_imp_soles * 0.25) ;
  end if ;
  ln_imp_soles := ln_imp_soles + ln_imp_racion ;

  --  Halla promedio de la ultima gratificacion
  if to_number(to_char(ld_fec_proceso,'MM')) < 07 then
    ls_concepto := '1411' ;
    ls_year := to_char(to_number(to_char(ld_fec_proceso,'YYYY')) - 1) ;
    ld_fec_gratif := to_date('31'||'/'||'12'||'/'||ls_year,'DD/MM/YYYY') ;
  elsif to_number(to_char(ld_fec_proceso,'MM')) = 07 or
        to_number(to_char(ld_fec_proceso,'MM')) < 12 then
    ls_concepto := '1410' ;
    ls_year := to_char (ld_fec_proceso,'YYYY') ;
    ld_fec_gratif := to_date('31'||'/'||'07'||'/'||ls_year,'DD/MM/YYYY') ;
  elsif to_number(to_char(ld_fec_proceso,'MM')) = 12 then
    ls_concepto := '1411' ;
    ls_year := to_char(ld_fec_proceso,'YYYY') ;
    ld_fec_gratif := to_date('31'||'/'||'12'||'/'||ls_year,'DD/MM/YYYY') ;
  end if ;
  ln_contador := 0 ; ln_imp_gratif := 0 ;
  select count(*)
    into ln_contador from historico_calculo hc
    where hc.concep = ls_concepto and hc.cod_trabajador = ls_codigo and
          hc.fec_calc_plan = ld_fec_gratif ;
  if ln_contador > 0 then
    select sum(nvl(hc.imp_soles,0))
      into ln_imp_gratif from historico_calculo hc
      where hc.concep = ls_concepto and hc.cod_trabajador = ls_codigo and
            hc.fec_calc_plan = ld_fec_gratif ;
  end if ;
  ln_imp_20 := ln_imp_gratif / 6 ;
  ln_imp_soles := ln_imp_soles + (ln_imp_gratif / 6) ;

  --  Calcula fondo de retiro a la fecha
  ln_imp_soles_ano := ln_imp_soles * ln_telano ;
  ln_imp_soles_mes := (ln_imp_soles / 12) * ln_telmes ;
  ln_imp_soles_dia := (ln_imp_soles / 360) * ln_teldia ;
  ln_imp_soles     := ln_imp_soles_ano + ln_imp_soles_mes + ln_imp_soles_dia ;

  ln_imp_21 := ln_imp_soles_ano ;
  ln_imp_22 := ln_imp_soles_mes ;
  ln_imp_23 := ln_imp_soles_dia ;
  ln_imp_24 := ln_imp_soles ;

  --  Graba registro por fondo de retiro
  if ln_imp_soles > 0 then         
   insert into tt_rh_fonret_relac ( --tt_rpt_fondo_retiro (
      fecha, tipo_trabajador, desc_tipo_trabajador, origen, desc_origen, codigo,
      seccion, desc_seccion, area, desc_area, nombres, fec_ingreso, ano_descto,
      mes_descto, dia_descto, ano_increm, mes_imcrem,
      dia_increm, telano, telmes, teldia, 
      imp_01, imp_02, imp_03, imp_04, imp_05, imp_06,
      imp_07, imp_08, imp_09, imp_10, imp_11, imp_12,
      imp_13, imp_14, imp_15, imp_16, imp_17, imp_18,
      imp_19, imp_20, imp_21, imp_22, imp_23, imp_24 )
      values (
         ld_fec_proceso, ls_tipo_trabajador, ls_desc_trabajador, 
         ls_cod_origen, ls_nombre_origen, ls_codigo,
         ls_cod_seccion, ls_desc_seccion, ls_cod_area, ls_desc_area, 
         ls_nombres, ld_fec_ingreso, ln_ano_descto,
         ln_mes_descto, ln_dia_descto, ln_ano_increm, ln_mes_increm,
         ln_dia_increm, ln_telano, ln_telmes, ln_teldia,
         ln_imp_01, ln_imp_02, ln_imp_03, ln_imp_04, ln_imp_05, ln_imp_06,
         ln_imp_07, ln_imp_08, ln_imp_09, ln_imp_10, ln_imp_11, ln_imp_12,
         ln_imp_13, ln_imp_14, ln_imp_15, ln_imp_16, ln_imp_17, ln_imp_18,
         ln_imp_19, ln_imp_20, ln_imp_21, ln_imp_22, ln_imp_23, ln_imp_24 ) ;
  end if ;
end usp_rh_fondo_retiro_trab;
/
