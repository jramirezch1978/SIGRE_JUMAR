create or replace procedure usp_rh_backup_grupos_calculo (
  an_ano in number, an_mes in number, an_semana in number ) is

--  Cursor de grupos de calculo
cursor c_cabecera is
  select g.grupo_calculo, g.desc_grupo, g.concepto_gen
  from grupo_calculo g
  order by g.grupo_calculo ;

--  Cursor de grupos de calculo al detalle
cursor c_detalle is
  select d.grupo_calculo, d.concepto_calc
  from grupo_calculo_det d
  order by d.grupo_calculo, d.concepto_calc ;

begin

--  ***********************************************************
--  ***   BACKUP DE GRUPOS DE CALCULO DE RECURSOS HUMANOS   ***
--  ***********************************************************

delete from hist_grupo_calculo_det d
  where d.ano = an_ano and d.mes = an_mes and d.semana = an_semana ;

delete from hist_grupo_calculo g
  where g.ano = an_ano and g.mes = an_mes and g.semana = an_semana ;

for rc_c in c_cabecera loop

  insert into hist_grupo_calculo (
    ano, mes, semana, grupo_calculo, desc_grupo,
    concepto_gen, flag_replicacion )
  values (
    an_ano, an_mes, an_semana, rc_c.grupo_calculo, rc_c.desc_grupo,
    rc_c.concepto_gen, '1' ) ;

end loop ;

for rc_d in c_detalle loop

  insert into hist_grupo_calculo_det (
    ano, mes, semana, grupo_calculo, concepto_calc, flag_replicacion )
  values (
    an_ano, an_mes, an_semana, rc_d.grupo_calculo, rc_d.concepto_calc, '1' ) ;

end loop ;

end usp_rh_backup_grupos_calculo ;
/
