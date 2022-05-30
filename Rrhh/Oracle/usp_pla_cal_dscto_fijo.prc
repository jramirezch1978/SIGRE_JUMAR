create or replace procedure usp_pla_cal_dscto_fijo
  ( as_codtra      in maestro.cod_trabajador%type, 
    as_codusr      in usuario.cod_usr%type,
    ad_fec_proceso in date,
    an_diatra      in calculo.dias_trabaj%type, 
    an_diames      in calculo.dias_trabaj%type
   ) is
   
   ld_ran_ini rrhhparam.fec_desde%type;
   ld_ran_fin rrhhparam.fec_desde%type;

   -- determinar Descuentos Variables
   Cursor c_dscto_variable is
   Select gdv.fec_movim, gdv.concep, gdv.imp_var, 
          gdv.cencos
     from gan_desct_variable gdv
     where gdv.cod_trabajador = as_codtra 
           and ( gdv.fec_movim between 
   ld_ran_ini and ld_ran_fin ) ;
           
   -- determinar concepto
   Cursor c_concepto ( as_concepto concepto.concep%type ) is
   Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
          c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
          c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
          c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, 
          c.flag_t_quinquenio, 
          c.flag_e_essalud, c.flag_e_agrario, 
          c.flag_e_essalud_vida, c.flag_e_ies, 
          c.flag_e_senati, c.flag_e_sctr_ipss, 
          c.flag_e_sctr_onp, 
          c.nro_horas, c.fact_pago
     from concepto c
     where c.concep = as_concepto ;

   ln_hortra   sobretiempo_turno.horas_sobret%type;
   ln_horpag   sobretiempo_turno.horas_sobret%type;
   ln_impsol   calculo.imp_soles%type;
   ln_impdol   calculo.imp_dolar%type;
   ln_tipcam   calendario.cmp_dol_prom%type ;

begin

-- determinar rangos de generacion
  Select rh.fec_desde, rh.fec_hasta
    into ld_ran_ini, ld_ran_fin
    from rrhhparam rh
    where rh.reckey = '1' ;

-- Determinando el tipo de cambio del dolar
  Select tc.vta_dol_prom
    into ln_tipcam
    from calendario tc
    where tc.fecha = ad_fec_proceso ;
          ln_tipcam := nvl ( ln_tipcam, 1);
      
  For rc_dv in c_dscto_variable Loop
    For rc_c in c_concepto ( rc_dv.concep ) Loop
      ln_hortra := an_diatra * 8 ;
      ln_horpag := ln_hortra ;
      ln_impsol := rc_dv.imp_var ;
      ln_impdol := ln_impsol / ln_tipcam ;

      Insert into Calculo ( Cod_Trabajador, 
              Concep,          Fec_Proceso, 
              Horas_Trabaj,    Horas_Pag, Dias_Trabaj, 
              Imp_Soles,       Imp_Dolar, Flag_t_Snp, 
              Flag_t_Quinta,        Flag_t_Judicial, 
              Flag_t_Afp,           Flag_t_Bonif_30, 
              Flag_t_Bonif_25,      Flag_t_Gratif, 
              Flag_t_Cts,           Flag_t_Vacacio, 
              Flag_t_Bonif_Vacacio, Flag_t_Pago_Quincena, 
              Flag_t_Quinquenio,    Flag_e_Essalud, 
              Flag_e_Ies,           Flag_e_Senati, 
              Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
              Values ( as_codtra, 
              rc_dv.concep, ad_fec_proceso,
              ln_hortra,    ln_horpag, an_diatra, 
              ln_impsol,    ln_impdol,  rc_c.Flag_t_Snp, 
              rc_c.Flag_t_Quinta,     rc_c.Flag_t_Judicial, 
              rc_c.Flag_t_Afp,        rc_c.Flag_t_Bonif_30, 
              rc_c.Flag_t_Bonif_25,   rc_c.Flag_t_Gratif, 
              rc_c.Flag_t_Cts,        rc_c.Flag_t_Vacacio, 
              rc_c.Flag_t_Bonif_Vacacio, rc_c.Flag_t_Pago_Quincena, 
              rc_c.Flag_t_Quinquenio, rc_c.Flag_e_Essalud, 
              rc_c.Flag_e_Ies,        rc_c.Flag_e_Senati, 
              rc_c.Flag_e_Sctr_Ipss,  rc_c.Flag_e_Sctr_Onp ) ;
           
    End Loop;       
  End Loop ;
   
End usp_pla_cal_dscto_fijo;
/
