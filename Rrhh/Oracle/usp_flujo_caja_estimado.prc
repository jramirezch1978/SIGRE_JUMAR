create or replace procedure usp_flujo_caja_estimado
  ( as_tipo_moneda       in maestro.flag_estado%type,
    an_tipo_cambio       in concepto.fact_pago%type,
    an_periodo           in programacion_turnos.ano%type,
    an_mes_desde         in programacion_turnos.semana%type,
    an_mes_hasta         in programacion_turnos.semana%type,
    an_factor_01         in concepto.fact_pago%type,
    an_factor_02         in concepto.fact_pago%type,
    an_factor_03         in concepto.fact_pago%type,
    an_factor_04         in concepto.fact_pago%type,
    an_factor_05         in concepto.fact_pago%type,
    an_factor_06         in concepto.fact_pago%type,
    an_factor_07         in concepto.fact_pago%type,
    an_factor_08         in concepto.fact_pago%type,
    an_factor_09         in concepto.fact_pago%type,
    an_factor_10         in concepto.fact_pago%type,
    an_factor_11         in concepto.fact_pago%type,
    an_factor_12         in concepto.fact_pago%type
  ) is

--  Calculo de Flujo de Caja Estimado
--  Ganancias Fijas (GASPER)
--  Promedios de Sobretiempos de los 6 Ultimos Meses (GASPER)
--  Bonificacion 30% o 25% (GASPER)
--  Gratificaciones Para Julio y Diciembre (GASGRA)
--  Aportaciones por Trabajador (GASPER)
--  Bonificacion por Quinquenios (GASPER) en su Respectivo Mes
--  Compensacion por Tiempo de Servicios (GASCTS)

--  Variables
lk_promedio         constant char(3) := '001' ;

ls_codigo           maestro.cod_trabajador%type ;
ls_seccion          maestro.cod_seccion%type ;
ld_fec_ingreso      maestro.fec_ingreso%type ;
ls_situacion        maestro.situa_trabaj%type ;
ls_bonificacion     maestro.bonif_fija_30_25%type ;

ln_factor           concepto.fact_pago%type ;
ln_importe          number(13,2) ;
ln_ganancias        number(13,2) ;
ln_gasper_t         number(13,2) ;
ln_gratif_t         number(13,2) ;
ln_impcts_t         number(13,2) ;
ln_gasper           number(13,2) ;
ln_gratif           number(13,2) ;
ln_impcts           number(13,2) ;
ln_contador         number(15) ;

ld_fec_proceso     rrhhparam.fec_proceso%type ;
ld_fec_quinque     rrhhparam.fec_proceso%type ;
ld_ran_ini         rrhhparam.fec_proceso%type ;
ld_ran_fin         rrhhparam.fec_proceso%type ;
ln_nro_meses       number(15) ;
ln_acumulado       number(13,2) ;
ln_promedio        number(13,2) ;

ln_apo_segagr      number(13,2) ;
ln_apo_senati      number(13,2) ;
ln_apo_sctrip      number(13,2) ;
ln_apo_sctron      number(13,2) ;

ln_gasper_s_01     number(13,2) ;
ln_gasper_s_02     number(13,2) ;
ln_gasper_s_03     number(13,2) ;
ln_gasper_s_04     number(13,2) ;
ln_gasper_s_05     number(13,2) ;
ln_gasper_s_06     number(13,2) ;
ln_gasper_s_07     number(13,2) ;
ln_gasper_s_08     number(13,2) ;
ln_gasper_s_09     number(13,2) ;
ln_gasper_s_10     number(13,2) ;
ln_gasper_s_11     number(13,2) ;
ln_gasper_s_12     number(13,2) ;

ln_gratif_s_01     number(13,2) ;
ln_gratif_s_02     number(13,2) ;
ln_gratif_s_03     number(13,2) ;
ln_gratif_s_04     number(13,2) ;
ln_gratif_s_05     number(13,2) ;
ln_gratif_s_06     number(13,2) ;
ln_gratif_s_07     number(13,2) ;
ln_gratif_s_08     number(13,2) ;
ln_gratif_s_09     number(13,2) ;
ln_gratif_s_10     number(13,2) ;
ln_gratif_s_11     number(13,2) ;
ln_gratif_s_12     number(13,2) ;

