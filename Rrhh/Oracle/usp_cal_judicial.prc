create or replace procedure usp_cal_judicial
 ( as_codtra  in maestro.cod_trabajador%type ,
   ad_fec_proceso in rrhhparam.fec_proceso%type 
  ) is

lk_judicial      constant char(3) := '180';
ln_count         number(13,2);
ln_importe       number(13,2); 
ln_imp_soles     number(13,2);
ln_imp_dolar     number(13,2);  
ln_secuencia     number(13,2);
ln_porcentaje    number(13,2);
ln_portot        number(13,2);
ls_concep        concepto.concep%type;
ln_imp_total     number(13,2) ;

--  Identifica concepto de judiciales
Cursor c_judali is 
  select rhnd.concep 
  from rrhh_nivel_detalle rhnd
  where rhnd.cod_nivel = lk_judicial;

--  Lectura de la tabla de alimentistas
Cursor c_alimen (ls_concep  concepto.concep%type) is
  select j.porcentaje, j.secuencia
  from judicial j 
  where j.cod_trabajador = as_codtra and 
        j.concep = ls_concep and 
        j.flag_estado = '1' ;
   
begin

Select m.porc_judicial
  into ln_portot
  from maestro m 
  where m.cod_trabajador = as_codtra ;
ln_portot := nvl(ln_portot,1);

For rc_j in c_judali Loop 

  ls_concep := rc_j.concep;
           
  Select count(*)
    Into ln_count
    From calculo c 
    Where c.concep = ls_concep and 
          c.fec_proceso = ad_fec_proceso and 
          c.cod_trabajador = as_codtra ;
    
  If ln_count > 0 Then
      
    Select c.imp_soles
      Into ln_imp_soles
      From calculo c  
      Where c.cod_trabajador = as_codtra  and 
            c.concep = ls_concep and
            c.fec_proceso = ad_fec_proceso; 
     
    ln_imp_total := 0 ;
    For rc_a in c_alimen (ls_concep) Loop 

      ln_secuencia  := rc_a.secuencia;  
      ln_porcentaje := rc_a.porcentaje;
      ln_porcentaje := nvl(ln_porcentaje,1);      
     
      If ls_concep = '2201' or ls_concep = '2102' Then
        ln_importe   := ln_imp_soles ;        
        ln_imp_total := ln_imp_soles ;
      Else 
        ln_importe   := ln_imp_soles * ln_porcentaje / ln_portot ;
        ln_imp_total := ln_imp_total + ln_importe ;
      End if ;    
            
      -- Actualiza tabla de JUDICIALES 
      Update judicial
        set importe = ln_importe 
        Where  cod_trabajador = as_codtra and 
               concep = ls_concep and
               secuencia = ln_secuencia; 
     
    End Loop;

    If ln_imp_soles <> ln_imp_total then
      ln_importe := ln_importe + (ln_imp_soles - ln_imp_total) ;
      Update judicial
        set importe = ln_importe 
        Where  cod_trabajador = as_codtra and 
               concep = ls_concep and
               secuencia = ln_secuencia; 
    End if ;
    
  End If;

End loop;
   
end usp_cal_judicial;
/
