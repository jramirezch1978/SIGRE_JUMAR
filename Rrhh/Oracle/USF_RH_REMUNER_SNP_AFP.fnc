create or replace function USF_RH_REMUNER_SNP_AFP(
       an_periodo       in cntbl_asiento.ano%type, 
       as_origen        in origen.cod_origen%type, 
       as_trabajador    in maestro.cod_trabajador%type, 
       as_tipo_remun    in rrhh_fmt_remun_retenc.flag_tipo_retencion%type) 
       
return number is

ln_remunerac        number;
  
BEGIN 

-- Calculando en tabla "historico_calculo"
SELECT sum(NVL(r.valor_planilla,0) + NVL(r.valor_manual,0))
  INTO ln_remunerac 
  FROM rrhh_fmt_remun_retenc r
 WHERE r.ano = an_periodo 
   AND r.cod_origen = as_origen 
   AND r.cod_trabajador LIKE as_trabajador 
   AND r.flag_tipo_retencion = as_tipo_remun ;
       
RETURN( NVL(ln_remunerac,0));

END USF_RH_REMUNER_SNP_AFP;
/