ln_impcts_s_01     number(13,2) ;
ln_impcts_s_02     number(13,2) ;
ln_impcts_s_03     number(13,2) ;
ln_impcts_s_04     number(13,2) ;
ln_impcts_s_05     number(13,2) ;
ln_impcts_s_06     number(13,2) ;
ln_impcts_s_07     number(13,2) ;
ln_impcts_s_08     number(13,2) ;
ln_impcts_s_09     number(13,2) ;
ln_impcts_s_10     number(13,2) ;
ln_impcts_s_11     number(13,2) ;
ln_impcts_s_12     number(13,2) ;

ln_gasper_d_01     number(13,2) ;
ln_gasper_d_02     number(13,2) ;
ln_gasper_d_03     number(13,2) ;
ln_gasper_d_04     number(13,2) ;
ln_gasper_d_05     number(13,2) ;
ln_gasper_d_06     number(13,2) ;
ln_gasper_d_07     number(13,2) ;
ln_gasper_d_08     number(13,2) ;
ln_gasper_d_09     number(13,2) ;
ln_gasper_d_10     number(13,2) ;
ln_gasper_d_11     number(13,2) ;
ln_gasper_d_12     number(13,2) ;

ln_gratif_d_01     number(13,2) ;
ln_gratif_d_02     number(13,2) ;
ln_gratif_d_03     number(13,2) ;
ln_gratif_d_04     number(13,2) ;
ln_gratif_d_05     number(13,2) ;
ln_gratif_d_06     number(13,2) ;
ln_gratif_d_07     number(13,2) ;
ln_gratif_d_08     number(13,2) ;
ln_gratif_d_09     number(13,2) ;
ln_gratif_d_10     number(13,2) ;
ln_gratif_d_11     number(13,2) ;
ln_gratif_d_12     number(13,2) ;

ln_impcts_d_01     number(13,2) ;
ln_impcts_d_02     number(13,2) ;
ln_impcts_d_03     number(13,2) ;
ln_impcts_d_04     number(13,2) ;
ln_impcts_d_05     number(13,2) ;
ln_impcts_d_06     number(13,2) ;
ln_impcts_d_07     number(13,2) ;
ln_impcts_d_08     number(13,2) ;
ln_impcts_d_09     number(13,2) ;
ln_impcts_d_10     number(13,2) ;
ln_impcts_d_11     number(13,2) ;
ln_impcts_d_12     number(13,2) ;

ln_anios           number(4,2) ; 
ln_jornal          number(4,2) ; 
ln_quinquenio      integer ;     
ln_imp_quinquenio  number(13,2) ;
ln_quinquenio_01   number(13,2) ;
ln_quinquenio_02   number(13,2) ;
ln_quinquenio_03   number(13,2) ;
ln_quinquenio_04   number(13,2) ;
ln_quinquenio_05   number(13,2) ;
ln_quinquenio_06   number(13,2) ;
ln_quinquenio_07   number(13,2) ;
ln_quinquenio_08   number(13,2) ;
ln_quinquenio_09   number(13,2) ;
ln_quinquenio_10   number(13,2) ;
ln_quinquenio_11   number(13,2) ;
ln_quinquenio_12   number(13,2) ;

--  Registros del Maestro de Planillas
Cursor c_maestro is
  Select m.cod_trabajador, m.fec_ingreso, m.situa_trabaj,
         m.bonif_fija_30_25, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1'
  order by m.cod_trabajador ;

--  Conceptos Afectos a Promedios de Sobretiempos
Cursor c_concepto is 
  Select concep
  from rrhh_nivel_detalle rhnd
  where rhnd.cod_nivel = lk_promedio ;
  
begin

--  Elimina Registros de la Planilla Mensual
delete from flujo_caja fc
  where (fc.cod_flujo_caja = 'GASPER    ' or
         fc.cod_flujo_caja = 'GASGRA    ' or
         fc.cod_flujo_caja = 'GASCTS    ') and
         fc.periodo = an_periodo and
        (fc.mes between an_mes_desde and an_mes_hasta) and
         fc.flag_flujo = 'E' ;

--  Determina Ultimo Mes de Proceso
Select rh.fec_proceso
  into ld_fec_proceso
  from rrhhparam rh
  where rh.reckey = '1' ;

ln_gasper_s_01 := 0 ; ln_gasper_d_01 := 0 ;
ln_gasper_s_02 := 0 ; ln_gasper_d_02 := 0 ;
ln_gasper_s_03 := 0 ; ln_gasper_d_03 := 0 ;
ln_gasper_s_04 := 0 ; ln_gasper_d_04 := 0 ;
ln_gasper_s_05 := 0 ; ln_gasper_d_05 := 0 ;
ln_gasper_s_06 := 0 ; ln_gasper_d_06 := 0 ;
ln_gasper_s_07 := 0 ; ln_gasper_d_07 := 0 ;
ln_gasper_s_08 := 0 ; ln_gasper_d_08 := 0 ;
ln_gasper_s_09 := 0 ; ln_gasper_d_09 := 0 ;
ln_gasper_s_10 := 0 ; ln_gasper_d_10 := 0 ;
ln_gasper_s_11 := 0 ; ln_gasper_d_11 := 0 ;
ln_gasper_s_12 := 0 ; ln_gasper_d_12 := 0 ;

