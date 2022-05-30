create or replace procedure usp_liquidacion_cts
  (ad_fec_proceso in rrhhparam.fec_proceso%type,
   ad_fec_desde   in rrhhparam.fec_proceso%type,
   ad_fec_hasta   in rrhhparam.fec_proceso%type) is

lk_nivel1                 constant char(3) := '001' ;
ls_codigo                 char(8) ;
ls_nombres                varchar2(40) ;
ls_seccion                char(3) ;
ls_desc_seccion           varchar2(40) ;
ld_fec_ingreso            date ;
ln_dias                   number(5,2) ;
ls_concepto               char(4) ;
ls_desc_concepto          varchar2(30) ;
ln_importe                number(13,2) ;

ls_bonif                  char(1) ;
ln_contador               number(3) ;
ln_importe_3025           number(13,2) ;
ln_num_mes                number(5) ;
ln_acu_soles              number(13,2) ;
ld_ran_ini                date ;
ld_ran_fin                date ;
ln_importe_total          number(13,2) ;
ls_mes_proceso            char(2) ;
ls_year                   char(4) ;
ld_fec_pago               date ;

--  Conceptos de ganancias fijas
Cursor c_maestro is
  Select m.cod_trabajador, m.fec_ingreso, m.bonif_fija_30_25,
         m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and
        m.flag_cal_plnlla = '1' and
        m.cod_seccion <> '950' ;

--  Conceptos de ganancias fijas
Cursor c_ganancias_fijas is
  Select gdf.concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = ls_codigo and
        gdf.flag_estado = '1' and
        gdf.flag_trabaj = '1' and
        substr(gdf.concep,1,2) = '10' ;

--  Conceptos para hallar promedio de los ultimos seis meses
Cursor c_concep ( as_nivel in string ) is 
  select concep
  from rrhh_nivel_detalle 
  where cod_nivel = as_nivel ;

begin

delete from tt_liq_cts ;

