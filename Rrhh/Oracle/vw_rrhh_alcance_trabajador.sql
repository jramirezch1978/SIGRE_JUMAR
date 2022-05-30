create or replace view vw_rrhh_alcance_trabajador as
   select c.cod_trabajador, c.imp_soles, c.fec_proceso as fecha, upper(decode(trim(nvl(m.nro_cnta_ahorro,' ')) || 's', 's', 'sin tarjeta', 'con tarjeta')) as tarjeta
      from calculo c
         inner join rrhhparam rhp on c.concep = rhp.cnc_total_pgd
         inner join maestro m on c.cod_trabajador = m.cod_trabajador

   union all

   select hc.cod_trabajador, hc.imp_soles, hc.fec_calc_plan as fecha, upper(decode(trim(nvl(m.nro_cnta_ahorro,' ')) || 's', 's', 'sin tarjeta', 'con tarjeta')) as tarjeta 
      from historico_calculo hc
         inner join rrhhparam rhp on hc.concep = rhp.cnc_total_pgd
         inner join maestro m on hc.cod_trabajador = m.cod_trabajador