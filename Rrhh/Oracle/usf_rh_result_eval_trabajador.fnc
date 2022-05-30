create or replace function usf_rh_result_eval_trabajador (
  an_ano in number, an_mes in number, as_codigo maestro.cod_trabajador%type)
  return number is

ln_cont         number ;
ln_cont_scalif  number;
ln_result       number;
Begin
--No interesa quien lo evaluo
Select count(*)
  into ln_cont
  from rrhh_eval_trab_desempeno e
 where e.ano = an_ano
   and e.mes = an_mes
   and e.cod_trabajador = as_codigo;

If ln_cont = 0 then
   Return(null);
end if;

-- Registros sin calificar
Select count(*)
  into ln_cont_scalif
  from rrhh_eval_trab_desempeno e
 where e.ano = an_ano
   and e.mes = an_mes
   and e.cod_trabajador = as_codigo
   and e.calif_valor is null;

If ln_cont_scalif > 0 then
   Return(null);
end if;

-- Si no ha retornado entonces ya esta evaluado
Select sum((Nvl(c.porcentaje,0)/100)*e.calif_valor)
  into ln_result
  from rrhh_eval_trab_desempeno e, rrhh_calificacion_desempeno c
 where e.condes = c.condes
   and e.calif_concepto = c.calif_concepto
   and e.ano = an_ano
   and e.mes = an_mes
   and e.cod_trabajador = as_codigo;
   

return(ln_result) ;

end usf_rh_result_eval_trabajador ;
/
