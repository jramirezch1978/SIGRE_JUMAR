create or replace procedure usp_pla_cal_diferido
  ( as_codtra in maestro.cod_trabajador%type,
    ad_fec_proceso in rrhhparam.fec_proceso%type
  ) is
  
 lk_ingtot             constant char(3) := '100';   
 ln_ingtot             number(13,2);
 ln_desctot            number(13,2); 
 ln_imp_concep         number(13,2);
 ln_imp_concep_acum    number(13,2);
 ln_imp_concep_after   number(13,2);
 ln_imp_concep_before  number(13,2);
 ln_imp_concep_dif     number(13,2); 
 ln_imp_dolar          number(13,2); 
 ls_concep             concepto.concep%type; 
 ln_tipcam             calendario.cmp_dol_prom%type; 
  
 --  Determina los conceptos afectos al Trabajador 
 --  En el orden que fueron ingresados al sistema
 Cursor c_diferido is 
 Select c.concep, c.imp_soles
   from  calculo c
   where c.cod_trabajador = as_codtra and
         to_char(c.fec_proceso,'MM') = 
         to_char(ad_fec_proceso,'MM') and
         substr(c.concep,1,1) = '2'                                                                                                           
   order by c.cod_trabajador, c.concep ;

begin

--  Halla el tipo de cambio del dolar
Select tc.vta_dol_prom
  into ln_tipcam
  from calendario tc
  where tc.fecha = ad_fec_proceso ;
ln_tipcam := nvl(ln_tipcam,0) ;

--  Busca ingreso total de remuneraciones 
Select c.imp_soles
into ln_ingtot
from calculo c
where c.cod_trabajador =  as_codtra and
      to_char(c.fec_proceso,'MM') =
      to_char(ad_fec_proceso,'MM') and
      c.concep in (Select rpn.concep
                   from rrhh_nivel rpn
                   where  rpn.cod_nivel = lk_ingtot);
ln_ingtot := nvl(ln_ingtot,0) ;  

--  Suma descuentos de la tabla calculo
Select sum(c.imp_soles)
into ln_desctot
from calculo c 
where c.cod_trabajador = as_codtra and
      to_char(c.fec_proceso,'MM') =
      to_char(ad_fec_proceso,'MM') and
      substr(c.concep,1,1) = '2' ;                                                                                                                
ln_desctot := nvl(ln_desctot,0) ;  
  
--  Proceso de diferidos
If ln_desctot > ln_ingtot THen
  ln_imp_concep_acum := 0 ;
  ln_imp_concep_dif  := 0 ;

  --  Lee el cursor
  For rc_d in c_diferido  Loop
    ls_concep := rc_d.concep;
    If ln_imp_concep_dif = 0 then
      ln_imp_concep_before := rc_d.imp_soles; 
      ln_imp_concep_acum := ln_imp_concep_acum + ln_imp_concep_before;  

      If ln_ingtot < ln_imp_concep_acum Then
         
        --  Actualiza en la Tabla Calculo
        ln_imp_concep_after := ln_ingtot - 
                              (ln_imp_concep_acum - ln_imp_concep_before );
        ln_imp_dolar := ln_imp_concep_after / ln_tipcam ;
        update calculo
          set imp_soles = ln_imp_concep_after, imp_dolar = ln_imp_dolar
          where cod_trabajador = as_codtra and
                concep = ls_concep ;
         
        --  Guarda importes diferidos
        ln_imp_concep_dif := (ln_imp_concep_before - ln_imp_concep_after);         
        Insert into Diferido 
          ( Cod_Trabajador   , Concep,
            Importe          , Fec_Proceso )
        Values
          ( as_codtra         , ls_concep ,
            ln_imp_concep_dif , ad_fec_proceso );    
      End If;
  
    Else
  
      ln_imp_concep_dif := rc_d.imp_soles; 
      --  Actualiza en la Tabla Calculo
      update calculo
        set imp_soles = 0, imp_dolar = 0
        where cod_trabajador = as_codtra and
              concep = ls_concep ;
           --  Guarda importes diferidos
      Insert into Diferido 
        ( Cod_Trabajador   , Concep,
          Importe          , Fec_Proceso )
      Values
        ( as_codtra         , ls_concep ,
          ln_imp_concep_dif , ad_fec_proceso );    

    End If;
  End Loop;  
End If;  
  
End usp_pla_cal_diferido;
/
