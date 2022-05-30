create or replace package USP_SIGRE_RRHH is

  -- Author  : JRAMIREZ
  -- Created : 19/02/2014 09:16:15 a.m.
  -- Purpose : FUNCIONES Y PROCEDIMIENTOS PARA RECURSOS HUMANOS
  
  -- Public type declarations
  --type <TypeName> is <Datatype>;
  
  -- Public constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  is_tipo_trip               rrhhparam.tipo_trab_tripulante%TYPE;
  is_tipo_des                rrhhparam.tipo_trab_destajo%TYPE;
  is_tipo_ser                rrhhparam.tipo_trab_servis%TYPE;
  is_tipo_jor                rrhhparam.tipo_trab_obrero%TYPE;
  is_tipo_emp                rrhhparam.tipo_trab_empleado%TYPE;
  
  is_cnc_bonif_tri           concepto.concep%TYPE;
  is_cnc_partic_pesca        concepto.concep%TYPE;
  
  -- Grupos de Calculo para tripulantes
  is_grp_gratif_tri          grupo_calculo.grupo_calculo%TYPE;
  is_grp_VACAC_TRI           grupo_calculo.grupo_calculo%TYPE;
  is_grp_CTS_TRI             grupo_calculo.grupo_calculo%TYPE;
  
  -- Tipos de Planilla
  is_planilla_gratif_tri     char(1) := 'G';
  is_planilla_CTS_tri        char(1) := 'C';
  is_planilla_VACAC_tri      char(1) := 'V';
  
  -- Datos para la gratificacion Extraordinaria
  in_porc_bonif_ext          asistparam.porc_bonif_ext%TYPE;
  is_cnc_bonif_ext           asistparam.cnc_bonif_ext%TYPE;
  
  -- Parametros para el calculo de planilla
  is_cnc_total_ingreso       rrhhparam.cnc_total_ing%TYPE;
  is_cnc_total_dscto         rrhhparam.cnc_total_dsct%TYPE;
  is_cnc_total_pagado        rrhhparam.cnc_total_pgd%TYPE;
  is_cnc_total_aportes       rrhhparam.cnc_total_aport%TYPE;
  in_ano_tope_seg_inv        rrhhparam.tope_ano_seg_inv%TYPE;
  
  -- Conceptos diversos para calculo
  is_cnc_reintegro_grati     concepto.concep%TYPE := '1483';
  is_cnc_reint_asig_fam      concepto.concep%TYPE;
  
  
  -- AFP para REP
  is_afp_rep                 admin_afp.cod_afp%TYPE;
  
  -- funcion
  
  -- Esta funcion devuelve las toneladas que han entrado al calculo de la participacion de Pesca
  function of_get_toneladas(asi_origen          rrhh_param_org.origen%TYPE,
                            adi_fec_proceso     rrhh_param_org.fec_proceso%TYPE,
                            asi_tipo_trabajador rrhh_param_org.tipo_trabajador%TYPE,
                            asi_tipo_planilla   rrhh_param_org.tipo_planilla%TYPE,
                            asi_tripulante      maestro.cod_trabajador%TYPE) return number;

  -- Estas funciones son para el reporte por tripulantes de RRHH
  function of_total_partic_pesca(adi_fec_proceso     date,
                                 asi_codtra          maestro.cod_trabajador%TYPE) return number;
                            
  function of_total_bonif_pesca (adi_fec_proceso     date,
                                 asi_codtra          maestro.cod_trabajador%TYPE) return number;
                                 
  function of_base_calc_gratif (adi_fec_proceso     date,
                                asi_codtra          maestro.cod_trabajador%TYPE) return number;

  function of_base_calculo     (adi_fec_proceso     date,
                                asi_tipo_planilla   calculo.tipo_planilla%TYPE,
                                asi_codtra          maestro.cod_trabajador%TYPE) return number;

  -- Esta funcion devuelve la participacion de pesca del tripulante en un rango de fechas
  function of_total_concepto(ani_year            number,
                             ani_mes             number,
                             asi_concepto        concepto.concep%TYPE,
                             asi_codtra          maestro.cod_trabajador%TYPE) return number;
                      
  function of_get_tipo_trip(asi_nada varchar2) return varchar2;
  function of_get_tipo_emp(asi_nada varchar2) return varchar2;
  
  function of_hras_normales(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
  ) return decimal;
  
  function of_hras_extras(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
  ) return decimal;

  function of_dias_asist(
           asi_codtra  maestro.cod_trabajador%TYPE, 
           adi_fecha1  date, 
           adi_Fecha2  date
  ) return decimal;
  
  function of_dias_asist(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
  ) return decimal;
  
  function of_dias_asist(
           asi_codtra        maestro.cod_trabajador%TYPE, 
           adi_fec_proceso   date,
           asi_origen        origen.cod_origen%TYPE,
           asi_tipo_planilla calculo.tipo_planilla%TYPE
  ) return decimal;
  
  function of_dias_asist_alimentacion(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
  ) return decimal;

   function of_tipo_planilla(
           asi_tipo_planilla   rrhh_param_org.tipo_planilla%TYPE
   ) return varchar2;
  
  -- Public function and procedure declarations
  procedure SP_RH_DISTRIBUCION_ASIENTOS(
           adi_fec_proceso     in     date                                   ,
           asi_cod_trabajador  in     maestro.cod_trabajador%type            ,
           asi_origen          in     origen.cod_origen%TYPE                 ,
           asi_cnta_ctbl       in     cntbl_cnta.cnta_ctbl%type              ,
           asi_flag_debhab     in     cntbl_asiento_det.flag_debhab%TYPE     ,
           ani_imp_movsol      in     calculo.imp_soles%type                 ,
           ani_imp_movdol      in     calculo.imp_soles%type                 ,
           asi_tipo_doc        in     doc_tipo.tipo_doc%type                 ,
           asi_nro_doc         in     calculo.nro_doc_cc%type                ,
           ani_nro_libro       in     cntbl_libro.nro_libro%type             ,
           asi_det_glosa       in     cntbl_pre_asiento_det.det_glosa%TYPE   ,
           ani_nro_provisional in     cntbl_libro.num_provisional%type       ,
           ani_item            in out cntbl_pre_asiento_det.item%type        ,
           asi_concep          in     concepto.concep%type                   
    );
  
  procedure SP_RH_INSERT_ASIENTO(
         adi_fec_proceso    in date                                   ,
         asi_origen         in origen.cod_origen%type                 ,
         asi_cencos         in centros_costo.cencos%type              ,
         asi_cnta_ctbl      in cntbl_cnta.cnta_ctbl%type              ,
         asi_tipo_doc       in doc_tipo.tipo_doc%type                 ,
         asi_nro_doc        in calculo.nro_doc_cc%type                ,
         asi_cod_relacion   in cntbl_asiento_det.cod_relacion%TYPE    ,
         asi_flag_debhab    in cntbl_asiento_det.flag_debhab%TYPE     ,
         ani_nro_libro      in cntbl_libro.nro_libro%type             ,
         asi_glosa_det      in cntbl_pre_asiento_det.det_glosa%TYPE   ,
         ani_item           in out cntbl_pre_asiento_det.item%type    ,
         ani_num_prov       in cntbl_libro.num_provisional%type       ,
         ani_imp_soles      in cntbl_pre_asiento_det.imp_movsol%type  ,
         ani_imp_dolares    in cntbl_pre_asiento_det.imp_movsol%type  ,
         asi_concep         in concepto.concep%type                   ,
         asi_cbenef         in maestro.centro_benef%type              ,
         asi_cod_trabajador in maestro.cod_trabajador%TYPE
  );
  
  --Procedimiento para Procesar Gratificacion de Tripulantes
  procedure PROCESAR_GRATIF_TRIPULANTE (
    asi_codtra             in maestro.cod_trabajador%TYPE,
    asi_codusr             in usuario.cod_usr%TYPE,
    adi_fec_proceso        in date,
    asi_origen             in origen.cod_origen%TYPE
  );

  --Procedimiento para Procesar Vacaciones de Tripulantes
  procedure PROCESAR_VACAC_TRIPULANTE (
    asi_codtra             in maestro.cod_trabajador%TYPE,
    asi_codusr             in usuario.cod_usr%TYPE,
    adi_fec_proceso        in date,
    asi_origen             in origen.cod_origen%TYPE
  );

  --Procedimiento para Procesar CTS de Tripulantes
  procedure PROCESAR_CTS_TRIPULANTE (
    asi_codtra             in maestro.cod_trabajador%TYPE,
    asi_codusr             in usuario.cod_usr%TYPE,
    adi_fec_proceso        in date,
    asi_origen             in origen.cod_origen%TYPE
  );
  
  procedure usp_rh_cal_borra_hist_calculo (
    asi_origen         in origen.cod_origen%TYPE,
    adi_fec_proceso    in date,
    asi_tipo_trabaj    in tipo_trabajador.tipo_trabajador %TYPE,
    asi_tipo_planilla  in calculo.tipo_planilla%TYPE
  );

