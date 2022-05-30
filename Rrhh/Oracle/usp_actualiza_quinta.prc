create or replace procedure usp_actualiza_quinta is

ln_verifica       integer ;

cursor c_quinta is
  select q.codigo, q.proyect, q.impre, q.fecha
  from quinta11 q
  order by q.codigo ;

begin

for rc_qui in c_quinta loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica from quinta_categoria qc
    where qc.cod_trabajador = rc_qui.codigo and qc.fec_proceso = rc_qui.fecha ;
    
  if ln_verifica > 0 then

    update quinta_categoria q
      set q.rem_proyectable = rc_qui.proyect ,
          q.rem_imprecisa = q.rem_imprecisa - rc_qui.impre
      where q.cod_trabajador = rc_qui.codigo and q.fec_proceso = rc_qui.fecha ;

  end if ;
  
end loop ;

end usp_actualiza_quinta ;
/
