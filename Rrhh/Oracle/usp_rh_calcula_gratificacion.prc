create or replace procedure usp_rh_calcula_gratificacion (
    as_codtra       in maestro.cod_trabajador%TYPE   ,
    ad_fec_proceso  in date   ,
    an_porcentaje   in number ,
    ac_flag_monto   in VARCHAR2
) is

lk_no_gratif       constant char(3) := '080';
lk_dscto_grati     constant char(3) := '093';

ls_gan_fija        rrhhparam.grc_gnn_fija%TYPE ;
ld_fec_desde       date ;
ld_fec_hasta       date ;
ld_fec_ingreso     date ;
ld_fec_cese        date ;
ls_cod_seccion     maestro.cod_seccion%TYPE;
ls_bonificacion    char(1) ;
ln_porcentaje_jud  number(4,2) ;
ln_contador        number;
ln_dias_periodo    number;
ld_fecha1          date;
ld_Fecha2          date;
ln_count           number;


ln_dias_mes        number(5,2)  ;
ln_dias_inasist    number(5,2)  ;
ls_concepto_ng     grupo_calculo.concepto_gen%TYPE;
ln_dias_trabaj     gratificacion.dias_laborados%TYPE;

ls_tipo_jor        rrhhparam.tipo_trab_destajo%TYPE;
ls_tipo_des        rrhhparam.tipo_trab_obrero%TYPE;
ls_tipo_ejo        tipo_trabajador.tipo_trabajador%TYPE := 'EJO';
ls_tipo_emp        rrhhparam.tipo_trab_empleado%TYPE;
ls_tipo_tri        rrhhparam.tipo_trab_tripulante%TYPE;

ld_fin_mes         date;

--Variables locales
lc_tip_trab            tipo_trabajador.tipo_trabajador%type ;
ls_grp_variables       grupo_calculo.grupo_calculo%TYPE := '036';
ls_grp_fijos           rrhhparam_cconcep.grati_medio_ano%TYPE;
ls_grp_dias_descontar  rrhhparam_cconcep.dias_inasis_dsccont%TYPE;
ln_rmv                 rmv_x_tipo_trabaj.rmv%TYPE;

ln_rem_fija            gratificacion.rem_fija%TYPE;
ln_rem_variable        gratificacion.rem_variable%TYPE;
ln_bonif_ext           gratificacion.bonif_ext%TYPE;
ln_importe_bruto       gratificacion.imp_bruto%TYPE;
ln_importe_neto        gratificacion.imp_bruto%TYPE;
ln_variable1           gratificacion.imp_bruto%TYPE;
ln_variable2           gratificacion.imp_bruto%TYPE;
ln_variable3           gratificacion.imp_bruto%TYPE;
ln_variable4           gratificacion.imp_bruto%TYPE;
ln_variable5           gratificacion.imp_bruto%TYPE;
ln_variable6           gratificacion.imp_bruto%TYPE;
ln_reintegro           gratificacion.imp_bruto%TYPE;
ln_reint_asig_fam      gratificacion.imp_bruto%TYPE;

-- Dias de asistencia
ln_dias_jornal         number;
ln_dias_destajo        number;
ln_dias_trip           number;

cursor c_datos is
   select distinct case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end as concep
     from historico_calculo hc
    where hc.cod_trabajador = as_codtra
      and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = to_number(to_char(ld_fin_mes, 'yyyy'))
      AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);

