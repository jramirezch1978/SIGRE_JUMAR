create or replace function USF_RRHH_FECHA_LIC
(ac_anomes         in varchar2                     ,
 ac_cod_trabajador in maestro.cod_trabajador%type  ,
 ac_origen         in maestro.cod_origen%type      ,
 ac_ttrab          in maestro.tipo_trabajador%type ) return date is
  
 Result date;
 
/*ld_fecha_inicio Date ;
ld_fecha_final  Date ;*/

ln_count        Number ;

begin

--busco informacion en el historico
SELECT Count(*) 
  INTO ln_count 
  FROM historico_calculo hc
 WHERE (hc.cod_trabajador                   = ac_cod_trabajador ) and
       (to_char(hc.fec_calc_plan,'yyyymm')  = ac_anomes         ) ;

if ln_count = 0 then       

    SELECT Min(i.fec_desde) 
      INTO Result 
      FROM inasistencia i
     WHERE (i.concep in (select concepto_calc from grupo_calculo_det gcd where gcd.grupo_calculo = '803') ) and
           (i.cod_trabajador = ac_cod_trabajador       ) and
           (to_char(i.fec_desde,'yyyymm') = ac_anomes  )  
   GROUP BY i.cod_trabajador       ;
else

   SELECT Min(hi.fec_desde) 
     INTO Result 
     FROM historico_inasistencia hi
    WHERE (hi.concep in (select concepto_calc from grupo_calculo_det gcd where gcd.grupo_calculo = '803') ) and
          (hi.cod_trabajador = ac_cod_trabajador      ) and
          (to_char(hi.fec_desde,'yyyymm') = ac_anomes )  
   GROUP BY hi.cod_trabajador       ; 
   
end if ; 
  
RETURN(Result);

END USF_RRHH_FECHA_LIC;
/
