create or replace procedure usp_rh_cal_calcula_planilla (
  asi_codtra             in maestro.cod_trabajador%TYPE,
  asi_codusr             in usuario.cod_usr%TYPE,
  adi_fec_proceso        in date,
  asi_origen             in origen.cod_origen%TYPE,
  adi_fec_anterior       in date,
  asi_flag_control       in char,
  asi_flag_cierre_mes    in char,
  adi_fec_grati          in date
) is

ln_dias_trabajados     number(4,2) ;
ln_dias_mes            number(4,2) ;
ln_judicial            maestro.porc_judicial%TYPE ;
ln_judicial_utl        maestro.porc_jud_util%TYPE ;
ln_judicial_tt         maestro.porc_judicial%TYPE ;
ln_judicial_utl_tt     maestro.porc_jud_util%TYPE ;

ln_tipcam              number(7,3) ;
ln_ano_tope_seg_inv    rrhhparam.tope_ano_seg_inv%type ;

ln_imp_soles           calculo.imp_soles%TYPE;
ln_imp_dolar           calculo.imp_dolar%TYPE;
ln_gratif              calculo.imp_soles%TYPE;
ln_mes_gratif          number;
ln_year_gratif         number;

ls_flag_sobretiempo    maestro.flag_juicio%TYPE     ;
ls_bonif_fija_30_25    maestro.bonif_fija_30_25%TYPE;
ls_flag_sindicato      maestro.flag_sindicato%TYPE;
ls_cod_afp             maestro.cod_afp%type         ;
ls_seccion             seccion.cod_seccion%type     ;
ls_area                seccion.cod_area%type        ;
ls_tipo_trabajador     maestro.tipo_trabajador%type ;
ls_tipo_trip           maestro.tipo_trabajador%type ;
ls_flag_pensionista    maestro.flag_pensionista%TYPE;

ls_tipo_obr            maestro.tipo_trabajador%type ;

ld_fec_nac             Date                         ;
ls_tipo_emp            rrhhparam.tipo_trab_empleado%TYPE;              -- Tipo Empleado
ls_tipo_fun            tipo_trabajador.tipo_trabajador%TYPE := 'FUN';  -- Tipo Funcionario
ls_tipo_fge            tipo_trabajador.tipo_trabajador%TYPE := 'FGE';  -- Tipo Gerencial
ls_tipo_ser            tipo_trabajador.tipo_trabajador%TYPE := 'SER';
ls_tipo_des            rrhhparam.tipo_trab_destajo%TYPE;
ln_count               number;

-- Paraemtros generales
ls_grc_gan_fija        rrhhparam.grc_gnn_fija%TYPE;
ls_grc_sobretiempo     rrhhparam.grc_sobret_grd%TYPE;
ls_grc_guardias        rrhhparam.grc_pago_dias%TYPE;
ls_grc_dscto_ley       rrhhparam.grc_dsc_ley%TYPE;
ls_cnc_total_ingreso   rrhhparam.cnc_total_ing%TYPE;
ls_cnc_total_dscto     rrhhparam.cnc_total_dsct%TYPE;
ls_cnc_total_pagado    rrhhparam.cnc_total_pgd%TYPE;
ls_cnc_total_aportes   rrhhparam.cnc_total_aport%TYPE;
ls_doc_autom           rrhhparam.doc_reg_automatico%TYPE;  -- Documento automatico
ln_dias_racion_cocida  rrhhparam.dias_racion_cocida%TYPE;
ln_dias_mes_empleado   rrhhparam.dias_mes_empleado%TYPE;
ln_dias_mes_obrero     rrhhparam.dias_mes_obrero%TYPE;

ls_grp_afecto_CTS      rrhhparam_cconcep.afecto_pago_cts_urgencia%TYPE;
ls_grp_afecto_GRATI    rrhhparam_cconcep.concep_gratif%TYPE;
ls_grp_afecto_VACA     rrhhparam_cconcep.gan_fij_calc_vacac%TYPE;

ls_flag_calcula_CTS    rrhh_param_org.flag_calc_cts%TYPE;
ls_flag_calcula_VACA   rrhh_param_org.flag_calc_vacaciones%TYPE;
ls_flag_calcula_GRATI  rrhh_param_org.flag_calc_gratificacion%TYPE;

ls_concep_CTS          fl_param.concep_cts%TYPE;
ls_concep_VACA         fl_param.concep_vacaciones%TYPE;
ls_concep_GRATI        fl_param.concep_gratif%TYPE;
ls_cnc_bon_gratif      asistparam.cnc_bonif_ext%TYPE;
ln_porc_bon_gratif     asistparam.porc_bonif_ext%TYPE;

