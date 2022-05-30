create or replace procedure usp_rh_av_cns_evaluaciones (
  as_origen in char, as_tipo_trabaj in char, an_ano in number,
  an_mes in number ) is

lk_suspension         constant char(3) := '081' ;
lk_inasistencia       constant char(3) := '082' ;
lk_objetivos          constant char(3) := 'OBJ' ;
lk_desempeno          constant char(3) := 'DES' ;

ln_verifica           integer ;
ls_codigo             char(8) ;
ls_nombres            varchar2(60) ;
ls_concepto           char(4) ;
ln_nro_dias           number(5,2) ;
ld_fec_desde          date ;
ld_fec_hasta          date ;

ln_o_si_evaluado      number(1) ;
ln_o_con_puntaje      number(1) ;
ln_o_sin_puntaje      number(1) ;
ln_o_si_aprobado      number(1) ;
ln_o_no_aprobado      number(1) ;
ln_o_no_evaluado      number(1) ;
ln_o_con_pago         number(1) ;
ln_o_sin_pago         number(1) ;

ln_d_si_evaluado      number(1) ;
ln_d_con_puntaje      number(1) ;
ln_d_sin_puntaje      number(1) ;
ln_d_si_aprobado      number(1) ;
ln_d_no_aprobado      number(1) ;
ln_d_no_evaluado      number(1) ;
ln_d_con_pago         number(1) ;
ln_d_sin_pago         number(1) ;

ln_suspendido         number(1) ;
ln_faltas             number(1) ;

--  Lectura del maestro de trabajadores por areas
cursor c_maestro is
  select m.cod_trabajador, m.cod_area, m.cod_seccion, m.tipo_trabajador,
         a.desc_area, s.desc_seccion, t.desc_tipo_tra
  from maestro m, area a, seccion s, tipo_trabajador t
  where m.cod_area = a.cod_area and m.cod_area = s.cod_area and
        m.cod_seccion = s.cod_seccion and m.tipo_trabajador =
        t.tipo_trabajador and m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj
  order by m.cod_seccion, m.cod_trabajador ;
  
--  Lectura de inasistencias de trabajadores en el mes
cursor c_inasistencia is
  select i.nro_dias
  from incidencia_trabajador i
  where i.cod_trabajador = ls_codigo and nvl(i.flag_conformidad,'0') = '0' and
        trunc(i.fecha_movim) between ld_fec_desde and ld_fec_hasta and
        i.concep in ( select d.concepto_calc from grupo_calculo_det d
                      where d.grupo_calculo = lk_inasistencia )
  order by i.cod_trabajador, i.fecha_movim ;
  
begin

--  **********************************************************
--  ***   GENERA CONSULTA DEL ESTADO DE LAS EVALUACIONES   ***
--  **********************************************************

delete from tt_av_cns_evaluaciones ;

ld_fec_desde := to_date('01'||'/'||to_char(lpad(an_mes,2,'0'))||'/'||
                 to_char(an_ano),'DD/MM/YYYY') ;
ld_fec_hasta := last_day(ld_fec_desde) ;

for rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_nombres := usf_rh_nombre_trabajador(ls_codigo) ;

  ln_o_si_evaluado := 0 ; ln_o_con_puntaje := 0 ;
  ln_o_sin_puntaje := 0 ; ln_o_si_aprobado := 0 ;
  ln_o_no_aprobado := 0 ; ln_o_no_evaluado := 0 ;
  ln_o_con_pago    := 0 ; ln_o_sin_pago    := 0 ;
  ln_d_si_evaluado := 0 ; ln_d_con_puntaje := 0 ;
  ln_d_sin_puntaje := 0 ; ln_d_si_aprobado := 0 ;
  ln_d_no_aprobado := 0 ; ln_d_no_evaluado := 0 ;
  ln_d_con_pago    := 0 ; ln_d_sin_pago    := 0 ;
  ln_suspendido    := 0 ; ln_faltas        := 0 ;

  --  Control de las evaluaciones por objetivos
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_eval_trab_objetivo o
    where o.ano = an_ano and o.mes = an_mes and o.cod_area = rc_mae.cod_area and
          o.cod_seccion = rc_mae.cod_seccion ;
  if ln_verifica > 0 then
    ln_o_si_evaluado := 1 ;
    --  Verifica puntaje
    ln_verifica := 0 ;
    select sum(nvl(o.calif_valor,0)) into ln_verifica from rrhh_eval_trab_objetivo o
      where o.ano = an_ano and o.mes = an_mes and o.cod_area = rc_mae.cod_area and
            o.cod_seccion = rc_mae.cod_seccion ;
    if ln_verifica > 0 then
      ln_o_con_puntaje := 1 ;
    else
      ln_o_sin_puntaje := 1 ;
    end if ;
    --  Verifica aprobacion
    ln_verifica := 0 ;
    select sum(to_number(nvl(o.flag_estado,'0')))
      into ln_verifica from rrhh_eval_trab_objetivo o
      where o.ano = an_ano and o.mes = an_mes and o.cod_area = rc_mae.cod_area and
            o.cod_seccion = rc_mae.cod_seccion ;
    if ln_verifica > 0 then
      ln_o_si_aprobado := 1 ;
    else
      ln_o_no_aprobado := 1 ;
    end if ;
  else
    ln_o_no_evaluado := 1 ;
  end if ;

  --  Verifica pago por objetivos
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_compensacion_var cv
    where cv.cod_trabajador = rc_mae.cod_trabajador and cv.ano = an_ano and
          cv.mes = an_mes and cv.calif_tipo = lk_objetivos ;
   if ln_verifica > 0 then
    ln_o_con_pago := 1 ;
  else
    ln_o_sin_pago := 1 ;
  end if ;

  --  Control de las evaluaciones por desempeno
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_eval_trab_desempeno d
    where d.ano = an_ano and d.mes = an_mes and d.cod_trabajador = ls_codigo ;
  if ln_verifica > 0 then
    --  Verifica puntaje
    ln_verifica := 0 ;
    select sum(nvl(d.calif_valor,0)) into ln_verifica from rrhh_eval_trab_desempeno d
      where d.ano = an_ano and d.mes = an_mes and d.cod_trabajador = ls_codigo ;
    if ln_verifica > 50 then
      ln_d_con_puntaje := 1 ;
      ln_d_si_evaluado := 1 ;
    else
      ln_d_sin_puntaje := 1 ;
      ln_d_no_evaluado := 1 ;
    end if ;
    --  Verifica aprobacion
    ln_verifica := 0 ;
    select sum(to_number(nvl(d.flag_estado,'0')))
      into ln_verifica from rrhh_eval_trab_desempeno d
      where d.ano = an_ano and d.mes = an_mes and d.cod_trabajador = ls_codigo ;
    if ln_verifica > 0 then
      ln_d_si_aprobado := 1 ;
    else
      ln_d_no_aprobado := 1 ;
    end if ;
  else
    ln_d_no_evaluado := 1 ;
  end if ;

  --  Verifica pago por desempeno
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_compensacion_var cv
    where cv.cod_trabajador = ls_codigo and cv.ano = an_ano and
          cv.mes = an_mes and cv.calif_tipo = lk_desempeno ;
  if ln_verifica > 0 then
    ln_d_con_pago := 1 ;
  else
    ln_d_sin_pago := 1 ;
  end if ;

  --  Determina si el trabajador tiene suspension
  ln_verifica := 0 ;
  select count(*) into ln_verifica from grupo_calculo c
    where c.grupo_calculo = lk_suspension ;
  if ln_verifica > 0 then
    select c.concepto_gen into ls_concepto from grupo_calculo c
      where c.grupo_calculo = lk_suspension ;
    ln_verifica := 0 ;
    select count(*) into ln_verifica from incidencia_trabajador t
      where t.cod_trabajador = ls_codigo and t.concep = ls_concepto and
            (trunc(t.fecha_movim) between ld_fec_desde and ld_fec_hasta) and
            nvl(t.flag_conformidad,'0') = '0' ;
    if ln_verifica > 0 then
      ln_suspendido := 1 ;
    end if ;
  end if ;

  --  Determina inasistencias del trabajador
  ln_nro_dias := 0 ;
  for rc_ina in c_inasistencia loop
    ln_nro_dias := ln_nro_dias + nvl(rc_ina.nro_dias,0) ;
  end loop ;
  if ln_nro_dias > 3 then
    ln_faltas := 1 ;
  end if ;

  --  Inserta registro del trabajador para consulta
  insert into tt_av_cns_evaluaciones (
    ano, mes, cod_area, desc_area, cod_seccion,
    desc_seccion, cod_trabajador, nombres, tipo_trabajador,
    desc_tipo_tra, o_si_evaluado, o_con_puntaje, o_sin_puntaje,
    o_si_aprobado, o_no_aprobado, o_no_evaluado, o_con_pago,
    o_sin_pago, d_si_evaluado, d_con_puntaje, d_sin_puntaje,
    d_si_aprobado, d_no_aprobado, d_no_evaluado, d_con_pago,
    d_sin_pago, suspendido, faltas )
  values (
    an_ano, an_mes, rc_mae.cod_area, rc_mae.desc_area, rc_mae.cod_seccion,
    rc_mae.desc_seccion, ls_codigo, ls_nombres, rc_mae.tipo_trabajador,
    rc_mae.desc_tipo_tra, ln_o_si_evaluado, ln_o_con_puntaje, ln_o_sin_puntaje,
    ln_o_si_aprobado, ln_o_no_aprobado, ln_o_no_evaluado, ln_o_con_pago,
    ln_o_sin_pago, ln_d_si_evaluado, ln_d_con_puntaje, ln_d_sin_puntaje,
    ln_d_si_aprobado, ln_d_no_aprobado, ln_d_no_evaluado, ln_d_con_pago,
    ln_d_sin_pago, ln_suspendido, ln_faltas ) ;
    
end loop ;

end usp_rh_av_cns_evaluaciones ;
/
