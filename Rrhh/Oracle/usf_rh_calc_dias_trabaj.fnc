create or replace function usf_rh_calc_dias_trabaj(
       adi_fecha1          in DATE,
       adi_fecha2          IN DATE
) return number is
  ln_Result     number;
  ld_fec_ini    DATE;
  ld_fec_fin    DATE;
  ln_mes        NUMBER;
  ln_year       NUMBER;
BEGIN
  -- Inicializo el acumulador
  ln_result := 0;

  -- Esta función calcula los días trabajados basándose en meses completos de 30 días
  ln_mes  := to_number(to_char(adi_fecha1, 'mm'));
  ln_year := to_number(to_char(adi_fecha1, 'yyyy'));

  -- Obtengo la fecha inicial del mes
  ld_fec_ini := to_date('01/' || to_char(ln_mes, '00') || '/' || to_char(ln_year), 'dd/mm/yyyy');

  IF ld_fec_ini < adi_fecha1 THEN
     ld_fec_ini := adi_Fecha1;
  END IF;

  -- ahora calculo la fecha final del mes
  ln_mes  := to_number(to_char(ld_fec_ini, 'mm'));
  ln_year := to_number(to_char(ld_fec_ini, 'yyyy'));

  IF ln_mes = 12 THEN
     ln_year := ln_year +1;
     ln_mes := 1;
  ELSE
     ln_mes := ln_mes + 1;
  END IF;

  ld_fec_fin := to_date('01/' || to_char(ln_mes, '00') || '/' || to_char(ln_year), 'dd/mm/yyyy') - 1;

  WHILE ld_fec_fin <= adi_Fecha2 LOOP
        IF to_char(ld_fec_ini, 'dd') = '01' THEN
           ln_Result := ln_Result + 30;
        ELSE
           if to_char(ld_fec_fin, 'mm') = '02' then
              ln_Result := ln_Result + ld_fec_fin - ld_fec_ini + 2;
           else
              ln_Result := ln_Result + ld_fec_fin - ld_fec_ini + 1;
           end if;

        END IF;
        ld_fec_ini := ld_fec_fin + 1;

        -- ahora calculo la fecha final del mes
        ln_mes  := to_number(to_char(ld_fec_ini, 'mm'));
        ln_year := to_number(to_char(ld_fec_ini, 'yyyy'));

        IF ln_mes = 12 THEN
           ln_year := ln_year +1;
           ln_mes := 1;
        ELSE
           ln_mes := ln_mes + 1;
        END IF;

        ld_fec_fin := to_date('01/' || to_char(ln_mes, '00') || '/' || to_char(ln_year), 'dd/mm/yyyy') - 1;

  END LOOP;

  ln_Result := ln_Result + adi_fecha2 - ld_fec_ini + 1;

  return(ln_Result);
end usf_rh_calc_dias_trabaj;
/