ld_fec_cese            maestro.fec_cese%TYPE;
ld_fec_ingreso         maestro.fec_ingreso%TYPE;
ld_fec_inicio          rrhh_param_org.fec_inicio%TYPE;
ld_fec_final           rrhh_param_org.fec_final%TYPE;


begin

--  ******************************************************************
--  ***   PROCEDIMIENTOS PARA REALIZAR EL CALCULO DE LA PLANILLA   ***
--  ******************************************************************
select m.flag_sindicato       , m.cod_afp              , nvl(m.porc_judicial,0) ,
       nvl(m.porc_jud_util,0) , m.bonif_fija_30_25     , m.cod_area             ,
       m.cod_seccion          , nvl(m.flag_juicio,'0') , m.tipo_trabajador  ,
       m.fec_nacimiento       , m.fec_cese             , m.fec_ingreso      ,
       NVL(m.flag_pensionista,'0')
  into ls_flag_sindicato      , ls_cod_afp             , ln_judicial ,
       ln_judicial_utl        , ls_bonif_fija_30_25    , ls_area     ,
       ls_seccion             , ls_flag_sobretiempo    , ls_tipo_trabajador ,
       ld_fec_nac             , ld_fec_cese            , ld_fec_ingreso     ,
       ls_flag_pensionista
  from maestro m
 where(m.cod_trabajador = asi_codtra);

--  ******************************************************************
--  ***   PArametros para verificar si hay fecha de proceso
--  ******************************************************************
select count(*)
  into ln_count
  FROM rrhh_param_org t
 WHERE t.origen = asi_origen
   and t.fec_proceso = adi_fec_proceso
   and t.tipo_trabajador = ls_tipo_trabajador;

if ln_count = 0 then
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado parametros para Fechas de Proceso '
                                   || chr(13) || 'Tipo Trabajador: ' || ls_tipo_trabajador
                                   || chr(13) || 'Codigo Trab: ' || asi_codtra
                                   || chr(13) || 'Origen: ' || asi_origen
                                   || chr(13) || 'Fecha Proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
end if;

--  ******************************************************************
--  ***   OBTENGO EL INICIO Y EL FINAL DEL PERIODO
--  ******************************************************************
select fec_inicio, fec_final,
       NVL(r.flag_calc_vacaciones,0), NVL(r.flag_calc_cts,0), NVL(r.flag_calc_gratificacion,0)
  into ld_fec_inicio, ld_fec_final,
       ls_flag_calcula_VACA, ls_flag_calcula_CTS, ls_flag_calcula_GRATI
from rrhh_param_org r
where r.origen = asi_origen
  and r.fec_proceso = adi_fec_proceso
  and r.tipo_trabajador = ls_tipo_trabajador;

-- Si ceso antes del periodo no lo considero
if ld_fec_cese is not null and ld_fec_cese < ld_fec_inicio then
   return;
end if;

-- Si ingreso despues del periodo tampoco lo considero
if ld_fec_ingreso is not null and ld_fec_ingreso > ld_fec_final then
   return;
end if;

--  ******************************************************************
--  ***   OBTENGO LOS PARAMETROS QUE NECESITO
--  ******************************************************************
select NVL(r.tipo_trab_tripulante, 'TRI'), r.tope_ano_seg_inv, r.tipo_trab_empleado,
       r.grc_gnn_fija        , r.grc_sobret_grd    , r.grc_pago_dias      , r.grc_dsc_ley		 ,
		   r.cnc_total_ing		   , r.cnc_total_dsct	   , r.cnc_total_pgd	    , r.cnc_total_aport ,
       r.dias_racion_cocida  , r.dias_mes_empleado , r.dias_mes_obrero    , r.tipo_trab_obrero,
       r.tipo_trab_destajo
  into ls_tipo_trip          , ln_ano_tope_seg_inv , ls_tipo_emp         ,
       ls_grc_gan_fija       , ls_grc_sobretiempo  , ls_grc_guardias     , ls_grc_dscto_ley,
       ls_cnc_total_ingreso  , ls_cnc_total_dscto  , ls_cnc_total_pagado , ls_cnc_total_aportes,
       ln_dias_racion_cocida , ln_dias_mes_empleado, ln_dias_mes_obrero , ls_tipo_obr,
       ls_tipo_des
  from rrhhparam r
 where r.reckey = '1' ;

