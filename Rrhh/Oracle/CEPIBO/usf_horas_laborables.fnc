create or replace function usf_horas_laborables(
       adi_fec_proceso in date,
       asi_origen      in origen.cod_origen%TYPE,
       asi_codtra      in maestro.cod_trabajador%TYPE,
       asi_tipo_trabaj in tipo_trabajador.tipo_trabajador%TYPE
) return number is
  ln_Result              number;
  ls_cod_periocidad_rem  maestro.cod_periocidad_rem%TYPE;
  ln_count               number;
begin
  
  --Obtengo las fechas del rango por la fecha de proceso
  
  select m.flag_tipo_remun_rtps
    into ls_cod_periocidad_rem
    from maestro m
   where m.cod_trabajador = asi_codtra;
   
  /*
--  RAISE_APPLICATION_ERROR(-20000, ld_fecha2 - ld_Fecha1);
  ln_dias := ld_fecha2 - ld_Fecha1 + 1;
  ln_dias_descanso := 0;
  FOR ln_dia IN 0..ln_dias - 1 LOOP
      ld_fecha := ld_Fecha1 + ln_dia;
      if usf_rh_is_dia_descanso(asi_codtra, ld_fecha) then
         ln_dias_descanso := ln_dias_descanso + 1;
      end if;
  end loop;
  
  ln_count := 0;
  
  SELECT COUNT(*)
               INTO ln_count
               FROM calendario_feriado cf
              WHERE cf.origen = asi_origen
                 AND TO_DATE(cf.dia||'/'||cf.mes||'/'||TO_CHAR(ld_fecha1,'yyyy'),'dd/mm/yyyy') between ld_fecha1 and ld_fecha2;
  
  return (ln_dias - ln_dias_descanso - ln_count) * 8;*/
  
  
  if ls_cod_periocidad_rem = '03' then 
     ln_Result := 48; 
  elsif ls_cod_periocidad_rem = '02' then
     ln_Result := 104;  -- Cambios solicitados por CEPIBO, el 01/03/2014
  else
     ln_Result := 240;
  end if;
  
  return(ln_Result);
end usf_horas_laborables;
/
