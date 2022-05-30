create or replace procedure usp_actualiza_sobretiempo is

cursor c_movimiento is
  select h.cod_trabajador, h.fec_movim, h.concep, h.nro_doc,
         h.horas_sobret, h.cod_usr
  from historico_sobretiempo h
  where h.fec_movim between to_date('21/02/2004','dd/mm/yyyy') and
        to_date('29/02/2004','dd/mm/yyyy') ;

begin

for rc_mov in c_movimiento loop

  insert into sobretiempo_turno (
    cod_trabajador, fec_movim, concep,
    nro_doc, horas_sobret, cod_usr )
  values (
    rc_mov.cod_trabajador, rc_mov.fec_movim, rc_mov.concep,
    rc_mov.nro_doc, rc_mov.horas_sobret, rc_mov.cod_usr ) ;
  
end loop ;

end usp_actualiza_sobretiempo ;
/
