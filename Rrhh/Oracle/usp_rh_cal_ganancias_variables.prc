create or replace procedure usp_rh_cal_ganancias_variables(
       asi_codtra            in maestro.cod_trabajador%TYPE, 
       adi_fec_proceso       in date, 
       asi_origen            in origen.cod_origen%TYPE,
       ani_tipcam            in number ,
       asi_tip_trab          in maestro.tipo_trabajador%type,
       asi_tipo_planilla     in calculo.tipo_planilla%TYPE 
) is

ld_fec_desde         date ;
ld_fec_hasta         date ;
ln_imp_soles         calculo.imp_soles%TYPE ;
ln_imp_dolar         calculo.imp_dolar%TYPE ;
ln_imp_rem_basica    gan_desct_fijo.imp_gan_desc%TYPE;

--  Lectura de ganancias y descuentos variables
cursor c_variables is
  select gdv.concep, gdv.imp_var, gdv.nro_horas, gdv.nro_dias, c.fact_pago
  from gan_desct_variable gdv,
       concepto           c
  where gdv.concep = c.concep
    and gdv.cod_trabajador = asi_codtra 
    and substr(gdv.concep,1,1) = '1' 
    and trunc(gdv.fec_movim) between ld_fec_desde and ld_fec_hasta ;

begin

--  *****************************************************
--  ***   ADICIONA CONCEPTOS DE GANANCIAS VARIABLES   ***
--  *****************************************************

select p.fec_inicio, p.fec_final 
  into ld_fec_desde, ld_fec_hasta
  from rrhh_param_org p
 where p.origen          = asi_origen   
   and p.tipo_trabajador = asi_tip_trab 
   AND trunc(p.fec_proceso) = trunc(adi_fec_proceso)
   and p.tipo_planilla      = asi_tipo_planilla;


-- Calculo el importe de la remuneracion basica
select sum(gdf.imp_gan_desc)
  into ln_imp_rem_basica
  from gan_desct_fijo gdf
 where gdf.cod_trabajador = asi_codtra
   and gdf.concep         IN (SELECT D.CONCEPTO_CALC
                                FROM GRUPO_CALCULO_DET D
                               WHERE D.GRUPO_CALCULO = ('010'))
   and gdf.flag_estado = '1';

--select p.fec_desde, p.fec_hasta into ld_fec_desde, ld_fec_hasta
-- from rrhhparam p where p.reckey = '1' ;

for rc_gv in c_variables loop
    
    if rc_gv.imp_var > 0 then
       ln_imp_soles := nvl(rc_gv.imp_var,0) ;
    elsif rc_gv.nro_horas > 0 then
       ln_imp_soles := ln_imp_rem_basica / 240 * rc_gv.nro_horas * rc_gv.fact_pago ;
    else
       ln_imp_soles := ln_imp_rem_basica / 30 * rc_gv.nro_dias * rc_gv.fact_pago;
    end if;
    
    ln_imp_soles := NVL(ln_imp_soles, 0);
    ln_imp_dolar := ln_imp_soles / ani_tipcam ;
    
     update calculo c
       set imp_soles        = imp_soles + ln_imp_soles ,
           imp_dolar        = imp_dolar + ln_imp_dolar,
           c.dias_trabaj    = nvl(c.dias_trabaj,0) + rc_gv.nro_dias,
           c.horas_pag      = nvl(c.horas_pag, 0) + rc_gv.nro_horas,
           c.horas_trabaj   = nvl(c.horas_trabaj, 0) + rc_gv.nro_horas,
           flag_replicacion = '1'
     where cod_trabajador = asi_codtra 
       and concep         = rc_gv.concep 
       and tipo_planilla  = asi_tipo_planilla;
    
    if SQL%NOTFOUND then
       insert into calculo (
              cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
              dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
              tipo_planilla )
       values (
              asi_codtra, rc_gv.concep, adi_fec_proceso, rc_gv.nro_horas, rc_gv.nro_horas,
              rc_gv.nro_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
              asi_tipo_planilla ) ;
    end if;

end loop ;

end usp_rh_cal_ganancias_variables ;
/
