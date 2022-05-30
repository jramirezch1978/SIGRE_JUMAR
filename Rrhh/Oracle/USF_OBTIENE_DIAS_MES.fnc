create or replace function USF_OBTIENE_DIAS_MES(
       AD_F_INGRESO IN CONTRATO_RRHH.FECHA_INICIO%TYPE,
       AD_F_CESE IN CONTRATO_RRHH.FECHA_FIN%TYPE
)Return number is

ln_Result      number;
ln_rango_mes   number;

begin
     ln_rango_mes := MONTHS_BETWEEN(AD_F_CESE + 1, AD_F_INGRESO);
     ln_Result := (ln_rango_mes - TRUNC(ln_rango_mes,0)) * 31;
     RETURN ln_Result ;

end USF_OBTIENE_DIAS_MES;
/
