create or replace procedure usp_pla_cal_pre_gan01
  ( as_codtra      in maestro.cod_trabajador%type,
    ad_fec_proceso in rrhhparam.fec_proceso%type
   ) is

   ln_gratif      sldo_deveng.sldo_gratif_dev%type;
   ln_remune      sldo_deveng.sldo_rem_dev%type;
   ln_racion      sldo_deveng.sldo_racion%type;
   
   ln_num_reg     integer;
   lk_gratif      constant char(3) := '005';
   lk_remune      constant char(3) := '006';
   lk_racion      constant char(3) := '007';

   lc_concep      concepto.concep%type;
   ln_tope        concepto.imp_tope_max%type;
   ln_deuda       sldo_deveng.sldo_gratif_dev%type;
   ln_a_pagar     sldo_deveng.sldo_gratif_dev%type;
   ln_a_difere    sldo_deveng.sldo_gratif_dev%type;
   ln_a_pagar_acu sldo_deveng.sldo_gratif_dev%type;
   ld_fec_proceso sldo_deveng.fec_proceso%type ;
   lc_cod_nivel   rrhh_nivel_detalle.cod_nivel%type;
   ls_cencos      maestro.cencos%type;

begin

   --  Halla centro de costo del maestro
   Select m.cencos
     into ls_cencos
     from maestro m
     where m.cod_trabajador = as_codtra ;

   --  Verifica si tiene saldos por devengados
   ld_fec_proceso := add_months(ad_fec_proceso, -1) ;
   Select count(*) 
     into ln_num_reg
     from sldo_deveng sd
     where sd.cod_trabajador = as_codtra and
           sd.fec_proceso = ld_fec_proceso ;

   ln_num_reg := nvl( ln_num_reg, 0) ;

   If ln_num_reg > 0 Then
      
     Select sd.sldo_gratif_dev, sd.sldo_rem_dev, sd.sldo_racion
       into ln_gratif, ln_remune, ln_racion
       from sldo_deveng sd
       where sd.cod_trabajador = as_codtra and
             sd.fec_proceso = ld_fec_proceso ;
     
     ln_gratif := nvl (ln_gratif, 0) ;
     ln_remune := nvl (ln_remune, 0) ;
     ln_racion := nvl (ln_racion, 0) ;
       
     ln_a_pagar_acu := 0 ;
     For x in 1 .. 3 Loop
       If x = 1 Then 
         ln_deuda := ln_remune ;
         lc_cod_nivel := lk_remune ;
       ElsIF x = 2 Then
         ln_deuda := ln_gratif ;
         lc_cod_nivel := lk_gratif ;
       ElsIF x = 3 Then
         ln_deuda := ln_racion ;
         lc_cod_nivel := lk_racion ;
       End If ;
         
       If ln_deuda > 0 Then

         Select pn.concep
           into lc_concep
           from rrhh_nivel pn
            where pn.cod_nivel = lc_cod_nivel ;

         Select c.imp_tope_max
           into ln_tope 
           from concepto c
           where c.concep =  lc_concep ;
             
         ln_tope := nvl( ln_tope, 0);
           
         If ln_deuda >= ln_tope then 
           ln_a_pagar := ln_tope ;
           If ln_a_pagar_acu < ln_tope then
             ln_a_pagar := ln_tope - ln_a_pagar_acu;
             ln_a_pagar_acu := ln_a_pagar_acu + ln_a_pagar;
           Else
             ln_a_pagar_acu := ln_a_pagar_acu + ln_a_pagar;
           End if;
         Else 
           ln_a_pagar := ln_deuda ;
           ln_a_pagar_acu := ln_a_pagar_acu + ln_a_pagar;
           If ln_a_pagar_acu > ln_tope then
             ln_a_difere := ln_a_pagar_acu - ln_tope;
             ln_a_pagar := ln_a_pagar - ln_a_difere;
             If ln_a_pagar > 0 then
               Insert into gan_desct_variable 
                 ( cod_trabajador, fec_movim, concep, 
                    nro_doc,        imp_var,   cencos, 
                    cod_labor,      cod_usr,   proveedor,
                    tipo_doc )
               Values
                 ( as_codtra, ad_fec_proceso, lc_concep,
                   'autom', ln_a_pagar, ls_cencos,
                   '', '', '', 
                   '0002');
             End if;  
           End if;
         End if;
               
         If ln_a_pagar_acu <= ln_tope Then
                   
           Insert into gan_desct_variable 
             ( cod_trabajador, fec_movim, concep, 
               nro_doc,        imp_var,   cencos, 
               cod_labor,      cod_usr,   proveedor,
               tipo_doc )
           Values
             ( as_codtra, ad_fec_proceso, lc_concep,
               'autom', ln_a_pagar, ls_cencos,
               '', '', '', 
               'auto');
         End If;

       End If;
       
     End Loop;
       
   End If;
   
End usp_pla_cal_pre_gan01;
/
