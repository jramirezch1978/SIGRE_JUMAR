create or replace procedure usp_rh_cal_total_pagado (
    asi_codtra           in maestro.cod_trabajador%TYPE, 
    adi_fec_proceso      in date, 
    asi_origen           in origen.cod_origen%TYPE,
    asi_total_ingreso    in concepto.concep%TYPE, 
    asi_total_dscto      in concepto.concep%TYPE, 
    asi_total_pagado     in concepto.concep%TYPE,
    asi_tipo_planilla    in calculo.tipo_planilla%TYPE
) is

ln_imp_soles_gan        calculo.imp_soles%TYPE;
ln_imp_soles_des        calculo.imp_soles%TYPE;
ln_imp_dolar_gan        calculo.imp_soles%TYPE;
ln_imp_dolar_des        calculo.imp_soles%TYPE;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_soles%TYPE;

begin

--  ***********************************************
--  ***   CALCULA TOTAL PAGADO POR TRABAJADOR   ***
--  ***********************************************

select sum(nvl(c.imp_soles,0)), sum(nvl(c.imp_dolar,0))
  into ln_imp_soles_gan, ln_imp_dolar_gan
  from calculo c
 where c.cod_trabajador = asi_codtra 
   and c.concep         = asi_total_ingreso 
   and c.tipo_planilla  = asi_tipo_planilla;

select sum(nvl(c.imp_soles,0)), sum(nvl(c.imp_dolar,0))
  into ln_imp_soles_des, ln_imp_dolar_des
  from calculo c
 where c.cod_trabajador = asi_codtra 
   and c.concep         = asi_total_dscto 
   and c.tipo_planilla  = asi_tipo_planilla;

ln_imp_soles := NVL(ln_imp_soles_gan, 0) - NVL(ln_imp_soles_des,0) ;
ln_imp_dolar := NVL(ln_imp_dolar_gan, 0) - NVL(ln_imp_dolar_des, 0) ;

insert into calculo (
    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
    tipo_planilla )
values (
    asi_codtra, asi_total_pagado, adi_fec_proceso, 0, 0,
    0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
    asi_tipo_planilla ) ;

end usp_rh_cal_total_pagado ;
/
