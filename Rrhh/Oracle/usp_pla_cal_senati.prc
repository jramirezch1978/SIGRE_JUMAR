create or replace procedure usp_pla_cal_senati
  (  as_codtra in maestro.cod_trabajador%type,
     ad_fec_proceso in control.fec_proceso%type
  
  ) is
   
lk_senati constant char(3) :='320';  
ln_imp_senati number(13,2);
ln_fact_pago  number(13,2);
ln_imp_soles number(13,2);
ln_imp_senati_acum number(13,2); 
ls_concep_nivel concepto.concep%type;
ls_concep concepto.concep%type;
ls_cod_seccion seccion.cod_seccion%type;
  
--Cursor para los concepto del Nivel
cursor c_senati is 
 select  rpd.cod_concepto
 from rrhh_parm_detalle rpd
 where rpd.cod_nivel = lk_senati;

begin 

--Verificar que la Seccion del Trabaj sea Fabrica 
Select m.cod_seccion 
into ls_cod_seccion 
from  maestro m
where m.cod_trabajador = as_codtra ;

If ls_cod_seccion = '500' Then

   --Concepto del Nivel se Senati
   select rpn.cod_concepto
   into ls_concep_nivel
   from rrhh_parm_nivel rpn
   where rpn.cod_nivel = lk_senati;

   --Obtenemos el Fac Corresp ha este Concepto
   select c.fact_pago
   into ln_fact_pago 
   from concepto c
   where c.concep = ls_concep_nivel ;

   ln_imp_senati_acum := 0;

   For rc_senati in c_senati
    Loop 
      ls_concep := rc_senati.cod_concepto;
  
      --Obtnemos el importe por este concepto
      Select c.imp_soles
      into ln_imp_soles
      from calculo c
      where c.cod_trabajador = as_codtra and
            c.concep in (Select cp.concep
                         from concepto cp
                         where cp.concep = ls_concep and
                               cp.flag_e_senati = '1' );

     --Acumulamos los importe de c/concepto
     ln_imp_soles := nvl(ln_imp_soles,0);
     ln_imp_senati_acum := ln_imp_senati_acum + ln_imp_soles ;
    End Loop;
 
    If ln_imp_senati_acum > 0 then
       ln_imp_senati := ln_imp_senati_acum * ln_fact_pago ; 
     
       --Insertamos el registro en la Tabla Calculo                  
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
          ' ',    ' ',  ' ', 
          ln_imp_senati, ' ',  ' ', 
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
  
end usp_pla_cal_senati;
/
