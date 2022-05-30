create or replace procedure usp_rh_cal_calcula_planilla (
  asi_codtra             in maestro.cod_trabajador%TYPE,
  asi_codusr             in usuario.cod_usr%TYPE,
  adi_fec_proceso        in date,
  asi_origen             in origen.cod_origen%TYPE,
  asi_flag_control       in char,
  asi_flag_renta_quinta  in char,
  asi_flag_dso_af        in char,
  asi_tipo_planilla      in char,
  asi_flag_cierre_mes    in char
) is

ln_dias_trabajados     number(4,2) ;
ln_dias_mes            number(4,2) ;
ln_judicial            number(4,2) ;
ln_judicial_utl        number(4,2) ;
ln_tipcam              calendario.vta_dol_prom%TYPE;
ln_ano_tope_seg_inv    rrhhparam.tope_ano_seg_inv%type ;

ln_imp_soles           calculo.imp_soles%TYPE;
ln_imp_dolar           calculo.imp_dolar%TYPE;

ls_flag_sobretiempo    maestro.flag_juicio%TYPE     ;
ls_bonif_fija_30_25    maestro.bonif_fija_30_25%TYPE;
ls_flag_sindicato      maestro.flag_sindicato%TYPE;
ls_cod_afp             maestro.cod_afp%type         ;
ls_seccion             seccion.cod_seccion%type     ;
ls_area                seccion.cod_area%type        ;
ls_tipo_trabajador     maestro.tipo_trabajador%type ;
ls_tipo_trip           maestro.tipo_trabajador%type ;

ls_tipo_obr            maestro.tipo_trabajador%type ;

ld_fec_nac             Date                         ;
ls_tipo_emp            rrhhparam.tipo_trab_empleado%TYPE;              -- Tipo Empleado
ls_tipo_fun            tipo_trabajador.tipo_trabajador%TYPE := 'FUN';  -- Tipo Funcionario
ls_tipo_fge            tipo_trabajador.tipo_trabajador%TYPE := 'FGE';  -- Tipo Gerencial
ls_tipo_ser            tipo_trabajador.tipo_trabajador%TYPE := 'SER';
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
ln_imp_gratif          calculo.imp_soles%TYPE;

ls_flag_calcula_CTS    rrhh_param_org.flag_calc_cts%TYPE;
ls_flag_calcula_VACA   rrhh_param_org.flag_calc_vacaciones%TYPE;
ls_flag_calcula_GRATI  rrhh_param_org.flag_calc_gratificacion%TYPE;

ls_concep_CTS          fl_param.concep_cts%TYPE;
ls_concep_VACA         fl_param.concep_vacaciones%TYPE;
ls_concep_GRATI        fl_param.concep_gratif%TYPE;

ld_fec_cese            maestro.fec_cese%TYPE;
ld_fec_ingreso         maestro.fec_ingreso%TYPE;
ld_fec_inicio          rrhh_param_org.fec_inicio%TYPE;
ld_fec_final           rrhh_param_org.fec_final%TYPE;
ls_flag_cat_trab       maestro.flag_cat_trab%TYPE;


begin