SELECT t.afecto_pago_cts_urgencia, t.gan_fij_calc_vacac, t.grati_fin_ano
  INTO ls_grp_afecto_CTS, ls_grp_afecto_VACA, ls_grp_afecto_GRATI
  FROM rrhhparam_cconcep t
 WHERE t.reckey = '1';


-- Determino los dias para calculo de acuerdo al tipo de trabajador
if ls_tipo_trabajador IN (ls_tipo_emp, ls_tipo_fun, ls_tipo_fge) then
   --if to_char(adi_fec_proceso, 'mm') = '02' then
   --   ln_dias_mes := to_date('01/03' || to_char(adi_fec_proceso, 'yyyy'), 'dd/mm/yyyy') -
   --                  to_date('01/02' || to_char(adi_fec_proceso, 'yyyy'), 'dd/mm/yyyy');
   --else
      ln_dias_mes := nvl(ln_dias_mes_empleado,0) ;
   --end if;
else
  ln_dias_mes := nvl(ln_dias_mes_obrero,0) ;
end if ;

SELECT t.cnc_bonif_ext, t.porc_bonif_ext
  INTO ls_cnc_bon_gratif, ln_porc_bon_gratif
  FROM asistparam t
 WHERE t.reckey = '1';

-- Obtengo el tipo de cambio correspondiente
select nvl(tc.vta_dol_prom,1)
  into ln_tipcam
  from calendario tc
 where trunc(tc.fecha) = adi_fec_proceso ;

IF ln_tipcam = 0 THEN
   RAISE_APPLICATION_ERROR(-20000, 'No ha especificado tipo de cambio para ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
END IF;

--  REALIZA CALCULOS DE GANANCIAS POR TRABAJADOR
usp_rh_cal_prom_remun_vacac
  ( asi_codtra, asi_codusr, adi_fec_proceso, ls_doc_autom ) ;

usp_rh_cal_pago_devengados
  ( asi_codtra, asi_codusr, adi_fec_proceso, ls_doc_autom, adi_fec_anterior ) ;


--usp_rh_cal_add_diferi_quincena
  --( asi_codtra, asi_codusr, adi_fec_proceso, ls_doc_autom, adi_fec_anterior, ls_grc_gan_fija) ;

usp_rh_cal_treita_avos
  ( asi_codtra, asi_codusr, adi_fec_proceso, ls_doc_autom, asi_origen ,ls_tipo_trabajador ) ;

/*create or replace function usf_rh_cal_dias_trabajados
(
       asi_codtra          in maestro.cod_trabajador%TYPE ,
       asi_origen          in origen.cod_origen%TYPE,
       asi_tip_trab        in tipo_trabajador.tipo_trabajador%type,
       adi_fec_proceso     in date
)return number is*/
ln_dias_trabajados := usf_rh_cal_dias_trabajados
  ( asi_codtra, asi_origen ,ls_tipo_trabajador, ln_dias_mes, adi_fec_proceso) ;

--if ls_flag_calcula_GRATI <> 1 and ls_tipo_trabajador <> ls_tipo_emp THEN
  usp_rh_cal_asig_familiar
     ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
       ln_dias_trabajados, ln_dias_mes ) ;
--end if;

usp_rh_cal_ganancias_variables
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ,ls_tipo_trabajador) ;

if asi_flag_control = '1' and ls_tipo_trabajador <> ls_tipo_trip then  --toma en cuenta las ganacias fijas
   usp_rh_cal_ganancias_fijas
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados, ln_dias_mes ) ;
   usp_rh_cal_dominical
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados, ln_dias_mes ) ;
   usp_rh_cal_feriado
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados) ;
   usp_rh_cal_trabajo_dso
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados) ;
end if ;

usp_rh_cal_racion_cocida
  ( asi_codtra, asi_codusr, adi_fec_proceso, asi_origen, ln_dias_trabajados,
    ln_dias_mes, ln_dias_racion_cocida, ln_tipcam ) ;

usp_rh_cal_sobretiempo_turno
  ( asi_codtra, asi_codusr, adi_fec_proceso, asi_origen, ls_flag_sobretiempo,
    ln_tipcam, ls_grc_sobretiempo, ls_grc_guardias, ls_tipo_trabajador ) ;

--IF ls_flag_calcula_VACA = '1' then
  usp_rh_cal_vacaciones
    ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ) ;
--end if;

usp_rh_cal_bonificaciones
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_bonif_fija_30_25 ) ;

