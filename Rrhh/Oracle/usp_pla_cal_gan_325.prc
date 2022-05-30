create or replace procedure usp_pla_cal_gan_325(
   as_codtra      in maestro.cod_trabajador%type, 
   as_codusr      in usuario.cod_usr%type,
   ad_fec_proceso in rrhhparam.fec_proceso%type
   ) is
   
   lk_bonif25 constant char(3) := '091' ; --  Bonificacion 25%
   lk_bonif30 constant char(3) := '092' ; --  Bonificacion 30%

   ln_tipcam   calendario.cmp_dol_prom%type ;
   ls_bonif    maestro.bonif_fija_30_25%type ;
   ls_concep   concepto.concep%type ;
   ln_factor   number(5,2) ;
   ln_impsol   calculo.imp_soles%type;
   ln_impdol   calculo.imp_dolar%type;
   ln_valor    gan_desct_fijo.imp_gan_desc%type ;
    
   --  Busca conceptos
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

begin
   Select tc.vta_dol_prom
     into ln_tipcam
     from calendario tc
     where tc.fecha = ad_fec_proceso ;
   ln_tipcam := nvl ( ln_tipcam, 1);
      
   Select m.bonif_fija_30_25
     into ls_bonif
     from maestro m
     where m.cod_trabajador = as_codtra ;
   ls_bonif := nvl( ls_bonif, '0' ) ;
    
   If ls_bonif = '1' or ls_bonif = '2' Then
     If ls_bonif = '2' Then 
       Select sum( c.imp_soles )
         into ln_valor
         from calculo c
         where c.cod_trabajador = as_codtra 
               and c.flag_t_bonif_25 = '1'
               and (c.concep <> '1413' and c.concep <> '1414') ;

       Select rhpn.concep
         into ls_concep
         from rrhh_nivel rhpn
         where rhpn.cod_nivel = lk_bonif25 ;
     Else
       Select sum( c.imp_soles )
         into ln_valor
         from calculo c
         where c.cod_trabajador = as_codtra 
               and c.flag_t_bonif_30 = '1' 
               and (c.concep <> '1413' and c.concep <> '1414') ;

         Select rhpn.concep
           into ls_concep
           from rrhh_nivel rhpn
           where rhpn.cod_nivel = lk_bonif30 ;
     End if ;
           
     ln_valor := nvl( ln_valor, 0 ) ;

     For rc_c in c_concepto ( ls_concep ) Loop
       ln_factor := rc_c.fact_pago;
       ln_valor := ln_valor * ln_factor ;
       ln_impsol := ln_valor ;
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
         Flag_e_agrario,       Flag_e_essalud_vida,
         Flag_e_Ies,           Flag_e_Senati, 
         Flag_e_Sctr_Ipss,     Flag_e_Sctr_Onp )
       Values ( as_codtra, 
         ls_concep, ad_fec_proceso,
         0,       0,         0, 
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
           
     End Loop;       
       
   End If ;
      
End usp_pla_cal_gan_325;
/
