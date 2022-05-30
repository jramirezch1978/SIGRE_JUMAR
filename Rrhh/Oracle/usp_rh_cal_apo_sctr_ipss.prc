create or replace procedure usp_rh_cal_apo_sctr_ipss (
  asi_codtra         in maestro.cod_trabajador%TYPE,
  adi_fec_proceso    in date,
  ani_tipcam         in number,
  asi_origen         in origen.cod_origen%TYPE,
  asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) is

lk_sctr_ipss        grupo_calculo.grupo_calculo%TYPE;
ln_count            number ;
ls_concepto         concepto.concep%TYPE ;
ln_porcentaje       concepto.fact_pago%TYPE ;
ln_imp_soles        calculo.imp_soles%TYPE;
ln_imp_dolar        calculo.imp_soles%TYPE;

begin

  --  *******************************************************************
  --  ***   CALCULA APORTACIONES DEL SEGURO COMPLEMENTARIO I.P.S.S.   ***
  --  *******************************************************************

  select c.concep_sctr_ipss
    into lk_sctr_ipss
    from rrhhparam_cconcep c
   where c.reckey = '1' ;

  select count(*)
    into ln_count
    from grupo_calculo g
   where g.grupo_calculo = lk_sctr_ipss ;

  if ln_count > 0 then

    select g.concepto_gen
      into ls_concepto
      from grupo_calculo g
     where g.grupo_calculo = lk_sctr_ipss ;

    select count(*)
      into ln_count
      from gan_desct_fijo gdf
     where gdf.cod_trabajador = asi_codtra 
       and gdf.concep         = ls_concepto;

    select nvl(c.fact_pago,0)
      into ln_porcentaje
      from concepto c
      where c.concep = ls_concepto ;

    if ln_porcentaje > 0 and ln_count > 0 then
       select NVL(sum(nvl(c.imp_soles,0)),0)
         into ln_imp_soles
         from calculo c
         where c.cod_trabajador = asi_codtra
           and c.tipo_planilla  = asi_tipo_planilla
           and c.concep in ( select d.concepto_calc
                               from grupo_calculo_det d
                              where d.grupo_calculo = lk_sctr_ipss ) ;

       ln_imp_soles := ln_imp_soles * ln_porcentaje ;
       ln_imp_dolar := ln_imp_soles / ani_tipcam ;
       
       insert into calculo (
              cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
              dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
              tipo_planilla )
       values (
              asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
              0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
              asi_tipo_planilla ) ;
    end if ;

  end if ;

end usp_rh_cal_apo_sctr_ipss ;
/
