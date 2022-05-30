create or replace procedure usp_rh_av_evaluacion_objetivos (
  an_ano in number, an_mes in number, as_area in char,
  as_seccion in char, as_usuario in char ) is

ls_codigo              char(8) ;
ln_item                number(3) ;
li_verifica            integer ;

--  Lectura de conceptos de evaluacion por objetivos
cursor c_evaluacion is
  select co.calif_concepto, co.porcentaje
  from rrhh_calificacion_objetivo co
  where co.cod_area = as_area and co.cod_seccion = as_seccion and
        co.flag_estado = '1'
  order by co.porcentaje desc ;

begin

--  ***********************************************************
--  ***   GENERA MOVIMIENTO PARA EVALUACION POR OBJETIVOS   ***
--  ***********************************************************

li_verifica := 0 ;
select count(*) into li_verifica from rrhh_eval_trab_objetivo eo
  where eo.ano = an_ano and eo.mes = an_mes and eo.cod_area = as_area and
        eo.cod_seccion = as_seccion ;

if li_verifica = 0 then

  select min(m.cod_trabajador) into ls_codigo from maestro m
    where m.flag_cal_plnlla = '1' and m.flag_estado = '1' and
          m.cod_area = as_area and m.cod_seccion = as_seccion ;
      
  ln_item := 0 ;
  for rc_eva in c_evaluacion loop

    ln_item := ln_item + 1 ;
    insert into rrhh_eval_trab_objetivo (
      ano, mes, cod_trabajador, item, flag_estado, cod_area, cod_seccion,
      calif_concepto, calif_valor, cod_usr )
    values (
      an_ano, an_mes, ls_codigo, ln_item, '0', as_area, as_seccion,
      rc_eva.calif_concepto, null, as_usuario ) ;

  end loop ;

end if ;

commit ;

end usp_rh_av_evaluacion_objetivos ;
/
