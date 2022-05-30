create or replace procedure usp_pla_cal_gan_var(
   as_codtra      in maestro.cod_trabajador%type, 
   as_codusr      in usuario.cod_usr%type,
   ad_fec_proceso in rrhhparam.fec_proceso%type
   ) is
   
   ld_fec_desde   rrhhparam.fec_desde%type;
   ld_fec_hasta   rrhhparam.fec_hasta%type;

   --  Ganancias variables
   Cursor c_gan_var is
   Select distinct gdv.concep
     from gan_desct_variable gdv
     where gdv.cod_trabajador = as_codtra and
           substr(gdv.concep,1,1) = '1' and
           gdv.fec_movim between ld_fec_desde and ad_fec_proceso ;
          
   --  Suma los importes por concepto      
   Cursor c_suma (as_codtra maestro.cod_trabajador%type ,
                  as_concep concepto.concep%type ) is
   Select sum(gdv.imp_var) as importe 
     from gan_desct_variable gdv              
     where gdv.cod_trabajador = as_codtra and
           gdv.concep = as_concep and 
           gdv.fec_movim between ld_fec_desde and ad_fec_proceso ;
           
           
   --  Determina concepto
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

     ln_impsol      calculo.imp_soles%type;
     ln_impdol      calculo.imp_dolar%type;
     ln_tipcam      calendario.cmp_dol_prom%type;
     ln_contador    number(15);

begin

   --  Selecciona fecha desde y fecha hasta
   Select rh.fec_desde, rh.fec_hasta
     into ld_fec_desde, ld_fec_hasta
     from rrhhparam rh
     where rh.reckey = '1' ;
     
   --  Determina tipo de cambio del dolar
   Select tc.vta_dol_prom
     into ln_tipcam
     from calendario tc
    where tc.fecha = ad_fec_proceso ;
   ln_tipcam := nvl ( ln_tipcam, 1);
      
   For rc_gv in c_gan_var Loop
        For rc_suma in c_suma (as_codtra, rc_gv.concep) Loop
           ln_impsol := rc_suma.importe ;
           ln_impdol := ln_impsol / ln_tipcam ;
          For rc_c in c_concepto ( rc_gv.concep ) Loop
            ln_contador := 0 ;
            Select count(*)
              into ln_contador
              from calculo c
              where c.cod_trabajador = as_codtra and
                    c.concep = rc_gv.concep ;
            ln_contador := nvl(ln_contador,0) ;
            If ln_contador > 0 then
              Update calculo
              Set imp_soles = imp_soles + ln_impsol ,
                  imp_dolar = imp_dolar + ln_impdol
              where cod_trabajador = as_codtra and
                    concep = rc_gv.concep ;
            Else
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
                Flag_e_agrario,       Flag_e_essalud_vida,
                Flag_e_Ies,           Flag_e_Senati, 
                Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
              Values ( as_codtra, 
                rc_gv.concep, ad_fec_proceso,
                0    ,     0,     0, 
                ln_impsol,    ln_impdol,  rc_c.Flag_t_Snp, 
                rc_c.Flag_t_Quinta,     rc_c.Flag_t_Judicial, 
                rc_c.Flag_t_Afp,        rc_c.Flag_t_Bonif_30, 
                rc_c.Flag_t_Bonif_25,   rc_c.Flag_t_Gratif, 
                rc_c.Flag_t_Cts,        rc_c.Flag_t_Vacacio, 
                rc_c.Flag_t_Bonif_Vacacio, rc_c.Flag_t_Pago_Quincena, 
                rc_c.Flag_t_Quinquenio, rc_c.Flag_e_Essalud, 
                rc_c.Flag_e_agrario,    rc_c.Flag_e_essalud_vida,
                rc_c.Flag_e_Ies,        rc_c.Flag_e_Senati, 
                rc_c.Flag_e_Sctr_Ipss,  rc_c.Flag_e_Sctr_Onp ) ;
            End if ;
       End Loop;       
      End Loop; 
   End Loop ;
      
End usp_pla_cal_gan_var;
/
