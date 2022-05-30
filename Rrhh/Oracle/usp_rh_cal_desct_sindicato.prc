create or replace procedure usp_rh_cal_desct_sindicato (
  asi_codtra         in maestro.cod_trabajador%TYPE, 
  asi_origen         in origen.cod_origen%TYPE, 
  adi_fec_proceso    in date,
  ani_tipcam         in number,
  asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) is

lk_sind_emplea     char(3) ;
lk_sind_obrero     char(3) ;

ls_concepto        char(4) ;
ln_factor          concepto.fact_pago%TYPE;
ln_count           number;
ln_imp_soles       calculo.imp_soles%TYPE;
ln_imp_dolar       calculo.imp_dolar%TYPE;

begin

--  ***************************************************************
--  ***   GENERA DESCUENTO FIJO DEL SINDICATO A LOS AFILIADOS   ***
--  ***************************************************************

select c.sindicato_empleado, c.sindicato_obrero
  into lk_sind_emplea, lk_sind_obrero
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select c.concep, c.fact_pago
  into ls_concepto, ln_factor
  from concepto c,
       grupo_calculo gc
 where c.concep = gc.concepto_gen
   and gc.grupo_calculo = lk_sind_obrero;

select count(*)
  into ln_count
  from gan_desct_fijo gdf
 where gdf.concep = ls_Concepto
   and gdf.cod_trabajador = asi_codtra;
   
if ln_count > 0 then
    -- Obtengo primero el calculo por hora
    SELECT sum(c.imp_soles)
      INTO ln_imp_soles
      FROM calculo c
     WHERE c.COD_TRABAJADOR = asi_codtra
       and c.tipo_planilla  = asi_tipo_planilla
       AND c.CONCEP IN (SELECT D.CONCEPTO_CALC
                          FROM GRUPO_CALCULO_DET D
                         WHERE D.GRUPO_CALCULO = lk_sind_obrero);

    -- Calculo el importe
    ln_imp_soles := ln_imp_soles * ln_Factor;
    ln_imp_dolar := ln_imp_soles / ani_tipcam;

    IF ln_imp_soles > 0 OR ln_imp_dolar > 0 THEN
       update calculo c
          set c.horas_trabaj = null,
              c.horas_pag    = null,
              c.dias_trabaj  = null,
              c.imp_soles    = ln_imp_soles,
              c.imp_dolar    = ln_imp_dolar
        where c.cod_trabajador = asi_codtra
          and c.concep         = ls_concepto
          and c.fec_proceso    = adi_fec_proceso
          and c.tipo_planilla  = asi_tipo_planilla;
        
       if SQL%NOTFOUND then
          insert into calculo (
                       cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                       dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
          values (
                       asi_codtra, ls_concepto, adi_fec_proceso, null, null ,
                       null, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
       end if; 
    END IF;
end if ;

end usp_rh_cal_desct_sindicato ;
/
