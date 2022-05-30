create or replace procedure usp_pla_judicial
 ( as_codtra  in maestro.cod_trabajador%type ,
   ad_fec_proceso in control.fec_proceso%type 
  ) is

lk_judicial constant char(3) := '180';
ln_count number(13,2);
ln_importe number(13,2); 
ln_imp_soles number(13,2);
ln_imp_dolar number(13,2);  
ln_secuencia number(13,2);
ln_porcentaje number(13,2);
ln_portot number(13,2);
ls_concep concepto.concep%type;

--Cursor para ver los conceptos afectos a la jubilacion
Cursor c_judali is 
  select rpd.cod_concepto 
  from rrhh_parm_detalle rpd
  where rpd.cod_nivel = lk_judicial;

--Informacion referente a la Tabla judicial
Cursor c_alimen (ls_concep  concepto.concep%type) is
  select j.porcentaje, j.secuencia
  from judicial j 
  where j.cod_trabajador = as_codtra and 
        j.concep = ls_concep and 
        j.flag_estado = '1' ;
  
   
begin
--Todos los importes de la Tabla Calculo deben 
--tener el importe igual a cero

 Update judicial 
 set importe = 0 
 Where porcentaje <> 0 or 
       porcentaje <> null ;

--Obtenemos el Porcentaje de la Tabla Maestro 
select m.porc_judicial
into ln_portot
from maestro m
where m.cod_trabajador = as_codtra ;

ln_portot := nvl(ln_portot,1);

--Buscamos el Cursor de jud ali  
 For rc_j in c_judali
  Loop 
    ls_concep := rc_j.cod_concepto;
           
    --Verificamos si existen registros 
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
      
     
       For rc_a in c_alimen (ls_concep)
           Loop 
            ln_secuencia := rc_a.secuencia;  
            ln_porcentaje := rc_a.porcentaje;
                 
            --Actualizas la tabla judicial       
     
            IF ln_porcentaje = 0 or ln_porcentaje = null Then
               ln_importe := ln_imp_soles ;        
            Else 
               ln_importe := ln_imp_soles*ln_porcentaje/ln_portot ;
            End if ;    
            
            ---Actualizamos la Tabla Judiciales       
            Update judicial
            set importe = ln_importe 
            Where  cod_trabajador = as_codtra and 
                    concep = ls_concep and
                    secuencia = ln_secuencia; 
     
       End Loop;
    End If; 
 End loop;
   
end usp_pla_judicial;
/
