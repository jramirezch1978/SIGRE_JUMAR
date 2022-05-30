create or replace function USF_RH_IS_DIA_DESCANSO(
       asi_trabajador IN maestro.cod_trabajador%TYPE,
       adi_fecha      IN DATE
) return boolean is
  lb_Result           BOOLEAN := FALSE;  -- Por defecto es falso
  ln_count            NUMBER;
  ls_flag_dia_fijo    grp_dia_descanso.flag_dia_dijo%TYPE;
  ln_dia_descanso     grp_dia_descanso.dia_descanso%TYPE;
  
begin
  
  -- Esta función determina si la fecha enviada como parámetro es dia de descanso para el tabajador
  SELECT COUNT(*)
    INTO ln_count
    FROM grp_dia_descanso a,
         grp_dia_descanso_trabaj b
   WHERE a.cod_grupo = b.cod_grupo
     AND b.cod_trabajador = asi_trabajador;
  
  IF ln_count = 0 THEN
     -- Si no hay registros entonces la fecha por defecto es el día domingo (1)
     IF to_number(to_char(adi_fecha, 'd')) = 1 THEN
        lb_Result := TRUE;
     END IF;
  ELSIF ln_count > 1 THEN
     RAISE_APPLICATION_ERROR(-20000, 'El trabajador no puede estar en mas de un grupo, por favor verificar');
  ELSE
     SELECT a.flag_dia_dijo, a.dia_descanso
       INTO ls_flag_dia_fijo, ln_dia_descanso
       FROM grp_dia_descanso a,
            grp_dia_descanso_trabaj b
      WHERE a.cod_grupo = b.cod_grupo
        AND b.cod_trabajador = asi_trabajador;
     
     IF ls_flag_dia_fijo = '1' THEN
        -- si el flag fijo es 1 entonces tieie un día fijo
        IF to_number(to_char(adi_fecha, 'd')) = ln_dia_descanso THEN
           lb_Result := TRUE;
        END IF;
     ELSE
        -- Si el flag es '0' entonces el dia fijo esta en la tabla grp_dia_descanso_fechas
        SELECT COUNT(*)
          INTO ln_count
          FROM grp_dia_descanso_fechas a,
               grp_dia_descanso_trabaj b
         WHERE a.cod_grupo      = b.cod_grupo
           AND b.cod_trabajador = asi_trabajador
           AND a.fecha          = adi_fecha;
        
        IF ln_count > 0 THEN
           lb_Result := TRUE;          
        END IF;   
     END IF;
  END IF;
  
  return(lb_Result);
end USF_RH_IS_DIA_DESCANSO;
/