--  ******************************************************************
--  ***   PROCEDIMIENTOS PARA REALIZAR EL CALCULO DE LA PLANILLA   ***
--  ******************************************************************
select m.flag_sindicato       , m.cod_afp              , nvl(m.porc_judicial,0) ,
       nvl(m.porc_jud_util,0) , m.bonif_fija_30_25     , m.cod_area             ,
       m.cod_seccion          , nvl(m.flag_juicio,'0') , m.tipo_trabajador  ,
       m.fec_nacimiento       , m.fec_cese             , m.fec_ingreso,
       NVL(m.flag_cat_trab, '1')
  into ls_flag_sindicato      , ls_cod_afp             , ln_judicial ,
       ln_judicial_utl        , ls_bonif_fija_30_25    , ls_area     ,
       ls_seccion             , ls_flag_sobretiempo    , ls_tipo_trabajador ,
       ld_fec_nac             , ld_fec_cese            , ld_fec_ingreso,
       ls_flag_cat_trab
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
where r.origen          = asi_origen
  and r.fec_proceso     = adi_fec_proceso
  and r.tipo_trabajador = ls_tipo_trabajador
  and r.tipo_planilla   = asi_tipo_planilla;

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
       r.grc_gnn_fija        , r.grc_sobret_grd  , r.grc_pago_dias     , r.grc_dsc_ley		 ,
		   r.cnc_total_ing		   , r.cnc_total_dsct	 , r.cnc_total_pgd	   , r.cnc_total_aport ,
       r.dias_racion_cocida, r.dias_mes_empleado, r.dias_mes_obrero, r.tipo_trab_obrero
  into ls_tipo_trip          , ln_ano_tope_seg_inv , ls_tipo_emp       ,
       ls_grc_gan_fija       , ls_grc_sobretiempo  , ls_grc_guardias   , ls_grc_dscto_ley,
       ls_cnc_total_ingreso  , ls_cnc_total_dscto  , ls_cnc_total_pagado , ls_cnc_total_aportes,
       ln_dias_racion_cocida , ln_dias_mes_empleado, ln_dias_mes_obrero , ls_tipo_obr
  from rrhhparam r
 where r.reckey = '1' ;
 
SELECT t.afecto_pago_cts_urgencia, t.gan_fij_calc_vacac, t.grati_fin_ano
  INTO ls_grp_afecto_CTS, ls_grp_afecto_VACA, ls_grp_afecto_GRATI
  FROM rrhhparam_cconcep t
 WHERE t.reckey = '1';


-- Determino los dias para calculo de acuerdo al tipo de trabajador
if ls_tipo_trabajador IN (ls_tipo_emp, ls_tipo_fun, ls_tipo_fge, ls_tipo_trip, 'EJO') then

   ln_dias_mes := nvl(ln_dias_mes_empleado,0) ;

else
  ln_dias_mes := nvl(ln_dias_mes_obrero,0) ;
end if ;

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

-- Descuentos por adelanto de quincena
usp_rh_cal_add_diferi_quincena
  ( asi_codtra, asi_codusr, adi_fec_proceso, ls_doc_autom ) ;

/*
create or replace function usf_rh_cal_dias_trabajados(
       asi_codtra          in maestro.cod_trabajador%TYPE ,
       asi_origen          in origen.cod_origen%TYPE,
       asi_tip_trab        in tipo_trabajador.tipo_trabajador%type,
       ani_dias_mes        in number,
       adi_fec_proceso     in date,
       asi_tipo_planilla   in calculo.tipo_planilla%TYPE
)return number is
*/
ln_dias_trabajados := usf_rh_cal_dias_trabajados ( asi_codtra, asi_origen , ls_tipo_trabajador, ln_dias_mes, adi_fec_proceso, asi_tipo_planilla) ;


if asi_tipo_planilla = 'B' then
   -- Si la planilla es estrictamente de bonificaciones entonces proceso solo bonificaciones
  
   usp_rh_cal_fijo_tripulante( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, asi_tipo_planilla ) ;
     
elsif asi_flag_control = '1'  then  --toma en cuenta las ganacias fijas
   usp_rh_cal_ganancias_fijas
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados, ln_dias_mes, asi_tipo_planilla ) ;
   usp_rh_cal_asig_familiar
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados, asi_flag_dso_af, asi_tipo_planilla ) ;
   usp_rh_cal_feriado
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados, asi_tipo_planilla) ;
   USP_RH_CAL_DSO
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados, asi_tipo_planilla ) ;
   USP_RH_CAL_MOVILIDAD
   ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador,
     ln_dias_trabajados, asi_tipo_planilla ) ;
end if ;

-- Si la planilla es normal debo eliminar la bonificacion del tripulante
if asi_tipo_planilla = 'N' then
   delete calculo c
    where c.cod_trabajador = asi_codtra
      and c.tipo_planilla  = asi_tipo_planilla
      and c.fec_proceso    = adi_fec_proceso
      and c.concep         = usp_sigre_rrhh.is_cnc_bonif_tri;
