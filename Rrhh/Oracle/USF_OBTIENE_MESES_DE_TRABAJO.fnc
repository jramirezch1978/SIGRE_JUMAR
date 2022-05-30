create or replace function USF_OBTIENE_MESES_DE_TRABAJO(
       AD_F_INGRESO IN CONTRATO_RRHH.FECHA_INICIO%TYPE,
       AD_F_CESE IN CONTRATO_RRHH.FECHA_FIN%TYPE
)Return number is

ln_Result number;

begin
     ln_Result := trunc((MONTHS_BETWEEN(AD_F_CESE + 1, AD_F_INGRESO)),0);
     RETURN ln_Result;

end USF_OBTIENE_MESES_DE_TRABAJO;
/