ln_gratif_s_01 := 0 ; ln_gratif_d_01 := 0 ;
ln_gratif_s_02 := 0 ; ln_gratif_d_02 := 0 ;
ln_gratif_s_03 := 0 ; ln_gratif_d_03 := 0 ;
ln_gratif_s_04 := 0 ; ln_gratif_d_04 := 0 ;
ln_gratif_s_05 := 0 ; ln_gratif_d_05 := 0 ;
ln_gratif_s_06 := 0 ; ln_gratif_d_06 := 0 ;
ln_gratif_s_07 := 0 ; ln_gratif_d_07 := 0 ;
ln_gratif_s_08 := 0 ; ln_gratif_d_08 := 0 ;
ln_gratif_s_09 := 0 ; ln_gratif_d_09 := 0 ;
ln_gratif_s_10 := 0 ; ln_gratif_d_10 := 0 ;
ln_gratif_s_11 := 0 ; ln_gratif_d_11 := 0 ;
ln_gratif_s_12 := 0 ; ln_gratif_d_12 := 0 ;

ln_impcts_s_01 := 0 ; ln_impcts_d_01 := 0 ;
ln_impcts_s_02 := 0 ; ln_impcts_d_02 := 0 ;
ln_impcts_s_03 := 0 ; ln_impcts_d_03 := 0 ;
ln_impcts_s_04 := 0 ; ln_impcts_d_04 := 0 ;
ln_impcts_s_05 := 0 ; ln_impcts_d_05 := 0 ;
ln_impcts_s_06 := 0 ; ln_impcts_d_06 := 0 ;
ln_impcts_s_07 := 0 ; ln_impcts_d_07 := 0 ;
ln_impcts_s_08 := 0 ; ln_impcts_d_08 := 0 ;
ln_impcts_s_09 := 0 ; ln_impcts_d_09 := 0 ;
ln_impcts_s_10 := 0 ; ln_impcts_d_10 := 0 ;
ln_impcts_s_11 := 0 ; ln_impcts_d_11 := 0 ;
ln_impcts_s_12 := 0 ; ln_impcts_d_12 := 0 ;

ln_quinquenio_01 := 0 ; ln_quinquenio_02 := 0 ;
ln_quinquenio_03 := 0 ; ln_quinquenio_04 := 0 ;
ln_quinquenio_05 := 0 ; ln_quinquenio_06 := 0 ;
ln_quinquenio_07 := 0 ; ln_quinquenio_08 := 0 ;
ln_quinquenio_09 := 0 ; ln_quinquenio_10 := 0 ;
ln_quinquenio_11 := 0 ; ln_quinquenio_12 := 0 ;