end if;

usp_rh_cal_vacaciones
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ln_dias_mes, asi_tipo_planilla ) ;

usp_rh_cal_enfermedad
  ( asi_codtra, ls_tipo_trabajador, adi_fec_proceso, asi_origen, ln_tipcam, asi_tipo_planilla ) ;

usp_rh_cal_maternidad
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, asi_tipo_planilla ) ;

usp_rh_cal_reintegros
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ls_tipo_trabajador, asi_tipo_planilla ) ;

usp_rh_cal_ganancias_variables
  ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ,ls_tipo_trabajador, asi_tipo_planilla) ;

/*Calculo de Vacaciones, CTS y GRATI para Jornaleros o Tripulantes*/
   
select l.concep_cts, l.concep_gratif, l.concep_vacaciones
 into ls_concep_CTS, ls_concep_GRATI, ls_concep_VACA
 from fl_param l
where l.reckey = '1';
   
If ls_tipo_trabajador in (ls_tipo_obr,ls_tipo_trip, ls_tipo_ser) Then
  IF ls_flag_calcula_GRATI = '1' THEN
     -- Calculo de gratificacion
     
     Select NVL(Sum(Nvl(c.imp_soles,0)),0)
       Into ln_imp_soles
       From calculo c,
            (select distinct concepto_calc 
               from grupo_calculo_det 
              where grupo_calculo in (ls_grp_afecto_GRATI, '036')) gcc
      Where c.concep          = gcc.concepto_calc 
        AND c.cod_trabajador  = asi_codtra
        and c.tipo_planilla   = asi_tipo_planilla;
         
     if ln_imp_soles > 0 then
        ln_imp_soles := ln_imp_soles / 6;
        ln_imp_dolar := ln_imp_soles / ln_tipcam;
         
        update calculo c
           set c.imp_soles   = ln_imp_soles,
               c.imp_dolar   = ln_imp_dolar,
               c.dias_trabaj = ln_dias_trabajados
         where c.cod_trabajador = asi_codtra
           and c.concep         = ls_concep_GRATI
           and c.tipo_planilla  = asi_tipo_planilla;
        
        if SQL%NOTFOUND then
           Insert Into calculo(
                  cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                  dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item,
                  tipo_planilla)
           Values(
                  asi_codtra, ls_concep_GRATI, adi_fec_proceso, 0, 0, ln_dias_trabajados, 
                  ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                  asi_tipo_planilla);
        end if;
        
        -- ahora calculo la bonficacion extraordinaria
        if ln_imp_soles > 0 then
           ln_imp_soles := ln_imp_soles * USP_SIGRE_RRHH.in_porc_bonif_ext;
           ln_imp_dolar := ln_imp_soles / ln_tipcam;
             
           update calculo c
              set c.imp_soles   = ln_imp_soles,
                  c.imp_dolar   = ln_imp_dolar,
                  c.dias_trabaj = ln_dias_trabajados
            where c.cod_trabajador = asi_codtra
              and c.concep         = USP_SIGRE_RRHH.is_cnc_bonif_ext
              and c.tipo_planilla  = asi_tipo_planilla;
            
           if SQL%NOTFOUND then
              Insert Into calculo(
                     cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                     dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item, 
                     tipo_planilla)
              Values(
                     asi_codtra, USP_SIGRE_RRHH.is_cnc_bonif_ext, adi_fec_proceso, 0, 0, ln_dias_trabajados, 
                     ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                     asi_tipo_planilla);
           end if;
        end if;
     end if;
  END IF;
      
  IF ls_flag_calcula_VACA = '1' THEN
     -- Calculo de vacaciones
      Select Sum(Nvl(c.imp_soles,0))
       Into ln_imp_soles
       From calculo c,
            (select distinct concepto_calc from grupo_calculo_det where grupo_calculo in (ls_grp_afecto_VACA, '806')) gcc
      Where c.concep          = gcc.concepto_calc
        and c.cod_trabajador  = asi_codtra;
         
     if ln_imp_soles > 0 then
         ln_imp_soles := ln_imp_soles / 12;
         ln_imp_dolar := ln_imp_soles / ln_tipcam;

         update calculo c
            set c.imp_soles   = ln_imp_soles,
                c.imp_dolar   = ln_imp_dolar,
                c.dias_trabaj = ln_dias_trabajados
          where c.cod_trabajador = asi_codtra
            and c.concep         = ls_concep_VACA
            and c.tipo_planilla  = asi_tipo_planilla;
         
         if SQL%NOTFOUND then
            Insert Into calculo(
                   cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                   dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item,
                   tipo_planilla)
            Values(
                   asi_codtra, ls_concep_VACA, adi_fec_proceso, 0, 0, ln_dias_trabajados, 
                   ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                   asi_tipo_planilla);
         end if;
     end if;
  END IF;
      
  IF ls_flag_calcula_CTS = '1' THEN
     -- Obtengo el monto de la Gratificacion
     select nvl(sum(c.imp_soles), 0)
       into ln_imp_gratif
       from calculo c
      where c.cod_trabajador  = asi_codtra
        and c.concep          = ls_concep_GRATI
        and c.fec_proceso     = adi_fec_proceso;
     
     -- Calculo del CTS
     Select Sum(Nvl(c.imp_soles,0))
       Into ln_imp_soles
       From calculo c,
            (select distinct concepto_calc from grupo_calculo_det where grupo_calculo in (ls_grp_afecto_CTS, '071')) gcc
      Where c.concep          = gcc.concepto_calc 
        AND c.cod_trabajador  = asi_codtra
        and c.fec_proceso     = adi_fec_proceso
        and c.tipo_planilla   = asi_tipo_planilla;
         
     if ln_imp_soles > 0 then
         ln_imp_soles := (ln_imp_soles + ln_imp_gratif / 6) / 12;
         ln_imp_dolar := ln_imp_soles / ln_tipcam;

         update calculo c
            set c.imp_soles   = ln_imp_soles,
                c.imp_dolar   = ln_imp_dolar,
                c.dias_trabaj = ln_dias_trabajados
          where c.cod_trabajador = asi_codtra
            and c.concep         = ls_concep_CTS
            and c.tipo_planilla  = asi_tipo_planilla;
         
         if SQL%NOTFOUND then
            Insert Into calculo(
                     cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                     dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion,item,
                     tipo_planilla)
            Values(
                     asi_codtra, ls_concep_CTS, adi_fec_proceso, 0, 0, ln_dias_trabajados, 
                     ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                     asi_tipo_planilla);
         end if;
     end if;
  END IF;
