create or replace procedure usp_actualiza_direcciones is

ln_registro    number(15) ;
ls_direccion   varchar2(40) ;

--  Lee maestro de trabajadores
cursor c_maestro is
  select m.cod_trabajador, m.direccion
  from maestro m
  where m.direccion <> ' '
  order by m.cod_trabajador ;

begin

for rc_mae in c_maestro loop

  ls_direccion := substr(rc_mae.direccion,1,40) ;
  ln_registro  := 0 ;
  select count(*)
    into ln_registro
    from direcciones d
    where d.codigo = rc_mae.cod_trabajador ;
  if ln_registro > 0 then
    update direcciones
      Set dir_direccion = ls_direccion
      where codigo = rc_mae.cod_trabajador ;
  else
    insert into direcciones (
      codigo, item, descripcion, dir_pais,
      dir_dep_estado, dir_direccion, flag_uso )
    values (
      rc_mae.cod_trabajador, 1, 'DOMICILIO', 'PERU',
      'LIMA', ls_direccion, '1' ) ;
  end if ;
  
end loop ;

end usp_actualiza_direcciones ;
/
