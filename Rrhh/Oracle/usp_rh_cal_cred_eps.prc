create or replace procedure usp_rh_cal_cred_eps(
       asi_codtra            in maestro.cod_trabajador%TYPE, 
       adi_fec_proceso       in date, 
       ani_tipcam            in number,
       asi_origen            in origen.cod_origen%TYPE,
       asi_tipo_planilla     in calculo.tipo_planilla%TYPE 
) is

ls_cnc_cred_eps         rrhhparam_cconcep.cnc_cred_eps%TYPE;
ls_grc_essalud          grupo_calculo.grupo_calculo%TYPE;

ln_imp_soles            number(13,2) ;
ln_imp_dolar            number(13,2) ;

--  Cursor de conceptos por descuentos fijos
cursor c_cred_eps is
  select gdf.concep, gdf.imp_gan_desc, c.fact_pago
  from gan_desct_fijo gdf,
       concepto        c
  where gdf.concep         = c.concep
    and gdf.concep         = ls_cnc_cred_eps
    and gdf.cod_trabajador = asi_codtra 
    and gdf.flag_estado    = '1' ;
begin

--  ***************************************************************
--  ***   ADICIONA DESCUENTOS FIJOS POR TRABAJADOR AL CALCULO   ***
--  ***************************************************************

select c.cnc_cred_eps, c.concep_essalud
  into ls_cnc_cred_eps, ls_grc_essalud
  from rrhhparam_cconcep c 
 where c.reckey = '1' ;

for rc_des in c_cred_eps loop
    
    select nvl(sum(NVL(c.imp_soles,0)), 0)
      into ln_imp_soles
      from calculo c,
           grupo_calculo_det gcd
     where gcd.concepto_calc = c.concep
       and c.cod_trabajador  = asi_codtra
       and gcd.grupo_calculo = ls_grc_essalud
       and to_char(c.fec_proceso, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm')
       and c.tipo_planilla        = asi_tipo_planilla;

    ln_imp_soles := ln_imp_soles * rc_des.fact_pago;
    ln_imp_dolar := ln_imp_soles / ani_tipcam ;
    
    UPDATE calculo c
         SET horas_trabaj = null,
             horas_pag    = null,
									--		 imp_soles    = imp_soles + ln_imp_soles,
									--		 imp_dolar    = imp_dolar + ln_imp_dolar
						imp_soles    =  ln_imp_soles,
						imp_dolar    =  ln_imp_dolar
        WHERE cod_trabajador = asi_codtra
          AND concep         = ls_cnc_cred_eps
          and tipo_planilla  = asi_tipo_planilla;
    
    if SQL%NOTFOUND then
        insert into calculo (
          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, 
          item, tipo_planilla )
        values (
          asi_codtra, ls_cnc_cred_eps, adi_fec_proceso, 0, 0,
          0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
          asi_tipo_planilla ) ;
     end if;
      

end loop ;

end usp_rh_cal_cred_eps ;
/
