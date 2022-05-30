create or replace function USF_RH_DIAS_FERIADO(
       as_origen           in origen.cod_origen%type, 
       ad_fecha_ini        in date, 
       ad_fecha_fin        in date
)return number is
  an_feriados number;
begin
  
  SELECT COUNT(*) 
    INTO an_feriados 
    FROM calendar_feriado_plla c 
   WHERE c.cod_origen=as_origen AND c.fecha BETWEEN ad_fecha_ini AND ad_fecha_fin ;
  
  IF an_feriados>0 THEN 
     SELECT SUM(NVL(c.nro_dias,0)) 
       INTO an_feriados 
       FROM calendar_feriado_plla c 
      WHERE c.cod_origen=as_origen AND c.fecha BETWEEN ad_fecha_ini AND ad_fecha_fin ;
  END IF ;
     
  RETURN(NVL(an_feriados,0));
  
end USF_RH_DIAS_FERIADO;
/
