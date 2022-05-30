create or replace procedure usp_rh_av_calcula_evaluaciones (
  as_codigo in char, an_ano in number, an_mes in number,
  ad_fec_desde in date, ad_fec_hasta in date ) is

lk_suspension        constant char(3) := '081' ;
lk_inasistencia      constant char(3) := '082' ;
lk_calif_objetivo    constant char(3) := 'OBJ' ;
lk_calif_desempeno   constant char(3) := 'DES' ;
lk_comp_variable     constant char(8) := 'COMPVARI' ;

ln_verifica          integer ;
ls_concepto          char(4) ;
ln_nro_dias          number(5,2) ;
ls_area              char(1) ;
ls_seccion           char(3) ;
ls_seccion_dep       char(3) ;
ln_suma_obj          number(6,3) ;
ln_suma_dep          number(6,3) ;
ln_suma_des          number(6,3) ;
ls_user_obj          char(6) ;
ls_user_des          char(6) ;
ls_obj_adm           char(3) ;
ls_cod_banda         char(6) ;
ln_imp_tope          number(13,2) ;
ln_porc_distrib      number(5,3) ;
ln_pago_obj          number(13,2) ;
ln_pago_des          number(13,2) ;

--  Lectura de inasistencias de trabajadores en el mes
cursor c_inasistencia is
  select i.nro_dias
  from incidencia_trabajador i
  where i.cod_trabajador = as_codigo and nvl(i.flag_conformidad,'0') = '0' and
        trunc(i.fecha_movim) between ad_fec_desde and ad_fec_hasta and
        i.concep in ( select d.concepto_calc from grupo_calculo_det d
                      where d.grupo_calculo = lk_inasistencia )
  order by i.cod_trabajador, i.fecha_movim ;
  
--  Lectura de evaluaciones por objetivos del trabajador
cursor c_objetivos is
  select o.calif_valor, co.porcentaje, o.cod_usr
  from rrhh_eval_trab_objetivo o, rrhh_calificacion_objetivo co
  where o.cod_area = co.cod_area and o.cod_seccion = co.cod_seccion and
        o.calif_concepto = co.calif_concepto and o.ano = an_ano and o.mes =
        an_mes and o.cod_area = ls_area and o.cod_seccion = ls_seccion and
        o.flag_estado = '1'
  order by o.item ;

--  Lectura de evaluaciones por desempeno del trabajador
cursor c_desempeno is
  select d.calif_valor, cd.porcentaje, d.cod_usr
  from rrhh_eval_trab_desempeno d, rrhh_calificacion_desempeno cd
  where d.condes = cd.condes and d.calif_concepto = cd.calif_concepto and
        d.ano = an_ano and d.mes = an_mes and d.cod_trabajador = as_codigo and
        d.flag_estado = '1'
  order by d.item ;

begin

--  ******************************************************************
--  ***   GENERA PAGO POR EVALUACIONES DE OBJETIVOS Y DESEMPENOS   ***
--  ******************************************************************

--delete from rrhh_compensacion_var c
--  where c.ano = an_ano and c.mes = an_mes and c.cod_trabajador = as_codigo ;

--  Determina si el trabajador tiene suspension
ln_verifica := 0 ;
select count(*) into ln_verifica from grupo_calculo c
  where c.grupo_calculo = lk_suspension ;
if ln_verifica > 0 then
  select c.concepto_gen into ls_concepto from grupo_calculo c
    where c.grupo_calculo = lk_suspension ;
  ln_verifica := 0 ;
  select count(*) into ln_verifica from incidencia_trabajador t
    where t.cod_trabajador = as_codigo and t.concep = ls_concepto and
          (trunc(t.fecha_movim) between ad_fec_desde and ad_fec_hasta) and
          nvl(t.flag_conformidad,'0') = '0' ;
   if ln_verifica > 0 then
     return ;
   end if ;
end if ;
  
--  Determina inasistencias del trabajador
ln_nro_dias := 0 ;
for rc_ina in c_inasistencia loop
  ln_nro_dias := ln_nro_dias + nvl(rc_ina.nro_dias,0) ;
end loop ;
if ln_nro_dias > 3 then
  return ;
end if ;

--  selecciona datos del maestro de trabajadores
select m.cod_area, m.cod_seccion, m.contra, m.banda
  into ls_area, ls_seccion, ls_obj_adm, ls_cod_banda
  from maestro m where m.cod_trabajador = as_codigo ;
  
--  Sumatoria de calificacion por objetivos por seccion
ln_suma_obj := 0 ;
for rc_obj in c_objetivos loop
  if nvl(rc_obj.calif_valor,0) > 0 then
    ln_suma_obj := ln_suma_obj + ( nvl(rc_obj.porcentaje,0) *
                   nvl(rc_obj.calif_valor,0) / 100 ) ;
    ls_user_obj := rc_obj.cod_usr ;
  end if ;
end loop ;

