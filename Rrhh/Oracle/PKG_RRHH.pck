create or replace package PKG_RRHH is

  -- Author  : JRAMIREZ
  -- Created : 21/02/2016 07:06:15 p.m.
  -- Purpose : 
  
  -- Public type declarations
  is_cnc_vacaciones       concepto.concep%TYPE   := '1463';
  in_periodo_vacac_emp    number                 := 365;
  in_periodo_vacac_jor    number                 := 260;
  
  -- Public constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  --<VariableName> <Datatype>;

  -- Public function and procedure declarations
  function of_dias_asist(
           asi_codtra        maestro.cod_trabajador%TYPE, 
           ani_year          number
  ) return decimal;

  function of_vacaciones_gozadas(
           asi_codtra        maestro.cod_trabajador%TYPE, 
           ani_year          number
  ) return decimal;
  
  function of_dias_vacaciones(
           asi_codtra             maestro.cod_trabajador%TYPE, 
           asi_tipo_trabajador    tipo_trabajador.tipo_trabajador%TYPE     
  ) return decimal;

  function of_get_periodo_vacac_emp(asi_nada varchar2) return number;
  function of_get_periodo_vacac_jor(asi_nada varchar2) return number;
  
  -- funcion para el calculo de vacaciones
  function of_importe_vacaciones(
    asi_codtra        maestro.cod_trabajador%TYPE,
    ani_dias_vacac    number             
  ) return number;
  
  -- Procedimiento para reporte
  procedure sp_rpt_vacaciones(
    ani_year         number,
    asi_tipo_trabaj  tipo_trabajador.tipo_trabajador%TYPE,
    asi_codtra       maestro.cod_trabajador%TYPE
  );

