create or replace function usf_rh_cal_dias_trabajados(
       asi_codtra          in maestro.cod_trabajador%TYPE ,
       asi_origen          in origen.cod_origen%TYPE,
       asi_tip_trab        in tipo_trabajador.tipo_trabajador%type,
       ani_dias_mes        in number,
       adi_fec_proceso     in date,
       asi_tipo_planilla   in calculo.tipo_planilla%TYPE
)return number is

ls_grp_dias_inasis         rrhhparam_cconcep.dias_inasis_dsccont%TYPE;
ls_tipo_trabaj             maestro.tipo_trabajador%TYPE;
ls_cnc_vacaciones          concepto.concep%TYPE;
ln_dias                    number;
ld_fec_desde               date ;
ld_fec_hasta               date ;
ln_dias_trabajados         number(4,2) ;
ln_faltas                  number ;
ln_count                   number;
ln_dias_obrero             NUMBER;
ln_dias_campo              NUMBER;
ln_dias_destajo            number;
ld_fec_ing_trab            maestro.fec_ingreso%TYPE;
ld_fec_cese                maestro.fec_cese%TYPE;
ls_flag_tipo_sueldo        tipo_trabajador.flag_ingreso_boleta%TYPE;

--  Cursor de inasistencias a descontar
cursor c_inasistencias is
  select i.dias_inasist 
    from inasistencia i
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

  -- Determinar si el pago es por jornal o fijo
  select t.flag_ingreso_boleta, t.tipo_trabajador
    into ls_flag_tipo_sueldo, ls_tipo_trabaj
    from tipo_trabajador t
   where t.tipo_trabajador = asi_tip_trab;
   
  select c.dias_inasis_dsccont
    into ls_grp_dias_inasis
    from rrhhparam_cconcep c
   where c.reckey = '1' ;
  
  -- Obtengo el concepto de vacaciones
  select gc.concepto_gen
    into ls_cnc_vacaciones
    from grupo_calculo gc
   where gc.grupo_calculo = (select t.gan_fij_calc_vacac from rrhhparam_cconcep t);
  
  select count(*)
    into ln_count
   from rrhh_param_org p
   where p.origen          = asi_origen
     and p.tipo_trabajador = asi_tip_trab
     and trunc(p.fec_proceso) = trunc(adi_fec_proceso)
     and p.tipo_planilla      = asi_tipo_planilla;

  if ln_count = 0 then
       RAISE_APPLICATION_ERROR(-20000, 'Error, no ha especificado parametros para el origen ' || asi_origen ||
                                       ', fecha proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy') ||
                                       ', tipo_trabajador: ' || asi_tip_trab ||
                                       ', Tipo Planilla: ' || asi_tipo_planilla);
  end if;

  select trunc(t.fec_inicio), trunc(t.fec_final)
    into ld_fec_desde, ld_fec_hasta
    from rrhh_param_org t
   where trunc(t.fec_proceso) = trunc(adi_fec_proceso)
     and t.origen             = asi_origen
     and t.tipo_trabajador    = asi_tip_trab
     and t.tipo_planilla      = asi_tipo_planilla;

  -- Obtengo la fecha de inicio de trabajo del trabajador
  select m.fec_ingreso, m.fec_cese
    into ld_fec_ing_trab, ld_fec_cese
    from maestro m
   where m.cod_trabajador = asi_codtra;
  
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
  
  if asi_tip_trab = USP_SIGRE_RRHH.is_tipo_trip then
     
     if asi_tipo_planilla = 'B' then
        -- Calculo los días fijos
        select nvl(sum(f.nro_dias),0)
          into ln_dias_trabajados 
          from fl_dias_motorista f
         where f.anio            = to_number(to_char(adi_fec_proceso, 'yyyy'))
           and f.mes             = to_number(to_char(adi_fec_proceso, 'mm'))
           and f.cod_motorista   = asi_codtra;
     else 
        -- Si el flag de bonificacion de pesca no esta activa entoces no lo calculo nada mas
        select count(distinct fa.fecha)
          into ln_dias_trabajados
          from fl_asistencia fa
         where fa.tripulante = asi_codtra
           and trunc(fa.fecha) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta);
     end if;
     
  elsif asi_tip_trab in (USP_SIGRE_RRHH.is_tipo_des, USP_SIGRE_RRHH.is_tipo_ser) then
  
     select count(distinct p.fec_parte)
       into ln_dias_trabajados
       from tg_pd_destajo p,
            tg_pd_destajo_det pd
      where p.nro_parte = pd.nro_parte
        and pd.cod_trabajador = asi_codtra
        and trunc(p.fec_parte) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta)
        and p.flag_estado <> '0';
      
  else
      IF ls_tipo_trabaj in (USP_SIGRE_RRHH.is_tipo_des, USP_SIGRE_RRHH.is_tipo_jor) or ls_flag_tipo_sueldo = 'J' THEN
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

         SELECT COUNT(DISTINCT a.fec_parte)
           INTO ln_dias_destajo
           FROM tg_pd_destajo a,
                tg_pd_destajo_det b
          WHERE a.nro_parte      = b.nro_parte
            and b.cod_trabajador = asi_codtra
            AND trunc(a.fec_parte) BETWEEN trunc(ld_fec_desde) AND trunc(ld_fec_hasta)
            and a.flag_estado <> '0';
         
         ln_dias_trabajados := ln_dias_campo + ln_dias_obrero + ln_dias_destajo;
      ELSE
         ln_faltas := 0 ;
         for rc_ina in c_inasistencias loop
           ln_faltas := ln_faltas + nvl(rc_ina.dias_inasist,0) ;
         end loop ;
         
         ln_dias := ld_fec_hasta - ld_fec_desde + 1;
         
         if to_char(adi_fec_proceso, 'mm') = '02' then 
            if trunc(ld_fec_hasta) = trunc(Last_day(adi_fec_proceso)) then
               ln_dias := ln_dias + (30 - (trunc(usf_last_day(adi_fec_proceso)) - trunc(to_date('01/02/2015', 'dd/mm/yyyy'))));
            end if;
         end if;
         
         if ln_dias > ani_dias_mes then
            ln_dias := ani_dias_mes;
         end if;

         if ln_dias < ln_faltas then
            ln_dias_trabajados := 0;
         else
            ln_dias_trabajados := ln_dias - ln_faltas ;
         end if;

      END IF;
  end if;


  if ln_dias_trabajados > ln_dias then
     ln_dias_trabajados := ln_dias ;
  end if ;

  if ln_dias_trabajados > ani_dias_mes then
     ln_dias_trabajados := ani_dias_mes;
  end if;

  return(nvl(ln_dias_trabajados,0)) ;

end usf_rh_cal_dias_trabajados ;
/
