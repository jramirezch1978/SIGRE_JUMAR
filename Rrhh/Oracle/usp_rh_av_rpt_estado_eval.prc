create or replace procedure usp_rh_av_rpt_estado_eval (
  an_ano in number, an_mes in number, as_usuario in char ) is

lk_objetivos          constant char(3) := 'OBJ' ;
lk_desempeno          constant char(3) := 'DES' ;

ls_cod_area           char(1) ;
ls_cod_seccion        char(3) ;
ls_desc_seccion       varchar2(30) ;
ls_nom_usuario        varchar2(60) ;
ls_nombres            varchar2(60) ;
ln_verifica           integer ;
ln_contador           integer ;
ln_puntaje            number(6,2) ;

ls_flag_eval_o        char(1) ;
ls_flag_apro_o        char(1) ;
ls_flag_gere_o        char(1) ;
ls_flag_eval_d        char(1) ;
ls_flag_apro_d        char(1) ;
ls_flag_gere_d        char(1) ;

--  Lectura de secciones por evaluadores
cursor c_movimiento is
  select e.cod_area, e.cod_seccion, s.desc_seccion, u.nombre
  from rrhh_evaluadores e, seccion s, usuario u
  where e.cod_area = s.cod_area and e.cod_seccion = s.cod_seccion and
        e.cod_usr = u.cod_usr and e.cod_usr = as_usuario and e.flag_estado = '1'
  order by e.cod_area, e.cod_seccion ;
  
--  Lectura de trabajadores por secciones
cursor c_maestro is
  select m.cod_trabajador, m.cod_area, m.cod_seccion
  from maestro m
  where m.cod_area = ls_cod_area and m.cod_seccion = ls_cod_seccion and
        m.flag_cal_plnlla = '1' and m.flag_estado = '1'
  order by m.cod_trabajador ;
  
begin

--  *********************************************************
--  ***   GENERA REPORTE DEL ESTADO DE LAS EVALUACIONES   ***
--  *********************************************************

delete from tt_av_rpt_estado_eval ;

for rc_mov in c_movimiento loop

  ls_cod_area     := rc_mov.cod_area ;
  ls_cod_seccion  := rc_mov.cod_seccion ;
  ls_desc_seccion := rc_mov.desc_seccion ;
  ls_nom_usuario  := rc_mov.nombre ;

  for rc_mae in c_maestro loop

    ls_nombres := usf_rh_nombre_trabajador(rc_mae.cod_trabajador) ;

    ls_flag_eval_o := '0' ; ls_flag_apro_o := '0' ; ls_flag_gere_o := '0' ;
    ls_flag_eval_d := '0' ; ls_flag_apro_d := '0' ; ls_flag_gere_d := '0' ;

    --  Verifica evaluaciones por objetivos
    ln_verifica := 0 ;
    select count(*) into ln_verifica from rrhh_eval_trab_objetivo o
      where o.ano = an_ano and o.mes = an_mes and o.cod_area = rc_mae.cod_area and
            o.cod_seccion = rc_mae.cod_seccion ;
    if ln_verifica > 0 then
      ln_contador := 0 ;
      select sum(to_number(nvl(o.flag_estado,'0')))
        into ln_contador from rrhh_eval_trab_objetivo o
        where o.ano = an_ano and o.mes = an_mes and o.cod_area = rc_mae.cod_area and
              o.cod_seccion = rc_mae.cod_seccion ;
      if ln_contador > 0 then
        ls_flag_eval_o := '1' ; ls_flag_apro_o := '1' ;
      else
        ls_flag_eval_o := '1' ;
      end if ;
      ln_verifica := 0 ;
      select count(*) into ln_verifica from rrhh_compensacion_var cv
        where cv.cod_trabajador = rc_mae.cod_trabajador and cv.ano = an_ano and
              cv.mes = an_mes and cv.calif_tipo = lk_objetivos ;
      if ln_verifica > 0 then
        ln_contador := 0 ;
        select sum(to_number(nvl(cv.flag_estado,'0')))
          into ln_contador from rrhh_compensacion_var cv
          where cv.cod_trabajador = rc_mae.cod_trabajador and cv.ano = an_ano and
                cv.mes = an_mes and cv.calif_tipo = lk_objetivos ;
        if ln_contador = 2 then
          ls_flag_gere_o := '1' ;
        end if ;
      end if ;
    end if ;
      
    --  Verifica evaluaciones por desempeno
    ln_verifica := 0 ;
    select count(*) into ln_verifica from rrhh_eval_trab_desempeno d
      where d.cod_trabajador = rc_mae.cod_trabajador and d.ano = an_ano and
            d.mes = an_mes ;
    if ln_verifica > 0 then
      ln_puntaje := 0 ;
      select sum(nvl(d.calif_valor,'0'))
        into ln_puntaje from rrhh_eval_trab_desempeno d
        where d.cod_trabajador = rc_mae.cod_trabajador and d.ano = an_ano and
              d.mes = an_mes ;
      ln_contador := 0 ;
      select sum(to_number(nvl(d.flag_estado,'0')))
        into ln_contador from rrhh_eval_trab_desempeno d
        where d.cod_trabajador = rc_mae.cod_trabajador and d.ano = an_ano and
              d.mes = an_mes ;
      if ln_contador > 0 then
        ls_flag_eval_d := '1' ; ls_flag_apro_d := '1' ;
      elsif ln_contador = 0 then
        ls_flag_apro_d := '0' ;
        if nvl(ln_puntaje,0) = 100 then
          ls_flag_eval_d := '0' ;
        else
          if nvl(ln_puntaje,0) > 100 then
            ls_flag_eval_d := '1' ;
          elsif nvl(ln_puntaje,0) = 100 then
            ls_flag_eval_d := '0' ;
          end if ;
        end if ;
      end if ;

      ln_verifica := 0 ;
      select count(*) into ln_verifica from rrhh_compensacion_var cv
        where cv.cod_trabajador = rc_mae.cod_trabajador and cv.ano = an_ano and
              cv.mes = an_mes and cv.calif_tipo = lk_desempeno ;
      if ln_verifica > 0 then
        ln_contador := 0 ;
        select sum(to_number(nvl(cv.flag_estado,'0')))
          into ln_contador from rrhh_compensacion_var cv
          where cv.cod_trabajador = rc_mae.cod_trabajador and cv.ano = an_ano and
                cv.mes = an_mes and cv.calif_tipo = lk_desempeno ;
        if ln_contador = 2 then
          ls_flag_gere_d := '1' ;
        end if ;
      end if ;
    end if ;
      
    --  Inserta registro de evaluaciones por trabajador
    insert into tt_av_rpt_estado_eval (
      usuario, nom_usuario, seccion, desc_seccion,
      codtra, nombres, flag_eval_o, flag_apro_o,
      flag_gere_o, flag_eval_d, flag_apro_d, flag_gere_d )
    values (
      as_usuario, ls_nom_usuario, ls_cod_seccion, ls_desc_seccion,
      rc_mae.cod_trabajador, ls_nombres, ls_flag_eval_o, ls_flag_apro_o,
      ls_flag_gere_o, ls_flag_eval_d, ls_flag_apro_d, ls_flag_gere_d ) ;

  end loop ;
  
end loop ;

end usp_rh_av_rpt_estado_eval ;
/
