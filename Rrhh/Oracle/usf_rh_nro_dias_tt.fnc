create or replace function usf_rh_nro_dias_tt(
       asi_codtra in maestro.cod_trabajador%TYPE,
       adi_fecha1 in date,
       adi_fecha2 in date
) return number is
  ln_Result number;
begin
  select NVL(sum(s.dias_trabaj),0)
       into ln_Result 
       from (select distinct hc.dias_trabaj, hc.fec_calc_plan
               from historico_calculo hc
              where hc.cod_trabajador = asi_codtra
                and hc.dias_trabaj  is not null
                and trunc(hc.fec_calc_plan) between adi_fecha1 and adi_fecha2) s;
  
  if ln_Result > adi_fecha2 - adi_Fecha1 + 1 then
     ln_Result := adi_Fecha2 - adi_fecha1;
  end if;       
  
  return(ln_Result);
end usf_rh_nro_dias_tt;
/
