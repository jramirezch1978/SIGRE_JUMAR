create or replace procedure usp_rh_cal_maternidad (
       asi_codtra      in maestro.cod_trabajador%TYPE, 
       asi_tipo_trabaj in tipo_trabajador.tipo_trabajador%TYPE,
       adi_fec_proceso in date, 
       asi_origen      in origen.cod_origen%TYPE,
       ani_tipcam      in number 
) is

ls_grp_maternidad      rrhhparam_cconcep.maternidad%TYPE ;

ln_count                integer ;
ln_contador             integer ;
ls_concepto             concepto.concep%TYPE;
ln_dias                 calculo.dias_trabaj%TYPE;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_dolar%TYPE;

ls_tipo_des             rrhhparam.tipo_trab_destajo%TYPE;
ln_year1                number;
ln_year2                number;
ln_mes1                 number;
ln_mes2                 number;

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

   ln_contador := 0 ; 
   select count(*) 
     into ln_contador 
     from inasistencia i
    where i.cod_trabajador = asi_codtra 
      and i.fec_movim      = adi_fec_proceso
      and i.concep         = ls_concepto ;

  if ln_contador > 0 then

    select sum(nvl(i.dias_inasist,0)) 
      into ln_dias 
      from inasistencia i
     where i.cod_trabajador = asi_codtra 
       and i.fec_movim      = adi_fec_proceso
       and i.concep         = ls_concepto ;
    
    if asi_tipo_trabaj <> ls_tipo_des then
       -- Si es jornalero le calculo en base a lo que gana como jornal fijo 
       select NVL(sum(nvl(gdf.imp_gan_desc,0)),0) 
         into ln_imp_soles 
         from gan_desct_fijo gdf
        where gdf.cod_trabajador = asi_codtra 
          and gdf.flag_estado    = '1' 
          and gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                              where d.grupo_calculo = ls_grp_maternidad ) ;

       ln_imp_soles := (ln_imp_soles / 30) * ln_dias ;
    else
       -- Calculo en base a los ulitmos 6 meses que ha ganado
       ln_year1 := to_number(to_char(adi_fec_proceso, 'yyyy'));
       ln_mes1  := to_number(to_char(adi_fec_proceso, 'mm'));
       
       ln_mes1 := ln_mes1 - 1;
       
       if ln_mes1 <= 0 then
          ln_mes1 := 12;
          ln_year1 := ln_year1 - 1;
       end if;
       
       ln_mes2 := ln_mes1 - 6;
       ln_year2 := ln_year1;
       
       if ln_mes2 <= 0 then
          ln_mes2 := 12 + ln_mes2;
          ln_year2 := ln_year2 - 1;
       end if;

       select NVL(sum(nvl(hc.imp_soles,0)),0)
         into ln_imp_soles
         from historico_calculo hc
        where hc.cod_trabajador = asi_codtra
          and to_char(hc.fec_calc_plan, 'yyyymm') between trim(to_char(ln_year2, '0000')) || trim(to_char(ln_mes2, '00')) and trim(to_char(ln_year1, '0000')) || trim(to_char(ln_mes1, '00'))
          and hc.concep in ( select d.concepto_calc from grupo_calculo_det d
                                where d.grupo_calculo = ls_grp_maternidad ) ;
                                
       ln_imp_soles := (ln_imp_soles / 180) * ln_dias ;
    end if;
    
    ln_imp_dolar := ln_imp_soles / ani_tipcam ;

    insert into calculo (
      cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
      dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
    values (
      asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
      ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;

  end if ;

end if ;

end usp_rh_cal_maternidad ;
/