usp_rh_cal_enfermedad
  ( asi_codtra, ls_tipo_trabajador, adi_fec_proceso, asi_origen, ln_tipcam ) ;

usp_rh_cal_maternidad
  ( asi_codtra, ls_tipo_trabajador, adi_fec_proceso, asi_origen, ln_tipcam ) ;

usp_rh_cal_licencia_sindical
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ) ;

usp_rh_cal_comision_servicio
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ) ;

usp_rh_cal_desc_sustitutorio
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ) ;

usp_rh_cal_reintegros
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_bonif_fija_30_25,ls_tipo_trabajador ) ;

usp_rh_cal_bonificacion_30_25
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_bonif_fija_30_25 ) ;

   /*Calculo de Vacaciones, CTS y GRATI para Jornaleros o Tripulantes*/

   select l.concep_cts, l.concep_gratif, l.concep_vacaciones
     into ls_concep_CTS, ls_concep_GRATI, ls_concep_VACA
     from fl_param l
    where l.reckey = '1';

   If ls_tipo_trabajador in (ls_tipo_obr, ls_tipo_trip, ls_tipo_ser, ls_tipo_des)  Then
      IF ls_flag_calcula_GRATI = '1' THEN
         -- Calculo de gratificacion
         Select count(*)
           Into ln_count
           From calculo c,
                grupo_calculo_det gcc
          Where c.concep          = gcc.concepto_calc
            and gcc.grupo_calculo = ls_grp_afecto_GRATI
            AND c.cod_trabajador  = asi_codtra
            and c.fec_proceso     = adi_fec_proceso;

         if ln_count > 0 then
             Select NVL(Sum(Nvl(c.imp_soles,0)),0)
               Into ln_imp_soles
               From calculo c,
                    grupo_calculo_det gcc
              Where c.concep          = gcc.concepto_calc
                and gcc.grupo_calculo = ls_grp_afecto_GRATI
                AND c.cod_trabajador  = asi_codtra
                and c.fec_proceso     = adi_fec_proceso
              Group by c.cod_trabajador;

             ln_imp_soles := ln_imp_soles / 6;
             ln_imp_dolar := ln_imp_soles / ln_tipcam;
             
             update calculo 
                set imp_soles = ln_imp_soles,
                    imp_dolar = ln_imp_dolar,
                    dias_trabaj = ln_dias_trabajados
              where cod_trabajador = asi_codtra
                and concep         = ls_concep_GRATI;
             
             if SQL%NOTFOUND then
                 Insert Into calculo(
                         cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                         dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item)
                 Values(
                         asi_codtra, ls_concep_GRATI, adi_fec_proceso, 0, 0, ln_dias_trabajados,
                         ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1);
             end if;
                 

             
             -- Calculo la bonificación de la graticiación
             if to_number(to_char(adi_fec_proceso, 'yyyy')) between 2011 and 2014 then
                 -- Inserto la bonificacion de la gratificacion
                  ln_imp_soles := ln_imp_soles * ln_porc_bon_gratif;
                  ln_imp_dolar := ln_imp_soles / ln_tipcam ;

                  UPDATE calculo
                     SET horas_trabaj = null,
                         horas_pag    = null,
                         imp_soles    = imp_soles + ln_imp_soles,
                         imp_dolar    = imp_dolar + ln_imp_dolar
                    WHERE cod_trabajador = asi_codtra
                      AND concep = ls_cnc_bon_gratif;


                  IF SQL%NOTFOUND THEN
                     insert into calculo (
                            cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                            dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item )
                     values (
                            asi_codtra, ls_cnc_bon_gratif, adi_fec_proceso, null, null,
                            ln_dias_trabajados, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1 ) ;

                  END IF;
             end if;

         end if;
         
      END IF;

      IF ls_flag_calcula_VACA = '1' THEN
         -- Calculo de vacaciones
          Select count(*)
           Into ln_count
           From calculo c,
                grupo_calculo_det gcc
          Where c.concep          = gcc.concepto_calc
            and gcc.grupo_calculo = ls_grp_afecto_VACA
            AND c.cod_trabajador  = asi_codtra
            and c.fec_proceso     = adi_fec_proceso;

         if ln_count > 0 then
             Select Sum(Nvl(c.imp_soles,0))
               Into ln_imp_soles
               From calculo c,
                    grupo_calculo_det gcc
              Where c.concep          = gcc.concepto_calc
                and gcc.grupo_calculo = ls_grp_afecto_VACA
                AND c.cod_trabajador  = asi_codtra
                and c.fec_proceso     = adi_fec_proceso
              Group by c.cod_trabajador;

             ln_imp_soles := ln_imp_soles / 12;
             ln_imp_dolar := ln_imp_soles / ln_tipcam;
             
             update calculo 
                set imp_soles = ln_imp_soles,
                    imp_dolar = ln_imp_dolar,
                    dias_trabaj = ln_dias_trabajados
              where cod_trabajador = asi_codtra
                and concep         = ls_grp_afecto_VACA;                     
             
             if SQL%NOTFOUND then
                 Insert Into calculo(
                         cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                         dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item)
                 Values(
                         asi_codtra, ls_concep_VACA, adi_fec_proceso, 0, 0, ln_dias_trabajados,
                         ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1);
             end if;
               
         end if;
      END IF;

      IF ls_flag_calcula_CTS = '1' THEN
         -- Calculo del CTS
         Select count(*)
           Into ln_count
           From calculo c,
                grupo_calculo_det gcc
          Where c.concep          = gcc.concepto_calc
            and gcc.grupo_calculo = ls_grp_afecto_CTS
            AND c.cod_trabajador  = asi_codtra
            and c.fec_proceso     = adi_fec_proceso;

         if ln_count > 0 then
             Select Sum(Nvl(c.imp_soles,0))
               Into ln_imp_soles
               From calculo c,
                    grupo_calculo_det gcc
              Where c.concep          = gcc.concepto_calc
                and gcc.grupo_calculo = ls_grp_afecto_CTS
                AND c.cod_trabajador  = asi_codtra
                and c.fec_proceso     = adi_fec_proceso
              Group by c.cod_trabajador;
             
             -- Verifico si la gratificacion esta calculada en la misma boleta sino la jalo de la tabla gratificaciones 
             select count(*)
               into ln_count
               from calculo c
              where c.concep         = ls_concep_GRATI
                and c.cod_trabajador = asi_codtra
                and c.fec_proceso    = adi_fec_proceso;
             
             if ln_count = 0 then
                -- Obtengo el periodo para tomar la gratificacion
                if to_number(to_char(adi_fec_proceso, 'mm')) between 1 and 7 then
                   ln_year_gratif := to_number(to_char(adi_fec_proceso, 'yyyy')) - 1;
                   ln_mes_gratif  := 12;
                else
                   ln_year_gratif := to_number(to_char(adi_fec_proceso, 'yyyy'));
                   ln_mes_gratif  := 7;
                end if;
                -- Si no hay gratificacion entonces debo obtenerla de la ultima calculada
                select nvl(sum(hc.imp_soles),0)
                  into ln_gratif
                  from historico_calculo hc
                 where hc.concep in ('1461', '1462', '1471', ls_concep_GRATI)
                   and hc.cod_trabajador = asi_codtra
                   and to_number(to_char(hc.fec_calc_plan, 'mm')) = ln_mes_gratif
                   and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ln_year_gratif;
                   
             else
                ln_gratif := 0;
             end if;

             ln_imp_soles := ln_imp_soles / 12 + ln_gratif / 180 * ln_dias_trabajados;
             ln_imp_dolar := ln_imp_soles / ln_tipcam;

             Insert Into calculo(
                     cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                     dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item)
             Values(
                     asi_codtra, ls_concep_CTS, adi_fec_proceso, 0, 0, ln_dias_trabajados,
                     ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1);
         end if;
      END IF;
   End If;