if nvl(ln_suma_obj,0) > 0 then

  --  Determina seccion para calificacion de la gerencia
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rpt_grupo g
    where g.reporte = lk_comp_variable and substr(g.grupo,1,3) = ls_seccion ;
  if ln_verifica > 0 then
    select substr(nvl(descripcion,'000'),1,3) into ls_seccion_dep from rpt_grupo g
      where g.reporte = lk_comp_variable and substr(g.grupo,1,3) = ls_seccion ;
  else
    raise_application_error( -20000, 'No Existe Sección'||' '||ls_seccion||' '||
                             'En la Tabla de Configuración de Sistemas') ;
  end if ;
  
  --  Sumatoria de calificacion por objetivos de la dependencia
  if ls_seccion_dep = '000' then
    ln_suma_obj := 0 ;
  else
    if ls_seccion <> ls_seccion_dep then
      ls_area     := substr(ls_seccion_dep,1,1) ;
      ls_seccion  := substr(ls_seccion_dep,1,3) ;
      ln_suma_dep := 0 ;
      for rc_obj in c_objetivos loop
        if nvl(rc_obj.calif_valor,0) > 0 then
          ln_suma_dep := ln_suma_dep + ( nvl(rc_obj.porcentaje,0) *
                         nvl(rc_obj.calif_valor,0) / 100 ) ;
        end if ;
      end loop ;
      ln_suma_obj := (nvl(ln_suma_obj,0) * nvl(ln_suma_dep,0)) / 100 ;
    end if ;
  end if ;

end if ;

--  Sumatoria de calificacion por desempeno
ln_suma_des := 0 ;
for rc_des in c_desempeno loop
  if nvl(rc_des.calif_valor,0) > 0 then
    ln_suma_des := ln_suma_des + ( nvl(rc_des.porcentaje,0) *
                   nvl(rc_des.calif_valor,0) / 100 ) ;
    ls_user_des := rc_des.cod_usr ;
  end if ;
end loop ;
  
--  Si no tiene actitudes no realiza ningun pago
if nvl(ln_suma_des,0) = 0 then
  return ;
end if ;

--  Realiza pago por calificacion por objetivos
if nvl(ln_suma_obj,0) > 0 then

  ln_imp_tope := 0 ; ln_porc_distrib := 0 ; ln_pago_obj := 0 ;

  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_tope t
    where t.banda = ls_cod_banda and t.contra = ls_obj_adm ;
  if ln_verifica > 0 then
    select nvl(t.tope,0) into ln_imp_tope from rrhh_banda_salarial_tope t
      where t.banda = ls_cod_banda and t.contra = ls_obj_adm ;
  end if ;

  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_distrib d
    where d.banda = ls_cod_banda and d.calif_tipo = lk_calif_objetivo ;
  if ln_verifica > 0 then
    select nvl(d.porcentaje,0) into ln_porc_distrib from rrhh_banda_salarial_distrib d
      where d.banda = ls_cod_banda and d.calif_tipo = lk_calif_objetivo ;
  end if ;

  ln_pago_obj := ln_imp_tope * (ln_porc_distrib/100) * (ln_suma_obj/100) ;

  if nvl(ln_pago_obj,0) > 0 then
    if nvl(ln_pago_obj,0) > ln_imp_tope then
      ln_pago_obj := ln_imp_tope ;
    end if ;
    insert into rrhh_compensacion_var (
      ano, mes, cod_trabajador, calif_tipo,
      importe, flag_estado, usr_supervisor )
    values (
      an_ano, an_mes, as_codigo, lk_calif_objetivo,
      ln_pago_obj, '1', ls_user_obj ) ;
  end if ;
    
end if ;

--  Realiza pago por calificacion por desempeno
if nvl(ln_suma_des,0) > 0 then

  ln_imp_tope := 0 ; ln_porc_distrib := 0 ; ln_pago_des := 0 ;

  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_tope t
    where t.banda = ls_cod_banda and t.contra = ls_obj_adm ;
  if ln_verifica > 0 then
    select nvl(t.tope,0) into ln_imp_tope from rrhh_banda_salarial_tope t
      where t.banda = ls_cod_banda and t.contra = ls_obj_adm ;
  end if ;

  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_distrib d
    where d.banda = ls_cod_banda and d.calif_tipo = lk_calif_desempeno ;
  if ln_verifica > 0 then
    select nvl(d.porcentaje,0) into ln_porc_distrib from rrhh_banda_salarial_distrib d
      where d.banda = ls_cod_banda and d.calif_tipo = lk_calif_desempeno ;
  end if ;

  ln_pago_des := ln_imp_tope * (ln_porc_distrib/100) * (ln_suma_des/100) ;
  
  if nvl(ln_pago_des,0) > 0 then
    if nvl(ln_pago_des,0) > ln_imp_tope then
      ln_pago_des := ln_imp_tope ;
    end if ;
    insert into rrhh_compensacion_var (
      ano, mes, cod_trabajador, calif_tipo,
      importe, flag_estado, usr_supervisor )
    values (
      an_ano, an_mes, as_codigo, lk_calif_desempeno,
      ln_pago_des, '1', ls_user_des ) ;
  end if ;
    
end if ;

end usp_rh_av_calcula_evaluaciones ;
/
