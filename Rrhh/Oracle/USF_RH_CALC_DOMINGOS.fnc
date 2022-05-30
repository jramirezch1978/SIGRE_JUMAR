CREATE OR REPLACE FUNCTION USF_RH_CALC_DOMINGOS(
       ad_fecha_ini in date, 
       ad_fecha_fin in date
) 
return number is
  ln_dias_domingos number;

  -- 
  ln_dias_totales          number ;
  ln_dias_resto            number ;
  ls_dia                   char(3) ;
BEGIN 
  -- Calcula número de dias totales
  
  SELECT (ad_fecha_fin - ad_fecha_ini + 1) INTO ln_dias_totales FROM dual ;
  
  ln_dias_domingos := TRUNC(ln_dias_totales / 7) ;
  
  ln_dias_resto := MOD( ln_dias_totales, 7 ) ;
  
  IF ln_dias_resto > 0 THEN 
      SELECT TO_CHAR(ad_fecha_ini,'DY') INTO ls_dia FROM dual ;
      
      IF ln_dias_resto>=1 AND ls_dia='SUN' THEN 
         ln_dias_domingos := ln_dias_domingos + 1 ;
      END IF ; 
      IF ln_dias_resto>=2 AND ls_dia='SAT' THEN 
         ln_dias_domingos := ln_dias_domingos + 1 ;
      END IF ; 
      IF ln_dias_resto>=3 AND ls_dia='FRI' THEN 
         ln_dias_domingos := ln_dias_domingos + 1 ;
      END IF ; 
      IF ln_dias_resto>=4 AND ls_dia='THU' THEN 
         ln_dias_domingos := ln_dias_domingos + 1 ;
      END IF ; 
      IF ln_dias_resto>=5 AND ls_dia='WED' THEN 
         ln_dias_domingos := ln_dias_domingos + 1 ;
      END IF ; 
      IF ln_dias_resto>=6 AND ls_dia='TUE' THEN 
         ln_dias_domingos := ln_dias_domingos + 1 ;
      END IF ; 
  END IF ;
  
  RETURN(NVL(ln_dias_domingos,0));
  
END USF_RH_CALC_DOMINGOS;
/