--  Realiza Proceso por Trabajador
For rc_mae in c_maestro loop

  ls_codigo       := rc_mae.cod_trabajador ;
  ls_seccion      := rc_mae.cod_seccion ;
  ld_fec_ingreso  := rc_mae.fec_ingreso ;
  ls_situacion    := rc_mae.situa_trabaj ;
  ls_bonificacion := rc_mae.bonif_fija_30_25 ;
  ls_situacion    := nvl(ls_situacion,' ') ;
  ls_bonificacion := nvl(ls_bonificacion,' ') ;

  ln_gasper_t := 0 ; ln_gratif_t := 0 ;
  ln_impcts_t := 0 ;
  
  --  Acumula Ganancias Fijas
  ln_importe := 0 ; ln_ganancias := 0 ;
  Select sum(gdf.imp_gan_desc)
    into ln_importe
    from gan_desct_fijo gdf
    where gdf.cod_trabajador = ls_codigo and
          gdf.flag_estado = '1' and
          gdf.flag_trabaj = '1' and
          substr(gdf.concep,1,2) = '10' ;
  ln_importe   := nvl(ln_importe,0);
  ln_ganancias := ln_importe ;
  ln_gasper_t  := ln_gasper_t + ln_importe ;

  --  Calcula Promedios de Sobretiempos
  ln_promedio := 0 ;
  For rc_con in c_concepto Loop
    ld_ran_ini   := add_months(ld_fec_proceso, - 1) ;
    ln_nro_meses := 0 ;
    ln_acumulado := 0 ;
    For x in reverse 1 .. 6 Loop
      ld_ran_fin := ld_ran_ini ;
      ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
      ln_importe := 0 ;
      --  Determina si hay Registros en el Mes a Promediar
      Select count(*)
      into ln_contador
      from historico_calculo hc 
      where hc.concep = rc_con.concep and 
            hc.cod_trabajador = ls_codigo and 
            hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
      ln_contador := nvl(ln_contador,0) ;
      If ln_contador > 0 then 
        Select sum( hc.imp_soles)
          into ln_importe
          from historico_calculo hc 
          where hc.concep = rc_con.concep and
                hc.cod_trabajador = ls_codigo and
                hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
      End if ;
      ln_importe := nvl(ln_importe,0) ;
      If ln_importe > 0 then 
        ln_nro_meses := ln_nro_meses + 1 ;
        ln_acumulado := ln_acumulado + ln_importe ;
      End If ; 
      ld_ran_ini := ld_ran_ini - 1 ;
    End Loop ;
    If ln_nro_meses > 2 then
      ln_promedio := ln_promedio + ( ln_acumulado / 6 ) ;
    End If ;
  End Loop ;

  ln_gasper_t := ln_gasper_t + ln_promedio ;

  --  Calcula 30% o 25% por Trabajador
  If ls_bonificacion = '1' then
    ln_gasper_t := ln_gasper_t * 1.30 ;
  Elsif ls_bonificacion = '2' then
    ln_gasper_t := ln_gasper_t * 1.25 ;
  End if ;

  --  Determina Gratificaciones Para Julio y Diciembre
  ln_gratif_t := ln_gasper_t ;
  
  --  Calcula Aportaciones por Trabajador
  ln_apo_segagr := 0 ; ln_apo_senati := 0 ;
  ln_apo_sctrip := 0 ; ln_apo_sctron := 0 ;

  --  Seguro Agrario
  ln_factor := 0 ;
  Select c.fact_pago
    into ln_factor
    from concepto c
    where c.concep = '3002' and
          c.flag_estado = '1' ;
  ln_factor := nvl(ln_factor,0) ;
  ln_apo_segagr := ln_gasper_t * ln_factor ;

  --  SENATI
  If ls_seccion = '700' or ls_seccion = '710' or
     ls_seccion = '720' or ls_seccion = '730' or
     ls_seccion = '732' or ls_seccion = '740' or
     ls_seccion = '741' or ls_seccion = '743' or
     ls_seccion = '744' or ls_seccion = '745' or
     ls_seccion = '746' or ls_seccion = '731' then
     ln_factor := 0 ;
     Select c.fact_pago
       into ln_factor
       from concepto c
       where c.concep = '3003' and
             c.flag_estado = '1' ;
     ln_factor := nvl(ln_factor,0) ;  
     ln_apo_senati := ln_gasper_t * ln_factor ;
  End if ;

  --  S.C.T.R. I.P.S.S.  
  ln_factor := 0 ;
  Select s.porc_sctr_ipss
    into ln_factor
    from seccion s
    where s.cod_seccion = ls_seccion ;
  ln_factor := nvl(ln_factor,0) ;
  ln_apo_sctrip := ln_gasper_t * ln_factor / 100 ;

  --  S.C.T.R. O.N.P.
  ln_factor := 0 ;
  Select s.porc_sctr_onp
    into ln_factor
    from seccion s
    where s.cod_seccion = ls_seccion ;
  ln_factor := nvl(ln_factor,0) ;
  ln_apo_sctron := ln_ganancias * ln_factor / 100 ;
  
  --  Acumula Aportes a Gastos por Personal
  ln_gasper_t:= ln_gasper_t + (ln_apo_segagr + ln_apo_senati +
                               ln_apo_sctrip + ln_apo_sctron) ;

  --  Bonificaciones por Quinquenios
  --  (Suma a Gastos de Personal en su Respectivo Mes)
  ln_imp_quinquenio := 0 ;
  For x in an_mes_desde .. an_mes_hasta Loop
    ld_fec_quinque := to_date('01'||'/'||to_char(x)||'/'||to_char(an_periodo),'DD/MM/YYYY') ;
    ln_anios := months_between(ld_fec_quinque,ld_fec_ingreso) / 12 ;
    If ln_anios > 5 Then 
      ln_quinquenio := Trunc (ln_anios) ;
      ln_contador   := 0 ; ln_jornal := 0 ;
      Select count(*)
        into ln_contador
        from quinquenio q
        where q.quinquenio = ln_quinquenio and
              to_char(ld_fec_ingreso,'MM') = to_char(ld_fec_quinque,'MM') ;
      If ln_contador > 0 then
        Select q.jornal 
          into ln_jornal
          from quinquenio q
          where q.quinquenio = ln_quinquenio;
        ln_jornal := nvl(ln_jornal,0) ;
      End if;
      If ln_jornal > 0 Then 
        ln_imp_quinquenio := ln_ganancias / 30 * ln_jornal ;
        If x = 01 then
          ln_quinquenio_01 := ln_imp_quinquenio ;
        Elsif x = 02 then
          ln_quinquenio_02 := ln_imp_quinquenio ;
        Elsif x = 03 then
          ln_quinquenio_03 := ln_imp_quinquenio ;
        Elsif x = 04 then
          ln_quinquenio_04 := ln_imp_quinquenio ;
        Elsif x = 05 then
          ln_quinquenio_05 := ln_imp_quinquenio ;
        Elsif x = 06 then
          ln_quinquenio_06 := ln_imp_quinquenio ;
        Elsif x = 07 then
          ln_quinquenio_07 := ln_imp_quinquenio ;
        Elsif x = 08 then
          ln_quinquenio_08 := ln_imp_quinquenio ;
        Elsif x = 09 then
          ln_quinquenio_09 := ln_imp_quinquenio ;
        Elsif x = 10 then
          ln_quinquenio_10 := ln_imp_quinquenio ;
        Elsif x = 11 then
          ln_quinquenio_11 := ln_imp_quinquenio ;
        Elsif x = 12 then
          ln_quinquenio_12 := ln_imp_quinquenio ;
        End if ;
      End if ;
    End if ;
  End loop ;
                                  
  --  Calcula Concepto de C.T.S.
  ln_impcts_t := ln_gratif_t * 8.33 / 100 ;
  
  --  Acumula Importes por Trabajador a un Total General Mensual
  For x in an_mes_desde .. an_mes_hasta Loop
    If x = 01 then
      ln_gasper_s_01 := ln_gasper_s_01 + (ln_gasper_t + ln_quinquenio_01) ;
      ln_impcts_s_01 := ln_impcts_s_01 + ln_impcts_t ;
      If an_factor_01 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_01 := ln_gasper_s_01 + ((ln_gasper_t + ln_quinquenio_01) * an_factor_01) ;
        ln_impcts_s_01 := ln_impcts_s_01 + (ln_impcts_t * an_factor_01) ;
      End if ;
    Elsif x = 02 then
      ln_gasper_s_02 := ln_gasper_s_02 + (ln_gasper_t + ln_quinquenio_02) ;
      ln_impcts_s_02 := ln_impcts_s_02 + ln_impcts_t ;
      If an_factor_02 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_02 := ln_gasper_s_02 + ((ln_gasper_t + ln_quinquenio_02) * an_factor_02) ;
        ln_impcts_s_02 := ln_impcts_s_02 + (ln_impcts_t * an_factor_02) ;
      End if ;
    Elsif x = 03 then
      ln_gasper_s_03 := ln_gasper_s_03 + (ln_gasper_t + ln_quinquenio_03) ;
      ln_impcts_s_03 := ln_impcts_s_03 + ln_impcts_t ;
      If an_factor_03 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_03 := ln_gasper_s_03 + ((ln_gasper_t + ln_quinquenio_03) * an_factor_03) ;
        ln_impcts_s_03 := ln_impcts_s_03 + (ln_impcts_t * an_factor_03) ;
      End if ;
    Elsif x = 04 then
      ln_gasper_s_04 := ln_gasper_s_04 + (ln_gasper_t + ln_quinquenio_04) ;
      ln_impcts_s_04 := ln_impcts_s_04 + ln_impcts_t ;
      If an_factor_04 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_04 := ln_gasper_s_04 + ((ln_gasper_t + ln_quinquenio_04) * an_factor_04) ;
        ln_impcts_s_04 := ln_impcts_s_04 + (ln_impcts_t * an_factor_04) ;
      End if ;
    Elsif x = 05 then
      ln_gasper_s_05 := ln_gasper_s_05 + (ln_gasper_t + ln_quinquenio_05) ;
      ln_impcts_s_05 := ln_impcts_s_05 + ln_impcts_t ;
      If an_factor_05 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_05 := ln_gasper_s_05 + ((ln_gasper_t + ln_quinquenio_05) * an_factor_05) ;
        ln_impcts_s_05 := ln_impcts_s_05 + (ln_impcts_t * an_factor_05) ;
      End if ;
    Elsif x = 06 then
      ln_gasper_s_06 := ln_gasper_s_06 + (ln_gasper_t + ln_quinquenio_06) ;
      ln_impcts_s_06 := ln_impcts_s_06 + ln_impcts_t ;
      If an_factor_06 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_06 := ln_gasper_s_06 + ((ln_gasper_t + ln_quinquenio_06) * an_factor_06) ;
        ln_impcts_s_06 := ln_impcts_s_06 + (ln_impcts_t * an_factor_06) ;
      End if ;
    Elsif x = 07 then
      ln_gasper_s_07 := ln_gasper_s_07 + (ln_gasper_t + ln_quinquenio_07) ;
      ln_gratif_s_07 := ln_gratif_s_07 + ln_gratif_t ;
      ln_impcts_s_07 := ln_impcts_s_07 + ln_impcts_t ;
      If an_factor_07 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_07 := ln_gasper_s_07 + ((ln_gasper_t + ln_quinquenio_07) * an_factor_07) ;
        ln_gratif_s_07 := ln_gratif_s_07 + (ln_gratif_t * an_factor_07) ;
        ln_impcts_s_07 := ln_impcts_s_07 + (ln_impcts_t * an_factor_07) ;
      End if ;
    Elsif x = 08 then
      ln_gasper_s_08 := ln_gasper_s_08 + (ln_gasper_t + ln_quinquenio_08) ;
      ln_impcts_s_08 := ln_impcts_s_08 + ln_impcts_t ;
      If an_factor_08 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_08 := ln_gasper_s_08 + ((ln_gasper_t + ln_quinquenio_08) * an_factor_08) ;
        ln_impcts_s_08 := ln_impcts_s_08 + (ln_impcts_t * an_factor_08) ;
      End if ;
    Elsif x = 09 then
      ln_gasper_s_09 := ln_gasper_s_09 + (ln_gasper_t + ln_quinquenio_09) ;
      ln_impcts_s_09 := ln_impcts_s_09 + ln_impcts_t ;
      If an_factor_09 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_09 := ln_gasper_s_09 + ((ln_gasper_t + ln_quinquenio_09) * an_factor_09) ;
        ln_impcts_s_09 := ln_impcts_s_09 + (ln_impcts_t * an_factor_09) ;
      End if ;
    Elsif x = 10 then
      ln_gasper_s_10 := ln_gasper_s_10 + (ln_gasper_t + ln_quinquenio_10) ;
      ln_impcts_s_10 := ln_impcts_s_10 + ln_impcts_t ;
      If an_factor_10 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_10 := ln_gasper_s_10 + ((ln_gasper_t + ln_quinquenio_10) * an_factor_10) ;
        ln_impcts_s_10 := ln_impcts_s_10 + (ln_impcts_t * an_factor_10) ;
      End if ;
    Elsif x = 11 then
      ln_gasper_s_11 := ln_gasper_s_11 + (ln_gasper_t + ln_quinquenio_11) ;
      ln_impcts_s_11 := ln_impcts_s_11 + ln_impcts_t ;
      If an_factor_11 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_11 := ln_gasper_s_11 + ((ln_gasper_t + ln_quinquenio_11) * an_factor_11) ;
        ln_impcts_s_11 := ln_impcts_s_11 + (ln_impcts_t * an_factor_11) ;
      End if ;
    Elsif x = 12 then
      ln_gasper_s_12 := ln_gasper_s_12 + (ln_gasper_t + ln_quinquenio_12) ;
      ln_gratif_s_12 := ln_gratif_s_12 + ln_gratif_t ;
      ln_impcts_s_12 := ln_impcts_s_12 + ln_impcts_t ;
      If an_factor_12 > 0 and (ls_situacion='E' or ls_situacion='S') then
        ln_gasper_s_12 := ln_gasper_s_12 + ((ln_gasper_t + ln_quinquenio_12) * an_factor_12) ;
        ln_gratif_s_12 := ln_gratif_s_12 + (ln_gratif_t * an_factor_12) ;
        ln_impcts_s_12 := ln_impcts_s_12 + (ln_impcts_t * an_factor_12) ;
      End if ;
    End if ;  
  End loop ;  

