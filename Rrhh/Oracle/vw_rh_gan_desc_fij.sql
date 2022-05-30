create or replace view vw_rh_gan_desc_fij as

   select c.concep, c.cod_trabajador, c.imp_soles, c.fec_proceso 
      from calculo c

union all

   select hc.concep, hc.cod_trabajador, hc.imp_soles, hc.fec_calc_plan
      from historico_calculo hc
         left outer join calculo c
            on hc.concep = c.concep
            and hc.cod_trabajador = c.cod_trabajador
            and hc.fec_calc_plan = c.fec_proceso
      where c.concep is null