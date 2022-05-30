create or replace function usf_horas_laborables(
       adi_fec_proceso in date,
       asi_origen      in origen.cod_origen%TYPE,
       asi_codtra      in maestro.cod_trabajador%TYPE,
       asi_tipo_trabaj in tipo_trabajador.tipo_trabajador%TYPE
) return number is
  ln_Result            number;
  ld_fecha1            date;
  ld_fecha2            date;
  ln_dias              number;
  ln_dia               number;
  ld_fecha             date;
  ln_dias_descanso     number;
begin
  
  --Obtengo las fechas del rango por la fecha de proceso
  select trunc(r.fec_inicio), trunc(r.fec_final)
    into ld_fecha1, ld_Fecha2
    from rrhh_param_org r
   where r.origen = asi_origen
     and r.tipo_trabajador = asi_tipo_trabaj
     and r.fec_proceso = adi_fec_proceso;
  
--  RAISE_APPLICATION_ERROR(-20000, ld_fecha2 - ld_Fecha1);
  ln_dias := ld_fecha2 - ld_Fecha1 + 1;
  ln_dias_descanso := 0;
  FOR ln_dia IN 0..ln_dias - 1 LOOP
      ld_fecha := ld_Fecha1 + ln_dia;
      if usf_rh_is_dia_descanso(asi_codtra, ld_fecha) then
         ln_dias_descanso := ln_dias_descanso + 1;
      end if;
  end loop;
  
  return (ln_dias - ln_dias_descanso) * 8;
  /*
  if (ld_fecha2 - ld_Fecha1 + 1) >= 7 and (ld_fecha2 - ld_Fecha1) < 15 then 
    ln_Result := 48; 
  else
    ln_Result := (ld_fecha2 - ld_Fecha1 - 1) * 8;
  end if;
  */
  return(ln_Result);
end usf_horas_laborables;
/
