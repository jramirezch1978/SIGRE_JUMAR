create or replace function usf_rh_calc_dias_grupo
(
       asi_codtra          in maestro.cod_trabajador%TYPE ,
       asi_origen          in origen.cod_origen%TYPE,
       asi_tip_trab        in tipo_trabajador.tipo_trabajador%type,
       ani_dias_mes        in number,
       adi_desde           in date,
       adi_hasta           in date
)return number is

ls_grp_dias_inasis         rrhhparam_cconcep.dias_inasis_dsccont%TYPE;
ls_cnc_vacaciones          concepto.concep%TYPE;
ln_dias                    number;
ln_dias_JOR                NUMBER;
ln_dias_DES                number;
ln_dias_campo              NUMBER;
ln_dias_trip               number;
ln_dias_motorista          number;
ls_flag_tipo_sueldo        tipo_trabajador.flag_ingreso_boleta%TYPE;
ls_tipo_trip               rrhhparam.tipo_trab_tripulante%TYPE;
ls_tipo_des                rrhhparam.tipo_trab_destajo%TYPE;
ls_tipo_ser                rrhhparam.tipo_trab_servis%TYPE;
ls_tipo_emp                rrhhparam.tipo_trab_empleado%TYPE;

ln_tot_dias_trabaj         number;




begin

--  ***********************************************************************
--  ***   REALIZA CALCULO DE DIAS TRABAJADOS PARA CALCULO DE PLANILLA   ***
--  ***********************************************************************

  -- Determinar si el pago es por jornal o fijo
  select t.flag_ingreso_boleta
    into ls_flag_tipo_sueldo
    from tipo_trabajador t
   where t.tipo_trabajador = asi_tip_trab;
   
  select c.dias_inasis_dsccont
    into ls_grp_dias_inasis
    from rrhhparam_cconcep c
   where c.reckey = '1' ;
  
  select r.tipo_trab_tripulante, r.tipo_trab_destajo, r.tipo_trab_servis, r.tipo_trab_empleado
    into ls_tipo_trip, ls_tipo_des, ls_tipo_ser, ls_tipo_emp
    from rrhhparam r
   where r.reckey = '1' ;
     
  -- Obtengo el concepto de vacaciones
  select gc.concepto_gen
    into ls_cnc_vacaciones
    from grupo_calculo gc
   where gc.grupo_calculo = (select t.gan_fij_calc_vacac from rrhhparam_cconcep t);
  
  -- Dias como tripulante
  select count(distinct fa.fecha)
    into ln_dias_trip
    from fl_asistencia fa
   where fa.tripulante = asi_codtra
     and trunc(fa.fecha) BETWEEN trunc(adi_desde) AND trunc(adi_hasta);
    
  -- Dias como motorista
  select sum(fa.nro_dias)
    into ln_dias_motorista
    from fl_dias_motorista fa
   where fa.cod_motorista = asi_codtra
     and trim(to_char(fa.anio, '0000')) || trim(to_char(fa.mes, '00'))  BETWEEN to_char(adi_desde, 'yyyymm') AND to_char(adi_hasta, 'yyyymm');

  -- Dias como jornalero
  SELECT COUNT(DISTINCT a.fec_movim)
    INTO ln_dias_JOR
    FROM asistencia a
   WHERE a.cod_trabajador = asi_codtra
     AND trunc(a.fec_movim) BETWEEN trunc(adi_desde) AND trunc(adi_hasta);

  SELECT COUNT(DISTINCT a.fecha)
    INTO ln_dias_campo
    FROM pd_jornal_campo a
   WHERE a.cod_trabajador = asi_codtra
     AND trunc(a.fecha) BETWEEN trunc(adi_desde) AND trunc(adi_hasta);

  -- Dias como destajo
  select count(distinct a.fec_parte)
    into ln_dias_DES
    from tg_pd_destajo     a,
         tg_pd_destajo_det b
   where a.nro_parte = b.nro_parte
     and a.flag_estado <> '0'
     and b.cod_trabajador = asi_codtra
     AND trunc(a.fec_parte) BETWEEN trunc(adi_desde) AND trunc(adi_hasta);
     
  /*select nvl(sum(dias),0)
    into ln_dias_DES
    from (
         select nvl(sum(distinct hc.dias_trabaj),0) as dias
           from historico_calculo hc
          where hc.cod_trabajador = asi_codtra
            and hc.concep         in ('1107', '1201')
            and trunc(hc.fec_calc_plan) between adi_desde and adi_hasta
          union all
          select nvl(sum(distinct c.dias_trabaj),0)
           from calculo c
          where c.cod_trabajador = asi_codtra
            and c.concep         in ('1107', '1201')
            and trunc(c.fec_proceso) between adi_desde and adi_hasta
          );
  */  
  -- Dias como empleado
  if asi_tip_trab = ls_tipo_emp then
     select nvl(sum(dias),0)
       into ln_dias
       from (
             select nvl(sum(hc.dias_trabaj),0) as dias
               from historico_calculo hc
              where hc.cod_trabajador = asi_codtra
                and hc.concep         in ('1001', '1463', '1459')
                and trunc(hc.fec_calc_plan) between adi_desde and adi_hasta
              union all
              select nvl(sum(c.dias_trabaj),0)
               from calculo c
              where c.cod_trabajador = asi_codtra
                and c.concep         in ('1001', '1463', '1459')
                and trunc(c.fec_proceso) between adi_desde and adi_hasta
              );
  else
     ln_dias := 0;
  end if;
             
  ln_tot_dias_trabaj := nvl(ln_dias_campo,0) + nvl(ln_dias_DES,0) + nvl(ln_dias_JOR, 0) + NVL(ln_dias,0) + case when NVL(ln_dias_trip,0)= 0 then NVL(ln_dias_motorista, 0) else NVL(ln_dias_trip, 0) end;
  
  if ln_tot_dias_trabaj > ani_dias_mes then ln_tot_dias_trabaj := ani_dias_mes; end if;
  
  return(nvl(ln_tot_dias_trabaj,0)) ;

end usf_rh_calc_dias_grupo ;
/
