create or replace procedure usp_rh_cal_enfermedad (
       asi_codtra        in maestro.cod_trabajador%TYPE, 
       asi_tipo_trabaj   in maestro.tipo_trabajador%TYPE,
       adi_fec_proceso   in date, 
       asi_origen        in origen.cod_origen%TYPE,
       an_tipcam         in number,
       asi_tipo_planilla in calculo.tipo_planilla%TYPE 
) is

ls_grp_permiso20        rrhhparam_cconcep.enferm_patron_pirm20%TYPE;
ls_grp_subsidio         rrhhparam_cconcep.subsidio_enfermedad%TYPE;

ln_count                integer ;
ls_cnc_enfermedad       concepto.concep%TYPE;
ls_cnc_subsidio         concepto.concep%TYPE;
ln_dias                 number(5,2) ;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_dolar%TYPE;
ln_jornal               calculo.imp_soles%TYPE;

-- Para Jornaleros
ls_cnc_dominical        asistparam.cnc_dominical%TYPE;
ls_cnc_gratif_ext       asistparam.cnc_gratif_ext%TYPE;
ls_cnc_bon_gratif       asistparam.cnc_bonif_ext%TYPE;
ln_porc_gratif          asistparam.porc_gratif_campo%TYPE;
ln_porc_bonif           asistparam.porc_bonif_ext%TYPE;
ln_imp_gratif           calculo.imp_soles%TYPE := 0;
ln_acum_gratif          calculo.imp_soles%TYPE := 0;
ls_flag_tipo_sueldo     tipo_trabajador.flag_ingreso_boleta%TYPE;
ls_concepto             concepto.concep%TYPE;

begin

  --  **************************************************
  --  ***   REALIZA CALCULO POR DIAS DE ENFERMEDAD   ***
  --  **************************************************

  select c.enferm_patron_pirm20, c.subsidio_enfermedad
    into ls_grp_permiso20, ls_grp_subsidio
    from rrhhparam_cconcep c 
    where c.reckey = '1' ;

  SELECT a.cnc_dominical, a.cnc_gratif_ext, a.cnc_bonif_ext, a.porc_gratif_campo, a.porc_bonif_ext
    INTO ls_cnc_dominical, ls_cnc_gratif_ext, ls_cnc_bon_gratif, ln_porc_gratif, ln_porc_bonif
    FROM asistparam a
   WHERE a.reckey = '1';
   
  -- Obtengo el plag de pago de boleta si es jornal o sueldo
  select t.flag_ingreso_boleta
    into ls_flag_tipo_sueldo
    from tipo_trabajador t
   where t.tipo_trabajador = asi_tipo_trabaj;

  select count(*) 
    into ln_count 
    from grupo_calculo g
    where g.grupo_calculo = ls_grp_permiso20 ;

  if ln_count > 0 then

    select g.concepto_gen 
      into ls_cnc_enfermedad 
      from grupo_calculo g
      where g.grupo_calculo = ls_grp_permiso20;

    select count(*) 
      into ln_count 
      from inasistencia i
      where i.cod_trabajador = asi_codtra  
        and i.concep = ls_cnc_enfermedad 
        AND trunc(i.fec_movim) = trunc(adi_fec_proceso);

    if ln_count > 0 then

      select sum(nvl(i.dias_inasist,0)) 
        into ln_dias 
        from inasistencia i
        where i.cod_trabajador = asi_codtra 
          and i.concep = ls_cnc_enfermedad
          AND trunc(i.fec_movim) = trunc(adi_fec_proceso) ;

      select nvl(sum(nvl(gdf.imp_gan_desc,0)) ,0)
        into ln_imp_soles 
        from gan_desct_fijo gdf
        where gdf.cod_trabajador = asi_codtra 
          and gdf.flag_estado = '1' 
          and gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                              where d.grupo_calculo = ls_grp_permiso20 ) ;
      
      ln_jornal := (ln_imp_soles / 30) * ln_dias ;
      
      ln_imp_soles := ln_jornal;
      
      if ls_flag_tipo_sueldo = 'J' then
         -- Le calculo la gratificacion
         ln_imp_gratif := ln_imp_soles * ln_porc_gratif/100;
               
         -- Le quito la gratificacion
         ln_imp_soles := ln_imp_soles - ln_imp_gratif;
      end if;
      
      ln_imp_dolar := ln_imp_soles / an_tipcam ;
      
      UPDATE calculo
       SET horas_trabaj = null,
           horas_pag    = null,
           dias_trabaj  = dias_trabaj + 1,
           imp_soles    = imp_soles + ln_imp_soles,
           imp_dolar    = imp_dolar + ln_imp_dolar
      WHERE cod_trabajador = asi_codtra
        AND concep         = ls_cnc_enfermedad
        and tipo_planilla  = asi_tipo_planilla;

      if SQL%NOTFOUND then
          insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, 
                    item, tipo_planilla )
          values (
                    asi_codtra, ls_cnc_enfermedad, adi_fec_proceso, 0, 0,
                    ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                    asi_tipo_planilla ) ;
      end if;

      if ls_flag_tipo_sueldo = 'J' then
          -- Inserto el correspondiente al domincal
          ln_imp_soles := ln_jornal / 6;
          
          ln_imp_dolar := ln_imp_soles / an_tipcam ;
          ls_concepto  := ls_cnc_dominical ;

          UPDATE calculo c
             SET horas_trabaj = null,
                 horas_pag    = null,
                 c.dias_trabaj = c.dias_trabaj + ln_dias,
                 imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar
            WHERE cod_trabajador = asi_codtra
              AND concep         = ls_concepto
              and tipo_planilla  = asi_tipo_planilla;

          IF SQL%NOTFOUND THEN
             insert into calculo (
                    cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                    dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                    tipo_planilla )
             values (
                    asi_codtra, ls_concepto, adi_fec_proceso, null, null,
                    1, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                    asi_tipo_planilla ) ;

          END IF;

      end if;

    end if ;

  end if;
    
  -- Ahora viene el subsidio
  select count(*) 
    into ln_count 
    from grupo_calculo g
    where g.grupo_calculo = ls_grp_subsidio ;

  if ln_count > 0 then

    select g.concepto_gen 
      into ls_cnc_subsidio 
      from grupo_calculo g
      where g.grupo_calculo = ls_grp_subsidio;

    select count(*) 
      into ln_count 
      from inasistencia i
      where i.cod_trabajador = asi_codtra  
        and i.concep = ls_cnc_subsidio 
        AND trunc(i.fec_movim) = trunc(adi_fec_proceso);

    if ln_count > 0 then

      select sum(nvl(i.dias_inasist,0)) 
        into ln_dias 
        from inasistencia i
        where i.cod_trabajador = asi_codtra 
          and i.concep = ls_cnc_subsidio 
          AND trunc(i.fec_movim) = trunc(adi_fec_proceso);

      select nvl(sum(nvl(gdf.imp_gan_desc,0)),0)
        into ln_imp_soles 
        from gan_desct_fijo gdf
        where gdf.cod_trabajador = asi_codtra 
          and gdf.flag_estado = '1' 
          and gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
                              where d.grupo_calculo = ls_grp_subsidio ) ;

      ln_imp_soles := (ln_imp_soles / 30) * ln_dias ;
      ln_imp_dolar := ln_imp_soles / an_tipcam ;

      insert into calculo (
        cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
        dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
        tipo_planilla )
      values (
        asi_codtra, ls_cnc_subsidio, adi_fec_proceso, 0, 0,
        ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, 
        asi_tipo_planilla ) ;

    end if ;  
  end if;

end usp_rh_cal_enfermedad ;
/
