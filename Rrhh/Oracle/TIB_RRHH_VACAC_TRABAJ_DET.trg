create or replace trigger TIB_RRHH_VACAC_TRABAJ_DET
  before insert on rrhh_vacac_trabaj_det  
  for each row
  
DECLARE
  -- local variables here
  ln_dias_totales    rrhh_vacaciones_trabaj.dias_totales%type ;
  ln_dias_program    rrhh_vacaciones_trabaj.dias_program%type ;
  ln_dias_gozados    rrhh_vacaciones_trabaj.dias_gozados%type ;
  ln_nro_dias        rrhh_vacac_trabaj_det.nro_dias%type ;
  ls_flag_estado     rrhh_vacac_trabaj_det.flag_estado%type ;
BEGIN

ln_nro_dias := TRUNC(:new.fecha_fin) - TRUNC(:new.fecha_inicio) + 1;
 
:new.nro_dias := ln_nro_dias ;

IF NVL(ln_nro_dias,0) <=0 THEN
    RAISE_APPLICATION_ERROR(-20000, 'Número de días de vacaciones no puede ser menor o igual a 0') ;
    RETURN ;    
END IF ;

IF :new.flag_manual IS NULL THEN 
    RAISE_APPLICATION_ERROR(-20001, 'Tipo de ingreso de registro no puede ser nulo') ;
    RETURN ;    
END IF ; 

SELECT NVL(r.dias_totales,0), NVL(r.dias_gozados,0), NVL(r.dias_program,0) 
  INTO ln_dias_totales, ln_dias_gozados, ln_dias_program 
  FROM rrhh_vacaciones_trabaj r 
 WHERE r.cod_trabajador = :new.cod_trabajador 
   AND r.periodo_inicio = :new.periodo_inicio ;

IF ln_dias_totales < ln_dias_program + ln_nro_dias THEN 
   RAISE_APPLICATION_ERROR(-20001, 'Número de dias programados superaría a número de días totales de vacaciones de' 
                           ||CHR(13)|| 'Trabajador : ' || :new.cod_trabajador
                           ||CHR(13)|| 'Periodo    : ' || :new.periodo_inicio ) ;
   RETURN ;    
END IF ;

IF ln_dias_totales = ln_dias_gozados + ln_nro_dias THEN
   ls_flag_estado := '2' ;
ELSIF ln_dias_totales > ln_dias_gozados + ln_nro_dias THEN 
   ls_flag_estado := '1' ;
END IF ;

:new.flag_estado := ls_flag_estado ;
  
end TIB_RRHH_VACAC_TRABAJ_DET;
/
