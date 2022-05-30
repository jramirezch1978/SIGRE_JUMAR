create or replace view vw_rrhh_resumen_planilla as
select decode(substr(c.concep,1,1), '1', '1. GANANCIAS', '2', '2. DESCUENTOS', '3', '3. APORTACIONES', 'OTROS') as grupo, c.cod_trabajador, c.fec_proceso as fecha, to_char(c.fec_proceso, 'yyyy') as ano, to_char(c.fec_proceso, 'mm') as mes, c.concep, c.horas_trabaj as horas_trabajadas, c.horas_pag as horas_pagadas, c.imp_soles as importe_soles, c.dias_trabaj 
      from calculo c
      where c.concep <> (select rhp.cnc_total_ing  from rrhhparam rhp)
      and c.concep <> (select rhp.cnc_total_dsct from rrhhparam rhp)
      and c.concep <> (select rhp.cnc_total_aport from rrhhparam rhp)
      and c.concep <> (select rhp.cnc_total_pgd from rrhhparam rhp)
   
   union all

   select decode(substr(hc.concep,1,1), '1', '1. GANANCIAS', '2', '2. DESCUENTOS', '3', '3. APORTACIONES', 'OTROS') as grupo, hc.cod_trabajador, hc.fec_calc_plan as fecha, to_char(hc.fec_calc_plan, 'yyyy') as ano, to_char(hc.fec_calc_plan, 'mm') as mes, hc.concep, hc.horas_trabaj as horas_trabajadas, hc.horas_pagad as horas_pagadas, hc.imp_soles as importe_soles, hc.dias_trabaj
      from historico_calculo hc
         left outer join calculo c
            on hc.concep = c.concep
            and hc.cod_trabajador = c.cod_trabajador
            and hc.fec_calc_plan = c.fec_proceso
      where c.concep is null
      and hc.concep <> (select rhp.cnc_total_ing  from rrhhparam rhp)
      and hc.concep <> (select rhp.cnc_total_dsct from rrhhparam rhp)
      and hc.concep <> (select rhp.cnc_total_aport from rrhhparam rhp)
      and hc.concep <> (select rhp.cnc_total_pgd from rrhhparam rhp)

