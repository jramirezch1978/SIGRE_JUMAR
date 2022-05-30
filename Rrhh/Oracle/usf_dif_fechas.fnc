create or replace function usf_dif_fechas
( ad_fec_fin in date, 
  ad_fec_ini in date 
 ) 
return char is
ls_resul char(8); --Variable de Retorno  

ln_dif       number(6,2);
ln_anios     number(4,2);
ln_anios_tot number(2);

ln_meses     number(4,2);
ln_meses_tot number(2);

ln_dias      number(4,2);
ln_dias_tot  number(2);
 
begin

--Diferencia de Fechas Totales
   ln_dif:=MONTHS_BETWEEN(ad_fec_fin , ad_fec_ini);
   --Numero de Anios  
   ln_anios := ln_dif/12;
   ln_anios_tot := TRUNC(ln_anios); --El Nro de Anios Entero
        
   ln_dif := ln_anios - ln_anios_tot;           
   --Numero de Meses
   ln_meses := ln_dif * 12;
   ln_meses_tot := TRUNC(ln_meses);--Nro de Mes Entero      
              
   ln_dif := ln_meses - ln_meses_tot;      
   --Numero de dias
   ln_dias := ln_dif * 30;
   ln_dias_tot := TRUNC(ln_dias);--Nro Dia Entero            
--Fin de la Diferencia de FECHAS TOTALES             

--Union de los tiempos establecidos     
   ls_resul := to_char(ln_anios_tot)||'?'||to_Char(ln_meses_tot)||'?'||
               to_char(ln_dias_tot);       

  return(ls_resul);
end usf_dif_fechas;
/