End Loop ;

--  Convierte Flujo de Caja a Dolares
If an_tipo_cambio > 0 then
  For x in an_mes_desde .. an_mes_hasta Loop
    If x = 01 then
      ln_gasper_d_01 := ln_gasper_s_01 / an_tipo_cambio ;
      ln_impcts_d_01 := ln_impcts_s_01 / an_tipo_cambio ;
    Elsif x = 02 then
      ln_gasper_d_02 := ln_gasper_s_02 / an_tipo_cambio ;
      ln_impcts_d_02 := ln_impcts_s_02 / an_tipo_cambio ;
    Elsif x = 03 then
      ln_gasper_d_03 := ln_gasper_s_03 / an_tipo_cambio ;
      ln_impcts_d_03 := ln_impcts_s_03 / an_tipo_cambio ;
    Elsif x = 04 then
      ln_gasper_d_04 := ln_gasper_s_04 / an_tipo_cambio ;
      ln_impcts_d_04 := ln_impcts_s_04 / an_tipo_cambio ;
    Elsif x = 05 then
      ln_gasper_d_05 := ln_gasper_s_05 / an_tipo_cambio ;
      ln_impcts_d_05 := ln_impcts_s_05 / an_tipo_cambio ;
    Elsif x = 06 then
      ln_gasper_d_06 := ln_gasper_s_06 / an_tipo_cambio ;
      ln_impcts_d_06 := ln_impcts_s_06 / an_tipo_cambio ;
    Elsif x = 07 then
      ln_gasper_d_07 := ln_gasper_s_07 / an_tipo_cambio ;
      ln_gratif_d_07 := ln_gratif_s_07 / an_tipo_cambio ;
      ln_impcts_d_07 := ln_impcts_s_07 / an_tipo_cambio ;
    Elsif x = 08 then
      ln_gasper_d_08 := ln_gasper_s_08 / an_tipo_cambio ;
      ln_impcts_d_08 := ln_impcts_s_08 / an_tipo_cambio ;
    Elsif x = 09 then
      ln_gasper_d_09 := ln_gasper_s_09 / an_tipo_cambio ;
      ln_impcts_d_09 := ln_impcts_s_09 / an_tipo_cambio ;
    Elsif x = 10 then
      ln_gasper_d_10 := ln_gasper_s_10 / an_tipo_cambio ;
      ln_impcts_d_10 := ln_impcts_s_10 / an_tipo_cambio ;
    Elsif x = 11 then
      ln_gasper_d_11 := ln_gasper_s_11 / an_tipo_cambio ;
      ln_impcts_d_11 := ln_impcts_s_11 / an_tipo_cambio ;
    Elsif x = 12 then
      ln_gasper_d_12 := ln_gasper_s_12 / an_tipo_cambio ;
      ln_gratif_d_12 := ln_gratif_s_12 / an_tipo_cambio ;
      ln_impcts_d_12 := ln_impcts_s_12 / an_tipo_cambio ;
    End if ;  
  End loop ;  