End If;


usp_rh_cal_ganancia_total
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_ingreso, asi_tipo_planilla ) ;

--  REALIZA CALCULOS DE DESCUENTOS POR TRABAJADOR
if ls_flag_cat_trab = '1' then
   if ls_cod_afp is null then
      usp_rh_cal_snp ( asi_codtra, adi_fec_proceso, asi_origen, asi_tipo_planilla ) ;
   else
      usp_rh_cal_afp ( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam ,ln_ano_tope_seg_inv ,ld_fec_nac, asi_tipo_planilla ) ;
   end if ;
end if;

-- Quinta categoria
-- Ahora se puede elejir si se calcula o no la renta de quinta
if asi_flag_renta_quinta = '1' then
   usp_rh_cal_quinta_categoria( asi_codtra, ls_tipo_trabajador, adi_fec_proceso, ln_tipcam, asi_origen, ln_dias_trabajados, asi_tipo_planilla ) ;
end if ;

-- Descuentos fijos
usp_rh_cal_descuentos_fijos
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_cnc_total_ingreso, asi_tipo_planilla ) ;

-- Descuento Comedor
usp_rh_cal_desct_comedor
  ( asi_codtra, asi_origen, adi_fec_proceso, ln_tipcam, asi_tipo_planilla ) ;
  
