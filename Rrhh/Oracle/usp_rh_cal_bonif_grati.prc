create or replace procedure usp_rh_cal_bonif_grati(
  asi_codtra       in maestro.cod_trabajador%TYPE,
  adi_fec_proceso  in date,
  asi_origen       in origen.cod_origen%TYPE,
  ani_tipcam       in number,
  asi_tipo_trab    in maestro.tipo_trabajador%TYPE
) is

  ls_grp_grati_julio     rrhhparam_cconcep.grati_medio_ano%TYPE;
  ls_grp_grati_fin       rrhhparam_cconcep.grati_fin_ano%TYPE;
  ls_grp_essalud         rrhhparam_cconcep.concep_essalud%TYPE;
  ls_cnc_grati_julio     concepto.concep%TYPE;
  ls_cnc_grati_fin       concepto.concep%TYPE;
  ls_cnc_essalud         concepto.concep%TYPE;
  ls_cnc_bonif_ext       asistparam.cnc_bonif_ext%TYPE;
  
  ln_factor_essalud      concepto.fact_pago%TYPE;
  
  ln_count               number;
  ln_imp_soles           calculo.imp_soles%TYPE;
  ln_imp_dolar           calculo.imp_dolar%TYPE;
  
  ls_tipo_jub            rrhhparam.tipo_trab_jubilado%TYPE;  
      
  
begin
 
  -- Si el Jubilado es pensionista no le corresponde el 9%
  select r.tipo_trab_jubilado
    into ls_tipo_jub 
    from rrhhparam r
   where r.reckey = '1';
   
  if asi_tipo_trab = ls_tipo_jub then
    return;
  end if;
  
  -- Si ya existe el concepto de bonif Extraord entonces simplemente no proceso esto
  select count(*)
    into ln_count
    from calculo c
   where c.cod_trabajador = asi_codtra
     and c.concep         = ls_cnc_bonif_ext;
  
  if ln_count > 0 then
     return;
  end if;
     
  select r.grati_medio_ano, r.grati_fin_ano, r.concep_essalud
    into ls_grp_grati_julio, ls_grp_grati_fin, ls_grp_essalud
    from rrhhparam_cconcep r
   where r.reckey = '1';  
  
  
  
  select gc.concepto_gen
    into ls_cnc_grati_julio
    from grupo_calculo gc
   where gc.grupo_calculo = ls_grp_grati_julio;
   
  select gc.concepto_gen
    into ls_cnc_grati_fin
    from grupo_calculo gc
   where gc.grupo_calculo = ls_grp_grati_fin;

  select gc.concepto_gen
    into ls_cnc_essalud
    from grupo_calculo gc
   where gc.grupo_calculo = ls_grp_essalud;

  select a.cnc_bonif_ext
    into ls_cnc_bonif_ext
    from asistparam a
   where a.reckey = '1';
  
  -- Obtengo el factor de calculo de ESSALUD
  select c.fact_pago
    into ln_factor_essalud
    from concepto c
   where c.concep = ls_cnc_essalud;
  
  -- sumo todos los importes de gratificacion que hayan
  select NVL(sum(c.imp_soles),0)
    into ln_imp_soles
    from calculo c
   where c.concep in (ls_cnc_grati_julio, ls_cnc_grati_fin)
     and c.cod_trabajador = asi_codtra
     and c.fec_proceso = adi_fec_proceso;
  
  -- ahora calculo el importe que corresponde a la patronal
  ln_imp_soles := ln_imp_soles * ln_factor_essalud;
  ln_imp_dolar := ln_imp_soles / ani_tipcam;
  
  -- Lo adiciono ala boleta
  UPDATE calculo
     SET imp_soles    = imp_soles + ln_imp_soles,
         imp_dolar    = imp_dolar + ln_imp_dolar
    WHERE cod_trabajador = asi_codtra
      AND concep         = ls_cnc_bonif_ext
      and fec_proceso    = adi_fec_proceso;

  IF SQL%NOTFOUND THEN
     insert into calculo (
            cod_trabajador, concep, fec_proceso, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
     values (
            asi_codtra, ls_cnc_bonif_ext, adi_fec_proceso, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;
  END IF;
  

end usp_rh_cal_bonif_grati;
/
