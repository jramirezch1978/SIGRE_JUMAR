create or replace procedure usp_rh_cal_essalud_vida(
    asi_codtra          in maestro.cod_trabajador%TYPE,
    asi_origen          in origen.cod_origen%TYPE,
    ani_tipcam          in number,
    adi_fec_proceso     in date,
    asi_tip_trab        in maestro.tipo_trabajador%type,
    asi_tipo_planilla   in calculo.tipo_planilla%TYPE
) is

ld_fec_ini             date ;
ld_fec_hasta           date ;
ld_ini_per             date ;
ld_fin_per             date ;
ln_count               number ;
ln_imp_gan_desc        gan_desct_fijo.imp_gan_desc%type ;
ln_imp_gan_desc_dol    gan_desct_fijo.imp_gan_desc%type ;
ls_concepto            concepto.concep%type;

begin

select p.fec_inicio, p.fec_final
  into ld_fec_ini, ld_fec_hasta
  from rrhh_param_org p
 where p.origen           = asi_origen
   and p.tipo_trabajador  = asi_tip_trab
   AND trunc(p.fec_proceso) = trunc(adi_fec_proceso)
   and p.tipo_planilla      = asi_tipo_planilla;


select min(s.fecha_inicio) , max(s.fecha_fin)
  into ld_ini_per, ld_fin_per
  from semanas s
  where s.semana = ( select s.mes
                       from semanas s
                      where trunc(ld_fec_ini) between trunc(s.fecha_inicio) and trunc(s.fecha_fin))
                        and s.ano = ( select s.ano
                                        from semanas s
                                       where trunc(ld_fec_hasta) between trunc(s.fecha_inicio) and trunc(s.fecha_fin)) ;

select count(*)
  into ln_count
  from grupo_calculo gc
 where gc.grupo_calculo = ( select rhp.dscto_essalud_vida
                              from rrhhparam_cconcep rhp
                              where rhp.reckey = '1') ;

if ln_count > 0 then

   select gc.concepto_gen
     into ls_concepto
     from grupo_calculo gc
    where gc.grupo_calculo = ( select rhp.dscto_essalud_vida
                                from rrhhparam_cconcep rhp
                               where rhp.reckey = '1') ;

   select nvl(max(gdf.imp_gan_desc), 0)
     into ln_imp_gan_desc
     from gan_desct_fijo gdf
    where gdf.cod_trabajador = asi_codtra
      and gdf.concep         = ls_concepto;

   if ln_imp_gan_desc < 0  then return; end if;

   ln_imp_gan_desc_dol := ln_imp_gan_desc * ani_tipcam ;

   select count(*)
     into ln_count
     from historico_calculo hc
    where trim(hc.fec_calc_plan) between trim(ld_ini_per) and trim(ld_fin_per)
      and hc.cod_trabajador = asi_codtra
      and hc.concep         = ls_concepto;

   if ln_count > 0 then return; end if ;

   select count(*)
     into ln_count
     from calculo c
    where c.concep         = ls_concepto
      and c.cod_trabajador = asi_codtra
      and trunc(c.fec_proceso) = trim(adi_fec_proceso) 
      and c.tipo_planilla      = asi_tipo_planilla;

   if ln_count = 0 then
      insert into calculo (
             cod_trabajador, concep, fec_proceso, imp_soles,
             imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
      values (
             asi_codtra, ls_concepto, trunc(adi_fec_proceso), ln_imp_gan_desc,
             ln_imp_gan_desc_dol, asi_origen, '1', 1, asi_tipo_planilla ) ;
   end if ;

end if ;

end usp_rh_cal_essalud_vida ;
/
