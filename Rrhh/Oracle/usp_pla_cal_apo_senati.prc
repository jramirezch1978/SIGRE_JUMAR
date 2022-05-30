create or replace procedure usp_pla_cal_apo_senati
  (  as_codtra       in maestro.cod_trabajador%type,
     ad_fec_proceso  in rrhhparam.fec_proceso%type
  ) is
   
lk_senati           constant char(3) :='320';  
ln_imp_senati       number(13,2);
ln_imp_senatid      number(13,2);
ln_fact_pago        concepto.fact_pago%type;
ln_imp_senati_acum  number(13,2); 
ls_concep_nivel     concepto.concep%type;
ls_concep           concepto.concep%type;
ls_cod_seccion      seccion.cod_seccion%type;
ln_tipcam           calendario.cmp_dol_prom%type;
  
cursor c_senati (as_codtra maestro.cod_trabajador%type) is 
  select  c.concep, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,1,1) = '1' and
        c.flag_e_senati = '1' ;

begin 

--  Halla tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,1) ;

--  Verifica que la seccion del trabajador sea de fabrica
Select m.cod_seccion 
  into ls_cod_seccion 
  from  maestro m
  where m.cod_trabajador = as_codtra ;

-- substr(ls_cod_seccion,1,1) = '7' Then
If ls_cod_seccion = '700' or ls_cod_seccion = '710' or
   ls_cod_seccion = '720' or ls_cod_seccion = '730' or
   ls_cod_seccion = '732' or ls_cod_seccion = '740' or
   ls_cod_seccion = '741' or ls_cod_seccion = '743' or
   ls_cod_seccion = '744' or ls_cod_seccion = '745' or
   ls_cod_seccion = '746' or ls_cod_seccion = '731' then

   --  Concepto de nivel de Senati
   Select rpn.concep
     into ls_concep_nivel
     from rrhh_nivel rpn
     where rpn.cod_nivel = lk_senati;

   --  Obtiene factor
   Select c.fact_pago
     into ln_fact_pago 
     from concepto c
     where c.concep = ls_concep_nivel ;

   ln_imp_senati_acum := 0;
   For rc_senati in c_senati (as_codtra) Loop
     ln_imp_senati_acum := ln_imp_senati_acum + rc_senati.imp_soles ;
   End Loop;
 
   If ln_imp_senati_acum > 0 then
      ln_imp_senati  := ln_imp_senati_acum * ln_fact_pago ; 
      ln_imp_senatid := ln_imp_senati / ln_tipcam ;
     
      --  Inserta registro en la tabla calculo                  
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
          ls_concep_nivel, ad_fec_proceso,
          0 ,    0 ,  0 , 
          ln_imp_senati, ln_imp_senatid,  ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ' );
  
   End if;
End If;  
  
End usp_pla_cal_apo_senati;
/
