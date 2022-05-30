create or replace view vw_rh_inasistencia as
select i.cod_trabajador, i.concep, i.fec_desde, i.fec_hasta, i.dias_inasist, i.fec_movim 
   from inasistencia i

union all

select hi.cod_trabajador, hi.concep, hi.fec_desde, hi.fec_hasta, hi.dias_inasist, hi.fec_movim
   from historico_inasistencia hi
   left outer join inasistencia i 
      on i.cod_trabajador = hi.cod_trabajador 
      and i.concep = hi.concep 
      and trunc(i.fec_movim) = trunc(hi.fec_movim)
   where i.concep is null