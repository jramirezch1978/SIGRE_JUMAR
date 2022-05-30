create or replace procedure usp_rh_av_rpt_relacion_pago (
  as_origen in char, as_tipo_trabaj in char, an_ano in number,
  an_mes in number ) is

lk_objetivos          constant char(3) := 'OBJ' ;
lk_desempeno          constant char(3) := 'DES' ;

ls_nombres            varchar2(60) ;
ln_verifica           integer ;
ln_imp_obj            number(13,2) ;
ln_imp_des            number(13,2) ;
ln_imp_tot            number(13,2) ;

--  Lectura de trabajadores por secciones
cursor c_maestro is
  select m.cod_trabajador, m.cod_area, m.cod_seccion, s.desc_seccion,
         tt.desc_tipo_tra
  from maestro m, seccion s, tipo_trabajador tt
  where m.cod_area = s.cod_area and m.cod_seccion = s.cod_seccion and
        m.tipo_trabajador = tt.tipo_trabajador and m.flag_cal_plnlla = '1' and
        m.flag_estado = '1' and m.tipo_trabajador like as_tipo_trabaj and
        m.cod_origen = as_origen
  order by m.cod_seccion, m.cod_trabajador ;
  
begin

--  ************************************************************
--  ***   GENERA REPORTE DE PAGO POR COMPENSACION VARIABLE   ***
--  ************************************************************

delete from tt_av_rpt_pago_compensacion ;

for rc_mae in c_maestro loop

  ls_nombres := usf_rh_nombre_trabajador (rc_mae.cod_trabajador) ;
  ln_imp_obj := 0 ; ln_imp_des := 0 ; ln_imp_tot := 0 ;

  --  Determina pago de evaluacion por objetivos
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_compensacion_var cv
    where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador =
          rc_mae.cod_trabajador and cv.calif_tipo = lk_objetivos and
          cv.flag_estado = '2' ;
  if ln_verifica > 0 then
    select nvl(cv.importe,0) into ln_imp_obj from rrhh_compensacion_var cv
      where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador =
            rc_mae.cod_trabajador and cv.calif_tipo = lk_objetivos and
            cv.flag_estado = '2' ;
  end if ;          
          
  --  Determina pago de evaluacion por desempeno
  ln_verifica := 0 ;
  select count(*) into ln_verifica from rrhh_compensacion_var cv
    where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador =
          rc_mae.cod_trabajador and cv.calif_tipo = lk_desempeno and
          cv.flag_estado = '2' ;
  if ln_verifica > 0 then
    select nvl(cv.importe,0) into ln_imp_des from rrhh_compensacion_var cv
      where cv.ano = an_ano and cv.mes = an_mes and cv.cod_trabajador =
            rc_mae.cod_trabajador and cv.calif_tipo = lk_desempeno and
            cv.flag_estado = '2' ;
  end if ;          

  ln_imp_tot := ln_imp_obj + ln_imp_des ;
  
  --  Inserta registro por trabajador
  if nvl(ln_imp_tot,0) <> 0 then
    insert into tt_av_rpt_pago_compensacion (
      ano, mes, tipo_trabajador, cod_seccion,
      desc_seccion, cod_trabajador, nombres,
      imp_obj, imp_des, imp_tot )
    values (
      an_ano, an_mes, rc_mae.desc_tipo_tra, rc_mae.cod_seccion,
      rc_mae.desc_seccion, rc_mae.cod_trabajador, ls_nombres,
      ln_imp_obj, ln_imp_des, ln_imp_tot ) ;
  end if ;
  
end loop ;

end usp_rh_av_rpt_relacion_pago ;
/