-- Descuentos variables
usp_rh_cal_descuento_variable
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, asi_tipo_planilla ) ;

-- Tardanzas
usp_rh_cal_tardanzas( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_tipo_trabajador, ls_grc_gan_fija, asi_tipo_planilla) ;

-- Judicial
usp_rh_cal_porcentaje_judicial( asi_codtra, adi_fec_proceso, asi_origen, ln_tipcam, ln_judicial, ln_judicial_utl, asi_codusr, asi_tipo_planilla ) ;

-- Essalud Vida
usp_rh_cal_essalud_vida
   ( asi_codtra, asi_origen, ln_tipcam, adi_fec_proceso,ls_tipo_trabajador, asi_tipo_planilla ) ;

-- Cuenta corriente
usp_rh_cal_cuenta_corriente
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen ,ls_cnc_total_ingreso, asi_tipo_planilla);

-- Descuento total
usp_rh_cal_descuento_total
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_dscto, asi_tipo_planilla ) ;

usp_rh_cal_total_pagado
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_ingreso,
    ls_cnc_total_dscto, ls_cnc_total_pagado, asi_tipo_planilla ) ;

--  REALIZA CALCULOS DE APORTACIONES PATRONALES
usp_rh_cal_apo_sctr_ipss
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, asi_tipo_planilla ) ;

usp_rh_cal_apo_sctr_onp
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, asi_tipo_planilla ) ;



-- Los tripulantes no llevan senati
if ls_tipo_trabajador <> ls_tipo_trip then
   usp_rh_cal_apo_senati
       ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, asi_tipo_planilla ) ;
end if;

-- Aportacion que se hace al actual REP 5% que le corresponde de ahora en adelante a los tripulantes
if ls_tipo_trabajador = ls_tipo_trip then
   usp_rh_cal_apo_rep( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, asi_tipo_planilla ) ;
end if;

--  Otras Aportaciones indicadas por el trabajador
usp_rh_cal_otras_aport( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen , ls_cnc_total_ingreso, asi_tipo_planilla) ;

--elimina calculos en cero
delete from calculo hc
  where hc.cod_trabajador = asi_codtra
    and hc.fec_proceso    = adi_fec_proceso
    and nvl(imp_soles,0)  = 0
    and nvl(imp_dolar,0)  = 0
    and hc.concep         <> ls_cnc_total_pagado
    and tipo_planilla     = asi_tipo_planilla;
 
-- Elimino tambien todo aquellos que no tienen neto pagado
delete calculo c
where c.cod_trabajador not in (select distinct cod_trabajador
                                  from calculo t
                                  where concep = ls_cnc_total_ingreso
                                    and t.tipo_planilla = asi_tipo_planilla)
   and c.cod_trabajador = asi_codtra
   and c.tipo_planilla  = asi_tipo_planilla;
                                  
-- Aportacion Especial Cred EPS
usp_rh_cal_cred_eps
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, asi_tipo_planilla ) ;

usp_rh_cal_apo_essalud
  ( asi_codtra, adi_fec_proceso, ln_tipcam, asi_origen, ls_tipo_trabajador, '1', asi_tipo_planilla ) ;

usp_rh_cal_apo_total
  ( asi_codtra, adi_fec_proceso, asi_origen, ls_cnc_total_aportes, asi_tipo_planilla ) ;

--elimina calculos en cero
delete from calculo hc
  where hc.cod_trabajador = asi_codtra
    and hc.fec_proceso    = adi_fec_proceso
    and nvl(imp_soles,0)  = 0
    and nvl(imp_dolar,0)  = 0
    and hc.concep         <> ls_cnc_total_pagado;

-- Elimino fantasmas
delete calculo t
where t.cod_trabajador not in (select distinct t.cod_trabajador
                                from calculo t
                                where t.fec_proceso = adi_fec_proceso
                                and t.concep = '2399')
and t.fec_proceso = adi_fec_proceso
and t.tipo_planilla = asi_tipo_planilla;    

end usp_rh_cal_calcula_planilla ;
/
