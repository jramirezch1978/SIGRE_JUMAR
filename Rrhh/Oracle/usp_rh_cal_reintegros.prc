create or replace procedure usp_rh_cal_reintegros (
    asi_codtra           in maestro.cod_trabajador%TYPE,
    adi_fec_proceso      in date,
    asi_origen           in origen.cod_origen%TYPE,
    ani_tipcam           in number ,
    asi_tip_trab         in maestro.tipo_trabajador%type,
    asi_tipo_planilla    in calculo.tipo_planilla%TYPE
) is

lk_ganancias_fijas      char(3) ;
lk_reintegros           char(3) ;
lk_reintegros_por       char(3) ;

ld_fec_desde            date ;
ld_fec_hasta            date ;
ln_contador             integer ;
ln_dias_reintegro       number(5,2) ;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_soles%TYPE;
ln_imp_acumu            calculo.imp_soles%TYPE;
ls_concepto             concepto.concep%TYPE;

--  Lectura de conceptos de reintegros
cursor c_reintegros is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = lk_reintegros ;

begin

--  ******************************************
--  ***   REALIZA CALCULOS DE REINTEGROS   ***
--  ******************************************

select c.gan_fij_reintegro, c.concep_calc_reintegro, c.reintegro_2530_por_dia
  into lk_ganancias_fijas, lk_reintegros, lk_reintegros_por
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select p.fec_inicio, p.fec_final 
  into ld_fec_desde, ld_fec_hasta
  from rrhh_param_org p
 where p.origen          = asi_origen   
   and p.tipo_trabajador = asi_tip_trab 
   AND trunc(p.fec_proceso) = trunc(adi_fec_proceso)
   and p.tipo_planilla      = asi_tipo_planilla;


ln_imp_acumu := 0 ;
for rc_rei in c_reintegros loop

  ls_concepto := rc_rei.concepto_calc ;
  ln_contador := 0 ;
  select count(*) 
    into ln_contador 
    from inasistencia i
    where i.cod_trabajador = asi_codtra
      and i.concep = ls_concepto
      AND trunc(i.fec_movim) between ld_fec_desde and ld_fec_hasta ;

  if ln_contador > 0 then

    select sum(nvl(i.dias_inasist,0)) 
      into ln_dias_reintegro 
      from inasistencia i
      where i.cod_trabajador = asi_codtra
        and i.concep = ls_concepto
        AND trunc(i.fec_movim) between ld_fec_desde and ld_fec_hasta ;

    select sum(nvl(gdf.imp_gan_desc,0)) 
      into ln_imp_soles 
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = asi_codtra
        and gdf.flag_estado = '1'
        AND gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                            where d.grupo_calculo = lk_ganancias_fijas ) ;

    ln_imp_acumu := ln_imp_acumu + ln_imp_soles ;
    ln_imp_soles := (ln_imp_soles / 30) * ln_dias_reintegro ;
    ln_imp_dolar := ln_imp_soles / ani_tipcam ;

    insert into calculo (
      cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
      dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
    values (
      asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
      ln_dias_reintegro, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;

  end if ;

end loop ;

if nvl(ln_imp_soles,0) <> 0 then
  ln_imp_dolar := ln_imp_soles / ani_tipcam ;
  select g.concepto_gen 
    into ls_concepto 
    from grupo_calculo g
    where g.grupo_calculo = lk_reintegros_por ;
    
  insert into calculo (
    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
  values (
    asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
    ln_dias_reintegro, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
end if ;

end usp_rh_cal_reintegros ;
/
