create or replace procedure usp_rh_cal_sobretiempo_turno (
  as_codtra      in char, as_codusr           in char, ad_fec_proceso in date,
  as_origen      in char, as_flag_sobretiempo in char, an_tipcam      in number,
  as_sobretiempo in char, as_guardias         in char, ac_tipo_trab   in maestro.tipo_trabajador%type) is

lk_ganancias_fijas     char(3);

ld_fec_desde           date ;
ld_fec_hasta           date ;
ln_imp_total           number(13,2) ;
ln_imp_soles           number(13,2) ;
ln_imp_dolar           number(13,2) ;
ln_contador            integer ;

--  Cursor que determina conceptos de sobretiempos
cursor c_sobretiempo_turno is
  select st.horas_sobret, st.concep, c.fact_pago, c.imp_tope_min, c.nro_horas
  from sobretiempo_turno st, concepto c
  where st.concep = c.concep and st.cod_trabajador = as_codtra and
        ( substr(st.concep,1,2) = as_sobretiempo or substr(st.concep,1,2) = as_guardias ) and
        trunc(st.fec_movim) between ld_fec_desde and ld_fec_hasta
  order by st.cod_trabajador, st.concep ;

begin

--  *****************************************************
--  ***   REALIZA CALCULOS DE SOBRETIEMPOS Y TURNOS   ***
--  *****************************************************

select c.gan_fij_sobretiempo into lk_ganancias_fijas
   from rrhhparam_cconcep c where c.reckey = '1';

if as_flag_sobretiempo <> '1' then

   select p.fec_inicio, p.fec_final into ld_fec_desde, ld_fec_hasta
     from rrhh_param_org p 
    where (p.origen          = as_origen    ) and
          (p.tipo_trabajador = ac_tipo_trab ) AND
          trunc(p.fec_proceso ) = ad_fec_proceso;

--   select p.fec_desde, p.fec_hasta into ld_fec_desde, ld_fec_hasta
--      from rrhhparam p where p.reckey = '1' ;

   select sum(nvl(gdf.imp_gan_desc,0)) into ln_imp_total
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
          gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
          where d.grupo_calculo = lk_ganancias_fijas ) ;

   ln_imp_total := nvl(ln_imp_total,0) ;

   for rc_st in c_sobretiempo_turno loop

      if substr(rc_st.concep,1,2) = as_sobretiempo then
         if nvl(rc_st.imp_tope_min,0) > 0 then
            ln_imp_soles := nvl(rc_st.imp_tope_min,0) / nvl(rc_st.nro_horas,0) *
                            nvl(rc_st.horas_sobret,0) * nvl(rc_st.fact_pago,0) ;
         else
            ln_imp_soles := ln_imp_total / nvl(rc_st.nro_horas,0) *
                            nvl(rc_st.horas_sobret,0) * nvl(rc_st.fact_pago,0) ;
         end if ;

      else
         ln_imp_soles := nvl(rc_st.horas_sobret,0) * nvl(rc_st.fact_pago,0) ;
      end if ;

      ln_imp_dolar := ln_imp_soles / an_tipcam ;

      ln_contador := 0 ;

      select count(*) into ln_contador from calculo c
         where c.cod_trabajador = as_codtra
            and c.concep = rc_st.concep ;

      if ln_contador > 0 then
         update calculo
            set horas_trabaj     = horas_trabaj + nvl(rc_st.horas_sobret,0) ,
                horas_pag        = horas_pag + nvl(rc_st.horas_sobret,0) ,
                imp_soles        = imp_soles + ln_imp_soles ,
                imp_dolar        = imp_dolar + ln_imp_dolar,
                flag_replicacion = '1'
            where cod_trabajador = as_codtra and concep = rc_st.concep ;
      else
         insert into calculo (
               cod_trabajador, concep, fec_proceso, horas_trabaj,
               horas_pag, dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
            values (
               as_codtra, rc_st.concep, ad_fec_proceso, rc_st.horas_sobret,
               rc_st.horas_sobret, 0, ln_imp_soles, ln_imp_dolar,  as_origen, '1', 1 ) ;
      end if ;

  end loop ;

end if ;

end usp_rh_cal_sobretiempo_turno ;
/
