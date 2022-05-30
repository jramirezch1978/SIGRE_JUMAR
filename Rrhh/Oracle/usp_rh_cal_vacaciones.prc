create or replace procedure usp_rh_cal_vacaciones (
       asi_codtra       in maestro.cod_trabajador%TYPE,
       adi_fec_proceso  in date,
       asi_origen       in origen.cod_origen%TYPE,
       ani_tipcam       in number,
       ani_dia_mes      in number
) is

ls_grp_vacaciones      rrhhparam_cconcep.gan_fij_calc_vacac%TYPE;

ln_count                integer ;
ls_cnc_vacaciones       concepto.concep%TYPE;
ln_dias_vacaciones      inasistencia.dias_inasist%TYPE;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_hra_ext          calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_dolar%TYPE;
ls_flag_ingr_boleta     tipo_trabajador.flag_ingreso_boleta%TYPE;
ln_porc_gratif          asistparam.porc_gratif_campo%TYPE;
ln_porc_bonif_ext       asistparam.porc_bonif_ext%TYPE;
ld_fec_desde            date;
ld_fec_hasta            date;

ls_cnc_gratif_ext       asistparam.cnc_gratif_ext%TYPE;
ls_cnc_bon_gratif       asistparam.cnc_bonif_ext%TYPE;
ls_sector_agrario       tipo_trabajador.tipo_trabajador%TYPE;
ls_tipo_trabajador      tipo_trabajador.tipo_trabajador%TYPE;
ls_grp_vacac_variable   grupo_calculo.grupo_calculo%TYPE := '806';

ln_year2                number;
ln_year1                number;
ln_mes2                 number;
ln_mes1                 number;

ld_fec_proceso          date;
lbo_flag                boolean := false;
ln_meses                number;


begin