begin
  -- Obtengo de parametros
  select r.tipo_trab_destajo, r.tipo_trab_obrero, r.tipo_trab_empleado, r.tipo_trab_tripulante
    into ls_tipo_des, ls_tipo_jor, ls_tipo_emp, ls_tipo_tri
    from rrhhparam r
   where reckey = '1';
   
  --elimina informacion
  delete from gratificacion_det g
   where g.cod_trabajador = as_codtra
     and periodo = to_char(ad_fec_proceso,'yyyymm');

  delete from gratificacion g
   where g.cod_trabajador = as_codtra
     and periodo = to_char(ad_fec_proceso,'yyyymm');
     
  
  -- Parametros
  select c.grati_medio_ano, c.dias_inasis_dsccont
    into ls_grp_fijos, ls_grp_dias_descontar
    from rrhhparam_cconcep c
    where c.reckey = '1' ;

  select p.grc_gnn_fija
    into ls_gan_fija
    from rrhhparam p
   where p.reckey = '1' ;

  select last_day(ad_fec_proceso)
    into ld_fin_mes
    from dual ;

  --inicializacion de Variables
  ln_contador := 0 ;

  --  *************************************************************
  --  ***   REALIZA CALCULO DE GRATIFICACIONES POR TRABAJADOR   ***
  --  *************************************************************
  select count(*)
    into ln_contador
    from grupo_calculo g
   where g.grupo_calculo = lk_no_gratif ;

  if ln_contador > 0 then
     select g.concepto_gen
       into ls_concepto_ng
       from grupo_calculo g
       where g.grupo_calculo = lk_no_gratif ;
  end if ;


  /*Datos de Maestros*/
  select m.fec_ingreso, m.cod_seccion, nvl(m.bonif_fija_30_25,'0'),nvl(m.porc_judicial,0),
         m.tipo_trabajador, m.fec_cese
    into ld_fec_ingreso, ls_cod_seccion, ls_bonificacion, ln_porcentaje_jud,
         lc_tip_trab, ld_fec_cese
    from maestro m
   where m.cod_trabajador = as_codtra  ;

  -- Si es tripulante y no tiene ese codigo entonces simplemente lo regreso
  if lc_tip_trab = ls_tipo_tri and as_codtra <> '40002785' then 
     commit;
     return; 
  end if;
  
  --Obtengo la remuneracion minmima vital por trabajador
  select count(*)
    into ln_count
  from rmv_x_tipo_trabaj r 
  where trunc(r.fecha_desde) < trunc(ad_fec_proceso) 
    and r.tipo_trabajador = lc_tip_trab 
  order by r.fecha_desde desc;
  
  if ln_count = 0 then
     RAISE_APPLICATION_ERROR(-20000, 'Debe especificar la remuneración minima vital para el tipo de trabajador ' 
                                  || lc_tip_trab || 'con vigencia para la fecha ' || to_char(ad_fec_proceso, 'dd/mm/yyyy'));
  end if;
  
  select rmv 
    into ln_rmv
  from (select r.rmv 
          from rmv_x_tipo_trabaj r 
         where trunc(r.fecha_desde) < trunc(ad_fec_proceso) 
           and r.tipo_trabajador = lc_tip_trab 
        order by r.fecha_desde desc)
  where rownum = 1;


  select count(*)
    into ln_contador
    from seccion s
   where s.cod_area = 'D'
     and s.cod_seccion = ls_cod_seccion ;

  if ln_contador > 0 THEN return ; end if ;

  if to_char(ld_fin_mes,'mm') = '07' then
     ld_fec_desde := TO_DATE('01/01/'||to_char(ld_fin_mes,'YYYY'),'DD/MM/YYYY')  ;
     ld_fec_hasta := LAST_DAY(TO_DATE('01/06/'||to_char(ld_fin_mes,'YYYY'),'DD/MM/YYYY'))  ;
  elsif to_char(ld_fin_mes,'mm') = '12' then
     ld_fec_desde := TO_DATE('01/06/'||to_char(ld_fin_mes,'YYYY'),'DD/MM/YYYY')  ;
     ld_fec_hasta := LAST_DAY(TO_DATE('01/11/'||to_char(ld_fin_mes,'YYYY'),'DD/MM/YYYY'))  ;
  end if ;

  --  Determina dias para calculo de gratificacion del personal nuevo
  if ld_fec_ingreso > to_date('01/' || to_char(ld_fin_mes, 'mm/yyyy'), 'dd/mm/yyyy') then
     return;
  end if;
  
  if ld_fec_ingreso > ld_fec_desde then
     ld_fecha1 := ld_fec_ingreso;
  else
      ld_fecha1 := ld_fec_desde;
  end if;
  
  if ld_fec_cese is not null and ld_fec_cese < ld_fec_hasta then
     ld_fecha2 := ld_fec_cese;
  else
      ld_fecha2 := ld_fec_hasta;
  end if;
  
  if (ld_fecha2 - ld_fecha1) > 180 then
     ln_dias_periodo := 180;
  else
     ln_dias_periodo := (ld_fecha2 - ld_fecha1) + 1;
  end if;
  
  -- Si los días de periodo es menor o igual a cero simplemente lo termina el calculo nada mas
  if ln_dias_periodo <= 0 then return; end if;

  --  Acumula dias de inasistencias
  select NVL(sum(nvl(hi.dias_inasist,0)),0) 
    into ln_dias_inasist 
    from inasistencia hi
   where hi.cod_trabajador = as_codtra
     and hi.concep         in ( select d.concepto_calc 
                                  from grupo_calculo_det d
                                 where d.grupo_calculo = lk_dscto_grati ) 
     and hi.fec_movim between ld_fec_desde and ld_fec_hasta;

  if to_char(ld_fin_mes,'mm') = '12' then
     select NVL(sum(nvl(i.dias_inasist,0)),0) 
       into ln_dias_mes 
       from inasistencia i
      where i.cod_trabajador = as_codtra 
        and i.concep in ( select d.concepto_calc 
                            from grupo_calculo_det d 
                           where d.grupo_calculo = '093' )
        and to_char(i.fec_movim,'mm/yyyy') = to_char(ld_fin_mes,'mm/yyyy') ;
  end if ;

  --  Calcula importe bruto por los dias trabajados
  if lc_tip_trab in (ls_tipo_des, ls_tipo_jor, ls_tipo_ejo, ls_tipo_tri) then
     
     select count(distinct p.fec_parte)
       into ln_dias_destajo
       from tg_pd_destajo     p,
            tg_pd_destajo_det pd   
      where p.nro_parte  = pd.nro_parte
        and p.flag_estado <> '0'
        and pd.cod_trabajador = as_codtra
        and to_char(p.fec_parte, 'd') <> '1' -- No incluir los domingos
        and trunc(p.fec_parte) between ld_fec_desde and ld_fec_hasta;
     
     select count(distinct a.fec_movim)
       into ln_dias_jornal
       from asistencia     a   
      where a.cod_trabajador = as_codtra
        and to_char(a.fec_movim, 'd') <> '1' -- No incluir los domingos
        and trunc(a.fec_movim) between ld_fec_desde and ld_fec_hasta;

     select count(distinct f.fecha)
       into ln_dias_trip
       from fl_asistencia f  
      where f.tripulante = as_codtra
        and to_char(f.fecha, 'd') <> '1' -- No incluir los domingos
        and trunc(f.fecha) between ld_fec_desde and ld_fec_hasta;
     
     ln_dias_trabaj := ln_dias_destajo + ln_dias_jornal + ln_dias_trip ;
     
     -- A esto le sumo el dominical que sería un sexto
     ln_dias_trabaj := ln_dias_trabaj + ln_dias_trabaj / 6;
     
  else
     -- Calculo los dias en base a los dias que a asistido
     if ld_fec_ingreso > ld_fec_desde then
        ld_fec_desde := ld_fec_ingreso;
     end if;
     
     if ld_fec_cese < ld_fec_hasta and ld_fec_cese is not null then
        ld_fec_hasta := ld_fec_cese;
     end if;
     
     ln_dias_trabaj := ld_fec_hasta - ld_fec_desde + 1;
     
     if ln_dias_trabaj > 180 then ln_dias_trabaj := 180; end if;
     
     -- Ahora le quito todas las inasistencias 
     select NVL(sum(i.dias_inasist),0)
       INTO ln_dias_inasist
       FROM inasistencia i
      where i.cod_trabajador = as_codtra
        and i.concep in ( select d.concepto_calc
                          from grupo_calculo_det d
                         where d.grupo_calculo = ls_grp_dias_descontar )
        and trunc(i.fec_movim) between trunc(ld_fec_desde) and trunc(ld_fec_hasta) ;     
        
     ln_dias_trabaj := ln_dias_trabaj - ln_dias_inasist;
     
  end if;
  
  if ln_dias_trabaj <= 0 then return; return; end if;
  if ln_dias_trabaj > 180 then ln_dias_trabaj := 180; end if;
  if ln_dias_trabaj < 30 then return; end if;
  
  

  --  Acumula ganancias fijas por trabajador
  select nvl(sum(decode(Gdf.IMP_GAN_DESC, 0, (gdf.porcentaje * ln_rmv)/100, gdf.imp_gan_desc)),0)
    into ln_rem_fija
    from gan_desct_fijo gdf
   where gdf.cod_trabajador = as_codtra
     and gdf.flag_estado = '1'
     AND gdf.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_fijos);

  -- Concepto para remuneracion fija
  if ln_rem_fija > 0 then
     INSERT INTO GRATIFICACION_DET(
             COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, flag_fijo_var)
     select gdf.cod_trabajador,
            to_char(ad_fec_proceso, 'yyyymm'),
            ad_fec_proceso,
            gdf.concep,
            decode(Gdf.IMP_GAN_DESC, 0, (gdf.porcentaje * ln_rmv )/100, gdf.imp_gan_desc) * ln_dias_trabaj / 180,
            'F'
       from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_codtra
        and gdf.flag_estado = '1'
        AND gdf.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_fijos);
             
     --ln_importe_bruto := ln_rem_fija + ln_rem_Variable / ln_dias_periodo * 30;
  end if;
     
  
  -- Verifico si hay algun reintegro, de ser asi lo sumo
  select nvl(sum(gdv.imp_var),0)
    into ln_reintegro
    from gan_desct_variable gdv
   where gdv.concep = usp_sigre_rrhh.is_cnc_reintegro_grati
     and trunc(gdv.fec_movim) = trunc(ad_fec_proceso)
     and gdv.cod_trabajador   = as_codtra;
  
  if ln_reintegro > 0 then
     INSERT INTO GRATIFICACION_DET(
             COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
      select gdv.cod_trabajador,
             to_char(ad_fec_proceso, 'yyyymm'),
             ad_fec_proceso,
             gdv.concep,
             gdv.imp_var, 
             gdv.fec_movim,
             'V'
       from gan_desct_variable gdv
      where gdv.concep = usp_sigre_rrhh.is_cnc_reintegro_grati
        and trunc(gdv.fec_movim) = trunc(ad_fec_proceso)
        and gdv.cod_trabajador   = as_codtra;
    
  end if;
  
  -- Verifico si hay algun reintegro, de ser asi lo sumo
  select nvl(sum(gdv.imp_var),0)
    into ln_reint_asig_fam
    from gan_desct_variable gdv
   where gdv.concep = usp_sigre_rrhh.is_cnc_reint_asig_fam
     and trunc(gdv.fec_movim) = trunc(ad_fec_proceso)
     and gdv.cod_trabajador   = as_codtra;
  
  if ln_reint_asig_fam > 0 then
     INSERT INTO GRATIFICACION_DET(
             COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
      select gdv.cod_trabajador,
             to_char(ad_fec_proceso, 'yyyymm'),
             ad_fec_proceso,
             gdv.concep,
             gdv.imp_var, 
             gdv.fec_movim,
             'V'
       from gan_desct_variable gdv
      where gdv.concep = usp_sigre_rrhh.is_cnc_reint_asig_fam
        and trunc(gdv.fec_movim) = trunc(ad_fec_proceso)
        and gdv.cod_trabajador   = as_codtra;
    
  end if;

  -- Acumula conceptos de ganancias variables de los ultimos seis meses, debe tener como minimo tres meses
  ln_rem_variable := 0;
  for lc_reg in c_datos loop
      if to_char(ld_fin_mes,'mm') = '07' then
         select nvl(sum(hc.imp_soles),0)
           into ln_variable1
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '01/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable2
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '02/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable3
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '03/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable4
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '04/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable5
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '05/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable6
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '06/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            
     elsif to_char(ld_fin_mes,'mm') = '12' then
     
         select nvl(sum(hc.imp_soles),0)
           into ln_variable1
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '06/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables)
            and trunc(hc.fec_calc_plan) between trunc(ld_Fecha1) and trunc(ld_Fecha2);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable2
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '07/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables)
            and trunc(hc.fec_calc_plan) between trunc(ld_Fecha1) and trunc(ld_Fecha2);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable3
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end  = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '08/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables)
            and trunc(hc.fec_calc_plan) between trunc(ld_Fecha1) and trunc(ld_Fecha2);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable4
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end  = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '09/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables)
            and trunc(hc.fec_calc_plan) between trunc(ld_Fecha1) and trunc(ld_Fecha2);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable5
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '10/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables)
            and trunc(hc.fec_calc_plan) between trunc(ld_Fecha1) and trunc(ld_Fecha2);

         select nvl(sum(hc.imp_soles),0)
           into ln_variable6
           from historico_calculo hc
          where hc.cod_trabajador = as_codtra
            and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
            and to_char(hc.fec_calc_plan, 'mm/yyyy') = '11/' || trim(to_char(ld_fin_mes, 'yyyy'))
            AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables)
            and trunc(hc.fec_calc_plan) between trunc(ld_Fecha1) and trunc(ld_Fecha2);
     
     end if;
     
     ln_count := 0;
      --Valido si ha recibido al menos tres meses
      if ln_variable1 > 0 then ln_count := ln_count + 1; end if;
      if ln_variable2 > 0 then ln_count := ln_count + 1; end if;
      if ln_variable3 > 0 then ln_count := ln_count + 1; end if;
      if ln_variable4 > 0 then ln_count := ln_count + 1; end if;
      if ln_variable5 > 0 then ln_count := ln_count + 1; end if;
      if ln_variable6 > 0 then ln_count := ln_count + 1; end if;
      
      if ln_count >= 3 then
         ln_rem_variable := ln_rem_variable + ln_variable1 + ln_variable2 + ln_variable3 + ln_variable4 + ln_variable5 + ln_variable6;
         
         --Si es este caso inserto en el detalle el concepto correspondiente
         if to_char(ld_fin_mes,'mm') = '07' then
            if ln_variable1 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '01/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

            if ln_variable2 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '02/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

            if ln_variable3 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
               select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '03/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

            if ln_variable4 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '04/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;
             
            if ln_variable5 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '05/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;
             
            if ln_variable6 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '06/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

         elsif to_char(ld_fin_mes,'mm') = '12' then

            if ln_variable1 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '06/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

            if ln_variable2 > 0 then
                INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '07/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

            if ln_variable3 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '08/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

            if ln_variable4 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '09/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;
             
            if ln_variable5 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '10/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;
             
            if ln_variable6 > 0 then
               INSERT INTO GRATIFICACION_DET(
                       COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, fec_pago, flag_fijo_var)
                select hc.cod_trabajador,
                       to_char(ad_fec_proceso, 'yyyymm'),
                       ad_fec_proceso,
                       hc.concep,
                       (hc.imp_soles / 6) * ln_dias_trabaj / 180, 
                       hc.fec_calc_plan,
                       'V'
                 from historico_calculo hc
              where hc.cod_trabajador = as_codtra
                and case when hc.concep in ('1101', '1102', '1103', '1104', '1105') then '1101' else hc.concep end = lc_reg.concep
                and to_char(hc.fec_calc_plan, 'mm/yyyy') = '11/' || trim(to_char(ld_fin_mes, 'yyyy'))
                AND hc.concep in (select concepto_calc from grupo_calculo_det where grupo_calculo = ls_grp_variables);
            end if;

         end if;
      end if;
      
  end loop;
  
  --  Obtengo el importe de la gratificacion
  ln_importe_bruto := ln_rem_fija + ln_rem_Variable / 6;
    
  -- Importe Bruto de acuerdo a los dias laborados
  ln_importe_bruto := ln_importe_bruto / 180 * ln_dias_trabaj + ln_reintegro + ln_reint_asig_fam;
  
  -- Ahora con respecto a la bonificacion extraordinaria
  if to_number(to_char(ad_fec_proceso, 'yyyy')) between 2009 and 2015 then
     ln_bonif_ext := ln_importe_bruto * 0.09;
  else
     ln_bonif_ext := 0;
  end if;
  
  ln_importe_neto := (ln_importe_bruto + ln_bonif_ext) * an_porcentaje / 100;
  
  --  Actualiza o inserta registros por pago de gratificaciones
  if ln_importe_neto <= 0 then return; end if;

  select count(*)
    into ln_contador
    from gratificacion g
   where g.cod_trabajador = as_codtra
     and g.fec_proceso = ad_fec_proceso ;

  if ln_contador > 0 then
     update gratificacion g
        set imp_bruto        = ln_importe_bruto ,
            flag_replicacion = '1',
            periodo          = to_char(ad_fec_proceso,'yyyymm'),
            rem_fija         = ln_rem_fija,
            rem_variable     = ln_rem_variable + ln_reintegro,
            bonif_ext        = ln_bonif_ext,
            dias_laborados   = ln_dias_trabaj,
            imp_adelanto     = ln_importe_neto,
            g.per_inicio     = ld_fec_desde,
            g.per_fin        = ld_fec_hasta
      where cod_trabajador = as_codtra 
        and fec_proceso    = ad_fec_proceso ;
  else
    --VERIFICAR SI ACTUALIZARA MONTO DE ADELANTO
    if ac_flag_monto  = '1' then
       ln_importe_neto := 0.00 ;
    end if ;

    Insert into gratificacion(
           cod_trabajador, fec_proceso, imp_bruto, imp_adelanto, flag_replicacion,
           periodo, 
           REM_FIJA, REM_VARIABLE, BONIF_EXT, dias_laborados, 
           per_inicio, per_fin)
    values(
           as_codtra, ad_fec_proceso, ln_importe_bruto, ln_importe_neto, '1',
           to_char(ad_fec_proceso,'yyyymm'),
           ln_rem_fija, ln_rem_variable + ln_reintegro, ln_bonif_ext, ln_dias_trabaj,
           ld_fec_desde, ld_fec_hasta ) ;
  end if ;
  
  -- Inserto la bonificacion
  if ln_bonif_ext > 0 then
     INSERT INTO GRATIFICACION_DET(
           COD_TRABAJADOR, PERIODO, FEC_PROCESO, CONCEPTO, IMPORTE, flag_fijo_var)
     values(
           as_codtra, to_char(ad_fec_proceso, 'yyyymm'), ad_fec_proceso, '1472', ln_bonif_ext, '3');
  end if;
  
  
  COMMIT;

end usp_rh_calcula_gratificacion ;
/
