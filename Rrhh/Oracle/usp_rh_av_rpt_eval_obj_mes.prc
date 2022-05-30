create or replace procedure usp_rh_av_rpt_eval_obj_mes (
  an_ano in number, an_mes_des in number, an_mes_has in number ) is

ls_desc_area        varchar2(30) ;
ls_desc_secc        varchar2(30) ;
ls_cod_area         char(1) ;
ls_cod_seccion      char(3) ;
ln_mes              number(2) ;
ln_contador         integer ;
ln_total            number(13,2) ;
ln_promedio         number(13,2) ;

ln_eval_ene         number(5,2) ;
ln_eval_feb         number(5,2) ;
ln_eval_mar         number(5,2) ;
ln_eval_abr         number(5,2) ;
ln_eval_may         number(5,2) ;
ln_eval_jun         number(5,2) ;
ln_eval_jul         number(5,2) ;
ln_eval_ago         number(5,2) ;
ln_eval_set         number(5,2) ;
ln_eval_oct         number(5,2) ;
ln_eval_nov         number(5,2) ;
ln_eval_dic         number(5,2) ;

--  Cursor de evaluaciones por objetivos de las secciones
cursor c_evaluaciones is
  select o.mes, o.cod_area, o.cod_seccion, o.calif_valor, a.desc_area,
         s.desc_seccion
  from rrhh_eval_trab_objetivo o, area a, seccion s
  where o.cod_area = a.cod_area and ( o.cod_area = s.cod_area and
        o.cod_seccion = s.cod_seccion ) and o.ano = an_ano and
        o.mes between an_mes_des and an_mes_has
  order by o.cod_area, o.cod_seccion, o.ano, o.mes ;
rc_eva c_evaluaciones%rowtype ;
  
begin

--  ***************************************************************
--  ***   REPORTE DE EVALUACIONES POR OBJETIVOS POR SECCIONES   ***
--  ***************************************************************

delete from tt_av_rpt_eval_obj_mes ;

open c_evaluaciones ;
fetch c_evaluaciones into rc_eva ;

while c_evaluaciones%found loop

  ls_desc_area   := rc_eva.desc_area ;
  ls_desc_secc   := rc_eva.desc_seccion ;
  ls_cod_area    := rc_eva.cod_area ;
  ls_cod_seccion := rc_eva.cod_seccion ;

  ln_eval_ene := 0 ; ln_eval_feb := 0 ; ln_eval_mar := 0 ;
  ln_eval_abr := 0 ; ln_eval_may := 0 ; ln_eval_jun := 0 ;
  ln_eval_jul := 0 ; ln_eval_ago := 0 ; ln_eval_set := 0 ;
  ln_eval_oct := 0 ; ln_eval_nov := 0 ; ln_eval_dic := 0 ;

  while rc_eva.cod_seccion = ls_cod_seccion and c_evaluaciones%found loop

    ln_mes := rc_eva.mes ;

    ln_contador := 0 ; ln_total := 0 ; ln_promedio := 0 ;
    while rc_eva.cod_seccion = ls_cod_seccion and rc_eva.mes = ln_mes and
          c_evaluaciones%found loop

      ln_contador := ln_contador + 1 ;
      ln_total    := ln_total + nvl(rc_eva.calif_valor,0) ;
      fetch c_evaluaciones into rc_eva ;

    end loop ;
    
    ln_promedio := ln_total / ln_contador ;
    
    if ln_mes = 1 then
      ln_eval_ene := nvl(ln_promedio,0) ;
    elsif ln_mes = 2 then
      ln_eval_feb := nvl(ln_promedio,0) ;
    elsif ln_mes = 3 then
      ln_eval_mar := nvl(ln_promedio,0) ;
    elsif ln_mes = 4 then
      ln_eval_abr := nvl(ln_promedio,0) ;
    elsif ln_mes = 5 then
      ln_eval_may := nvl(ln_promedio,0) ;
    elsif ln_mes = 6 then
      ln_eval_jun := nvl(ln_promedio,0) ;
    elsif ln_mes = 7 then
      ln_eval_jul := nvl(ln_promedio,0) ;
    elsif ln_mes = 8 then
      ln_eval_ago := nvl(ln_promedio,0) ;
    elsif ln_mes = 9 then
      ln_eval_set := nvl(ln_promedio,0) ;
    elsif ln_mes = 10 then
      ln_eval_oct := nvl(ln_promedio,0) ;
    elsif ln_mes = 11 then
      ln_eval_nov := nvl(ln_promedio,0) ;
    elsif ln_mes = 12 then
      ln_eval_dic := nvl(ln_promedio,0) ;
    end if ;
    
  end loop ;

  insert into tt_av_rpt_eval_obj_mes (
    ano, mes_des, mes_has, area, desc_area,
    seccion, desc_seccion,
    eval_ene, eval_feb, eval_mar, eval_abr, eval_may, eval_jun,
    eval_jul, eval_ago, eval_set, eval_oct, eval_nov, eval_dic )
  values (
    an_ano, an_mes_des, an_mes_has, ls_cod_area, ls_desc_area,
    ls_cod_seccion, ls_desc_secc,
    ln_eval_ene, ln_eval_feb, ln_eval_mar, ln_eval_abr, ln_eval_may, ln_eval_jun,
    ln_eval_jul, ln_eval_ago, ln_eval_set, ln_eval_oct, ln_eval_nov, ln_eval_dic ) ;
  
end loop ;

end usp_rh_av_rpt_eval_obj_mes ;
/
