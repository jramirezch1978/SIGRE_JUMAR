create or replace function USF_RH_IS_DIA_DESCANSO_INT(
       asi_trabajador IN maestro.cod_trabajador%TYPE,
       adi_fecha      IN DATE
) return number is
  ln_Result number;
begin
  
  if usf_rh_is_dia_descanso(asi_trabajador, adi_Fecha) then
     ln_Result := 1;
  else
     ln_Result := 0;  
  end if;
  
  return(ln_Result);
end USF_RH_IS_DIA_DESCANSO_INT;
/