--  *****************************************************
--  ***   REALIZA CALCULO DE VACACIONES DEL PERIODO   ***
--  *****************************************************
  -- Obtengo el rango de fechas
  select r.fec_inicio, r.fec_final, m.tipo_trabajador
    into ld_fec_desde, ld_fec_hasta, ls_tipo_trabajador
    from rrhh_param_org r,
         maestro        m
   where r.tipo_trabajador = m.tipo_trabajador
     and r.origen = asi_origen
     and r.fec_proceso = adi_fec_proceso
     and m.cod_trabajador = asi_codtra;

  -- Obtengo el tipo de ingreso
  select tt.flag_ingreso_boleta, tt.flag_sector_agrario
    into ls_flag_ingr_boleta, ls_sector_agrario
    from tipo_trabajador tt,
         maestro         m
   where m.tipo_trabajador = tt.tipo_trabajador
     and m.cod_trabajador  = asi_codtra;

  -- Obtengo el porcentaje de la gratificacion
  select porc_gratif_campo, a.cnc_gratif_ext, a.cnc_bonif_ext, a.porc_bonif_ext
    into ln_porc_gratif, ls_cnc_gratif_ext, ls_cnc_bon_gratif, ln_porc_bonif_ext
    from asistparam a
   where a.reckey = '1';

  select c.gan_fij_calc_vacac
    into ls_grp_vacaciones
    from rrhhparam_cconcep c
   where c.reckey = '1' ;

  select count(*)
    into ln_count
    from grupo_calculo g
   where g.grupo_calculo = ls_grp_vacaciones ;

  if ln_count = 0 then return; end if;

  select g.concepto_gen
    into ls_cnc_vacaciones
    from grupo_calculo g
   where g.grupo_calculo = ls_grp_vacaciones;

  select count(*)
    into ln_count
    from inasistencia i
   where i.cod_trabajador = asi_codtra
     and i.concep         = ls_cnc_vacaciones
     AND trunc(i.fec_movim) between ld_fec_desde and ld_fec_hasta;

  -- Si no hay datos en inasistencia entonces no proceso nada
  if ln_count = 0 then return; end if;

  select sum(nvl(i.dias_inasist,0)), nvl(sum(i.importe),0)
    into ln_dias_vacaciones, ln_imp_soles
    from inasistencia i
   where i.cod_trabajador   = asi_codtra
     and i.concep           = ls_cnc_vacaciones
     AND trunc(i.fec_movim) between ld_fec_desde and ld_fec_hasta;
  
  -- Si la inasistencia ya tiene importe, entondes tomo directamente el importe y nada mas
  if ln_imp_soles = 0 then
      SELECT nvl(sum(DECODE(nvl(gdf.imp_gan_desc,0),0,nvl(gdf.porcentaje,0)*(select r.rmv from rmv_x_tipo_trabaj r where r.tipo_trabajador = ls_tipo_trabajador)/100,gdf.imp_gan_desc)),0)
        into ln_imp_soles
        from gan_desct_fijo gdf
       where gdf.cod_trabajador = asi_codtra
         and gdf.flag_estado = '1'
         AND gdf.concep in ( select d.concepto_calc
                               from grupo_calculo_det d
                              where d.grupo_calculo = ls_grp_vacaciones ) ;

      ln_imp_soles := (ln_imp_soles / ani_dia_mes) * ln_dias_vacaciones ;

      --Calculo promedio de Horas Extras
      ln_year2 := to_number(to_char(adi_fec_proceso, 'yyyy'));
      ln_mes2  := to_number(to_char(adi_fec_proceso, 'mm')) - 1;
      
      if ln_mes2 = 0 then
         ln_mes2 := 12; 
         ln_year2 := ln_year2 - 1;
      end if;
      
      -- 6 meses anteriores
      ln_mes1 := ln_mes2 - 5;
      ln_year1 := ln_year2;
      
      if ln_mes1 <= 0 then
         ln_mes1 := 12 + ln_mes1;
         ln_year1 := ln_year1 - 1;
      end if;
      
      -- Vamos a validar que haya recibido a mas de tres meses
      select min(hc.fec_calc_plan)
        into ld_fec_proceso
       from historico_calculo hc,
            grupo_calculo_det gcd
      where hc.concep         = gcd.concepto_calc
        and hc.cod_trabajador = asi_codtra
        and gcd.grupo_calculo = ls_grp_vacac_variable
        and to_char(hc.fec_calc_plan, 'yyyymm') between trim(to_char(ln_year1, '0000')) || trim(to_char(ln_mes1, '00')) and trim(to_char(ln_year2, '0000')) || trim(to_char(ln_mes2, '00'));
      
      if ld_fec_proceso is null then
         lbo_flag := false;
      else
         if to_number(to_char(ld_fec_proceso, 'yyyy')) = ln_year2 then
            ln_meses := ln_mes2 - to_number(to_char(ld_fec_proceso, 'mm')) + 1;
         else
            ln_meses := 12 - to_number(to_char(ld_fec_proceso, 'mm')) + 1 + ln_mes2;
         end if;
         
         if ln_meses < 3 then
            lbo_flag := false;
         else
            lbo_flag := true;
         end if;
      end if;
            
      if lbo_flag then
          select NVL(sum(hc.imp_soles),0)
            into ln_imp_hra_ext
           from historico_calculo hc,
                grupo_calculo_det gcd
          where hc.concep         = gcd.concepto_calc
            and hc.cod_trabajador = asi_codtra
            and gcd.grupo_calculo = ls_grp_vacac_variable
            and to_char(hc.fec_calc_plan, 'yyyymm') between trim(to_char(ln_year1, '0000')) || trim(to_char(ln_mes1, '00')) and trim(to_char(ln_year2, '0000')) || trim(to_char(ln_mes2, '00'));
      else
         ln_imp_hra_ext := 0;
      end if;
      
      ln_imp_soles := ln_imp_soles + ln_imp_hra_ext / 180 * ln_dias_vacaciones;
  end if;
  
  -- Calculo el importe en dolares y luego ya lo inserto en la tabla calculo
  ln_imp_dolar := ln_imp_soles / ani_tipcam ;

  insert into calculo (
         cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
         dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item)
  values (
         asi_codtra, ls_cnc_vacaciones, adi_fec_proceso, 0, 0,
         ln_dias_vacaciones, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;

end usp_rh_cal_vacaciones ;
/