usp_rh_cal_ganancia_total
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_ingreso ) ;

-- Judicial
select count(*)
  into ln_count
  from judicial j
 where j.cod_trabajador = asi_codtra;

if ln_count > 0 then
   select nvl(sum(nvl(j.porcentaje,0)),0), nvl(sum(nvl(j.porc_utilidad,0)),0)
     into ln_judicial_tt, ln_judicial_utl_tt
     from judicial j
    where j.cod_trabajador = asi_codtra;
   
   if ln_judicial_tt > 0 then
      ln_judicial := ln_judicial_tt;
      update maestro m
         set m.porc_judicial = ln_judicial
       where m.cod_trabajador = asi_codtra;
   end if;
   if ln_judicial_utl_tt > 0 then
      ln_judicial_utl := ln_judicial_utl_tt;
      update maestro m
         set m.porc_jud_util = ln_judicial_utl_tt
       where m.cod_trabajador = asi_codtra;
   end if;

end if;


if nvl(ln_judicial,0) <> 0 or nvl(ln_judicial_utl,0) <> 0 then
  usp_rh_cal_porcentaje_judicial
    ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ln_judicial,
      ls_grc_dscto_ley, ln_judicial_utl, asi_codusr ) ;
end if ;


--  REALIZA CALCULOS DE DESCUENTOS POR TRABAJADOR
if ls_flag_pensionista = '0' then
    if ls_cod_afp is null then
      usp_rh_cal_snp ( asi_codtra, adi_fec_proceso, asi_origen ) ;
    else
      usp_rh_cal_afp ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ,ln_ano_tope_seg_inv ,ld_fec_nac ) ;
    end if ;
