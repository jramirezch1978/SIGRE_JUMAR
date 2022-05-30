create or replace procedure usp_rh_av_rpt_evaluaciones (
  as_tipo_trabajador in char, as_origen in char, as_codigo in char,
  as_seccion in char, an_ano in number, an_mes in number ) is

lk_objetivos          constant char(3) := 'OBJ' ;
lk_desempeno          constant char(3) := 'DES' ;

ls_codigo             char(8) ;
ls_area               char(1) ;
ls_seccion            char(3) ;
ls_nomtra             varchar2(60) ;
ln_imp_tope           number(13,2) ;
ln_peso_obj           number(5,3) ;
ln_peso_des           number(5,3) ;
ls_desc_calif         varchar2(60) ;
ls_valor_calif        char(3) ;
ln_valor_calif        number(6,3) ;
ln_contador           integer ;
ln_verifica           integer ;
ln_imp_obj            number(13,2) ;
ln_imp_des            number(13,2) ;
ln_calif              number(3) ;

--  Cursor de lectura de trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.tipo_trabajador, m.cod_area, m.cod_seccion,
         m.cod_origen, m.contra, m.banda, m.condes, s.desc_seccion,
         tt.desc_tipo_tra, ct.descripcion, bs.descripcion as desc_banda,
         cd.descripcion as desc_condes, o.nombre as nom_origen
  from maestro m, seccion s, tipo_trabajador tt, rrhh_condicion_trabajador ct,
       rrhh_banda_salarial bs, rrhh_condicion_desempeno cd, origen o
  where m.cod_area = s.cod_area and m.cod_seccion = s.cod_seccion and
        m.tipo_trabajador = tt.tipo_trabajador and m.contra = ct.contra and
        m.banda = bs.banda and m.condes = cd.condes and m.cod_origen = o.cod_origen and
        m.flag_cal_plnlla = '1' and m.flag_estado = '1' and
        m.cod_trabajador like as_codigo and m.cod_seccion like as_seccion and
        m.tipo_trabajador like as_tipo_trabajador and m.cod_origen like as_origen
  order by m.cod_seccion, m.cod_trabajador ;

--  Lectura de evaluaciones por objetivos
cursor c_objetivos is
  select eo.item, eo.calif_concepto, eo.calif_valor, eo.cod_usr, co.porcentaje,
         u.nombre as nom_user_obj, cc.descripcion as desc_objetivo
  from rrhh_eval_trab_objetivo eo, rrhh_calificacion_objetivo co, usuario u,
       rrhh_calificacion_concepto cc
  where eo.cod_area = co.cod_area and eo.cod_seccion = co.cod_seccion and
        eo.calif_concepto = co.calif_concepto and eo.cod_usr = u.cod_usr and
        eo.calif_concepto = cc.calif_concepto and cc.calif_tipo = lk_objetivos and
        eo.ano = an_ano and eo.mes = an_mes and eo.cod_area = ls_area and
        eo.cod_seccion = ls_seccion
  order by eo.item ;
  
--  Lectura de evaluaciones por desempeno
cursor c_desempeno is
  select ed.item, ed.calif_concepto, ed.calif_valor, ed.cod_usr, cd.porcentaje,
         u.nombre as nom_user_des, cc.descripcion as desc_desempeno
  from rrhh_eval_trab_desempeno ed, rrhh_calificacion_desempeno cd, usuario u,
       rrhh_calificacion_concepto cc
  where ed.condes = cd.condes and ed.calif_concepto = cd.calif_concepto and
        ed.cod_usr = u.cod_usr and ed.calif_concepto = cc.calif_concepto and
        cc.calif_tipo = lk_desempeno and ed.ano = an_ano and ed.mes = an_mes and
        ed.cod_trabajador = ls_codigo
  order by ed.item ;
  
begin

--  ************************************************************************
--  ***   GENERA EVALUACIONES POR OBJETIVOS Y DESEMPENO POR TRABAJADOR   ***
--  ************************************************************************

delete from tt_av_rpt_evaluaciones ;

