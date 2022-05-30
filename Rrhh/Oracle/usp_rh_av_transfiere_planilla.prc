create or replace procedure usp_rh_av_transfiere_planilla (
  as_origen in char, as_tipo_trabaj in char, an_ano in number,
  an_mes in number, as_usuario in char ) is

lk_pago_objetivos      constant char(3) := '083' ;

ln_verifica            integer ;
ls_concepto            char(4) ;
ld_fecha               date ;
ls_codigo              char(8) ;
ln_importe             number(13,2) ;

--  Lectura del pago por compensacion variable
cursor c_movimiento is
  select cv.cod_trabajador, cv.calif_tipo, cv.importe
  from rrhh_compensacion_var cv, maestro m
  where cv.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and cv.ano = an_ano and
        cv.mes = an_mes and cv.flag_estado = '2'
  order by cv.ano, cv.mes, cv.cod_trabajador, cv.calif_tipo ;

begin

--  ****************************************************************
--  ***   ADICIONA PAGO DE COMPENSACION VARIABLE A LA PLANILLA   ***
--  ****************************************************************

select p.fec_proceso into ld_fecha from rrhh_param_org p
  where p.origen = as_origen ;
  
--select p.fec_proceso into ld_fecha from rrhhparam p
--  where p.reckey = '1' ;
  
select c.concepto_gen into ls_concepto
  from grupo_calculo c
  where c.grupo_calculo = lk_pago_objetivos ;
  
delete from gan_desct_variable v
  where v.concep = ls_concepto and v.fec_movim = ld_fecha and
        v.cod_trabajador in ( select m.cod_trabajador from maestro m
                              where m.cod_origen = as_origen and
                              m.tipo_trabajador like as_tipo_trabaj ) ;

for rc_mov in c_movimiento loop

  ls_codigo  := rc_mov.cod_trabajador ;
  ln_importe := nvl(rc_mov.importe,0) ;

  ln_verifica := 0 ;
  select count(*) into ln_verifica from gan_desct_variable v
    where v.cod_trabajador = ls_codigo and v.concep = ls_concepto and
          v.fec_movim = ld_fecha ;
  if ln_verifica > 0 then
    update gan_desct_variable
      set imp_var = imp_var + nvl(ln_importe,0)
    where cod_trabajador = ls_codigo and concep = ls_concepto and
          fec_movim = ld_fecha ;
  else      
    insert into gan_desct_variable (
      cod_trabajador, fec_movim, concep, imp_var, cod_usr )
    values (
      ls_codigo, ld_fecha, ls_concepto, ln_importe, as_usuario ) ;
  end if ;
  
end loop ;

end usp_rh_av_transfiere_planilla ;





/*
create or replace procedure usp_rh_av_transfiere_planilla (
  as_origen in char, as_tipo_trabaj in char, an_ano in number,
  an_mes in number, as_usuario in char ) is

lk_pago_objetivos      constant char(3) := '083' ;
lk_pago_desempeno      constant char(3) := '084' ;
lk_gana_objetivos      constant char(3) := '086' ;
lk_gana_desempeno      constant char(3) := '087' ;
lk_objetivos           constant char(3) := 'OBJ' ;
lk_desempeno           constant char(3) := 'DES' ;

ln_verifica            integer ;
ls_concepto            char(4) ;
ld_fecha               date ;
ls_codigo              char(8) ;
ln_importe             number(13,2) ;
ls_grupo_calculo       char(3) ;

--  Lectura del pago por compensacion variable
cursor c_movimiento is
  select cv.cod_trabajador, cv.calif_tipo, cv.importe
  from rrhh_compensacion_var cv, maestro m
  where cv.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador like as_tipo_trabaj and cv.ano = an_ano and
        cv.mes = an_mes and cv.flag_estado = '2'
  order by cv.ano, cv.mes, cv.cod_trabajador, cv.calif_tipo ;

--  Lectura de conceptos por calificaciones
cursor c_conceptos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = ls_grupo_calculo
  order by d.grupo_calculo, d.concepto_calc ;
  
begin

--  ****************************************************************
--  ***   ADICIONA PAGO DE COMPENSACION VARIABLE A LA PLANILLA   ***
--  ****************************************************************

select p.fec_proceso into ld_fecha from rrhhparam p
  where p.reckey = '1' ;
  
select c.concepto_gen into ls_concepto
  from grupo_calculo c
  where c.grupo_calculo = lk_pago_objetivos ;
  
delete from gan_desct_variable v
  where v.concep = ls_concepto and v.fec_movim = ld_fecha and
        v.cod_trabajador in ( select m.cod_trabajador from maestro m
                              where m.cod_origen = as_origen and
                              m.tipo_trabajador like as_tipo_trabaj ) ;

--delete from gan_desct_variable v
--  where v.concep in ( select d.concepto_calc from grupo_calculo_det d where
--        d.grupo_calculo = lk_pago_objetivos ) and v.cod_trabajador in
--        ( select m.cod_trabajador from maestro m where m.cod_origen = as_origen
--          and m.tipo_trabajador like as_tipo_trabaj ) ;

--delete from gan_desct_variable v
--  where v.concep in ( select d.concepto_calc from grupo_calculo_det d where
--        d.grupo_calculo = lk_pago_desempeno ) and v.cod_trabajador in
--        ( select m.cod_trabajador from maestro m where m.cod_origen = as_origen
--          and m.tipo_trabajador like as_tipo_trabaj ) ;

for rc_mov in c_movimiento loop

  ls_codigo  := rc_mov.cod_trabajador ;
  ln_importe := nvl(rc_mov.importe,0) ;

--  if as_tipo = '1' then
    if rc_mov.calif_tipo = lk_objetivos then
      ls_grupo_calculo := lk_gana_objetivos ;
    elsif rc_mov.calif_tipo = lk_desempeno then
      ls_grupo_calculo := lk_gana_desempeno ;
    end if ;
--  elsif as_tipo = '2' then
--    if rc_mov.calif_tipo = lk_objetivos then
--      ls_grupo_calculo := lk_pago_objetivos ;
--    elsif rc_mov.calif_tipo = lk_desempeno then
--      ls_grupo_calculo := lk_pago_desempeno ;
--    end if ;
--  end if ;
    
--  for rc_con in c_conceptos loop
    ln_verifica := 0 ;
    select count(*) into ln_verifica from gan_desct_variable v
      where v.cod_trabajador = ls_codigo and v.concep = ls_concepto and
            v.fec_movim = ld_fecha ;
    if ln_verifica > 0 then
      update gan_desct_variable
        set imp_var = imp_var + nvl(ln_importe,0)
      where cod_trabajador = ls_codigo and concep = ls_concepto and
            fec_movim = ld_fecha ;
    else      
      insert into gan_desct_variable (
        cod_trabajador, fec_movim, concep, imp_var, cod_usr )
      values (
        ls_codigo, ld_fecha, ls_concepto, ln_importe, as_usuario ) ;
    end if ;
--  end loop ;
  
end loop ;

end usp_rh_av_transfiere_planilla ;
*/
/
