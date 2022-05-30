create or replace procedure USP_PLA_CALCULO(
   as_codtra             in maestro.cod_trabajador%type,
   as_codusr             in usuario.cod_usr%type,
   ad_fec_proceso        in control.fec_proceso%type, 
   an_und_impos_tribuc   in control.und_impos_tribut%type,
   an_dias_racion_cocida in control.dias_racion_cocida%type, 
   an_imp_sindic         in control.imp_sindic_obre%type,
   an_dias_mes           in control.dias_mes_obrero%type, 
   an_imp_redondeo       in control.imp_redondeo%type, 
   ad_feriado1           in control.dia_feriado1%type,
   ad_feriado2           in control.dia_feriado2%type,
   ad_feriado3           in control.dia_feriado3%type,
   ad_feriado4           in control.dia_feriado4%type,
   ad_feriado5           in control.dia_feriado5%type,
   as_tiptra             in maestro.tipo_trabajador%type
   ) is

   ln_tmp integer;       -- temporal 
   ln_dia_tra control.dias_mes_obrero%type;  -- dias trabajados
   ls_cod_afp maestro.cod_afp%type;          -- afp del trabajador
begin

   Select m.cod_afp
      into ls_cod_afp
      from maestro m
      where m.cod_trabajador = as_codtra;
   -- -- -- Ganancias -- -- --
   usp_pla_cal_pre_gan ( as_codtra, as_codusr, ad_fec_proceso );
   usp_pla_cal_pre_gan01( as_codtra, ad_fec_proceso) ;
   usp_pla_cal_pre_gan02(as_codtra ,as_codusr, ad_fec_proceso);
     
   
   usp_pla_cal_pre_des   ( as_codtra, as_codusr, ad_fec_proceso );            -- diferidos

   usp_pla_cal_pre_des01 ( as_codtra, as_codusr, 
      ad_fec_proceso, an_imp_sindic  );             -- sindicato

   usp_pla_cal_pre_des02 ( as_codtra, as_codusr, 
      ad_fec_proceso, ad_feriado1, ad_feriado2, 
      ad_feriado3, ad_feriado4, ad_feriado5  );     -- 30vos

    ln_dia_tra := usf_pla_cal_dia_tra ( as_codtra, an_dias_mes );
   
--    ln_tmp     := usp_pla_cal_gan_fij ( as_codtra, ln_dia_tra );
--   ln_tmp     := usp_pla_cal_rac_coc ( as_codtra, ln_dia_tra );
--    ln_tmp     := usp_pla_cal_sob_tur ( as_codtra, ln_dia_tra );
--    ln_tmp     := usp_pla_cal_gan_var ( as_codtra, ln_dia_tra );
--    ln_tmp     := usp_pla_cal_gan_325 ( as_codtra, ln_dia_tra );
--    ln_tmp     := usp_pla_cal_gan_tot ( as_codtra );

   -- -- -- Descuentos -- -- --
   -- if ls_cod_afp is null then
         -- ln_tmp     := usp_pla_cal_snp ( as_codtra ); 
   -- else 
         -- ln_tmp     := usp_pla_cal_afp ( as_codtra );  
   -- endif;
   -- ln_tmp     := usp_pla_cal_5ta_cat ( as_codtra );
   -- ln_tmp     := usp_pla_cal_por_jud ( as_codtra );
   -- ln_tmp     := usp_pla_cal_cta_cte ( as_codtra, ln_dia_tra );
   -- ln_tmp     := usp_pla_cal_des_fij ( as_codtra, ln_dia_tra );
   -- ln_tmp     := usp_pla_cal_des_var ( as_codtra, ln_dia_tra );
   -- ln_tmp     := usp_pla_cal_diferid ( as_codtra );
   -- ln_tmp     := usp_pla_cal_des_tot ( as_codtra );
   
   -- -- -- Aportes -- -- --
   -- ln_tmp     := usp_pla_cal_apo_por ( as_codtra );
   -- ln_tmp     := usp_pla_cal_apo_sec ( as_codtra );
   -- ln_tmp     := usp_pla_cal_apo_tot ( as_codtra );
  
end USP_PLA_CALCULO;
/
