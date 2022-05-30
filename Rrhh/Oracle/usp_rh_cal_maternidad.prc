create or replace procedure usp_rh_cal_maternidad (
  asi_codtra         in maestro.cod_trabajador%TYPE, 
  adi_fec_proceso    in date, 
  asi_origen         in origen.cod_origen%TYPE,
  ani_tipcam         in number,
  asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) is

ls_grp_maternidad       rrhhparam_cconcep.maternidad%TYPE ;

ln_count                integer ;
ls_concepto             calculo.concep%TYPE;
ln_dias                 calculo.dias_trabaj%TYPE ;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_dolar%TYPE ;

begin

--  **************************************************
--  ***   REALIZA CALCULO POR DIAS DE MATERNIDAD   ***
--  **************************************************

select c.maternidad 
  into ls_grp_maternidad
  from rrhhparam_cconcep c 
 where c.reckey = '1' ;

select count(*) 
  into ln_count 
  from grupo_calculo g
 where g.grupo_calculo = ls_grp_maternidad ;

if ln_count > 0 then

  select g.concepto_gen 
    into ls_concepto 
    from grupo_calculo g
   where g.grupo_calculo = ls_grp_maternidad ;

  select nvl(sum(i.dias_inasist),0)
    into ln_dias 
    from inasistencia i
   where i.cod_trabajador = asi_codtra 
     and i.concep         = ls_concepto 
     AND trunc(i.fec_movim) = trunc(adi_fec_proceso);
  
  if ln_dias > 0 then
     select sum(nvl(gdf.imp_gan_desc,0)) 
       into ln_imp_soles 
       from gan_desct_fijo gdf
      where gdf.cod_trabajador = asi_codtra 
        and gdf.flag_estado    = '1' 
        and gdf.concep in ( select d.concepto_calc 
                              from grupo_calculo_det d
                             where d.grupo_calculo = ls_grp_maternidad ) ;

     ln_imp_soles := ln_imp_soles / 30 * ln_dias ;
     ln_imp_dolar := ln_imp_soles / ani_tipcam ;

     insert into calculo (
          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
          tipo_planilla )
     values (
          asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
          ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
          asi_tipo_planilla ) ;

  end if ;

end if ;

end usp_rh_cal_maternidad ;
/