end USP_SIGRE_RRHH;
/
create or replace package body USP_SIGRE_RRHH is

  -- Private type declarations
  --type <TypeName> is <Datatype>;
  
  -- Private constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Private variable declarations
  --<VariableName> <Datatype>;
  function of_get_toneladas(asi_origen          rrhh_param_org.origen%TYPE,
                            adi_fec_proceso     rrhh_param_org.fec_proceso%TYPE,
                            asi_tipo_trabajador rrhh_param_org.tipo_trabajador%TYPE,
                            asi_tipo_planilla   rrhh_param_org.tipo_planilla%TYPE,
                            asi_tripulante      maestro.cod_trabajador%TYPE
  ) return number is
    ln_Toneladas  number;
    ld_fecha1     date;
    ld_fecha2     date;
    ln_count      number;
  begin
    select count(*)  
      into ln_count
      from rrhh_param_org r
     where r.origen       = asi_origen
       and r.fec_proceso  = adi_fec_proceso
       and r.tipo_trabajador = asi_tipo_trabajador
       and r.tipo_planilla   = asi_tipo_planilla;
    
    if ln_count = 0 then
       return 0; 
    end if;

    select r.fec_inicio, r.fec_final  
      into ld_fecha1, ld_fecha2
      from rrhh_param_org r
     where r.origen       = asi_origen
       and r.fec_proceso  = adi_fec_proceso
       and r.tipo_trabajador = asi_tipo_trabajador
       and r.tipo_planilla   = asi_tipo_planilla;
  
    select nvl(sum(flpp.pesca_asignada),0)
      into ln_Toneladas
      from fl_participacion_pesca flpp
     where flpp.tripulante = asi_tripulante
       and trunc(flpp.fecha) between trunc(ld_Fecha1) and trunc(ld_Fecha2);
    
    return ln_Toneladas;
  end ;
                              
  function of_total_partic_pesca(adi_fec_proceso     date,
                                 asi_codtra          maestro.cod_trabajador%TYPE
  ) return number is
  begin
    return of_total_concepto(to_number(to_char(adi_fec_proceso, 'yyyy')), 
                             to_number(to_char(adi_fec_proceso, 'mm')),
                             is_cnc_partic_pesca,
                             asi_codtra);
  end ;
  
  -- Funcion que devuelve el total de la bonificacion de tripulantes
  function of_total_bonif_pesca(adi_fec_proceso     date,
                                 asi_codtra          maestro.cod_trabajador%TYPE
  ) return number is
  begin
    return of_total_concepto(to_number(to_char(adi_fec_proceso, 'yyyy')), 
                             to_number(to_char(adi_fec_proceso, 'mm')),
                             is_cnc_bonif_tri,
                             asi_codtra);
  end ;
  
  -- total de la base de calculo para la gratificacion
  function of_base_calc_gratif(adi_fec_proceso     date,
                                 asi_codtra          maestro.cod_trabajador%TYPE
  ) return number is
    ln_return number;
  begin
    select nvl(sum(hc.imp_soles),0)
      into ln_return
      from historico_calculo hc,
           grupo_calculo_det gcd
     where hc.concep                                    = gcd.concepto_calc
       and gcd.grupo_calculo                            = is_grp_gratif_tri
       and hc.cod_trabajador                            = asi_codtra
       and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = to_number(to_char(adi_fec_proceso, 'yyyy'))
       and to_number(to_char(hc.fec_calc_plan, 'mm'))   = to_number(to_char(adi_fec_proceso, 'mm'));
    
    return ln_Return;
  end ;

  -- total de la base de calculo de acuerdo al tipo de planilla
  function of_base_calculo(adi_fec_proceso     date,
                           asi_tipo_planilla   calculo.tipo_planilla%TYPE,
                           asi_codtra          maestro.cod_trabajador%TYPE
  ) return number is
    ln_return number;
  begin
    
    if asi_tipo_planilla = is_planilla_gratif_tri then
      
       select nvl(sum(hc.imp_soles),0)
         into ln_return
         from historico_calculo hc,
              grupo_calculo_det gcd
        where hc.concep                                    = gcd.concepto_calc
          and gcd.grupo_calculo                            = is_grp_gratif_tri
          and hc.cod_trabajador                            = asi_codtra
          and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = to_number(to_char(adi_fec_proceso, 'yyyy'))
          and to_number(to_char(hc.fec_calc_plan, 'mm'))   = to_number(to_char(adi_fec_proceso, 'mm'));
          
    elsif asi_tipo_planilla = is_planilla_VACAC_tri then
    
       select nvl(sum(hc.imp_soles),0)
         into ln_return
         from historico_calculo hc,
              grupo_calculo_det gcd
        where hc.concep                                    = gcd.concepto_calc
          and gcd.grupo_calculo                            = is_planilla_VACAC_tri
          and hc.cod_trabajador                            = asi_codtra
          and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = to_number(to_char(adi_fec_proceso, 'yyyy'))
          and to_number(to_char(hc.fec_calc_plan, 'mm'))   = to_number(to_char(adi_fec_proceso, 'mm'));

    elsif asi_tipo_planilla = is_planilla_CTS_tri then
    
       select nvl(sum(hc.imp_soles),0)
         into ln_return
         from historico_calculo hc,
              grupo_calculo_det gcd
        where hc.concep                                    = gcd.concepto_calc
          and gcd.grupo_calculo                            = is_planilla_CTS_tri
          and hc.cod_trabajador                            = asi_codtra
          and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = to_number(to_char(adi_fec_proceso, 'yyyy'))
          and to_number(to_char(hc.fec_calc_plan, 'mm'))   = to_number(to_char(adi_fec_proceso, 'mm'));

    else
       ln_Return := 0;
    end if;
    
    return ln_Return;
  end ;

  -- Obtengo el total obtenido por concepto, de manera mensual
  function of_total_concepto(ani_year            number,
                             ani_mes             number,
                             asi_concepto        concepto.concep%TYPE,
                             asi_codtra          maestro.cod_trabajador%TYPE
  ) return number is
    ln_total_hist     number;
    ln_total_calc     number;
  begin
  
    select nvl(sum(hc.imp_soles),0)
      into ln_total_hist
      from historico_calculo hc
     where hc.cod_trabajador                            = asi_codtra
       and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
       and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes
       and hc.concep                                    = asi_concepto;
    
    select nvl(sum(ca.imp_soles),0)
      into ln_total_calc
      from calculo ca,
           maestro m
     where ca.cod_trabajador                            = m.cod_trabajador
       and ca.cod_trabajador                            = asi_codtra
       and to_number(to_char(ca.fec_proceso, 'yyyy'))   = ani_year
       and to_number(to_char(ca.fec_proceso, 'mm'))     = ani_mes
       and ca.concep                                    = asi_concepto;

    return ln_total_calc + ln_total_hist;
  end ;

  function of_tipo_planilla(
          asi_tipo_planilla   rrhh_param_org.tipo_planilla%TYPE
  ) return varchar2 is
    ls_Return varchar2(1000);
  begin
    select decode(asi_tipo_planilla, 'N', 'Planilla Normal', 
                                     'B', 'Bonificaciones Tripulante', 
                                     'G', 'Gratificacion Tripulante', 
                                     'C', 'CTS Tripulante', 
                                     'V', 'Vacaciones Tripulante')    
      into ls_Return
      from dual;
  
    return ls_Return;
  end ;

  function of_get_tipo_emp(asi_nada varchar2) return varchar2 is
  begin
    return is_tipo_emp;
  end;
  function of_get_tipo_trip(asi_nada varchar2) return varchar2 is
  begin
    return is_tipo_trip;
  end;
    
  function of_dias_asist(
           asi_codtra  maestro.cod_trabajador%TYPE, 
           adi_fecha1  date, 
           adi_Fecha2  date
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
         and trunc(i.fec_movim) between trunc(adi_fecha1) and trunc(adi_fecha2)
         and i.flag_vacac_adelantadas = '0' ;
    
  begin
    
    --  ***********************************************************************
    --  ***   REALIZA CALCULO DE DIAS TRABAJADOS PARA CALCULO DE PLANILLA   ***
    --  ***********************************************************************
    
    ld_fec_desde := adi_fecha1;
    ld_fec_hasta := adi_Fecha2;
    
    
    
    ln_dias_periodo := adi_fecha2 - adi_fecha1 + 1;
    
    -- Obtengo la fecha de inicio de trabajo del trabajador
    select m.fec_ingreso, m.fec_cese, m.tipo_trabajador, tt.flag_ingreso_boleta
      into ld_fec_ing_trab, ld_fec_cese, ls_tipo_trabajador, ls_flag_tipo_sueldo
      from maestro m,
           tipo_trabajador tt
     where m.tipo_trabajador = tt.tipo_trabajador
       and m.cod_trabajador = asi_codtra;
     
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

    if ls_tipo_trabajador = is_tipo_trip then
       select count(distinct fa.fecha)
         into ln_dias_asistencia
         from fl_asistencia fa
        where fa.tripulante = asi_codtra
          and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

    elsif ls_tipo_trabajador in (is_tipo_des, is_tipo_ser) then

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
  
  -- Asistencia por fecha de proceso
  function of_dias_asist(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
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
    
    -- Obtengo la fecha de inicio de trabajo del trabajador
    select m.fec_ingreso, m.fec_cese, m.tipo_trabajador, tt.flag_ingreso_boleta
      into ld_fec_ing_trab, ld_fec_cese, ls_tipo_trabajador, ls_flag_tipo_sueldo
      from maestro m,
           tipo_trabajador tt
     where m.tipo_trabajador = tt.tipo_trabajador
       and m.cod_trabajador = asi_codtra;
    
    -- Obtengo el rando de fechas de la fecha de proceso
    select r.fec_inicio, r.fec_final
      into ld_fec_desde, ld_fec_hasta
      from rrhh_param_org r
     where r.origen          = asi_origen
       and r.tipo_trabajador = ls_tipo_trabajador
       and r.fec_proceso     = adi_fec_proceso;
    
    if to_char(adi_fec_proceso, 'mm') = '02' then
       ln_dias_periodo := 30;
    else
       ln_dias_periodo := ld_fec_hasta - ld_fec_desde + 1;
    end if;
    
    if ln_dias_periodo > 31 then
       ln_dias_periodo := 30;
    end if;

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

    if ls_tipo_trabajador = is_tipo_trip then
       select count(distinct fa.fecha)
         into ln_dias_asistencia
         from fl_asistencia fa
        where fa.tripulante = asi_codtra
          and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

    elsif ls_tipo_trabajador in (is_tipo_des, is_tipo_ser) then

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

  -- Asistencia por fecha de proceso y tipo de planilla
  function of_dias_asist(
           asi_codtra        maestro.cod_trabajador%TYPE, 
           adi_fec_proceso   date,
           asi_origen        origen.cod_origen%TYPE,
           asi_tipo_planilla calculo.tipo_planilla%TYPE
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
    
    -- Obtengo la fecha de inicio de trabajo del trabajador
    select m.fec_ingreso, m.fec_cese, m.tipo_trabajador, tt.flag_ingreso_boleta
      into ld_fec_ing_trab, ld_fec_cese, ls_tipo_trabajador, ls_flag_tipo_sueldo
      from maestro m,
           tipo_trabajador tt
     where m.tipo_trabajador = tt.tipo_trabajador
       and m.cod_trabajador = asi_codtra;
    
    -- Obtengo el rando de fechas de la fecha de proceso
    select r.fec_inicio, r.fec_final
      into ld_fec_desde, ld_fec_hasta
      from rrhh_param_org r
     where r.origen          = asi_origen
       and r.tipo_trabajador = ls_tipo_trabajador
       and r.fec_proceso     = adi_fec_proceso
       and r.tipo_planilla   = asi_tipo_planilla;
    
    if to_char(adi_Fec_proceso, 'mm') = '02' then
       ln_dias_periodo := 30;
    else
       ln_dias_periodo := ld_fec_hasta - ld_fec_desde + 1;
    end if;
    
    if ln_dias_periodo > 31 then
       ln_dias_periodo := 30;
    end if;

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

    if ls_tipo_trabajador = is_tipo_trip then
       if asi_tipo_planilla = 'B' then
          -- Calculo los dias fijos
          select nvl(sum(f.nro_dias),0)
            into ln_dias_asistencia 
            from fl_dias_motorista f
           where f.anio            = to_number(to_char(adi_fec_proceso, 'yyyy'))
             and f.mes             = to_number(to_char(adi_fec_proceso, 'mm'))
             and f.cod_motorista   = asi_codtra;
       else
          select count(distinct fa.fecha)
            into ln_dias_asistencia
            from fl_asistencia fa
           where fa.tripulante = asi_codtra
             and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);
       end if;
    elsif ls_tipo_trabajador in (is_tipo_des, is_tipo_ser) then

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
  
  -- Asistencia por fecha de proceso para el caso de alimentacion
  function of_dias_asist_alimentacion(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
  ) return decimal is
  
    ln_dias_asistencia   number;
    ln_dias_periodo      number;
    
    ls_grp_dias_inasis         grupo_Calculo.Grupo_Calculo%TYPE;
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
    
    -- Obtengo la fecha de inicio de trabajo del trabajador
    select m.fec_ingreso, m.fec_cese, m.tipo_trabajador, tt.flag_ingreso_boleta
      into ld_fec_ing_trab, ld_fec_cese, ls_tipo_trabajador, ls_flag_tipo_sueldo
      from maestro m,
           tipo_trabajador tt
     where m.tipo_trabajador = tt.tipo_trabajador
       and m.cod_trabajador = asi_codtra;
    
    -- Obtengo el rando de fechas de la fecha de proceso
    select r.fec_inicio, r.fec_final
      into ld_fec_desde, ld_fec_hasta
      from rrhh_param_org r
     where r.origen          = asi_origen
       and r.tipo_trabajador = ls_tipo_trabajador
       and r.fec_proceso     = adi_fec_proceso;
    
    if to_char(adi_fec_proceso, 'mm') = '02' then
       ln_dias_periodo := 30;
    else
       ln_dias_periodo := ld_fec_hasta - ld_fec_desde + 1;
    end if;
    
    if ln_dias_periodo > 31 then
       ln_dias_periodo := 30;
    end if;
    
    ls_grp_dias_inasis := PKG_CONFIG.USF_GET_PARAMETER('GRUPO_ASISTENCIA_ALIMENTACION', '094');

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

    if ls_tipo_trabajador = is_tipo_trip then
       select count(distinct fa.fecha)
         into ln_dias_asistencia
         from fl_asistencia fa
        where fa.tripulante = asi_codtra
          and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

    elsif ls_tipo_trabajador in (is_tipo_des, is_tipo_ser) then

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
  
  -- Total de Horas Ordinarias
  function of_hras_normales(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
  ) return decimal is
  
    ln_dias_asistencia   number;
    ln_hrs_normal        number;
    ln_dias_periodo      number;
    
    ls_grp_dias_inasis         rrhhparam_cconcep.dias_inasis_dsccont%TYPE;
    ls_cnc_vacaciones          concepto.concep%TYPE;
    ln_dias                    number;
    ld_fec_desde               date ;
    ld_fec_hasta               date ;
    ln_faltas                  number ;
    ln_hras_obrero             NUMBER;
    ln_hras_campo              NUMBER;
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
    
    -- Obtengo la fecha de inicio de trabajo del trabajador
    select m.fec_ingreso, m.fec_cese, m.tipo_trabajador, tt.flag_ingreso_boleta
      into ld_fec_ing_trab, ld_fec_cese, ls_tipo_trabajador, ls_flag_tipo_sueldo
      from maestro m,
           tipo_trabajador tt
     where m.tipo_trabajador = tt.tipo_trabajador
       and m.cod_trabajador = asi_codtra;
    
    -- Obtengo el rando de fechas de la fecha de proceso
    select r.fec_inicio, r.fec_final
      into ld_fec_desde, ld_fec_hasta
      from rrhh_param_org r
     where r.origen          = asi_origen
       and r.tipo_trabajador = ls_tipo_trabajador
       and r.fec_proceso     = adi_fec_proceso;
       
    ln_dias_periodo := ld_fec_hasta - ld_fec_desde + 1;
    
    if ln_dias_periodo > 31 then
       ln_dias_periodo := 30;
    end if;

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

    if ls_tipo_trabajador = is_tipo_trip then
       select nvl(sum(fa.horas), 0)
         into ln_hrs_normal
         from fl_asistencia fa
        where fa.tripulante = asi_codtra
          and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

    elsif ls_tipo_trabajador in (is_tipo_des, is_tipo_ser) then

       select count(distinct p.fec_parte)
         into ln_dias_asistencia
         from tg_pd_destajo p,
              tg_pd_destajo_det pd
        where p.nro_parte = pd.nro_parte
          and pd.cod_trabajador = asi_codtra
          and trunc(p.fec_parte) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta)
          and p.flag_estado <> '0';
          
       ln_hrs_normal := ln_dias_asistencia * 8;

    else
        IF ls_flag_tipo_sueldo = 'J' THEN
           -- Dias Trabajados
           SELECT nvl(sum(nvl(a.hor_diu_nor,0) + nvl(a.hor_noc_nor,0)),0)
             INTO ln_hras_obrero
             FROM asistencia a
            WHERE a.cod_trabajador = asi_codtra
              AND trunc(a.fec_movim) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

           SELECT nvl(sum(a.hrs_normales),0)
             INTO ln_hras_campo
             FROM pd_jornal_campo a
            WHERE a.cod_trabajador = asi_codtra
              AND trunc(a.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

           ln_hrs_normal := ln_hras_campo + ln_hras_obrero;
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
           
           ln_hrs_normal := ln_dias_asistencia * 8;
           
        END IF;
    end if;

    if ln_hrs_normal > ln_dias_periodo * 8 then
       ln_hrs_normal := ln_dias_periodo * 8;
    end if;

    return(nvl(ln_hrs_normal,0)) ;
      
               
  end;

  -- Total de Horas Ordinarias
  function of_hras_extras(
           asi_codtra      maestro.cod_trabajador%TYPE, 
           adi_fec_proceso date,
           asi_origen      origen.cod_origen%TYPE
  ) return decimal is
  
    ln_hrs_extras        number;
    ld_fec_desde               date ;
    ld_fec_hasta               date ;
    ln_hras_obrero             NUMBER;
    ln_hras_campo              NUMBER;
    ld_fec_ing_trab            maestro.fec_ingreso%TYPE;
    ld_fec_cese                maestro.fec_cese%TYPE;
    ls_flag_tipo_sueldo        tipo_trabajador.flag_ingreso_boleta%TYPE;
    ls_tipo_trabajador         tipo_trabajador.tipo_trabajador%TYPE;
    
  begin
    
    --  ***********************************************************************
    --  ***   REALIZA CALCULO DE DIAS TRABAJADOS PARA CALCULO DE PLANILLA   ***
    --  ***********************************************************************
    
    -- Obtengo la fecha de inicio de trabajo del trabajador
    select m.fec_ingreso, m.fec_cese, m.tipo_trabajador, tt.flag_ingreso_boleta
      into ld_fec_ing_trab, ld_fec_cese, ls_tipo_trabajador, ls_flag_tipo_sueldo
      from maestro m,
           tipo_trabajador tt
     where m.tipo_trabajador = tt.tipo_trabajador
       and m.cod_trabajador = asi_codtra;
    
    -- Obtengo el rando de fechas de la fecha de proceso
    select r.fec_inicio, r.fec_final
      into ld_fec_desde, ld_fec_hasta
      from rrhh_param_org r
     where r.origen          = asi_origen
       and r.tipo_trabajador = ls_tipo_trabajador
       and r.fec_proceso     = adi_fec_proceso;
       
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

    if ls_tipo_trabajador = is_tipo_trip then
       select nvl(sum(case when fa.horas > 8 then fa.horas - 8 else 0 end), 0)
         into ln_hrs_extras
         from fl_asistencia fa
        where fa.tripulante = asi_codtra
          and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

    elsif ls_tipo_trabajador in (is_tipo_des, is_tipo_ser) then

       ln_hrs_extras := 0;

    else
        IF ls_flag_tipo_sueldo = 'J' THEN
           -- Dias Trabajados
           SELECT nvl(sum(nvl(a.hor_ext_diu_1,0) + nvl(a.hor_ext_diu_2,0) + nvl(a.hor_ext_noc_1,0) + nvl(a.hor_ext_noc_2,0)),0)
             INTO ln_hras_obrero
             FROM asistencia a
            WHERE a.cod_trabajador = asi_codtra
              AND trunc(a.fec_movim) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

           SELECT nvl(sum(nvl(a.hrs_extras_25,0) + nvl(a.hrs_extras_35,0) + nvl(a.hrs_noc_extras_35,0) + nvl(a.hrs_extras_100,0)),0)
             INTO ln_hras_campo
             FROM pd_jornal_campo a
            WHERE a.cod_trabajador = asi_codtra
              AND trunc(a.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);

           ln_hrs_extras := ln_hras_campo + ln_hras_obrero;
           
        ELSE
          
           ln_hrs_extras := 0;
           
        END IF;
    end if;

    return(nvl(ln_hrs_extras,0)) ;
      
               
  end;

  
  -- Function and procedure implementations
  procedure SP_RH_DISTRIBUCION_ASIENTOS(
           adi_fec_proceso     in     date                                   ,
           asi_cod_trabajador  in     maestro.cod_trabajador%type            ,
           asi_origen          in     origen.cod_origen%TYPE                 ,
           asi_cnta_ctbl       in     cntbl_cnta.cnta_ctbl%type              ,
           asi_flag_debhab     in     cntbl_asiento_det.flag_debhab%TYPE     ,
           ani_imp_movsol      in     calculo.imp_soles%type                 ,
           ani_imp_movdol      in     calculo.imp_soles%type                 ,
           asi_tipo_doc        in     doc_tipo.tipo_doc%type                 ,
           asi_nro_doc         in     calculo.nro_doc_cc%type                ,
           ani_nro_libro       in     cntbl_libro.nro_libro%type             ,
           asi_det_glosa       in     cntbl_pre_asiento_det.det_glosa%TYPE   ,
           ani_nro_provisional in     cntbl_libro.num_provisional%type       ,
           ani_item            in out cntbl_pre_asiento_det.item%type        ,
           asi_concep          in     concepto.concep%type                   
    ) is

    ln_total_dist           distribucion_cntble.nro_horas%type    ;

    ln_imp_sol              cntbl_Asiento_det.Imp_Movsol%TYPE;
    ln_imp_dol              cntbl_asiento_det.imp_movdol%TYPE;
    ln_tot_imp_sol          cntbl_asiento_det.imp_movsol%TYPE;
    ln_tot_imp_dol          cntbl_asiento_det.imp_movdol%TYPE;

    Cursor c_hist_distribucion is
      select hc.cod_trabajador, 
             decode(hc.cencos, null, m.cencos, hc.cencos) as cencos , 
             decode(hc.centro_benef, null, m.centro_benef, hc.centro_benef) as centro_benef,
             sum(hc.nro_horas) as nro_horas
        from historico_distrib_cntble hc ,
             maestro                  m
       where hc.cod_trabajador     = m.cod_trabajador
         and hc.cod_trabajador     = asi_cod_trabajador
         and to_number(to_char(hc.fec_calculo, 'yyyy')) = to_number(to_char(adi_fec_proceso, 'yyyy'))
         and to_number(to_char(hc.fec_calculo, 'mm'))   = to_number(to_char(adi_fec_proceso, 'mm'))
      group by hc.cod_trabajador, 
               decode(hc.cencos, null, m.cencos, hc.cencos), 
               decode(hc.centro_benef, null, m.centro_benef, hc.centro_benef)  
    order by cencos, centro_benef  ;


    begin

      select NVL(Sum(dc.nro_horas),0)
        into ln_total_dist
        from historico_distrib_cntble dc
       where dc.cod_trabajador     = asi_cod_trabajador
         and to_number(to_char(dc.fec_calculo, 'yyyy')) = to_number(to_char(adi_fec_proceso, 'yyyy'))
         and to_number(to_char(dc.fec_calculo, 'mm'))   = to_number(to_char(adi_fec_proceso, 'mm'))
      group by dc.cod_trabajador ;

      --inicializar
      ln_tot_imp_sol := 0; ln_tot_imp_dol := 0;

      For rc_hist_dist in c_hist_distribucion Loop --informacion historica

          /*Porcentaje de horas*/
          ln_imp_sol := Round(ani_imp_movsol * rc_hist_dist.nro_horas / ln_total_dist ,2) ;
          ln_imp_dol := Round(ani_imp_movdol * rc_hist_dist.nro_horas / ln_total_dist ,2) ;

          if ln_tot_imp_sol + ln_imp_sol > ani_imp_movsol then
             ln_imp_sol := ani_imp_movsol - ln_tot_imp_sol;
          end if;

          if ln_tot_imp_dol + ln_imp_dol > ani_imp_movdol then
             ln_imp_dol := ani_imp_movdol - ln_tot_imp_dol;
          end if;

          --acumula porcentaje de participacion
          ln_tot_imp_sol := Nvl(ln_tot_imp_sol,0) + ln_imp_sol ;
          ln_tot_imp_dol := Nvl(ln_tot_imp_dol,0) + ln_imp_dol ;

          --INSERT ASIENTOS DETALLE
          USP_SIGRE_RRHH.SP_RH_INSERT_ASIENTO(adi_fec_proceso     ,
                                              asi_origen    ,
                                              rc_hist_dist.cencos ,
                                              asi_cnta_ctbl      ,
                                              asi_tipo_doc        ,
                                              asi_nro_doc   ,
                                              asi_cod_trabajador   ,
                                              asi_flag_debhab     ,
                                              ani_nro_libro ,
                                              asi_det_glosa       ,
                                              ani_item           ,
                                              ani_nro_provisional ,
                                              ln_imp_sol    ,
                                              ln_imp_dol           ,
                                              asi_concep         ,
                                              rc_hist_dist.centro_benef, 
                                              rc_hist_dist.cod_trabajador);


      End Loop ;


      IF ln_tot_imp_sol <> ani_imp_movsol or ln_tot_imp_dol <> ani_imp_movdol THEN
        --HALLAR COSTO RESTANTE A CENTRO DE COSTO POR DEFECTO DE TRABAJADOR
        ln_imp_sol := NVL(Round(ani_imp_movsol - ln_tot_imp_sol,2),0) ;
        ln_imp_dol := NVL(Round(ani_imp_movdol - ln_tot_imp_dol,2),0) ;
        
        update cntbl_pre_asiento_det cad
           set cad.imp_movsol = cad.imp_movsol + ln_imp_sol,
               cad.imp_movdol = cad.imp_movsol + ln_imp_dol
         where cad.origen     = asi_origen
           and cad.nro_libro  = ani_nro_libro
           and cad.nro_provisional = ani_nro_provisional
           and cad.item            = ani_item - 1;


        --INSERT ASIENTOS DETALLE
        /*
        USP_SIGRE_RRHH.SP_RH_INSERT_ASIENTO(adi_fec_proceso     ,asi_origen       ,asi_cencos         ,asi_cnta_ctbl      ,
                                            asi_tipo_doc        ,asi_nro_doc      ,asi_cod_trabajador ,
                                            asi_flag_debhab     ,ani_nro_libro    ,asi_det_glosa     ,ani_item           ,
                                            ani_nro_provisional ,NVL(ln_imp_sol,0),NVL(ln_imp_dol,0)   ,asi_concep         ,
                                            asi_centro_benef    , asi_cod_trabajador);
       */

      END IF ;


    end ;
  
  
  procedure SP_RH_INSERT_ASIENTO(
         adi_fec_proceso    in date                                   ,
         asi_origen         in origen.cod_origen%type                 ,
         asi_cencos         in centros_costo.cencos%type              ,
         asi_cnta_ctbl      in cntbl_cnta.cnta_ctbl%type              ,
         asi_tipo_doc       in doc_tipo.tipo_doc%type                 ,
         asi_nro_doc        in calculo.nro_doc_cc%type                ,
         asi_cod_relacion   in cntbl_asiento_det.cod_relacion%TYPE   ,
         asi_flag_debhab    in cntbl_asiento_det.flag_debhab%TYPE     ,
         ani_nro_libro      in cntbl_libro.nro_libro%type             ,
         asi_glosa_det      in cntbl_pre_asiento_det.det_glosa%TYPE   ,
         ani_item           in out cntbl_pre_asiento_det.item%type    ,
         ani_num_prov       in cntbl_libro.num_provisional%type       ,
         ani_imp_soles      in cntbl_pre_asiento_det.imp_movsol%type  ,
         ani_imp_dolares    in cntbl_pre_asiento_det.imp_movsol%type  ,
         asi_concep         in concepto.concep%type                   ,
         asi_cbenef         in maestro.centro_benef%type              ,
         asi_cod_trabajador in maestro.cod_trabajador%TYPE
  ) is

  ls_grupo_cntbl        centros_costo.grp_cntbl%type ;
  ls_cnta_cntbl         cntbl_cnta.cnta_ctbl%type    ;
  ls_flag_cencos        cntbl_cnta.flag_cencos%type  ;
  ls_flag_doc           cntbl_cnta.flag_doc_ref%type ;
  ls_flag_crel          cntbl_cnta.flag_codrel%type  ;
  ls_flag_centro_benef  cntbl_cnta.flag_centro_benef%type  ;
  ls_cencos             centros_costo.cencos%type    ;
  ls_tipo_doc           doc_tipo.tipo_doc%Type       ;
  ls_nro_doc            calculo.nro_doc_cc%type      ;
  ls_cod_relacion       maestro.cod_trabajador%type  ;
  ln_count              Number                       ;
  ls_centro_benef       maestro.centro_benef%type    ;

  begin


    if Substr(asi_cnta_ctbl,1,1) = '9' then --es una cuenta de gasto

       if asi_cencos is null then
          --inserto en tabla de errores inconsistencia de grupo contable de centros de costo
          Insert Into TT_RH_INC_ASIENTOS(
                 cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,
                 grp_cntbl,obs)
          Values(
                 asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,
                 asi_flag_debhab ,asi_cnta_ctbl ,ls_grupo_cntbl ,'Centro de costo no puede ser nulo' ) ;
           --
           RAISE_APPLICATION_ERROR(-20000,'La Cuenta Contable ' || asi_cnta_ctbl || ' pide como referencia centro de costo, pero el Centro de Costo del trabajador '
                                           ||asi_cod_relacion||' esta vacio, por favor verifique.'
                                           || chr(13) || 'Concepto: ' || asi_concep);
           return ;
       end if ;

       select count(*)
         into ln_count
         from matriz_transf_cntbl_cencos mt
        where mt.org_cnta_ctbl = asi_cnta_ctbl
          and mt.cencos        = asi_cencos
          and mt.flag_estado   = '1';

       if ln_count = 0 then
          ls_cnta_cntbl := asi_cnta_ctbl ;
       else
          select dst_cnta_ctbl
            into ls_cnta_cntbl
            from matriz_transf_cntbl_cencos mt
           where mt.org_cnta_ctbl = asi_cnta_ctbl
             and mt.cencos        = asi_cencos
             and mt.flag_estado   = '1';

          if ls_cnta_cntbl is null then
             --inserto en tabla de errores inconsistencia de grupo contable de centros de costo
             Insert Into TT_RH_INC_ASIENTOS(
                    cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
             Values(
                    asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,
                    asi_cnta_ctbl ,ls_grupo_cntbl ,'Centro de costo y Cuenta Contable NO TIENE Cuenta Destino, '
                                  || 'en la matriz de dstribucion, por favor verifique' ) ;

             RAISE_APPLICATION_ERROR(-20000,'Centro de costo y Cuenta Contable NO TIENE Cuenta Destino, '
                                         || 'en la matriz de dstribucion, por favor verifique.'
                                         || chr(13) || 'Centro Costo: ' || asi_cencos
                                         || chr(13) || 'Cnta Cntbl: ' || asi_cnta_ctbl);
                                         
             --
             return ;
          end if ;
        end if ;
    else
       ls_cnta_cntbl := asi_cnta_ctbl ;
    end if;

    --verifico si nueva cuenta existe o esta activa
    select count(*)
      into ln_count
      from cntbl_cnta c
     where c.cnta_ctbl = ls_cnta_cntbl
       and c.flag_estado = '1' ;

    if ln_count = 0 then
       --inserto en tabla de errores inconsistencia de cnta cntble inexistente o desactivada
       Insert Into TT_RH_INC_ASIENTOS(
              cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
       Values(
              asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,
              ls_cnta_cntbl ,ls_grupo_cntbl ,'Cuenta Contable no Existe o Esta Desactivada, por favor verifique' ) ;
              
       RAISE_APPLICATION_ERROR(-20000,'La Cuenta Contable '||ls_cnta_cntbl||' es inexistente o inactiva');
      return ;
    end if ;

    --verificar valores de datos requeridos segun cuenta
    select Nvl(c.flag_cencos,'0'),Nvl(c.flag_doc_ref,'0'),Nvl(c.flag_codrel,'0'), Nvl(c.flag_centro_benef,'0')
      into ls_flag_cencos,ls_flag_doc,ls_flag_crel,ls_flag_centro_benef
      from cntbl_cnta c
     where c.cnta_ctbl = ls_cnta_cntbl ;


    if ls_flag_cencos = '1' then --requiere centro de costo
       ls_cencos := asi_cencos ;
    else
       ls_cencos := null ;
    end if ;

    if ls_flag_centro_benef = '1' then --requiere centro de beneficio
       ls_centro_benef := asi_cbenef ;
    else
       ls_centro_benef := null ;
    end if ;

    if ls_flag_doc = '1' then --requiere docuemnto de referencia
       if asi_tipo_doc is null then --tipo de documento no puede ser nulo
          RAISE_APPLICATION_ERROR(-20000,'El Concepto ' || asi_concep || ' tiene la Cuenta Contable ' || ls_cnta_cntbl 
                                       || ' la cual esta configurada para que pida Documento de Referencia.'
                                       || chr(13) || 'Cod Trabajador: ' || asi_cod_trabajador
                                       || chr(13) || 'Tipo Doc: ' || ls_tipo_doc
                                       || chr(13) || 'Nro Doc: ' || ls_nro_doc);
          Insert Into TT_RH_INC_ASIENTOS(
                 cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
          Values(
                 asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,ls_cnta_cntbl ,
                 ls_grupo_cntbl ,'Cuenta Contable Requiere tipo de Documento' ) ;
          return ;
       else
          ls_tipo_doc := asi_tipo_doc ;
       end if ;

       if asi_nro_doc is null then --nro de documento no puede ser nulo
          --insertar en tabla temporal problema de documento
          Insert Into TT_RH_INC_ASIENTOS(
                 cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
          Values(
                 asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,ls_cnta_cntbl ,
                 ls_grupo_cntbl ,'Cuenta Contable Requiere Nro de Documento' ) ;
          return ;
       else
          ls_nro_doc := asi_nro_doc ;
       end if ;
    else --no se coloca tipo ni nro de documento
       ls_tipo_doc := null ;
       ls_nro_doc  := null ;
    end if ;

    if ls_flag_crel = '1' then --requiere codigo de relacion
       ls_cod_relacion := asi_cod_relacion ;
    else
       ls_cod_relacion := null ;
    end if ;



    --actualiza asiento si ya existe
    Update cntbl_pre_asiento_det c
       set c.imp_movsol = c.imp_movsol + ani_imp_soles,
           c.imp_movdol = c.imp_movdol + ani_imp_dolares
      Where c.origen                = asi_origen
        and c.nro_libro             = ani_nro_libro
        and c.nro_provisional       = ani_num_prov
        and c.cnta_ctbl             = ls_cnta_cntbl
        and c.fec_cntbl             = adi_fec_proceso
        and c.flag_debhab           = asi_flag_debhab
        and Nvl(c.cencos,' ')       = Nvl(ls_cencos,' ')
        and Nvl(c.tipo_docref,' ')  = Nvl(ls_tipo_doc,' ')
        and Nvl(c.nro_docref1,' ')  = Nvl(ls_nro_doc,' ')
        and Nvl(c.cod_relacion,' ') = Nvl(ls_cod_relacion,' ')
        and Nvl(c.centro_benef,' ') = Nvl(ls_centro_benef,' ')
        and nvl(c.det_glosa, ' ')   = nvl(asi_glosa_det, ' ')
        and c.concep                = asi_concep;



    IF SQL%NOTFOUND THEN
       --CONTADOR DE ITEM
       --incrementa contador del detalle

       Insert Into cntbl_pre_asiento_det   (
              origen      ,nro_libro ,nro_provisional   ,item        ,det_glosa ,flag_debhab ,
              cnta_ctbl   ,fec_cntbl   ,tipo_docref     ,nro_docref1 ,cencos    ,imp_movsol  ,
              imp_movdol  ,cod_relacion, centro_benef   ,concep )
       Values(
              asi_origen     ,ani_nro_libro   ,ani_num_prov   ,ani_item    ,asi_glosa_det ,asi_flag_debhab ,
              ls_cnta_cntbl ,adi_fec_proceso ,ls_tipo_doc     ,ls_nro_doc  ,ls_cencos     ,ani_imp_soles   ,
              ani_imp_dolares,ls_cod_relacion, ls_centro_benef, asi_concep );
       
       ani_item := ani_item + 1;


    END IF ;
    
  END;
  
  procedure PROCESAR_GRATIF_TRIPULANTE (
    asi_codtra             in maestro.cod_trabajador%TYPE,
    asi_codusr             in usuario.cod_usr%TYPE,
    adi_fec_proceso        in date,
    asi_origen             in origen.cod_origen%TYPE
  ) IS
    
    ln_count               number;
    ln_tipcam              calendario.vta_dol_prom%TYPE;
    ls_concepto            concepto.concep%TYPE;
    ln_imp_soles           calculo.imp_soles%TYPE;
    ln_imp_dolar           calculo.imp_soles%TYPE;
    ls_cod_afp             maestro.cod_afp%TYPE;
    ld_fec_nac             maestro.fec_nacimiento%TYPE;
    ln_judicial            maestro.porc_judicial%TYPE;
    ln_judicial_utl        maestro.porc_jud_util%TYPE;
  
  begin
    --  *********************************************************
    --  ***   CALCULA LAS GRATIFICACIONES DE LOS TRIPULANTES   ***
    --  *********************************************************
    -- Obtengo el tipo de cambio correspondiente
    select nvl(tc.vta_dol_prom,1)
      into ln_tipcam
      from calendario tc
     where trunc(tc.fecha) = adi_fec_proceso ;

    IF ln_tipcam = 0 THEN
       RAISE_APPLICATION_ERROR(-20000, 'No ha especificado tipo de cambio para ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
    END IF;

    -- Obtengo los datos del maestro de trabajadores
    select m.cod_afp, m.fec_nacimiento, nvl(m.porc_judicial,0) ,
       nvl(m.porc_jud_util,0) 
      into ls_cod_afp, ld_fec_nac, ln_judicial, ln_judicial_utl
      from maestro m
     where m.cod_trabajador = asi_codtra;
     
    -- Verifico que no exista en calculo ninguna planilla pendiente de tripulantes
    select count(*)
      into ln_count
      from calculo c,
           maestro m
     where c.cod_trabajador = m.cod_trabajador
       and m.tipo_trabajador = usp_sigre_rrhh.is_tipo_trip
       and to_char(c.fec_proceso, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm')
       and c.cod_trabajador                 = asi_codtra;
    
    if ln_count > 0 then
       RAISE_APPLICATION_ERROR(-20000, 'Existen aun planillas sin cerrar para TRIPULANTES. Para procesar Gratificaciones es necesario que todas las planillas esten cerradas. '
                         || chr(13) || 'Periodo: ' || to_char(adi_fec_proceso, 'yyyy/mm')
                         || chr(13) || 'Registros Encontrados: ' || trim(to_char(ln_count)));
    end if;
    
    -- Limpio la tabla calculo para que no haya nada
    delete calculo c
    where c.cod_trabajador = asi_codtra
      and c.tipo_planilla = USP_SIGRE_RRHH.is_planilla_gratif_tri
      and c.fec_proceso = adi_fec_proceso;


    -- Calculo el importe total
    select nvl(sum(hc.imp_soles),0)
      into ln_imp_soles
      from historico_calculo hc,
           grupo_calculo_det gcd
     where hc.concep          = gcd.concepto_calc
       and gcd.grupo_calculo  = usp_sigre_rrhh.is_grp_gratif_tri 
       and hc.cod_trabajador  = asi_codtra
       and to_char(hc.fec_calc_plan, 'yyyymm') = to_char(adi_Fec_proceso, 'yyyymm');
    
    SELECT gc.concepto_gen
      into ls_concepto
      from grupo_calculo gc
     where gc.grupo_calculo = is_grp_gratif_tri;
    
    if ls_concepto is null then
       RAISE_APPLICATION_ERROR(-20000, 'No existe concepto de planilla enlazado al grupo de calculo ' || is_grp_gratif_tri);
    end if;
    
    -- Si el importe es cero entonces no hay nada mas que hacer
    if ln_imp_soles = 0 then return; end if;
    
    -- Calculo el proporcional
    ln_imp_soles := ln_imp_soles * 0.1666;

    -- Calculo en dolares
    ln_imp_dolar := ln_imp_soles / ln_tipcam ;
          
    UPDATE calculo
       SET horas_trabaj = null,
           horas_pag    = null,
           imp_soles    = imp_soles + ln_imp_soles,
           imp_dolar    = imp_dolar + ln_imp_dolar
      WHERE cod_trabajador = asi_codtra
        AND concep         = ls_concepto
        and tipo_planilla  = 'G';
          
    if SQL%NOTFOUND then
        insert into calculo (
          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
        values (
          asi_codtra, ls_concepto, adi_fec_proceso, null, null,
          null, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, 'G' ) ;
    end if;
    
    -- Inserto la bonificacion extraordinaria
    if to_number(to_char(adi_fec_proceso, 'yyyy')) between 2015 and 2099 then
       ln_imp_soles := ln_imp_soles * USP_SIGRE_RRHH.in_porc_bonif_ext;
       ln_imp_dolar := ln_imp_soles / ln_tipcam;
             
       update calculo c
          set c.imp_soles   = ln_imp_soles,
              c.imp_dolar   = ln_imp_dolar
        where c.cod_trabajador = asi_codtra
          and c.concep         = USP_SIGRE_RRHH.is_cnc_bonif_ext
          and c.tipo_planilla  = USP_SIGRE_RRHH.is_planilla_gratif_tri;
            
       if SQL%NOTFOUND then
          Insert Into calculo(
                 cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                 dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item, 
                 tipo_planilla)
          Values(
                 asi_codtra, USP_SIGRE_RRHH.is_cnc_bonif_ext, adi_fec_proceso, 0, 0, 0, 
                 ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                 USP_SIGRE_RRHH.is_planilla_gratif_tri);
       end if;
    end if;
    
    -- Elimino toda participacion de pesca si lo hubiera
    delete calculo c
    where c.concep = usp_sigre_rrhh.is_cnc_partic_pesca
      and c.cod_trabajador = asi_codtra
      and c.tipo_planilla = USP_SIGRE_RRHH.is_planilla_gratif_tri;
    
    -- Ganancias Variables
    usp_rh_cal_ganancias_variables( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam , USP_SIGRE_RRHH.is_tipo_trip ,  USP_SIGRE_RRHH.is_planilla_gratif_tri) ;
    -- Elimino el concepto de participacion de pesca para evitar
    delete calculo c
    where c.cod_trabajador = asi_codtra
      and c.concep         = usp_sigre_rrhh.is_cnc_partic_pesca;

    -- Ahora las sumas
    usp_rh_cal_ganancia_total( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_ingreso, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    --  REALIZA CALCULOS DE DESCUENTOS POR TRABAJADOR
    /*
    if ls_cod_afp is null then
       usp_rh_cal_snp ( asi_codtra, adi_fec_proceso, asi_origen, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;
    else
       usp_rh_cal_afp ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, in_ano_tope_seg_inv, ld_fec_nac, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;
    end if ;
    */
    -- Descuentos variables
    usp_rh_cal_descuento_variable( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;    

    -- Judicial
    usp_rh_cal_porcentaje_judicial( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ln_judicial, ln_judicial_utl, asi_codusr, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    -- Cuenta corriente
    usp_rh_cal_cuenta_corriente
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ,is_cnc_total_ingreso, USP_SIGRE_RRHH.is_planilla_gratif_tri);

    -- Descuento total
    usp_rh_cal_descuento_total
      ( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_dscto, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    usp_rh_cal_total_pagado
      ( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_ingreso, is_cnc_total_dscto, is_cnc_total_pagado, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    --  REALIZA CALCULOS DE APORTACIONES PATRONALES
    usp_rh_cal_apo_sctr_ipss
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    usp_rh_cal_apo_sctr_onp
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    
    -- Aportacion que se hace al actual REP 5% que le corresponde de ahora en adelante a los tripulantes
    --usp_rh_cal_apo_rep( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    --elimina calculos en cero
    delete from calculo hc
      where hc.cod_trabajador = asi_codtra
        and hc.fec_proceso    = adi_fec_proceso
        and nvl(imp_soles,0)  = 0
        and nvl(imp_dolar,0)  = 0
        and hc.concep         <> is_cnc_total_pagado
        and tipo_planilla     = USP_SIGRE_RRHH.is_planilla_gratif_tri ;
     
    -- Elimino tambien todo aquellos que no tienen neto pagado
    delete calculo c
    where c.cod_trabajador not in (select distinct cod_trabajador
                                      from calculo t
                                      where concep = is_cnc_total_ingreso
                                        and t.tipo_planilla = USP_SIGRE_RRHH.is_planilla_gratif_tri )
       and c.cod_trabajador = asi_codtra
       and c.tipo_planilla  = USP_SIGRE_RRHH.is_planilla_gratif_tri ;
                                      
    -- Aportacion Especial Cred EPS
    usp_rh_cal_apo_total
      ( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_aportes, USP_SIGRE_RRHH.is_planilla_gratif_tri ) ;

    --elimina calculos en cero
    delete from calculo hc
      where hc.cod_trabajador = asi_codtra
        and hc.fec_proceso    = adi_fec_proceso
        and nvl(imp_soles,0)  = 0
        and nvl(imp_dolar,0)  = 0
        and hc.concep         <> is_cnc_total_pagado;

  end;
  
  
  -- Procesa la planilla de Vacaciones de los tripulantes
  procedure PROCESAR_VACAC_TRIPULANTE (
    asi_codtra             in maestro.cod_trabajador%TYPE,
    asi_codusr             in usuario.cod_usr%TYPE,
    adi_fec_proceso        in date,
    asi_origen             in origen.cod_origen%TYPE
  ) IS
    
    ln_count               number;
    ln_tipcam              calendario.vta_dol_prom%TYPE;
    ls_concepto            concepto.concep%TYPE;
    ln_imp_soles           calculo.imp_soles%TYPE;
    ln_imp_dolar           calculo.imp_soles%TYPE;
    ls_cod_afp             maestro.cod_afp%TYPE;
    ld_fec_nac             maestro.fec_nacimiento%TYPE;
    ln_judicial            maestro.porc_judicial%TYPE;
    ln_judicial_utl        maestro.porc_jud_util%TYPE;
    ls_tipo_trabajador     maestro.tipo_trabajador%TYPE;
  
  begin
    --  *********************************************************
    --  ***   CALCULA LAS VACACIONES DE LOS TRIPULANTES   ***
    --  *********************************************************
    -- Obtengo el tipo de cambio correspondiente
    select nvl(tc.vta_dol_prom,1)
      into ln_tipcam
      from calendario tc
     where trunc(tc.fecha) = adi_fec_proceso ;

    IF ln_tipcam = 0 THEN
       RAISE_APPLICATION_ERROR(-20000, 'No ha especificado tipo de cambio para ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
    END IF;

    -- Obtengo los datos del maestro de trabajadores
    select m.cod_afp, m.fec_nacimiento, nvl(m.porc_judicial,0) ,
           nvl(m.porc_jud_util,0), m.tipo_trabajador
      into ls_cod_afp, ld_fec_nac, ln_judicial, ln_judicial_utl,
           ls_tipo_trabajador
      from maestro m
     where m.cod_trabajador = asi_codtra;
     
    -- Verifico que no exista en calculo ninguna planilla pendiente de tripulantes
    select count(*)
      into ln_count
      from calculo c,
           maestro m
     where c.cod_trabajador = m.cod_trabajador
       and m.tipo_trabajador = usp_sigre_rrhh.is_tipo_trip
       and to_char(c.fec_proceso, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm')
       and c.cod_trabajador                 = asi_codtra;
    
    if ln_count > 0 then
       RAISE_APPLICATION_ERROR(-20000, 'Existen aun planillas sin cerrar para TRIPULANTES. Para procesar Gratificaciones es necesario que todas las planillas esten cerradas. '
                         || chr(13) || 'Periodo: ' || to_char(adi_fec_proceso, 'yyyy/mm')
                         || chr(13) || 'Registros Encontrados: ' || trim(to_char(ln_count)));
    end if;

    -- Calculo el importe total
    select nvl(sum(hc.imp_soles),0)
      into ln_imp_soles
      from historico_calculo hc,
           grupo_calculo_det gcd
     where hc.concep          = gcd.concepto_calc
       and gcd.grupo_calculo  = usp_sigre_rrhh.is_grp_VACAC_TRI 
       and hc.cod_trabajador  = asi_codtra
       and to_char(hc.fec_calc_plan, 'yyyymm') = to_char(adi_Fec_proceso, 'yyyymm');
    
    SELECT gc.concepto_gen
      into ls_concepto
      from grupo_calculo gc
     where gc.grupo_calculo = usp_sigre_rrhh.is_grp_VACAC_TRI;
    
    if ls_concepto is null then
       RAISE_APPLICATION_ERROR(-20000, 'No existe concepto de planilla enlazado al grupo de calculo ' || usp_sigre_rrhh.is_grp_VACAC_TRI);
    end if;
    
    -- Si el importe es cero entonces no hay nada mas que hacer
    if ln_imp_soles = 0 then return; end if;
    
    -- Calculo el proporcional
    ln_imp_soles := ln_imp_soles * 8.33 / 100;

    -- Calculo en dolares
    ln_imp_dolar := ln_imp_soles / ln_tipcam ;
          
    UPDATE calculo
       SET horas_trabaj = null,
           horas_pag    = null,
           imp_soles    = imp_soles + ln_imp_soles,
           imp_dolar    = imp_dolar + ln_imp_dolar
      WHERE cod_trabajador = asi_codtra
        AND concep         = ls_concepto
        and tipo_planilla  = usp_sigre_rrhh.is_planilla_VACAC_tri;
          
    if SQL%NOTFOUND then
        insert into calculo (
          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
        values (
          asi_codtra, ls_concepto, adi_fec_proceso, null, null,
          null, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, usp_sigre_rrhh.is_planilla_VACAC_tri ) ;
    end if;
    
    
    -- Ahora las sumas
    usp_rh_cal_ganancia_total( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_ingreso, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;

    --  REALIZA CALCULOS DE DESCUENTOS POR TRABAJADOR
    if ls_cod_afp is null then
       usp_rh_cal_snp ( asi_codtra, adi_fec_proceso, asi_origen, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;
    else
       usp_rh_cal_afp ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, in_ano_tope_seg_inv, ld_fec_nac, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;
    end if ;
    

    -- Cuenta corriente
    usp_rh_cal_cuenta_corriente
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ,is_cnc_total_ingreso, USP_SIGRE_RRHH.is_planilla_VACAC_tri);

    -- Essalud Vida
    usp_rh_cal_essalud_vida
       ( asi_codtra, asi_origen, ln_tipcam, adi_fec_proceso,ls_tipo_trabajador, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;
       
    -- Descuentos variables
    usp_rh_cal_descuento_variable( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;    

    -- Judicial
    usp_rh_cal_porcentaje_judicial( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ln_judicial, ln_judicial_utl, asi_codusr, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;

    -- Descuento total
    usp_rh_cal_descuento_total
      ( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_dscto, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;

    usp_rh_cal_total_pagado
      ( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_ingreso, is_cnc_total_dscto, is_cnc_total_pagado, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;

    --  REALIZA CALCULOS DE APORTACIONES PATRONALES
    usp_rh_cal_apo_sctr_ipss
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;

    usp_rh_cal_apo_sctr_onp
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;
      
    --  Otras Aportaciones indicadas por el trabajador
    usp_rh_cal_otras_aport( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen , is_cnc_total_ingreso, USP_SIGRE_RRHH.is_planilla_VACAC_tri) ;

    
    -- Aportacion que se hace al actual REP 5% que le corresponde de ahora en adelante a los tripulantes
    usp_rh_cal_apo_rep( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;
    
    -- Calculo de ESSALUD
    usp_rh_cal_apo_essalud( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_tipo_trabajador, '0', USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;


    --elimina calculos en cero
    delete from calculo hc
      where hc.cod_trabajador = asi_codtra
        and hc.fec_proceso    = adi_fec_proceso
        and nvl(imp_soles,0)  = 0
        and nvl(imp_dolar,0)  = 0
        and hc.concep         <> is_cnc_total_pagado
        and tipo_planilla     = USP_SIGRE_RRHH.is_planilla_VACAC_tri ;
     
    -- Elimino tambien todo aquellos que no tienen neto pagado
    delete calculo c
    where c.cod_trabajador not in (select distinct cod_trabajador
                                      from calculo t
                                      where concep = is_cnc_total_ingreso
                                        and t.tipo_planilla = USP_SIGRE_RRHH.is_planilla_VACAC_tri )
       and c.cod_trabajador = asi_codtra
       and c.tipo_planilla  = USP_SIGRE_RRHH.is_planilla_gratif_tri ;
                                      
    -- Aportacion Especial Cred EPS
    usp_rh_cal_apo_total( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_aportes, USP_SIGRE_RRHH.is_planilla_VACAC_tri ) ;

    --elimina calculos en cero
    delete from calculo hc
      where hc.cod_trabajador = asi_codtra
        and hc.fec_proceso    = adi_fec_proceso
        and nvl(imp_soles,0)  = 0
        and nvl(imp_dolar,0)  = 0
        and hc.concep         <> is_cnc_total_pagado;

  end;

  -- Procesa la planilla de CTS de los tripulantes
  procedure PROCESAR_CTS_TRIPULANTE (
    asi_codtra             in maestro.cod_trabajador%TYPE,
    asi_codusr             in usuario.cod_usr%TYPE,
    adi_fec_proceso        in date,
    asi_origen             in origen.cod_origen%TYPE
  ) IS
    
    ln_count               number;
    ln_tipcam              calendario.vta_dol_prom%TYPE;
    ls_concepto            concepto.concep%TYPE;
    ln_imp_soles           calculo.imp_soles%TYPE;
    ln_imp_dolar           calculo.imp_soles%TYPE;
    ls_cod_afp             maestro.cod_afp%TYPE;
    ld_fec_nac             maestro.fec_nacimiento%TYPE;
    ln_judicial            maestro.porc_judicial%TYPE;
    ln_judicial_utl        maestro.porc_jud_util%TYPE;
  
  begin
    --  *********************************************************
    --  ***   CALCULA EL CTS DE LOS TRIPULANTES   ***
    --  *********************************************************
    -- Obtengo el tipo de cambio correspondiente
    select nvl(tc.vta_dol_prom,1)
      into ln_tipcam
      from calendario tc
     where trunc(tc.fecha) = adi_fec_proceso ;

    IF ln_tipcam = 0 THEN
       RAISE_APPLICATION_ERROR(-20000, 'No ha especificado tipo de cambio para ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
    END IF;

    -- Obtengo los datos del maestro de trabajadores
    select m.cod_afp, m.fec_nacimiento, nvl(m.porc_judicial,0) ,
       nvl(m.porc_jud_util,0) 
      into ls_cod_afp, ld_fec_nac, ln_judicial, ln_judicial_utl
      from maestro m
     where m.cod_trabajador = asi_codtra;
     
    -- Verifico que no exista en calculo ninguna planilla pendiente de tripulantes
    select count(*)
      into ln_count
      from calculo c,
           maestro m
     where c.cod_trabajador                 = m.cod_trabajador
       and m.tipo_trabajador                = usp_sigre_rrhh.is_tipo_trip
       and to_char(c.fec_proceso, 'yyyymm') = to_char(adi_fec_proceso, 'yyyymm')
       and c.cod_trabajador                 = asi_codtra;
    
    if ln_count > 0 then
       RAISE_APPLICATION_ERROR(-20000, 'Existen aun planillas sin cerrar para TRIPULANTES. Para procesar Gratificaciones es necesario que todas las planillas esten cerradas. '
                         || chr(13) || 'Periodo: ' || to_char(adi_fec_proceso, 'yyyy/mm')
                         || chr(13) || 'Registros Encontrados: ' || trim(to_char(ln_count)));
    end if;

    -- Calculo el importe total
    select nvl(sum(hc.imp_soles),0)
      into ln_imp_soles
      from historico_calculo hc,
           grupo_calculo_det gcd
     where hc.concep          = gcd.concepto_calc
       and gcd.grupo_calculo  = usp_sigre_rrhh.is_grp_CTS_TRI 
       and hc.cod_trabajador  = asi_codtra
       and to_char(hc.fec_calc_plan, 'yyyymm') = to_char(adi_Fec_proceso, 'yyyymm');
    
    SELECT gc.concepto_gen
      into ls_concepto
      from grupo_calculo gc
     where gc.grupo_calculo = usp_sigre_rrhh.is_grp_CTS_TRI;
    
    if ls_concepto is null then
       RAISE_APPLICATION_ERROR(-20000, 'No existe concepto de planilla enlazado al grupo de calculo ' || usp_sigre_rrhh.is_grp_CTS_TRI);
    end if;
    
    -- Si el importe es cero entonces no hay nada mas que hacer
    if ln_imp_soles = 0 then return; end if;
    
    -- Calculo el proporcional
    ln_imp_soles := ln_imp_soles * 8.33 / 100;

    -- Calculo en dolares
    ln_imp_dolar := ln_imp_soles / ln_tipcam ;
          
    UPDATE calculo
       SET horas_trabaj = null,
           horas_pag    = null,
           imp_soles    = imp_soles + ln_imp_soles,
           imp_dolar    = imp_dolar + ln_imp_dolar
      WHERE cod_trabajador = asi_codtra
        AND concep         = ls_concepto
        and tipo_planilla  = usp_sigre_rrhh.is_grp_CTS_TRI;
          
    if SQL%NOTFOUND then
        insert into calculo (
          cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
        values (
          asi_codtra, ls_concepto, adi_fec_proceso, null, null,
          null, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, usp_sigre_rrhh.is_planilla_CTS_tri ) ;
    end if;
    
    
    -- Ahora las sumas
    usp_rh_cal_ganancia_total( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_ingreso, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    --  REALIZA CALCULOS DE DESCUENTOS POR TRABAJADOR
    if ls_cod_afp is null then
       usp_rh_cal_snp ( asi_codtra, adi_fec_proceso, asi_origen, USP_SIGRE_RRHH.is_grp_CTS_TRI ) ;
    else
       usp_rh_cal_afp ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, in_ano_tope_seg_inv, ld_fec_nac, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;
    end if ;
    
    -- Judicial
    usp_rh_cal_porcentaje_judicial( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ln_judicial, ln_judicial_utl, asi_codusr, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    -- Cuenta corriente
    usp_rh_cal_cuenta_corriente
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ,is_cnc_total_ingreso, USP_SIGRE_RRHH.is_planilla_CTS_tri);

    -- Descuentos variables
    usp_rh_cal_descuento_variable
       ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    -- Descuento total
    usp_rh_cal_descuento_total
      ( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_dscto, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    usp_rh_cal_total_pagado
      ( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_ingreso, is_cnc_total_dscto, is_cnc_total_pagado, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    --  REALIZA CALCULOS DE APORTACIONES PATRONALES
    usp_rh_cal_apo_sctr_ipss
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    usp_rh_cal_apo_sctr_onp
      ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    
    -- Aportacion que se hace al actual REP 5% que le corresponde de ahora en adelante a los tripulantes
    usp_rh_cal_apo_rep( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    --elimina calculos en cero
    delete from calculo hc
      where hc.cod_trabajador = asi_codtra
        and hc.fec_proceso    = adi_fec_proceso
        and nvl(imp_soles,0)  = 0
        and nvl(imp_dolar,0)  = 0
        and hc.concep         <> is_cnc_total_pagado
        and tipo_planilla     = USP_SIGRE_RRHH.is_planilla_CTS_tri ;
     
    -- Elimino tambien todo aquellos que no tienen neto pagado
    delete calculo c
    where c.cod_trabajador not in (select distinct cod_trabajador
                                      from calculo t
                                      where concep = is_cnc_total_ingreso
                                        and t.tipo_planilla = USP_SIGRE_RRHH.is_planilla_CTS_tri )
       and c.cod_trabajador = asi_codtra
       and c.tipo_planilla  = USP_SIGRE_RRHH.is_planilla_CTS_tri ;
                                      
    -- Aportacion Especial Cred EPS
    usp_rh_cal_apo_total( asi_codtra, adi_fec_proceso, asi_origen, is_cnc_total_aportes, USP_SIGRE_RRHH.is_planilla_CTS_tri ) ;

    --elimina calculos en cero
    delete from calculo hc
      where hc.cod_trabajador = asi_codtra
        and hc.fec_proceso    = adi_fec_proceso
        and nvl(imp_soles,0)  = 0
        and nvl(imp_dolar,0)  = 0
        and hc.concep         <> is_cnc_total_pagado;

  end;

  -- Procesa la planilla de historico de calculo
  procedure usp_rh_cal_borra_hist_calculo (
      asi_origen         in origen.cod_origen%TYPE,
      adi_fec_proceso    in date,
      asi_tipo_trabaj    in tipo_trabajador.tipo_trabajador %TYPE,
      asi_tipo_planilla  in calculo.tipo_planilla%TYPE
    
  ) IS
  
    ls_doc_autom    rrhhparam.doc_reg_automatico%TYPE;
    
  begin
    SELECT doc_reg_automatico
      INTO ls_doc_autom
      FROM rrhhparam
     WHERE reckey = '1';

    --  *****************************************************************
    --  ***   ELIMINA MOVIMIENTO DE LA PLANILLA HISTORICA CALCULADA   ***
    --  *****************************************************************
    
    -- Borro la glosa del historico 
    delete historico_calculo_glosa t
     where t.cod_trabajador in (select distinct cod_trabajador 
                                  from historico_calculo hc
                                 where hc.tipo_trabajador = asi_tipo_trabaj
                                   and hc.fec_calc_plan   = adi_fec_proceso
                                   and hc.tipo_planilla   = asi_tipo_planilla
                                   and hc.cod_origen      = asi_origen)
       and t.fecha_calc      = adi_fec_proceso
       and t.tipo_planilla   = asi_tipo_planilla;

    delete from HISTORICO_calculo c
      where c.tipo_trabajador = asi_tipo_trabaj
        and c.fec_calc_plan   = adi_fec_proceso
        and c.cod_origen      = asi_origen 
        and c.tipo_planilla = asi_tipo_planilla;

    delete from quinta_categoria q
      where q.fec_proceso = adi_fec_proceso
        and q.cod_trabajador in ( select m.cod_trabajador
                                    from maestro m
                                   where m.tipo_trabajador = asi_tipo_trabaj
                                     and m.cod_origen      = asi_origen ) 
        and q.tipo_planilla  = asi_tipo_planilla;
    
    delete historico_rrhh_param_org t
     where t.tipo_trabajador = asi_tipo_trabaj
       and t.cod_origen      = asi_origen
       and t.fec_proceso     = adi_fec_proceso
       and t.tipo_planilla   = asi_tipo_planilla;
       

    commit ;
    
  end;

begin
  -- Initialization
  --<Statement>;
  select r.tipo_trab_tripulante , r.tipo_trab_destajo , r.tipo_Trab_servis  , r.tipo_trab_obrero,
         r.cnc_total_ing        , r.cnc_total_dsct    , r.tope_ano_seg_inv  , r.tipo_trab_empleado,
         r.cnc_total_pgd        , r.cnc_total_aport
    into is_tipo_trip           , is_tipo_des         , is_tipo_ser         , is_tipo_jor, 
         is_cnc_total_ingreso   , is_cnc_total_dscto  , in_ano_tope_seg_inv , is_tipo_emp,
         is_cnc_total_pagado    , is_cnc_total_aportes
  from rrhhparam r
  where r.reckey = '1' ;
  
  -- Parmetros de Asistencia
  select a.porc_bonif_ext, a.cnc_bonif_ext
    into in_porc_bonif_ext, is_cnc_bonif_ext
    from asistparam a
   where a.reckey = '1';
   
   
  -- Parametros para is_cod_afp
  is_afp_rep := PKG_CONFIG.USF_GET_PARAMETER('CODIGO_AFP_REP', 'CB');
  
  -- Concepto de bonificacion para tripulantes
  is_cnc_bonif_tri := PKG_CONFIG.USF_GET_PARAMETER('CONCEPTO BONIF ESPECIALIDAD', '1005');
  -- Concepto de Participacion de Pesca
  is_cnc_partic_pesca := PKG_CONFIG.USF_GET_PARAMETER('CONCEPTO PARTIC PESCA TRIP', '1301');
  
  -- grupos de Calculo para planilla de tripulantes
  is_grp_gratif_tri := PKG_CONFIG.USF_GET_PARAMETER('GRUPO GRATIF. TRIPULANTE', '064');
  is_grp_VACAC_TRI  := PKG_CONFIG.USF_GET_PARAMETER('GRUPO VACAC. TRIPULANTE', '065');
  is_grp_CTS_TRI    := PKG_CONFIG.USF_GET_PARAMETER('GRUPO C.T.S. TRIPULANTE', '066');
  is_cnc_reint_asig_fam := PKG_CONFIG.USF_GET_PARAMETER('REINTEGRO ASIG. FAMILIAR', '1410');

end USP_SIGRE_RRHH;
/
