create or replace procedure usp_pla_cal_des_fij
   ( as_codtra        in maestro.cod_trabajador%type, 
     ad_fec_proceso   in rrhhparam.fec_proceso%type
   ) is
   
   lk_dscto_fij constant char(3) := '150' ; 
   
   --  Determina descuentos fijos
   Cursor c_dscto_fijo is
   Select gdf.concep, imp_gan_desc
     from gan_desct_fijo gdf
     where gdf.cod_trabajador = as_codtra 
          and gdf.flag_estado = '1'
          and gdf.flag_trabaj = '1'
          and gdf.concep in (
          Select rhpd.concep
            from rrhh_nivel_detalle rhpd
            where rhpd.cod_nivel = lk_dscto_fij ) ;
           
   --  Determinar concepto
   Cursor c_concepto ( as_concepto concepto.concep%type ) is
   Select c.flag_t_snp, c.flag_t_quinta, c.flag_t_judicial,
          c.flag_t_afp, c.flag_t_bonif_30, c.flag_t_bonif_25,
          c.flag_t_gratif, c.flag_t_cts, c.flag_t_vacacio, 
          c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, 
          c.flag_t_quinquenio, 
          c.flag_e_essalud, c.flag_e_agrario, 
          c.flag_e_essalud_vida, c.flag_e_ies, 
          c.flag_e_senati, c.flag_e_sctr_ipss, 
          c.flag_e_sctr_onp
     from concepto c
     where c.concep = as_concepto ;

   ln_impsol calculo.imp_soles%type;
   ln_impdol calculo.imp_dolar%type;
   ln_tipcam calendario.cmp_dol_prom%type ;
   ln_num_reg   number(5) ;
   
   
begin
   --  Halla tipo de cambio del dolar
   Select tc.vta_dol_prom
     into ln_tipcam
     from calendario tc
     where tc.fecha = ad_fec_proceso ;
   ln_tipcam := nvl ( ln_tipcam, 1);
      
   For rc_dscto_fijo in c_dscto_fijo Loop

   Select count( * )
     into ln_num_reg
     from gan_desct_fijo gdf
     where gdf.cod_trabajador = as_codtra 
           and gdf.flag_estado = '1'
           and gdf.flag_trabaj = '1'
           and gdf.concep in (
           Select rhpd.concep
             from rrhh_nivel_detalle rhpd
             where rhpd.cod_nivel = lk_dscto_fij ) ;
   ln_num_reg := nvl(ln_num_reg,0) ;

   If ln_num_reg > 0 then
     ln_impsol := rc_dscto_fijo.imp_gan_desc ;
     ln_impdol := ln_impsol / ln_tipcam ;
     For rc_c in c_concepto ( rc_dscto_fijo.concep ) Loop
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
         rc_dscto_fijo.concep, ad_fec_proceso,
         0,    0, 0, 
         ln_impsol,    ln_impdol,  ' ', 
         ' ',          ' ', 
         ' ',          ' ', 
         ' ',          ' ', 
         ' ',          ' ', 
         ' ',          ' ', 
         ' ',          ' ', 
         ' ',          ' ', 
         ' ',          ' ');

     End Loop; 
   End if ;
   End Loop ; 
  
End usp_pla_cal_des_fij;
/