end if;

-- Quinta categoria
--cambio provisional no calcular para el caso de tripulantes

-- Solo por este a?o no se va a calcular la renta de quinta
--if ls_flag_calcula_GRATI <> 1 and ls_tipo_trabajador <> ls_tipo_emp THEN
   usp_rh_cal_quinta_categoria
   ( asi_codtra, ls_tipo_trabajador, adi_fec_proceso, ln_tipcam, asi_origen,
     ln_dias_trabajados, ln_dias_mes ) ;
--end if ;

-- Descuentos fijos
usp_rh_cal_descuentos_fijos
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_cnc_total_ingreso ) ;

-- Descuento Comedor
usp_rh_cal_desct_comedor
  ( asi_codtra, asi_origen, adi_fec_proceso, ln_tipcam ) ;

-- Descuentos variables
usp_rh_cal_descuento_variable
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ) ;

-- Tardanzas
usp_rh_cal_tardanzas
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_bonif_fija_30_25,
    ls_grc_gan_fija ,ls_tipo_trabajador) ;

-- Calculo de cuota sindical
usp_rh_cal_desct_sindicato
   (asi_codtra, asi_origen, adi_fec_proceso, ln_tipcam);


/*usp_rh_cal_diferidos
  ( as_codtra, ad_fec_proceso, ln_tipcam, ls_total_ingreso ) ;*/

-- Essalud Vida
usp_rh_cal_essalud_vida
   ( asi_codtra, asi_origen, ln_tipcam, adi_fec_proceso,ls_tipo_trabajador ) ;

-- Cuenta corriente
usp_rh_cal_cuenta_corriente
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ,ls_cnc_total_ingreso,
    adi_fec_grati);

-- Descuento total
usp_rh_cal_descuento_total
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_dscto ) ;

usp_rh_cal_total_pagado
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_ingreso,
    ls_cnc_total_dscto, ls_cnc_total_pagado ) ;

--  REALIZA CALCULOS DE APORTACIONES PATRONALES
usp_rh_cal_apo_sctr_ipss
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ) ;

usp_rh_cal_apo_sctr_onp
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_seccion ) ;



-- Los tripulantes no llevan senati
if ls_tipo_trabajador <> ls_tipo_trip then
   usp_rh_cal_apo_senati
       ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen,ls_area , ls_seccion ) ;
end if;

--  Aportaciones para empresa - realizado por A. Rojas solo para proceso espcial
if ls_tipo_trabajador = ls_tipo_trip then
   usp_rh_cal_apo_cbssp
       ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ,ls_area,ls_seccion) ;
end if;

--  Otras Aportaciones indicadas por el trabajador
usp_rh_cal_otras_aport
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen , ls_cnc_total_ingreso) ;

--elimina calculos en cero
delete from calculo hc
  where hc.cod_trabajador = asi_codtra
    and hc.fec_proceso    = adi_fec_proceso
    and nvl(imp_soles,0)  = 0
    and nvl(imp_dolar,0)  = 0
    and hc.concep         <> ls_cnc_total_pagado;

-- Elimino tambien todo aquellos que no tienen neto pagado
delete calculo c
where c.cod_trabajador not in (select distinct cod_trabajador
                                  from calculo t
                                  where concep = ls_cnc_total_ingreso)
   and c.cod_trabajador = asi_codtra;

-- Aportacion Especial Cred EPS
usp_rh_cal_cred_eps
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ) ;

usp_rh_cal_apo_essalud
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_tipo_trabajador ) ;

usp_rh_cal_apo_total
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_aportes ) ;

--elimina calculos en cero
delete from calculo hc
  where hc.cod_trabajador = asi_codtra
    and hc.fec_proceso    = adi_fec_proceso
    and nvl(imp_soles,0)  = 0
    and nvl(imp_dolar,0)  = 0
    and hc.concep         <> ls_cnc_total_pagado;

end usp_rh_cal_calcula_planilla ;
/
