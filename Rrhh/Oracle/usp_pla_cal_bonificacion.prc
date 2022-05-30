create or replace procedure usp_pla_cal_bonificacion
  (as_codtra      in maestro.cod_trabajador%type,
  ad_fec_proceso  in calculo.fec_proceso%type,
  an_diames       in rrhhparam.dias_mes_obrero%type
  ) is

ls_tipo_ina        char(3);
lk_gan_fij         constant char(3) := '085';
lk_gan_fij_25      constant char(3) := '086';
lk_gan_fij_30      constant char(3) := '087';
ls_concep_bon      concepto.concep%type;
ls_concep_bon25    concepto.concep%type;
ls_concep_bon30    concepto.concep%type;
ln_diavac          calculo.dias_trabaj%type;
ln_imp_soles       calculo.imp_soles%type;
ln_imp_dolar       calculo.imp_soles%type;
ln_tipcam          calendario.cmp_dol_prom%type;
ls_bonif           maestro.bonif_fija_30_25%type;
ln_factor          concepto.fact_pago%type;

--  Concepto de inasistencias
Cursor c_inasistencias is
Select i.dias_inasist
  from inasistencia i
  where i.cod_trabajador = as_codtra
        and i.concep in (
        Select rhpn.concep
          from rrhh_nivel rhpn
          where rhpn.cod_nivel = ls_tipo_ina );
      
--  Conceptos de ganancias fijas
Cursor c_ganancias_fijas is
  Select gdf.concep, gdf.imp_gan_desc
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = as_codtra 
        and gdf.flag_estado = '1'
        and gdf.flag_trabaj = '1'
        and gdf.concep in (
        Select rhpd.concep
          from rrhh_nivel_detalle rhpd
          where rhpd.cod_nivel = lk_gan_fij ) ;

--  Determina conceptos
Cursor c_concepto ( as_concepto concepto.concep%type ) is
  Select c.flag_t_snp,       c.flag_t_quinta,        c.flag_t_judicial,
    c.flag_t_afp,            c.flag_t_bonif_30,      c.flag_t_bonif_25,
    c.flag_t_gratif,         c.flag_t_cts,           c.flag_t_vacacio, 
    c.flag_t_bonif_vacacio,  c.flag_t_pago_quincena, 
    c.flag_t_quinquenio, 
    c.flag_e_essalud,        c.flag_e_agrario, 
    c.flag_e_essalud_vida,   c.flag_e_ies, 
    c.flag_e_senati,         c.flag_e_sctr_ipss, 
    c.flag_e_sctr_onp,
    c.nro_horas, c.fact_pago
  from concepto c
  where c.concep = as_concepto ;
             
begin

Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
        ln_tipcam := nvl ( ln_tipcam, 1);

--  Obtiene concepto de vacaciones del periodo
select rpn.concep
  into ls_concep_bon
  from rrhh_nivel rpn
  where rpn.cod_nivel = lk_gan_fij;

--  Obtiene concepto de vacaciones del periodo 25%
select rpn.concep
  into ls_concep_bon25
  from rrhh_nivel rpn
  where rpn.cod_nivel = lk_gan_fij_25;

--  Obtiene concepto de vacaciones del periodo 30%
select rpn.concep
  into ls_concep_bon30
  from rrhh_nivel rpn
  where rpn.cod_nivel = lk_gan_fij_30;

--  Indica si percibe bonificacion del 25% o 30%
Select m.bonif_fija_30_25
  into ls_bonif
  from maestro m
  where m.cod_trabajador = as_codtra ;
  ls_bonif := nvl(ls_bonif,0) ;

--  Determina si tiene dias de vacaciones
ln_diavac := 0 ;
ls_tipo_ina := lk_gan_fij ;  
For rc_ina in c_inasistencias Loop
  ln_diavac := ln_diavac + rc_ina.dias_inasist ;
End Loop ;
  
