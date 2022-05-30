create or replace trigger tia_mov_mes_vacac_bonif
  after insert on mov_mes_vacac_bonif  
  for each row
    
DECLARE 
  -- local variables here
  ln_dias vacac_bonif_deveng.sldo_dias_vacacio%type;
  ln_dias_vac vacac_bonif_deveng.sldo_dias_vacacio%type;
  ls_codtra maestro.cod_trabajador%type;
  ln_periodo mov_mes_vacac_bonif.per_vac_bonif%type ;
   
BEGIN 
  --Calcular el nro de dias de Vacac
  ln_dias := (TO_DATE(:new.fec_hasta)-TO_DATE(:new.fec_desde))+1;
  ls_codtra := :new.cod_trabajador;
  ln_periodo := :new.per_vac_bonif;
   
  --Nro de Dias de vacac son 30  
  IF ln_dias > 30 THEN 
     ln_dias := 30;
  END IF;
  
  IF :new.flag_vac_bonif = '1' THEN   
     --La diferencia de fechas debe ser > CERO
     select  sum(vbd.sldo_dias_vacacio)
     into ln_dias_vac
     from vacac_bonif_deveng  vbd
     where vbd.cod_trabajador = ls_codtra and
           vbd.periodo = ln_periodo ;
     
     ln_dias_vac := nvl(ln_dias_vac,0);
   
    IF ln_dias_vac - ln_dias > 0 THEN 
       --Actualiza la Tabla
       update vacac_bonif_deveng 
         set sldo_dias_vacacio = ln_dias_vac - ln_dias 
       where cod_trabajador = ls_codtra and
             periodo = ln_periodo; 
  
     END IF; --Fin de la diferencia
  END IF; --Fin de Flag = 1 
  
  ---FLAG = 2
  
  IF :new.flag_vac_bonif = '2' THEN   
     --La diferencia de fechas debe ser > CERO
     select  sum(vbd.sldo_dias_bonif)
     into ln_dias_vac
     from vacac_bonif_deveng  vbd
     where vbd.cod_trabajador = ls_codtra and
           vbd.periodo = ln_periodo ;
     
     ln_dias_vac := nvl(ln_dias_vac,0);
   
    IF ln_dias_vac - ln_dias > 0 THEN 
       --Actualiza la Tabla
       update vacac_bonif_deveng 
         set sldo_dias_bonif = ln_dias_vac - ln_dias 
       where cod_trabajador = ls_codtra and
             periodo = ln_periodo; 
  
     END IF; --Fin de la diferencia
  END IF; --Fin de Flag = 1 
  
  
end tia_mov_mes_vacac_bonif;
/
