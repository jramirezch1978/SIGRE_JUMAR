create or replace procedure usp_pla_cal (
   as_codtra             in maestro.cod_trabajador%type,
   as_codusr             in usuario.cod_usr%type,
   ad_fec_proceso        in rrhhparam.fec_proceso%type, 
   an_und_impos_tribuc   in rrhhparam.und_impos_tribut%type,
   an_dias_racion_cocida in rrhhparam.dias_racion_cocida%type, 
   an_imp_redondeo       in rrhhparam.imp_redondeo%type, 
   ad_feriado1           in rrhhparam.dia_feriado1%type,
   ad_feriado2           in rrhhparam.dia_feriado2%type,
   ad_feriado3           in rrhhparam.dia_feriado3%type,
   ad_feriado4           in rrhhparam.dia_feriado4%type,
   ad_feriado5           in rrhhparam.dia_feriado5%type ) is

   ln_tmp integer;
   ln_dia_tra            rrhhparam.dias_mes_obrero%type ;
   ls_cod_afp            maestro.cod_afp%type ;
   ls_tipo_trabajador    maestro.tipo_trabajador%type ;
   an_imp_sindic         rrhhparam.imp_sindic_obre%type ;
   an_dias_mes           rrhhparam.dias_mes_obrero%type ;

begin

   Select m.cod_afp, m.tipo_trabajador
      into ls_cod_afp, ls_tipo_trabajador
      from maestro m
      where m.cod_trabajador = as_codtra;
   
   If ls_tipo_trabajador = 'OBR' then
     Select rh.imp_sindic_obre, rh.dias_mes_obrero
       into an_imp_sindic, an_dias_mes
       from rrhhparam rh
       where rh.reckey = '1' ;
   Elsif ls_tipo_trabajador = 'EMP' then
     Select rh.imp_sindic_empl, rh.dias_mes_empleado
       into an_imp_sindic, an_dias_mes
       from rrhhparam rh
       where rh.reckey = '1' ;
   End if ;
   
   --  Ganancias 
   usp_pla_cal_pre_gan   ( as_codtra, as_codusr, ad_fec_proceso );
   usp_pla_cal_pre_gan01 ( as_codtra, ad_fec_proceso ) ;
--   usp_pla_cal_pre_gan02 ( as_codtra ,as_codusr, ad_fec_proceso );
   
   usp_pla_cal_pre_des   ( as_codtra, as_codusr, ad_fec_proceso );  
   usp_pla_cal_pre_des01 ( as_codtra, as_codusr, 
                           ad_fec_proceso, an_imp_sindic  );         
   usp_pla_cal_pre_des02 ( as_codtra, as_codusr, 
                           ad_fec_proceso, ad_feriado1, ad_feriado2, 
                           ad_feriado3, ad_feriado4, ad_feriado5  ); 

  ln_dia_tra := usf_pla_cal_dia_tra ( as_codtra, an_dias_mes );
   
  usp_pla_cal_gan_fij      ( as_codtra, as_codusr, ad_fec_proceso,
                             ln_dia_tra, an_dias_mes );
  usp_pla_cal_rac_coc      ( as_codtra, as_codusr, ad_fec_proceso,
                             ln_dia_tra, an_dias_mes, an_dias_racion_cocida );
  usp_pla_cal_sob_tur      ( as_codtra, as_codusr, ad_fec_proceso );
  usp_pla_cal_vacaciones   ( as_codtra, ad_fec_proceso, an_dias_mes );
  usp_pla_cal_bonificacion ( as_codtra, ad_fec_proceso, an_dias_mes );

  usp_pla_cal_enfermedad   ( as_codtra, ad_fec_proceso, an_dias_mes );
  usp_pla_cal_maternidad   ( as_codtra, ad_fec_proceso, an_dias_mes );
  usp_pla_cal_lic_sindic   ( as_codtra, ad_fec_proceso, an_dias_mes );
  usp_pla_cal_com_servic   ( as_codtra, ad_fec_proceso, an_dias_mes );
  usp_pla_cal_des_sustit   ( as_codtra, ad_fec_proceso, an_dias_mes );
  usp_pla_cal_reintegros   ( as_codtra, ad_fec_proceso ) ;
  
  usp_pla_cal_gan_var      ( as_codtra, as_codusr, ad_fec_proceso );
  usp_pla_cal_gan_325      ( as_codtra, as_codusr, ad_fec_proceso );
  usp_pla_cal_gan_tot      ( as_codtra, as_codusr, ad_fec_proceso );

  --  Descuentos
  If ls_cod_afp is null then
    usp_pla_cal_snp    ( as_codtra, ad_fec_proceso ); 
  Else  
    usp_pla_cal_afp    ( as_codtra, ad_fec_proceso );  
  End if;
  usp_pla_cal_quinta   ( as_codtra, ad_fec_proceso,
                         an_und_impos_tribuc );
  usp_pla_cal_por_jud  ( as_codtra, ad_fec_proceso );
  usp_pla_cal_cta_cte  ( as_codtra, ad_fec_proceso );
  usp_pla_cal_des_fij  ( as_codtra, ad_fec_proceso );
  usp_pla_cal_des_var  ( as_codtra, ad_fec_proceso );
  usp_pla_cal_tardanzas( as_codtra, ad_fec_proceso );
  usp_pla_cal_diferido ( as_codtra, ad_fec_proceso );
  usp_pla_cal_des_tot  ( as_codtra, ad_fec_proceso );
  usp_pla_cal_pagado   ( as_codtra, ad_fec_proceso );
   
  --  Aportes
--  usp_pla_cal_apo_essalud     ( as_codtra, ad_fec_proceso );
  usp_pla_cal_apo_sctr_ipss   ( as_codtra, ad_fec_proceso );
  usp_pla_cal_apo_sctr_onp    ( as_codtra, ad_fec_proceso );
  usp_pla_cal_apo_seg_agrario ( as_codtra, ad_fec_proceso );
  usp_pla_cal_apo_senati      ( as_codtra, ad_fec_proceso );
  usp_pla_cal_apo_tot         ( as_codtra, ad_fec_proceso );
  
end USP_PLA_CAL;
/
