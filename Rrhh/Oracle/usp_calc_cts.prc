create or replace procedure usp_calc_cts
   (as_codtra      in maestro.cod_trabajador%type,
    ad_fec_proceso in calculo.fec_proceso%type
   ) is

lk_nivel1          constant char(3) := '001' ;
lk_bonif25         constant char(3) := '091' ;
lk_bonif30         constant char(3) := '092' ;
lk_gan_fij         constant char(3) := '400' ;
lk_gra_jul         constant char(3) := '401' ;
lk_gra_dic         constant char(3) := '402' ;
lk_gratif          char(3) ;
ls_concep          concepto.concep%type ;
ln_imp_soles       calculo.imp_soles%type ;
ls_bonif           maestro.bonif_fija_30_25%type ;
ls_cod_seccion     maestro.cod_seccion%type ;
ln_factor          concepto.fact_pago%type ;
ln_dia_tra         prov_cts_gratif.dias_trabaj%type ;
ln_prov_cts_01     prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_02     prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_03     prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_04     prov_cts_gratif.prov_cts_01%type ;
ln_prov_cts_05     prov_cts_gratif.prov_cts_01%type ;
ln_prov_acumul     prov_cts_gratif.prov_cts_01%type ;
ls_mes_proceso     char(2) ;
ls_year            char(4) ;
ld_fec_pago        historico_calculo.fec_calc_plan%type ;
ln_contador        integer ;

ld_ran_ini         date;
ld_ran_fin         date;
ln_num_reg         number(5);
ln_imp_solesv      historico_calculo.imp_soles%type ;
ln_num_mes         integer;
ln_acu_soles       historico_calculo.imp_soles%type ;
ln_tot_soles       historico_calculo.imp_soles%type ;
ld_fec_ingreso     maestro.fec_ingreso%type ;

--  Conceptos de ganancias fijas
Cursor c_ganancias_fijas is
  Select gdf.concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = as_codtra 
        and gdf.flag_estado = '1'
        and gdf.flag_trabaj = '1'
        and gdf.concep in (
        select rhnd.concep
        from rrhh_nivel_detalle rhnd
        where rhnd.cod_nivel = lk_gan_fij ) ;

--  Cursor para gratificaciones ( Julio o Diciembre )
Cursor c_historico_calculo is
  Select hc.concep, hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = as_codtra 
        and hc.fec_calc_plan = ld_fec_pago
        and hc.concep in (
        select rhn.concep
        from rrhh_nivel rhn
        where rhn.cod_nivel = lk_gratif ) ;

--  Determina conceptos para aplicar el 30% o 25%
Cursor c_concepto ( as_concepto concepto.concep%type ) is
  Select c.fact_pago
  from concepto c
  where c.concep = as_concepto ;
             
--  Conceptos para hallar promedio de los ultimos seis meses
Cursor c_concep ( as_nivel in string ) is 
  select concep
  from rrhh_nivel_detalle 
  where cod_nivel = as_nivel ;

begin

--  Indica si percibe bonificacion del 25% o 30%
Select m.bonif_fija_30_25, m.cod_seccion, m.fec_ingreso
  into ls_bonif, ls_cod_seccion, ld_fec_ingreso
  from maestro m
  where m.cod_trabajador = as_codtra ;
  
--  Calcula provisiones de C.T.S.