End if ;

--  Graba Informacion del Flujo de Caja Estimado de Planilla
--  Graba Flujo de Caja en SOLES
If as_tipo_moneda = 'S' then                        
  For x in an_mes_desde .. an_mes_hasta Loop
    ln_gasper := 0 ; ln_gratif := 0 ; ln_impcts := 0 ;
    If x = 01 then
      ln_gasper := ln_gasper_s_01 ;
      ln_impcts := ln_impcts_s_01 ;
    Elsif x = 02 then
      ln_gasper := ln_gasper_s_02 ;
      ln_impcts := ln_impcts_s_02 ;
    Elsif x = 03 then
      ln_gasper := ln_gasper_s_03 ;
      ln_impcts := ln_impcts_s_03 ;
    Elsif x = 04 then
      ln_gasper := ln_gasper_s_04 ;
      ln_impcts := ln_impcts_s_04 ;
    Elsif x = 05 then
      ln_gasper := ln_gasper_s_05 ;
      ln_impcts := ln_impcts_s_05 ;
    Elsif x = 06 then
      ln_gasper := ln_gasper_s_06 ;
      ln_impcts := ln_impcts_s_06 ;
    Elsif x = 07 then
      ln_gasper := ln_gasper_s_07 ;
      ln_gratif := ln_gratif_s_07 ;
      ln_impcts := ln_impcts_s_07 ;
    Elsif x = 08 then
      ln_gasper := ln_gasper_s_08 ;
      ln_impcts := ln_impcts_s_08 ;
    Elsif x = 09 then
      ln_gasper := ln_gasper_s_09 ;
      ln_impcts := ln_impcts_s_09 ;
    Elsif x = 10 then
      ln_gasper := ln_gasper_s_10 ;
      ln_impcts := ln_impcts_s_10 ;
    Elsif x = 11 then
      ln_gasper := ln_gasper_s_11 ;
      ln_impcts := ln_impcts_s_11 ;
    Elsif x = 12 then
      ln_gasper := ln_gasper_s_12 ;
      ln_gratif := ln_gratif_s_12 ;
      ln_impcts := ln_impcts_s_12 ;
    End if ;  
    ln_gasper := nvl(ln_gasper,0) ;
    ln_gratif := nvl(ln_gratif,0) ;
    ln_impcts := nvl(ln_impcts,0) ;
    If ln_gasper > 0 then
      Insert into flujo_caja
        ( cod_flujo_caja, periodo, mes, flag_flujo,
          cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
      Values
        ( 'GASPER    ', an_periodo, x, 'E',
          ln_gasper, '1', 'S/.', 0 ) ;
    End if ;
    If ln_gratif > 0 then
      Insert into flujo_caja
        ( cod_flujo_caja, periodo, mes, flag_flujo,
          cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
      Values
        ( 'GASGRA    ', an_periodo, x, 'E',
          ln_gratif, '1', 'S/.', 0 ) ;
    End if ;
    If ln_impcts > 0 then
      Insert into flujo_caja
        ( cod_flujo_caja, periodo, mes, flag_flujo,
          cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
      Values
        ( 'GASCTS    ', an_periodo, x, 'E',
          ln_impcts, '1', 'S/.', 0 ) ;
    End if ;
  End loop ;  
--  Graba Flujo de Caja en DOLARES
Else
  For x in an_mes_desde .. an_mes_hasta Loop
    ln_gasper := 0 ; ln_gratif := 0 ; ln_impcts := 0 ;
    If x = 01 then
      ln_gasper := ln_gasper_d_01 ;
      ln_impcts := ln_impcts_d_01 ;
    Elsif x = 02 then
      ln_gasper := ln_gasper_d_02 ;
      ln_impcts := ln_impcts_d_02 ;
    Elsif x = 03 then
      ln_gasper := ln_gasper_d_03 ;
      ln_impcts := ln_impcts_d_03 ;
    Elsif x = 04 then
      ln_gasper := ln_gasper_d_04 ;
      ln_impcts := ln_impcts_d_04 ;
    Elsif x = 05 then
      ln_gasper := ln_gasper_d_05 ;
      ln_impcts := ln_impcts_d_05 ;
    Elsif x = 06 then
      ln_gasper := ln_gasper_d_06 ;
      ln_impcts := ln_impcts_d_06 ;
    Elsif x = 07 then
      ln_gasper := ln_gasper_d_07 ;
      ln_gratif := ln_gratif_d_07 ;
      ln_impcts := ln_impcts_d_07 ;
    Elsif x = 08 then
      ln_gasper := ln_gasper_d_08 ;
      ln_impcts := ln_impcts_d_08 ;
    Elsif x = 09 then
      ln_gasper := ln_gasper_d_09 ;
      ln_impcts := ln_impcts_d_09 ;
    Elsif x = 10 then
      ln_gasper := ln_gasper_d_10 ;
      ln_impcts := ln_impcts_d_10 ;
    Elsif x = 11 then
      ln_gasper := ln_gasper_d_11 ;
      ln_impcts := ln_impcts_d_11 ;
    Elsif x = 12 then
      ln_gasper := ln_gasper_d_12 ;
      ln_gratif := ln_gratif_d_12 ;
      ln_impcts := ln_impcts_d_12 ;
    End if ;  
    ln_gasper := nvl(ln_gasper,0) ;
    ln_gratif := nvl(ln_gratif,0) ;
    ln_impcts := nvl(ln_impcts,0) ;
    If ln_gasper > 0 then
      Insert into flujo_caja
        ( cod_flujo_caja, periodo, mes, flag_flujo,
          cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
      Values
        ( 'GASPER    ', an_periodo, x, 'E',
          ln_gasper, '1', 'US$', an_tipo_cambio ) ;
    End if ;
    If ln_gratif > 0 then
      Insert into flujo_caja
        ( cod_flujo_caja, periodo, mes, flag_flujo,
          cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
      Values
        ( 'GASGRA    ', an_periodo, x, 'E',
          ln_gratif, '1', 'US$', an_tipo_cambio ) ;
    End if ;
    If ln_impcts > 0 then
      Insert into flujo_caja
        ( cod_flujo_caja, periodo, mes, flag_flujo,
          cantidad, flag_estado, cod_moneda, tipo_cambio_estim )
      Values
        ( 'GASCTS    ', an_periodo, x, 'E',
          ln_impcts, '1', 'US$', an_tipo_cambio ) ;
    End if ;
  End loop ;  
End if ;

End usp_flujo_caja_estimado ;
/
