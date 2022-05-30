create or replace view vw_rh_sobretirmpo as
select s.cod_trabajador, s.fec_movim, s.concep, s.nro_doc, s.horas_sobret, s.cod_usr
   from sobretiempo_turno s
   union all
select hs.cod_trabajador, hs.fec_movim, hs.concep, hs.nro_doc, hs.horas_sobret, hs.cod_usr 
   from historico_sobretiempo hs
   left outer join sobretiempo_turno s
      on s.cod_trabajador = hs.cod_trabajador
      and s.concep = hs.concep
      and trunc(s.fec_movim) = trunc(hs.fec_movim)
   where s.concep is null
   