If ls_cod_seccion <> '950' then

  ln_imp_soles := 0 ;
  For rc_gan in c_ganancias_fijas
    Loop
      ln_imp_soles := ln_imp_soles + rc_gan.imp_gan_desc ;
    End Loop ;
  
  If ls_bonif = '1' then
    Select rhn.concep
      into ls_concep
      from rrhh_nivel rhn
       where rhn.cod_nivel = lk_bonif30 ;
 
    For rc_c in c_concepto ( ls_concep ) Loop
      ln_factor := rc_c.fact_pago;
      ln_imp_soles := ln_imp_soles + ( ln_imp_soles * ln_factor ) ;
    End Loop;       

  Elsif ls_bonif = '2' then
    Select rhn.concep
      into ls_concep
      from rrhh_nivel rhn
       where rhn.cod_nivel = lk_bonif25 ;
 
    For rc_c in c_concepto ( ls_concep ) Loop
      ln_factor := rc_c.fact_pago;
      ln_imp_soles := ln_imp_soles + ( ln_imp_soles * ln_factor ) ;
    End Loop;       

  End if ;
 
  ls_mes_proceso := to_char (ad_fec_proceso, 'MM' ) ;
  If ls_mes_proceso = '04' then
    ls_year     := to_char ( ad_fec_proceso, 'YYYY' ) ;
    ls_year     := to_char ( to_number(ls_year) - 1 ) ;
    ld_fec_pago := to_date ( '31'||'/'||'12'||'/'||ls_year,'DD/MM/YYYY' ) ;
    lk_gratif   := lk_gra_dic ;
  Elsif ls_mes_proceso = '10' then
    ls_year     := to_char ( ad_fec_proceso, 'YYYY' ) ;
    ld_fec_pago := to_date ( '31'||'/'||'07'||'/'||ls_year,'DD/MM/YYYY' ) ;
    lk_gratif   := lk_gra_jul ;
  End if ;

  For rc_gra in c_historico_calculo Loop
    ln_imp_soles := ln_imp_soles + ( rc_gra.imp_soles / 6 ) ;
  End Loop ;
  
  --  Calcula promedio de los ultimos seis meses
  
  ln_tot_soles := 0 ;
  For rc_concep in c_concep ( lk_nivel1 ) Loop

    ld_ran_ini   := add_months(ad_fec_proceso, - 1) ;
    ln_num_mes   := 0 ; 
    ln_acu_soles := 0 ;
            
    For x in reverse 1 .. 6 Loop
      ld_ran_fin    := ld_ran_ini ;
      ld_ran_ini    := add_months( ld_ran_fin, -1 ) + 1 ;
      ln_imp_solesv := 0 ;
                
      Select count( hc.imp_soles )
        into ln_num_reg
        from historico_calculo hc 
        where hc.concep = rc_concep.concep and 
              hc.cod_trabajador = as_codtra and 
              hc.fec_calc_plan between 
              ld_ran_ini and ld_ran_fin ;
              
      ln_num_reg := nvl ( ln_num_reg , 0 ) ;
      If ln_num_reg > 0 then 
        Select sum( hc.imp_soles)
          into ln_imp_solesv
          from historico_calculo hc 
          where hc.concep = rc_concep.concep and
                hc.cod_trabajador = as_codtra and
                hc.fec_calc_plan between 
                ld_ran_ini and ld_ran_fin ;
      End if;
      ln_imp_solesv := nvl ( ln_imp_solesv , 0 ) ;

      If ln_imp_solesv > 0 then 
        ln_num_mes   := ln_num_mes + 1 ;
        ln_acu_soles := ln_acu_soles + ln_imp_solesv ;
      End if; 
                
      ld_ran_ini := ld_ran_ini - 1 ;
    End Loop ;
    
    If ln_num_mes > 2 Then 
      ln_tot_soles := ln_tot_soles + (ln_acu_soles / 6 ) ;
    End If;
        
  End Loop;
  
  --  Calcula C.T.S. del semestre  
  
  Select pcg.dias_trabaj, prov_cts_01, prov_cts_02, prov_cts_03,
         prov_cts_04, prov_cts_05
    into ln_dia_tra, ln_prov_cts_01, ln_prov_cts_02, ln_prov_cts_03,
         ln_prov_cts_04, ln_prov_cts_05
    from prov_cts_gratif pcg
    where pcg.cod_trabajador = as_codtra ;
  
  ln_imp_soles   := ln_imp_soles + ln_tot_soles ;
  ln_prov_acumul := ln_prov_cts_01 + ln_prov_cts_02 + ln_prov_cts_03 +  
                    ln_prov_cts_05 + ln_prov_cts_05 ;
  ln_prov_acumul := nvl(ln_prov_acumul,0) ;
  ln_dia_tra     := nvl(ln_dia_tra,0) ;
  ln_imp_soles   := ( ( ( ln_imp_soles / 360 ) * ln_dia_tra ) - ln_prov_acumul ) ;

  ln_contador := 0 ;
  Select count(*)
    Into ln_contador
    from prov_cts_gratif p
    where p.cod_trabajador = as_codtra ;
    
  If ln_contador > 0 then
    Update prov_cts_gratif
    Set prov_cts_06 = ln_imp_soles
    Where cod_trabajador = as_codtra ;
  Else
    Insert into prov_cts_gratif
        ( cod_trabajador, dias_trabaj, flag_estado,
          prov_cts_01   , prov_cts_02, prov_cts_03,
          prov_cts_04   , prov_cts_05, prov_cts_06 ) Values
        ( as_codtra     , ln_dia_tra , '1'        ,
          0             , 0          , 0          ,
          0             , 0           , ln_imp_soles ) ;
  End if ;

End if ;

end usp_calc_cts ;
/
