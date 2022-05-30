create or replace procedure usp_actualiza_quincena is

ln_registro    integer ;

cursor c_movimiento is
  select c.codigo, c.importe
  from cts c
  where c.codigo is not null ;

begin

for rc_mov in c_movimiento loop

  ln_registro := 0 ;
  select count(*)
    into ln_registro
    from adelanto_quincena q
    where q.cod_trabajador = rc_mov.codigo ;
    
  if ln_registro > 0 then
    update adelanto_quincena
      set imp_adelanto = imp_adelanto + rc_mov.importe
      where cod_trabajador = rc_mov.codigo ;
  else
    insert into adelanto_quincena (
      cod_trabajador, concep, fec_proceso, imp_adelanto )
    values (
      rc_mov.codigo, '2310', to_date('30/04/2003','DD/MM/YYYY'), rc_mov.importe ) ;
  end if ;
    
end loop ;

end usp_actualiza_quincena ;
/
