create or replace procedure usp_rh_av_desapr_eval_desemp (
  an_ano in number, an_mes in number,
  as_codigo in char) is

begin

Update rrhh_eval_trab_desempeno e
   set e.flag_estado = '0'
 where e.ano = an_ano
   and e.mes = an_mes
   and e.cod_trabajador = as_codigo;


end usp_rh_av_desapr_eval_desemp ;
/
