create or replace function usf_rh_is_dia_feriado(
       asi_origen in origen.cod_origen%TYPE,
       adi_fecha  in date
) return boolean is
  lb_Result boolean;
  ln_count  number;
begin
  SELECT COUNT(*)
     INTO ln_count
     FROM calendario_feriado cf
    WHERE cf.origen = asi_origen
      AND cf.mes    = to_number(to_char(adi_fecha, 'mm'))
      AND cf.dia    = to_number(to_char(adi_fecha, 'dd'));
  
  if ln_count > 0 then
     lb_Result := true;
  else
     lb_Result := false;
  end if;           
  return(lb_Result);
end usf_rh_is_dia_feriado;
/