For rc_mae in c_maestro Loop
  
  ls_codigo      := rc_mae.cod_trabajador ;
  ld_fec_ingreso := rc_mae.fec_ingreso ;
  ls_bonif       := rc_mae.bonif_fija_30_25 ;
  ls_seccion     := rc_mae.cod_seccion ;
  ls_bonif       := nvl(ls_bonif,'0') ;
  ls_nombres     := usf_nombre_trabajador(ls_codigo) ;

  If ls_seccion is null then
    ls_seccion := '340' ;
  End if ;
  
  Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_seccion = ls_seccion ;
  ls_desc_seccion := nvl(ls_desc_seccion,' ') ;

  ln_contador := 0 ; ln_dias := 0 ;
  Select count(*)
    into ln_contador
    from prov_cts_gratif pcg
    where pcg.cod_trabajador = ls_codigo ;
  ln_contador := nvl(ln_contador,0) ;

  If ln_contador > 0 then
    Select pcg.dias_trabaj
      into ln_dias
      from prov_cts_gratif pcg
      where pcg.cod_trabajador = ls_codigo ;
    ln_dias := nvl(ln_dias,0) ;
  End if ;

  --  Genera liquidacion si tiene dias trabajados en el semestre
  If ln_dias > 0 then 
  
    --  Calcula ganancias fijas
    ln_importe_3025 := 0 ;
    For rc_gan in c_ganancias_fijas Loop

      ls_concepto     := rc_gan.concep ;
      ln_importe      := rc_gan.imp_gan_desc ;
      ln_importe      := nvl(ln_importe,0) ;
      ln_importe_3025 := ln_importe_3025 + ln_importe ;
      
      If ln_importe > 0 then

        ln_importe := ( ln_importe / 360 ) * ln_dias ;
        Select c.desc_breve
          into ls_desc_concepto
          from concepto c
          where c.concep = ls_concepto ;
        ls_desc_concepto := nvl(ls_desc_concepto,' ' ) ;

        Insert into tt_liq_cts
          (fecha, fec_desde, fec_hasta,
           codigo, nombres, seccion,
           desc_seccion, fec_ingreso, dias,
           concepto, desc_concepto, importe)
        Values
          (ad_fec_proceso, ad_fec_desde, ad_fec_hasta,
           ls_codigo, ls_nombres, ls_seccion,
           ls_desc_seccion, ld_fec_ingreso, ln_dias,
           ls_concepto, ls_desc_concepto, ln_importe) ;
      
      End if ;
      
    End Loop ;
  
    --  Calcula bonificacion del 30% o 25%
    ln_importe := 0 ;
    If ls_bonif = '1' then
      ln_importe := ( ( ln_importe_3025 * 0.30 ) / 360 ) * ln_dias ;
      Insert into tt_liq_cts
        (fecha, fec_desde, fec_hasta,
         codigo, nombres, seccion,
         desc_seccion, fec_ingreso, dias,
         concepto, desc_concepto, importe)
      Values
        (ad_fec_proceso, ad_fec_desde, ad_fec_hasta,
         ls_codigo, ls_nombres, ls_seccion,
         ls_desc_seccion, ld_fec_ingreso, ln_dias,
         '1030', 'BONIFICACION 30%', ln_importe) ;
    Elsif ls_bonif = '2' then
      ln_importe := ( ( ln_importe_3025 * 0.25 ) / 360 ) * ln_dias ;
      Insert into tt_liq_cts
        (fecha, fec_desde, fec_hasta,
         codigo, nombres, seccion,
         desc_seccion, fec_ingreso, dias,
         concepto, desc_concepto, importe)
      Values
        (ad_fec_proceso, ad_fec_desde, ad_fec_hasta,
         ls_codigo, ls_nombres, ls_seccion,
         ls_desc_seccion, ld_fec_ingreso, ln_dias,
         '1025', 'BONIFICACION 25%', ln_importe) ;
    End if ;
  
    --  Calcula promedio de los ultimos seis meses
    ln_importe       := 0 ;
    ln_importe_total := 0 ;
    ln_num_mes       := 0 ;
    For rc_concep in c_concep ( lk_nivel1 ) Loop

      ld_ran_ini   := add_months(ad_fec_proceso, - 1) ;
      ln_num_mes   := 0 ; 
      ln_acu_soles := 0 ;
            
      For x in reverse 1 .. 6 Loop
        ld_ran_fin    := ld_ran_ini ;
        ld_ran_ini    := add_months( ld_ran_fin, -1 ) + 1 ;
        ln_importe := 0 ;
                
        ln_contador := 0 ;
        Select count( hc.imp_soles )
          into ln_contador
          from historico_calculo hc 
          where hc.concep = rc_concep.concep and 
                hc.cod_trabajador = ls_codigo and 
                hc.fec_calc_plan between 
                ld_ran_ini and ld_ran_fin ;
              
        ln_contador := nvl ( ln_contador , 0 ) ;
        If ln_contador > 0 then 
          Select sum( hc.imp_soles)
            into ln_importe
            from historico_calculo hc 
            where hc.concep = rc_concep.concep and
                  hc.cod_trabajador = ls_codigo and
                  hc.fec_calc_plan between 
                  ld_ran_ini and ld_ran_fin ;
        End if;
        ln_importe := nvl ( ln_importe , 0 ) ;

        If ln_importe > 0 then 
          ln_num_mes   := ln_num_mes + 1 ;
          ln_acu_soles := ln_acu_soles + ln_importe ;
        End if; 
                
        ld_ran_ini := ld_ran_ini - 1 ;
      End Loop ;
    
      If ln_num_mes > 2 Then 
        ln_importe_total := ln_importe_total + (ln_acu_soles / 6 ) ;
      End If;
        
    End Loop;
  
    If ln_importe_total > 0 then
      Insert into tt_liq_cts
        (fecha, fec_desde, fec_hasta,
         codigo, nombres, seccion,
         desc_seccion, fec_ingreso, dias,
         concepto, desc_concepto, importe)
      Values
        (ad_fec_proceso, ad_fec_desde, ad_fec_hasta,
         ls_codigo, ls_nombres, ls_seccion,
         ls_desc_seccion, ld_fec_ingreso, ln_dias,
         '1450', 'GANANCIAS VARIABLES', ln_importe_total) ;
    End if ;
  
    --  Halla gratificaciones
    ln_importe     := 0 ;
    ls_mes_proceso := to_char (ad_fec_proceso, 'MM' ) ;
    If ls_mes_proceso = '04' then
      ls_year     := to_char ( ad_fec_proceso, 'YYYY' ) ;
      ls_year     := to_char ( to_number(ls_year) - 1 ) ;
      ld_fec_pago := to_date ( '31'||'/'||'12'||'/'||ls_year,'DD/MM/YYYY' ) ;
      ls_concepto := '1411' ;
    Elsif ls_mes_proceso = '10' then
      ls_year     := to_char ( ad_fec_proceso, 'YYYY' ) ;
      ld_fec_pago := to_date ( '31'||'/'||'07'||'/'||ls_year,'DD/MM/YYYY' ) ;
      ls_concepto := '1410' ;
    End if ;

    Select sum( hc.imp_soles)
      into ln_importe
      from historico_calculo hc 
      where hc.concep = ls_concepto and
            hc.cod_trabajador = ls_codigo and
            hc.fec_calc_plan  = ld_fec_pago ;
    ln_importe := nvl(ln_importe,0) ;
    
    If ln_importe > 0 then
      Select c.desc_breve
        into ls_desc_concepto
        from concepto c
        where c.concep = ls_concepto ;
      ls_desc_concepto := nvl(ls_desc_concepto,' ' ) ;
      Insert into tt_liq_cts
        (fecha, fec_desde, fec_hasta,
         codigo, nombres, seccion,
         desc_seccion, fec_ingreso, dias,
         concepto, desc_concepto, importe)
      Values
        (ad_fec_proceso, ad_fec_desde, ad_fec_hasta,
         ls_codigo, ls_nombres, ls_seccion,
         ls_desc_seccion, ld_fec_ingreso, ln_dias,
         ls_concepto, ls_desc_concepto, ln_importe) ;
    End if ;
     
  End if ;

End loop ;

End usp_liquidacion_cts ;
/
