lock table historico_distrib_cntble in exclusive mode;

alter table historico_distrib_cntble disable all triggers;

delete historico_distrib_cntble;

insert into historico_distrib_cntble(cod_trabajador, cencos, fec_movimiento, cod_labor, cod_usr, und, nro_horas, fec_calculo, centro_benef)
select cod_trabajador, cencos, fec_movimiento, cod_labor, cod_usr, und, nro_horas, fec_calculo, centro_benef
from distribucion_cntble;

commit;

alter table historico_distrib_cntble enable all triggers;
