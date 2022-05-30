create or replace function USF_RH_DIAS_INASIST_UTIL(
       as_trabajador       in maestro.cod_trabajador%type, 
       ad_fecha_ini        in date, 
       ad_fecha_fin        in date
)return number is
  ln_dias_inasistencia number;
  
CURSOR c_inasistencia(as_grupo_calculo in grupo_calculo.grupo_calculo%type ) is
SELECT hi.cod_trabajador, hi.cod_origen, hi.fec_desde, hi.fec_hasta, hi.dias_inasist 
  FROM historico_inasistencia hi, grupo_calculo gc, grupo_calculo_det gcd 
 WHERE gc.grupo_calculo=gcd.grupo_calculo and 
       hi.cod_trabajador = as_trabajador and 
       gcd.concepto_calc = hi.concep and 
       gcd.grupo_calculo=as_grupo_calculo and 
       hi.fec_movim BETWEEN ad_fecha_ini AND ad_fecha_fin ;

ln_dias_domingo            Number ;
ln_dias_feriado            Number ;
ln_dias_falta              number ;
ls_grupo_calculo           grupo_calculo.grupo_calculo%type ;      
BEGIN 

ln_dias_inasistencia := 0 ;

SELECT u.grp_inasist_anual INTO ls_grupo_calculo FROM utlparam u WHERE u.reckey='1' ;

IF ls_grupo_calculo is NULL THEN
   RAISE_APPLICATION_ERROR( -20000, 'Defina grupo de calculo de inasistencias');
END IF ;

FOR c_ina IN c_inasistencia(ls_grupo_calculo) LOOP
    ln_dias_falta := NVL(c_ina.dias_inasist,0) ;
    ln_dias_domingo := USF_RH_CALC_DOMINGOS(c_ina.fec_desde, c_ina.fec_hasta) ;
    ln_dias_feriado := USF_RH_DIAS_FERIADO(c_ina.cod_origen, c_ina.fec_desde, c_ina.fec_hasta) ;
    ln_dias_inasistencia := ln_dias_inasistencia + ln_dias_falta - ln_dias_domingo - ln_dias_feriado ;
END LOOP ;

RETURN( NVL(ln_dias_inasistencia,0));

END USF_RH_DIAS_INASIST_UTIL;
/
