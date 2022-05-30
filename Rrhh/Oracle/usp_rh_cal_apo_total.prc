create or replace procedure usp_rh_cal_apo_total (
  asi_codtra                in maestro.cod_trabajador%TYPE,
  adi_fec_proceso           in date,
  asi_origen                in origen.cod_origen%TYPE,
  asi_cnc_total_aportes     in concepto.concep%TYPE,
  asi_tipo_planilla         in calculo.tipo_planilla%TYPE
) is

ln_imp_soles        calculo.imp_soles%TYPE;
ln_imp_dolar        calculo.imp_dolar%TYPE;

begin

--  **********************************************************
--  ***   SUMATORIA DE TODAS LAS APORTACIONES PATRONALES   ***
--  **********************************************************

select NVL(sum(nvl(c.imp_soles,0)),0), NVL(sum(nvl(c.imp_dolar,0)),0)
  into ln_imp_soles, ln_imp_dolar
  from calculo c
 where c.cod_trabajador = asi_codtra
   and substr(c.concep,1,1) = '3' 
   and c.tipo_planilla      = asi_tipo_planilla;

insert into calculo (
       cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
       dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
       tipo_planilla )
values (
       asi_codtra, asi_cnc_total_aportes, adi_fec_proceso, 0, 0,
       0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
       asi_tipo_planilla ) ;

end usp_rh_cal_apo_total ;
/