for rc_mae in c_maestro loop

  ls_codigo  := rc_mae.cod_trabajador ;
  ls_area    := rc_mae.cod_area ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_nomtra  := usf_rh_nombre_trabajador (ls_codigo) ;

  --  Determina importe tope por banda salarial
  ln_verifica := 0 ; ln_imp_tope := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_tope t
    where t.banda = rc_mae.banda and t.contra = rc_mae.contra ;
  if ln_verifica > 0 then
    select nvl(t.tope,0) into ln_imp_tope from rrhh_banda_salarial_tope t
      where t.banda = rc_mae.banda and t.contra = rc_mae.contra ;
  end if ;
    
  --  Determina peso de evaluacion por objetivos y desempeno
  ln_verifica := 0 ; ln_peso_obj := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_distrib d
    where d.banda = rc_mae.banda and d.calif_tipo = lk_objetivos ;
  if ln_verifica > 0 then
    select nvl(d.porcentaje,0) into ln_peso_obj from rrhh_banda_salarial_distrib d
      where d.banda = rc_mae.banda and d.calif_tipo = lk_objetivos ;
  end if ;
  ln_verifica := 0 ; ln_peso_des := 0 ;
  select count(*) into ln_verifica from rrhh_banda_salarial_distrib d
    where d.banda = rc_mae.banda and d.calif_tipo = lk_desempeno ;
  if ln_verifica > 0 then
    select nvl(d.porcentaje,0) into ln_peso_des from rrhh_banda_salarial_distrib d
      where d.banda = rc_mae.banda and d.calif_tipo = lk_desempeno ;
  end if ;

  --  Graba registros por evaluaciones por objetivos
  ln_contador := 0 ;
  for rc_obj in c_objetivos loop

    ln_contador := ln_contador + 1 ; ln_imp_obj := 0 ;
    if ln_contador = 1 then
      select ct.descripcion into ls_desc_calif from rrhh_calificacion_tipo ct
        where ct.calif_tipo = lk_objetivos ;
      ln_verifica := 0 ;
      select count(*) into ln_verifica from rrhh_compensacion_var cv
        where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador = ls_codigo and
              cv.calif_tipo = lk_objetivos ;
      if ln_verifica > 0 then
        select nvl(cv.importe,0) into ln_imp_obj from rrhh_compensacion_var cv
          where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador = ls_codigo and
                cv.calif_tipo = lk_objetivos ;
      end if ;
    end if ;
    
    ln_valor_calif := nvl(rc_obj.porcentaje,0) ;
    ln_calif       := nvl(rc_obj.porcentaje,0) * nvl(rc_obj.calif_valor,0) / 100 ;
    ls_valor_calif := lpad(to_char(ln_calif),3,'0') ;

    --  Inserta registros de evaluaciones
    insert into tt_av_rpt_evaluaciones (
      ano, mes, codigo, nom_tra, cod_seccion, desc_seccion,
      tipo_trabajador, desc_tipo_tra, cod_origen,
      nom_origen, contra, descripcion, banda,
      desc_banda, condes, desc_condes, imp_banda, peso_obj,
      peso_des, tipo_calif, desc_tipo_calif, cod_usr, nombre_usuario,
      item, calif_concepto, desc_calif, porcentaje,
      valor, valor_calif, imp_calif )
    values (        
      an_ano, an_mes, ls_codigo, ls_nomtra, rc_mae.cod_seccion, rc_mae.desc_seccion,
      rc_mae.tipo_trabajador, rc_mae.desc_tipo_tra, rc_mae.cod_origen,
      rc_mae.nom_origen, rc_mae.contra, rc_mae.descripcion, rc_mae.banda,
      rc_mae.desc_banda, rc_mae.condes, rc_mae.desc_condes, ln_imp_tope, ln_peso_obj,
      ln_peso_des, lk_objetivos, ls_desc_calif, rc_obj.cod_usr, rc_obj.nom_user_obj,
      rc_obj.item, rc_obj.calif_concepto, rc_obj.desc_objetivo, rc_obj.porcentaje,
      ls_valor_calif, ln_calif, ln_imp_obj ) ;

  end loop ;

  --  Graba registros por evaluaciones por desempeno
  ln_contador := 0 ;
  for rc_des in c_desempeno loop

    ln_contador := ln_contador + 1 ; ln_imp_des := 0 ;
    if ln_contador = 1 then
      select ct.descripcion into ls_desc_calif from rrhh_calificacion_tipo ct
        where ct.calif_tipo = lk_desempeno ;
      ln_verifica := 0 ;
      select count(*) into ln_verifica from rrhh_compensacion_var cv
        where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador = ls_codigo and
              cv.calif_tipo = lk_desempeno ;
      if ln_verifica > 0 then
        select nvl(cv.importe,0) into ln_imp_des from rrhh_compensacion_var cv
          where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador = ls_codigo and
                cv.calif_tipo = lk_desempeno ;
      end if ;
    end if ;
    
    ln_valor_calif := nvl(rc_des.porcentaje,0) ;
    ln_calif       := nvl(rc_des.porcentaje,0) * nvl(rc_des.calif_valor,0) / 100 ;
    ls_valor_calif := lpad(to_char(ln_calif),3,'0') ;

    --  Inserta registros de evaluaciones
    insert into tt_av_rpt_evaluaciones (
      ano, mes, codigo, nom_tra, cod_seccion, desc_seccion,
      tipo_trabajador, desc_tipo_tra, cod_origen,
      nom_origen, contra, descripcion, banda,
      desc_banda, condes, desc_condes, imp_banda, peso_obj,
      peso_des, tipo_calif, desc_tipo_calif, cod_usr, nombre_usuario,
      item, calif_concepto, desc_calif, porcentaje,
      valor, valor_calif, imp_calif )
    values (        
      an_ano, an_mes, ls_codigo, ls_nomtra, rc_mae.cod_seccion, rc_mae.desc_seccion,
      rc_mae.tipo_trabajador, rc_mae.desc_tipo_tra, rc_mae.cod_origen,
      rc_mae.nom_origen, rc_mae.contra, rc_mae.descripcion, rc_mae.banda,
      rc_mae.desc_banda, rc_mae.condes, rc_mae.desc_condes, ln_imp_tope, ln_peso_obj,
      ln_peso_des, lk_desempeno, ls_desc_calif, rc_des.cod_usr, rc_des.nom_user_des,
      rc_des.item, rc_des.calif_concepto, rc_des.desc_desempeno, rc_des.porcentaje,
      ls_valor_calif, ln_calif, ln_imp_des ) ;

  end loop ;

end loop ;

end usp_rh_av_rpt_evaluaciones ;
/
