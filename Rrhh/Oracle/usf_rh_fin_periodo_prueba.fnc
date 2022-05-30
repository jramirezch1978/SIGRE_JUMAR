create or replace function usf_rh_fin_periodo_prueba(
       adi_fec_inicio      in date,
       ani_periodo_prueba  in number,
       asi_dias_meses      in varchar2
) return date is
  ln_Result date;
begin
  case 
      when substr(upper(asi_dias_meses),1,1) = 'D' then
           ln_Result := adi_fec_inicio + ani_periodo_prueba;
      when substr(upper(asi_dias_meses),1,1) = 'M' then
           ln_Result := ADD_MONTHS(adi_fec_inicio, ani_periodo_prueba);
      ELSE 
           ln_Result := adi_fec_inicio;
  end case;
  
  return(ln_Result);
end usf_rh_fin_periodo_prueba;
/
