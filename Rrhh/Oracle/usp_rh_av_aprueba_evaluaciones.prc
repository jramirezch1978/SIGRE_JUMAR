create or replace procedure usp_rh_av_aprueba_evaluaciones (
  an_ano in number, an_mes in number, as_area in char,
  as_seccion in char ) is

ls_codigo            char(8) ;
ln_verifica          integer ;
ln_puntaje           number(5) ;
ln_sw                integer ;
lk_concepto          constant char(6) := 'ASICAP' ;

--  Lectura del maestro de trabajadores activos
cursor c_maestro is
  select m.cod_trabajador
  from maestro m
  where m.flag_cal_plnlla = '1' and m.flag_estado = '1' and
        m.cod_area = as_area and m.cod_seccion = as_seccion
  order by m.cod_trabajador ;
    
--  Lectura para aprobar calificaciones por desempeno
cursor c_desempeno is
  select d.ano, d.mes, d.cod_trabajador, d.item
  from rrhh_eval_trab_desempeno d
  where d.ano = an_ano and d.mes = an_mes and d.cod_trabajador = ls_codigo and
        d.flag_estado = '0' and ln_sw = 1
  order by d.item
  for update ;
  
begin

--  *************************************************************
--  ***   REALIZA APROBACION DE LAS EVALUACIONES REALIZADAS   ***
--  *************************************************************

for rc_mov in c_maestro loop

  ls_codigo := rc_mov.cod_trabajador ;

  ln_verifica := 0 ; ln_puntaje := 0 ; ln_sw := 0 ;
  select count(*) into ln_verifica
    from rrhh_eval_trab_desempeno d
    where d.ano = an_ano and d.mes = an_mes and d.flag_estado = '0' and
           d.cod_trabajador = ls_codigo ;
  if ln_verifica > 0 then
    select sum(nvl(d.calif_valor,0)) into ln_puntaje
      from rrhh_eval_trab_desempeno d
      where d.ano = an_ano and d.mes = an_mes and d.flag_estado = '0' and
             d.cod_trabajador = ls_codigo ;
  end if ;
  
  if nvl(ln_puntaje,0) > 50 then
    ln_sw := 1 ;
  end if ;

  for rc_des in c_desempeno loop

    update rrhh_eval_trab_desempeno d
      set d.flag_estado = '1'
      where d.ano = rc_des.ano and d.mes = rc_des.mes and
            d.cod_trabajador = rc_des.cod_trabajador and d.item = rc_des.item ;

  end loop ;
    
end loop ;

end usp_rh_av_aprueba_evaluaciones ;
/
