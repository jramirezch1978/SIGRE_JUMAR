create or replace procedure usp_cambia_mes_evaluacion is

cursor c_movimiento is
  select t.ano, t.mes, t.cod_trabajador, t.item, t.flag_estado, t.condes,
         t.calif_concepto, t.calif_valor, t.cod_usr, t.flag_replicacion
  from rrhh_eval_trab_desempeno t
  where t.ano = 2005 and t.mes = 12 and t.cod_usr = 'esoto'
  order by t.cod_usr, t.cod_trabajador, t.item ;

begin

for rc_mov in c_movimiento loop

  insert into rrhh_eval_trab_desempeno (
    ano, mes, cod_trabajador, item,
    flag_estado, condes, calif_concepto,
    calif_valor, cod_usr, flag_replicacion )
  values (
    rc_mov.ano, 11, rc_mov.cod_trabajador, rc_mov.item,
    rc_mov.flag_estado, rc_mov.condes, rc_mov.calif_concepto,
    rc_mov.calif_valor, rc_mov.cod_usr, rc_mov.flag_replicacion ) ;
    
end loop ;
  
end usp_cambia_mes_evaluacion;
/