end PKG_RRHH;
/
create or replace package body PKG_RRHH is

  -- Private type declarations
  ---type <TypeName> is <Datatype>;
  
  -- Private constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Private variable declarations
  --<VariableName> <Datatype>;

  -- Function and procedure implementations
  function of_dias_asist(
           asi_codtra        maestro.cod_trabajador%TYPE, 
           ani_year          number
  ) return decimal is
  
    ln_dias_asistencia   number;
    ln_dias_periodo      number;
    
    ls_grp_dias_inasis         rrhhparam_cconcep.dias_inasis_dsccont%TYPE;
    ls_cnc_vacaciones          concepto.concep%TYPE;
    ln_dias                    number;
    ld_fec_desde               date ;
    ld_fec_hasta               date ;
    ln_faltas                  number ;
    ln_dias_obrero             NUMBER;
    ln_dias_campo              NUMBER;
    ld_fec_ing_trab            maestro.fec_ingreso%TYPE;
    ld_fec_cese                maestro.fec_cese%TYPE;
    ls_flag_tipo_sueldo        tipo_trabajador.flag_ingreso_boleta%TYPE;
    ls_tipo_trabajador         tipo_trabajador.tipo_trabajador%TYPE;
    
    --  Cursor de inasistencias a descontar
    cursor c_inasistencias is
      select i.dias_inasist from inasistencia i
       where i.cod_trabajador = asi_codtra
         and (i.concep in ( select d.concepto_calc
                             from grupo_calculo_det d
                            where d.grupo_calculo = ls_grp_dias_inasis )
              or i.concep = ls_cnc_vacaciones)
         and trunc(i.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta)
         and i.flag_vacac_adelantadas = '0' ;
    
  begin
    
    --  ***********************************************************************
    --  ***   REALIZA CALCULO DE DIAS TRABAJADOS PARA CALCULO DE PLANILLA   ***
    --  ***********************************************************************
    
    ld_fec_desde := to_date('01/01/' || trim(to_char(ani_year, '0000')), 'dd/mm/yyyy');
    ld_fec_hasta := to_date('31/12/' || trim(to_char(ani_year, '0000')), 'dd/mm/yyyy');
    
    ln_dias_periodo := ld_fec_hasta - ld_fec_desde + 1;
    
    -- Obtengo la fecha de inicio de trabajo del trabajador
    select m.fec_ingreso, m.fec_cese, m.tipo_trabajador, tt.flag_ingreso_boleta
      into ld_fec_ing_trab, ld_fec_cese, ls_tipo_trabajador, ls_flag_tipo_sueldo
      from maestro m,
           tipo_trabajador tt
     where m.tipo_trabajador = tt.tipo_trabajador
       and m.cod_trabajador  = asi_codtra;
     
    -- Grupo de dias de inasistencia
    select c.dias_inasis_dsccont
      into ls_grp_dias_inasis
      from rrhhparam_cconcep c
     where c.reckey = '1' ;

    -- Obtengo el concepto de vacaciones
    select gc.concepto_gen
      into ls_cnc_vacaciones
      from grupo_calculo gc
     where gc.grupo_calculo = (select t.gan_fij_calc_vacac from rrhhparam_cconcep t);

    if ld_fec_hasta < ld_fec_ing_trab then
       -- El trabajador ha ingresado despues del rango por lo que no corresponde nada
       return 0;
    end if;

    -- Verifico si la fecha de inicio de calculo es mayor o menor de la fecha de inicio de trabajo
    if ld_fec_desde < ld_fec_ing_trab then
       ld_fec_desde := ld_fec_ing_trab;
    end if;

    --Fecha de cese
    if ld_fec_cese is not null then
       if ld_fec_cese < ld_fec_desde then return 0; end if;
       if ld_fec_cese < ld_fec_hasta then
          ld_fec_hasta := ld_fec_cese;
       end if;
    end if;

    if ld_fec_desde > ld_fec_hasta then
       RAISE_APPLICATION_ERROR(-20000, 'Error, la fecha de inicio es mayor a la fecha de fin ' || asi_codtra);
    end if;

    if ls_tipo_trabajador = USP_SIGRE_RRHH.is_tipo_trip then
       select count(distinct fa.fecha)
         into ln_dias_asistencia
         from fl_asistencia fa
        where fa.tripulante = asi_codtra
          and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

    elsif ls_tipo_trabajador in (USP_SIGRE_RRHH.is_tipo_des, USP_SIGRE_RRHH.is_tipo_ser) then

       select count(distinct p.fec_parte)
         into ln_dias_asistencia
         from tg_pd_destajo p,
              tg_pd_destajo_det pd
        where p.nro_parte = pd.nro_parte
          and pd.cod_trabajador = asi_codtra
          and trunc(p.fec_parte) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta)
          and p.flag_estado <> '0';

    else
      
       IF ls_flag_tipo_sueldo = 'J' THEN
          -- Dias Trabajados
          SELECT COUNT(DISTINCT a.fec_movim)
            INTO ln_dias_obrero
            FROM asistencia a
           WHERE a.cod_trabajador = asi_codtra
             AND trunc(a.fec_movim) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

          SELECT COUNT(DISTINCT a.fecha)
            INTO ln_dias_campo
            FROM pd_jornal_campo a
           WHERE a.cod_trabajador = asi_codtra
             AND trunc(a.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

          ln_dias_asistencia := ln_dias_campo + ln_dias_obrero;
       ELSE
          ln_faltas := 0 ;
          for rc_ina in c_inasistencias loop
              ln_faltas := ln_faltas + nvl(rc_ina.dias_inasist,0) ;
          end loop ;

          ln_dias := ld_fec_hasta - ld_fec_desde + 1;

          if ln_dias > ln_dias_periodo then
             ln_dias := ln_dias_periodo;
          end if;

          if ln_dias < ln_faltas then
             ln_dias_asistencia := 0;
          else
             ln_dias_asistencia := ln_dias - ln_faltas ;
          end if;

       END IF;
    end if;


    if ln_dias_asistencia > ln_dias then
       ln_dias_asistencia := ln_dias ;
    end if ;

    if ln_dias_asistencia > ln_dias_periodo then
       ln_dias_asistencia := ln_dias_periodo;
    end if;

    return(nvl(ln_dias_asistencia,0)) ;
      
               
  end;

  function of_vacaciones_gozadas(
           asi_codtra        maestro.cod_trabajador%TYPE, 
           ani_year          number
  ) return decimal is
  
    ln_Return  decimal;
  begin
    
    --  ***********************************************************************
    --  ***   REALIZA CALCULO DE DIAS TRABAJADOS PARA CALCULO DE PLANILLA   ***
    --  ***********************************************************************
    select sum(i.dias_inasist)
      into ln_Return
      from inasistencia i
     where i.cod_trabajador = asi_codtra
       and i.concep         = is_cnc_vacaciones
       and i.periodo_inicio = ani_year;


    return(nvl(ln_Return,0)) ;
      
               
  end;

  function of_get_periodo_vacac_emp(
       asi_nada varchar2
  ) return number is
  
  begin
    return(nvl(in_periodo_vacac_emp,0)) ;
  end;

  function of_get_periodo_vacac_jor(
       asi_nada varchar2
  ) return number is
  
  begin
    return(nvl(in_periodo_vacac_jor,0)) ;
  end;
  
  function of_dias_vacaciones(
    asi_codtra             maestro.cod_trabajador%TYPE,
    asi_tipo_trabajador    tipo_trabajador.tipo_trabajador%TYPE                  
  ) return decimal is
  
    ln_Return decimal;
    
  begin
    select 
        case 
             when asi_tipo_trabajador = usp_sigre_rrhh.is_tipo_emp then
               trunc(PKG_RRHH.of_dias_asist(asi_codtra, 2015) / pkg_rrhh.of_get_periodo_vacac_emp(null) * 30)
             else
               trunc(PKG_RRHH.of_dias_asist(asi_codtra, 2015) / pkg_rrhh.of_get_periodo_vacac_jor(null) * 30)
           end
      into ln_Return
      from dual;
      
      return ln_Return;
       
  end ;

  function of_importe_vacaciones(
    asi_codtra        maestro.cod_trabajador%TYPE,
    ani_dias_vacac    number                  
  ) return number is
  
    ln_count                integer ;
    ln_imp_fijo             calculo.imp_soles%TYPE;
    ln_imp_variable         calculo.imp_soles%TYPE;
    ln_imp_soles            calculo.imp_soles%TYPE;
    ld_fec_proceso          date;

    ls_tipo_trabajador      tipo_trabajador.tipo_trabajador%TYPE;
    ls_grp_vacac_fijo       rrhhparam_cconcep.gan_fij_calc_vacac%TYPE;
    ls_grp_vacac_variable   grupo_calculo.grupo_calculo%TYPE := '806';

    ln_year2                number;
    ln_year1                number;
    ln_mes2                 number;
    ln_mes1                 number;

    lbo_flag                boolean := false;
    ln_meses                number;
    ln_rmv                  rmv_x_tipo_trabaj.rmv%TYPE;


    begin


    --  *******************************************
    --  ***   RELIZA EL CALCULO DE VACACIONES   ***
    --  *******************************************
    -- Obtiene el fijo y el promedio de las variables de los ultimos 6 meses
    
    -- Obtengo el tipo de trabajador
    select tipo_trabajador
      into ls_tipo_trabajador
      from maestro m
     where m.cod_trabajador = asi_codtra;
    
    -- Obtengo la remuneracion minima vital para el tipo de trabajador
    select count(*)
      into ln_count
      from rmv_x_tipo_trabaj t
      where t.tipo_trabajador = ls_tipo_trabajador;
    
    if ln_count = 0 then
       RAISE_APPLICATION_ERROR(-20000, 'No ha definido remuneración minima vital para el tipo de trabajador ' 
                                       || ls_tipo_trabajador || '. Por favor verifique!');
    end if;
      
    select r.rmv 
      into ln_rmv
      from rmv_x_tipo_trabaj r 
     where r.tipo_trabajador = ls_tipo_trabajador
       and rownum = 1;
    
    -- Grupo de Calculo de los conceptos fijos
    select c.gan_fij_calc_vacac
      into ls_grp_vacac_fijo
      from rrhhparam_cconcep c
     where c.reckey = '1' ;

      SELECT nvl(sum(DECODE(nvl(gdf.imp_gan_desc,0), 0, nvl(gdf.porcentaje,0)* ln_rmv /100, gdf.imp_gan_desc)),0)
        into ln_imp_fijo
        from gan_desct_fijo gdf
       where gdf.cod_trabajador = asi_codtra
         and gdf.flag_estado = '1'
         AND gdf.concep in ( select d.concepto_calc
                               from grupo_calculo_det d
                              where d.grupo_calculo = ls_grp_vacac_fijo ) ;

      --Calculo promedio de Ingresos Extras
      ln_year2 := to_number(to_char(sysdate, 'yyyy'));
      ln_mes2  := to_number(to_char(sysdate, 'mm')) - 1;
      
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
            into ln_imp_variable
           from historico_calculo hc,
                grupo_calculo_det gcd
          where hc.concep         = gcd.concepto_calc
            and hc.cod_trabajador = asi_codtra
            and gcd.grupo_calculo = ls_grp_vacac_variable
            and to_char(hc.fec_calc_plan, 'yyyymm') between trim(to_char(ln_year1, '0000')) || trim(to_char(ln_mes1, '00')) and trim(to_char(ln_year2, '0000')) || trim(to_char(ln_mes2, '00'));
      else
         ln_imp_variable := 0;
      end if;
      
      ln_imp_soles := ln_imp_fijo + ln_imp_variable / 6;
      
      ln_imp_soles := ln_imp_soles / 30 * ani_dias_vacac;
      
      return ln_imp_soles;

    end ;

  procedure sp_rpt_vacaciones(
    ani_year         number,
    asi_tipo_trabaj  tipo_trabajador.tipo_trabajador%TYPE,
    asi_codtra       maestro.cod_trabajador%TYPE
  ) is
    
    ls_grp_vacac_fijo       rrhhparam_cconcep.gan_fij_calc_vacac%TYPE;
    ls_grp_vacac_variable   grupo_calculo.grupo_calculo%TYPE := '806';
    ln_rmv                  rmv_x_tipo_trabaj.rmv%TYPE;
    ln_count                number;
    ln_dias_pendientes      number;
    
    -- Importes para cada mes
    ln_importe01            number;
    ln_importe02            number;
    ln_importe03            number;
    ln_importe04            number;
    ln_importe05            number;
    ln_importe06            number;
    ln_importe07            number;
    ln_importe08            number;
    ln_importe09            number;
    ln_importe10            number;
    ln_importe11            number;
    ln_importe12            number;
    ln_importe              number;
    
    -- Cursor con los datos de todos los trabajadores
    cursor c_datos is
      select m.COD_TRABAJADOR, 
             m.TIPO_TRABAJADOR,
             PKG_RRHH.of_dias_asist(m.COD_TRABAJADOR, ani_year) as dias_trabajados,
             PKG_RRHH.of_dias_vacaciones(m.cod_trabajador, m.tipo_trabajador) as dias_vacaciones,
             PKG_RRHH.of_vacaciones_gozadas(m.COD_TRABAJADOR, ani_year) as vacaciones_gozadas
        from vw_pr_trabajador m
       where PKG_RRHH.of_dias_asist(m.COD_TRABAJADOR, ani_year) > 0
         and PKG_RRHH.of_dias_vacaciones(m.cod_trabajador, m.tipo_trabajador) - PKG_RRHH.of_vacaciones_gozadas(m.COD_TRABAJADOR, ani_year) > 0
         and m.tipo_trabajador like asi_tipo_trabaj
         and m.cod_trabajador  like asi_codtra
         and m.flag_estado     <> '0'
         and m.FEC_CESE        is null
      order by m.tipo_trabajador, m.nom_trabajador;
      
    -- Cursor con los datos de las variables fijas
    cursor c_fijos(as_trabajador  maestro.cod_trabajador%TYPE) is
      SELECT gdf.concep,
             nvl(sum(DECODE(nvl(gdf.imp_gan_desc,0), 0, nvl(gdf.porcentaje,0)* ln_rmv /100, gdf.imp_gan_desc)),0) as importe
        from gan_desct_fijo gdf
       where gdf.cod_trabajador = as_trabajador
         and gdf.flag_estado = '1'
         AND gdf.concep in ( select d.concepto_calc
                               from grupo_calculo_det d
                              where d.grupo_calculo = ls_grp_vacac_fijo ) 
      group by gdf.concep;
    
    -- cursor con los conceptos variables
    cursor c_variables(as_trabajador    maestro.cod_trabajador%TYPE,
                       ani_year         number) is
      select distinct hc.concep
       from historico_calculo hc,
            grupo_calculo_det gcd
      where hc.concep         = gcd.concepto_calc
        and hc.cod_trabajador = as_trabajador
        and gcd.grupo_calculo = ls_grp_vacac_variable
        and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year;
                       

  
  begin
    --  *******************************************************
    --  ***   Llena la tabla con los conceptos necesarios   ***
    --  *******************************************************
    -- Elimino todos los datos de la tabla temporal
    delete tt_rrhh_vacaciones_trab;
    
    -- Grupo de Calculo de los conceptos fijos
    select c.gan_fij_calc_vacac
      into ls_grp_vacac_fijo
      from rrhhparam_cconcep c
     where c.reckey = '1' ;

    
    -- Recorro el cursor buscando datos
    for lc_reg in c_datos loop
        -- Dias pendientes
        ln_dias_pendientes := lc_reg.dias_vacaciones - lc_reg.vacaciones_gozadas;
        
        -- Obtengo la remuneracion minima vital para el tipo de trabajador
        select count(*)
          into ln_count
          from rmv_x_tipo_trabaj t
          where t.tipo_trabajador = lc_reg.tipo_trabajador;
        
        if ln_count = 0 then
           RAISE_APPLICATION_ERROR(-20000, 'No ha definido remuneración minima vital para el tipo de trabajador ' 
                                           || lc_reg.tipo_trabajador || '. Por favor verifique!');
        end if;
          
        select r.rmv 
          into ln_rmv
          from rmv_x_tipo_trabaj r 
         where r.tipo_trabajador = lc_reg.tipo_trabajador
           and rownum = 1;
        
        -- Recorro los conceptos fijos para agregarlos
        for lc_fijos in c_fijos(lc_reg.cod_trabajador) loop
            insert into tt_rrhh_vacaciones_trab(
                   cod_trabajador, concep, dias_trabajados, dias_vacaciones, 
                   vacaciones_gozadas, flag_fijo_variable, importe)
            values(
                   lc_reg.cod_trabajador, lc_fijos.concep, lc_reg.dias_trabajados, lc_reg.dias_vacaciones,
                   lc_reg.vacaciones_gozadas, 'F', lc_fijos.importe / 30 * ln_dias_pendientes);
        end loop;

        -- Calculo de los ingresos extras, en este caso será todo el año
        for lc_variables in c_variables(lc_reg.cod_trabajador, ani_year) loop
            -- Importe Enero
            select nvl(sum(hc.imp_soles),0)
              into ln_importe01
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 01;
               
            -- Importe Febrero
            select nvl(sum(hc.imp_soles),0)
              into ln_importe02
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 02;
            
            -- Importe Marzo
            select nvl(sum(hc.imp_soles),0)
              into ln_importe03
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 03;
               
            -- Importe Abril
            select nvl(sum(hc.imp_soles),0)
              into ln_importe04
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 04;
               
            -- Importe Mayo
            select nvl(sum(hc.imp_soles),0)
              into ln_importe05
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 05;
               
            -- Importe Junio
            select nvl(sum(hc.imp_soles),0)
              into ln_importe06
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 06;
               
            -- Importe Julio
            select nvl(sum(hc.imp_soles),0)
              into ln_importe07
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 07;
               
            -- Importe Agosto
            select nvl(sum(hc.imp_soles),0)
              into ln_importe08
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 08;
               
            -- Importe Setiembre
            select nvl(sum(hc.imp_soles),0)
              into ln_importe09
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 09;
               
            -- Importe Octubre
            select nvl(sum(hc.imp_soles),0)
              into ln_importe10
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 10;
               
            -- Importe Noviembre
            select nvl(sum(hc.imp_soles),0)
              into ln_importe11
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 11;
               
            -- Importe Diciembre
            select nvl(sum(hc.imp_soles),0)
              into ln_importe12
              from historico_calculo hc
             where hc.cod_trabajador = lc_reg.cod_trabajador
               and hc.concep         = lc_variables.concep
               and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
               and to_number(to_char(hc.fec_calc_plan, 'mm'))   = 12;
            
            ln_count := 0;
            if ln_importe01 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe02 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe03 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe04 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe05 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe06 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe07 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe08 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe09 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe10 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe11 > 0 then ln_count := ln_count + 1; end if;
            if ln_importe12 > 0 then ln_count := ln_count + 1; end if;
            
            -- Si ha recibido el concepto variable minimo tres veces o mas entonces lo considero en el calculo
            if ln_count >= 3 then
               ln_importe := ln_importe01 + ln_importe02 + ln_importe03 + ln_importe04 + ln_importe05 + ln_importe06 +
                             ln_importe07 + ln_importe08 + ln_importe09 + ln_importe10 + ln_importe11 + ln_importe12;
                             
               if ln_importe > 0 then
                  ln_importe := ln_importe / 12;
                  
                  ln_importe := ln_importe / 30 * ln_dias_pendientes;
                  
                  -- Inserto 
                  insert into tt_rrhh_vacaciones_trab(
                         cod_trabajador, concep, dias_trabajados, dias_vacaciones, 
                         vacaciones_gozadas, flag_fijo_variable, importe)
                  values(
                         lc_reg.cod_trabajador, lc_variables.concep, lc_reg.dias_trabajados, lc_reg.dias_vacaciones,
                         lc_reg.vacaciones_gozadas, 'V', ln_importe);
               end if;
            end if;
               
        end loop;
        
        commit;
          --ln_imp_soles := ln_imp_fijo + ln_imp_variable / 6;
          
          --ln_imp_soles := ln_imp_soles / 30 * ani_dias_vacac;
          
          --return ln_imp_soles;

    end loop;
    
  end;

begin
  -- Initialization
  in_periodo_vacac_jor := PKG_CONFIG.USF_GET_PARAMETER('PERIODO_VACACION_JOR', 260);
end PKG_RRHH;
/
