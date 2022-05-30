create or replace procedure usp_pla_cal_apo_essalud
  (  as_codtra       in maestro.cod_trabajador%type,
     ad_fec_proceso  in rrhhparam.fec_proceso%type
  ) is
   
lk_essalud           constant char(3) :='300';  
ln_imp_essalud       number(13,2);
ln_imp_essaludd      number(13,2);
ln_fact_pago         concepto.fact_pago%type;
ln_imp_essalud_acum  number(13,2); 
ls_concep_nivel      concepto.concep%type;
ls_concep            concepto.concep%type;
ln_tipcam            calendario.cmp_dol_prom%type;
  
--  Halla el concepto del nivel
cursor c_essalud (as_codtra maestro.cod_trabajador%type) is 
  select  c.concep, c.imp_soles
  from calculo c
  where c.cod_trabajador = as_codtra and
        substr(c.concep,1,1) = '1' and
        c.flag_e_essalud = '1' ;

begin 

--  Halla tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,1) ;

--  Concepto del Nivel
select rpn.concep
into ls_concep_nivel
from rrhh_nivel rpn
where rpn.cod_nivel = lk_essalud;

--  Halla factor para calculo
select c.fact_pago
into ln_fact_pago 
from concepto c
where c.concep = ls_concep_nivel ;
ln_fact_pago := nvl(ln_fact_pago,0) ;

ln_imp_essalud_acum := 0;

ln_imp_essalud_acum := 0 ;
For rc_essalud in c_essalud (as_codtra)
 Loop 
  ln_imp_essalud_acum := ln_imp_essalud_acum + rc_essalud.imp_soles ;
 End Loop;
ln_imp_essalud_acum := nvl(ln_imp_essalud_acum,0) ;
 
 If ln_imp_essalud_acum > 0 then
    ln_imp_essalud  := ln_imp_essalud_acum * ln_fact_pago ; 
    ln_imp_essaludd := ln_imp_essalud / ln_tipcam ; 
     
     -- Inserta registros
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
          ln_imp_essalud, ln_imp_essaludd,  ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ', 
          ' ',     ' ' );
  
  End if;
  
End usp_pla_cal_apo_essalud;
/