--  Calcula vacaciones si tiene dias
If ln_diavac > 0 then

  ln_imp_soles := 0 ;
  For rc_gan in c_ganancias_fijas Loop
    ln_imp_soles := ln_imp_soles + rc_gan.imp_gan_desc ;
  End Loop ;
    
  ln_imp_soles := (ln_imp_soles / 30) * ln_diavac ;  
  ln_imp_dolar := ln_imp_soles / ln_tipcam ;

  For rc_c in c_concepto ( ls_concep_bon ) Loop
    Insert into Calculo ( Cod_Trabajador, 
      Concep,               Fec_Proceso, 
      Horas_Trabaj,         Horas_Pag, Dias_Trabaj, 
      Imp_Soles,            Imp_Dolar, Flag_t_Snp, 
      Flag_t_Quinta,        Flag_t_Judicial, 
      Flag_t_Afp,           Flag_t_Bonif_30, 
      Flag_t_Bonif_25,      Flag_t_Gratif, 
      Flag_t_Cts,           Flag_t_Vacacio, 
      Flag_t_Bonif_Vacacio, Flag_t_Pago_Quincena, 
      Flag_t_Quinquenio,    Flag_e_Essalud, 
      Flag_e_agrario,       Flag_e_essalud_vida,
      Flag_e_Ies,           Flag_e_Senati, 
      Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
    Values ( as_codtra, 
      ls_concep_bon, ad_fec_proceso,
      0            , 0             , ln_diavac, 
      ln_imp_soles , ln_imp_dolar  , rc_c.Flag_t_Snp, 
      rc_c.Flag_t_Quinta           , rc_c.Flag_t_Judicial, 
      rc_c.Flag_t_Afp              , rc_c.Flag_t_Bonif_30, 
      rc_c.Flag_t_Bonif_25         , rc_c.Flag_t_Gratif, 
      rc_c.Flag_t_Cts              , rc_c.Flag_t_Vacacio, 
      rc_c.Flag_t_Bonif_Vacacio    , rc_c.Flag_t_Pago_Quincena, 
      rc_c.Flag_t_Quinquenio       , rc_c.Flag_e_Essalud, 
      rc_c.Flag_e_agrario          , rc_c.Flag_e_essalud_vida,
      rc_c.Flag_e_Ies              , rc_c.Flag_e_Senati, 
      rc_c.Flag_e_Sctr_Ipss        , rc_c.Flag_e_Sctr_Onp ) ;
    End Loop ;
    
  If ls_bonif = '1' or ls_bonif = '2' then
    If ls_bonif = '2' then
       For rc_c in c_concepto ( ls_concep_bon25 ) Loop
         ln_factor := rc_c.fact_pago ;
         ln_imp_soles := ln_imp_soles * ln_factor ;
         ln_imp_dolar := ln_imp_soles / ln_tipcam ;
       Insert into Calculo ( Cod_Trabajador, 
         Concep,               Fec_Proceso, 
         Horas_Trabaj,         Horas_Pag, Dias_Trabaj, 
         Imp_Soles,            Imp_Dolar, Flag_t_Snp, 
         Flag_t_Quinta,        Flag_t_Judicial, 
         Flag_t_Afp,           Flag_t_Bonif_30, 
         Flag_t_Bonif_25,      Flag_t_Gratif, 
         Flag_t_Cts,           Flag_t_Vacacio, 
         Flag_t_Bonif_Vacacio, Flag_t_Pago_Quincena, 
         Flag_t_Quinquenio,    Flag_e_Essalud, 
         Flag_e_agrario,       Flag_e_essalud_vida,
         Flag_e_Ies,           Flag_e_Senati, 
         Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
       Values ( as_codtra, 
         ls_concep_bon25, ad_fec_proceso,
         0            , 0             , ln_diavac, 
         ln_imp_soles , ln_imp_dolar  , rc_c.Flag_t_Snp, 
         rc_c.Flag_t_Quinta           , rc_c.Flag_t_Judicial, 
         rc_c.Flag_t_Afp              , rc_c.Flag_t_Bonif_30, 
         rc_c.Flag_t_Bonif_25         , rc_c.Flag_t_Gratif, 
         rc_c.Flag_t_Cts              , rc_c.Flag_t_Vacacio, 
         rc_c.Flag_t_Bonif_Vacacio    , rc_c.Flag_t_Pago_Quincena, 
         rc_c.Flag_t_Quinquenio       , rc_c.Flag_e_Essalud, 
         rc_c.Flag_e_agrario          , rc_c.Flag_e_essalud_vida,
         rc_c.Flag_e_Ies              , rc_c.Flag_e_Senati, 
         rc_c.Flag_e_Sctr_Ipss        , rc_c.Flag_e_Sctr_Onp ) ;
       End Loop ;
    Else
       For rc_c in c_concepto ( ls_concep_bon30 ) Loop
         ln_factor := rc_c.fact_pago ;
         ln_imp_soles := ln_imp_soles * ln_factor ;
         ln_imp_dolar := ln_imp_soles / ln_tipcam ;
       Insert into Calculo ( Cod_Trabajador, 
         Concep,               Fec_Proceso, 
         Horas_Trabaj,         Horas_Pag, Dias_Trabaj, 
         Imp_Soles,            Imp_Dolar, Flag_t_Snp, 
         Flag_t_Quinta,        Flag_t_Judicial, 
         Flag_t_Afp,           Flag_t_Bonif_30, 
         Flag_t_Bonif_25,      Flag_t_Gratif, 
         Flag_t_Cts,           Flag_t_Vacacio, 
         Flag_t_Bonif_Vacacio, Flag_t_Pago_Quincena, 
         Flag_t_Quinquenio,    Flag_e_Essalud, 
         Flag_e_agrario,       Flag_e_essalud_vida,
         Flag_e_Ies,           Flag_e_Senati, 
         Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
       Values ( as_codtra, 
         ls_concep_bon30, ad_fec_proceso,
         0            , 0             , ln_diavac, 
         ln_imp_soles , ln_imp_dolar  , rc_c.Flag_t_Snp, 
         rc_c.Flag_t_Quinta           , rc_c.Flag_t_Judicial, 
         rc_c.Flag_t_Afp              , rc_c.Flag_t_Bonif_30, 
         rc_c.Flag_t_Bonif_25         , rc_c.Flag_t_Gratif, 
         rc_c.Flag_t_Cts              , rc_c.Flag_t_Vacacio, 
         rc_c.Flag_t_Bonif_Vacacio    , rc_c.Flag_t_Pago_Quincena, 
         rc_c.Flag_t_Quinquenio       , rc_c.Flag_e_Essalud, 
         rc_c.Flag_e_agrario          , rc_c.Flag_e_essalud_vida,
         rc_c.Flag_e_Ies              , rc_c.Flag_e_Senati, 
         rc_c.Flag_e_Sctr_Ipss        , rc_c.Flag_e_Sctr_Onp ) ;
       End Loop ;
    End if ;
  End if ;
End if ;
      
End usp_pla_cal_bonificacion;
/
