insert into historico_calculo(
       cod_trabajador, concep, fec_calc_plan, cencos, cod_seccion, horas_trabaj, horas_pagad, dias_trabaj, cod_moneda, imp_soles, imp_dolar,
       cod_origen, tipo_trabajador, item)
select cod_trabajador, concep, fec_calc_plan, cencos, cod_seccion, horas_trabaj, horas_pagad, dias_trabaj, cod_moneda, imp_soles, imp_dolar,
       cod_origen, tipo_trabajador, 1
from flota_112013              
     
