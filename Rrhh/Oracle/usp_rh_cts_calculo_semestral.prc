create or replace procedure usp_rh_cts_calculo_semestral (
  asi_codtra       in maestro.cod_trabajador%TYPE,
  adi_fec_proceso  in date
) is

ls_grp_prom_remun_vacac     rrhhparam_cconcep.prom_remun_vacac%TYPE;
ls_grp_bonificacion25       rrhhparam_cconcep.bonif_vacacion25%TYPE;
ls_grp_bonificacion30       rrhhparam_cconcep.bonif_vacacion30%TYPE;
ls_grp_gan_fij_calc_cts     rrhhparam_cconcep.gan_fij_calc_cts%TYPE ;
ls_grp_grati_medio_ano      rrhhparam_cconcep.grati_medio_ano%TYPE ;
ls_grp_grati_fin_ano        rrhhparam_cconcep.grati_fin_ano%TYPE;
ls_grp_gan_var_ppto         rrhhparam_cconcep.gan_var_ppto%type ;
ls_grp_dias_descontar       rrhhparam_cconcep.dias_inasis_dsccont%TYPE;

ls_estado                   maestro.flag_estado%TYPE;

ld_fecha_ini                date ;
ld_fecha_fin                date ;

ls_tipo_emp                 rrhhparam.tipo_trab_empleado%TYPE;
ls_tipo_jor                 rrhhparam.tipo_trab_obrero%TYPE;
ls_tipo_des                 rrhhparam.tipo_trab_destajo%TYPE;

ln_rem_computable         historico_calculo.imp_soles%type ;  -- Remuneración computable
ln_gratificacion          historico_calculo.imp_soles%TYPE;   -- Monto de la gratificación
ln_rem_variable           historico_calculo.imp_soles%TYPE;   -- remuneraciones Variables
ln_rem_fija               historico_calculo.imp_soles%TYPE;   -- Remuneración Fija
ln_CTS_calculado          prov_cts_gratif.prov_cts_01%TYPE;   -- Importe del CTS Calculado
ln_dias_trabaj            NUMBER;
ln_dias_inasistencia      NUMBER;
ln_dias                   NUMBER;
ld_fecha1                 DATE;
ld_fecha2                 DATE;

-- Maestro de Trabajadores
ls_bonificacion             maestro.bonif_fija_30_25%type ;
ls_cod_seccion              maestro.cod_seccion%type ;
ld_fec_ingreso              maestro.fec_ingreso%type ;
ld_fec_cese                 maestro.fec_cese%TYPE;
ls_cencos                   maestro.cencos%TYPE;
ls_tipo_trabajador          maestro.tipo_trabajador%TYPE;
ls_reint_gratif             concepto.concep%TYPE := '1483';


begin

--  **************************************************************
--  ***   REALIZA CALCULO DE C.T.S. SEMESTRAL POR TRABAJADOR   ***
--  **************************************************************

-- Elimino lo que este calculado
  delete CTS_DECRETO_URGENCIA
    where cod_trabajador = asi_codtra
      and fec_proceso    = adi_fec_proceso;

-- Capturo los parametros iniciales
select c.prom_remun_vacac, c.bonificacion25, c.bonificacion30,
       c.gan_fij_calc_cts, c.grati_medio_ano, c.grati_fin_ano, 
       c.gan_var_ppto, c.dias_inasis_dsccont
  into ls_grp_prom_remun_vacac, ls_grp_bonificacion25, ls_grp_bonificacion30,
       ls_grp_gan_fij_calc_cts, ls_grp_grati_medio_ano, ls_grp_grati_fin_ano,
       ls_grp_gan_var_ppto, ls_grp_dias_descontar
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select r.tipo_trab_destajo, r.tipo_trab_empleado, r.tipo_trab_obrero
  into ls_tipo_des, ls_tipo_emp, ls_tipo_jor
  from rrhhparam r
 where r.reckey = '1';
 
select m.bonif_fija_30_25, m.cod_seccion, m.fec_ingreso, m.fec_cese,
       m.cencos, m.tipo_trabajador, nvl(flag_estado, '0')
  into ls_bonificacion, ls_cod_seccion, ld_fec_ingreso, ld_fec_cese,          
       ls_cencos, ls_tipo_trabajador, ls_estado
  from maestro m 
 where m.cod_trabajador = asi_codtra ;

if ls_estado = '0' then return; end if;
 
-- Calculo las fechas de inicio y fin de periodo para el CTS de acuerdo a la fecha de proceso
if to_char(adi_fec_proceso, 'mm') in ('04', '05') then
   ld_fecha_ini := to_date('01/11/' || to_char(to_number(to_char(adi_fec_proceso, 'yyyy')) - 1), 'dd/mm/yyyy');
   ld_fecha_fin := to_date('30/04/' || to_char(adi_fec_proceso, 'yyyy'), 'dd/mm/yyyy');
else
   ld_fecha_ini := to_date('01/05/' || to_char(adi_fec_proceso, 'yyyy'), 'dd/mm/yyyy');
   ld_fecha_fin := to_date('31/10/' || to_char(adi_fec_proceso, 'yyyy'), 'dd/mm/yyyy');
end if;

-- Si ingresó después no se le calcula CTS
if trunc(ld_fec_ingreso) > trunc(ld_fecha_fin) then return; end if ;

-- Primer sumo la remuneración que percibe actualmente
select NVL(sum(gdf.imp_gan_desc),0)
  INTO ln_rem_fija
from gan_desct_fijo gdf
where gdf.cod_trabajador = asi_codtra and gdf.flag_estado = '1' and
      gdf.concep in ( select d.concepto_calc 
                        from grupo_calculo_det d
                       where d.grupo_calculo = ls_grp_gan_fij_calc_cts ) ;

--  Sumo todos los ingresos de sobretiempo que sean variables o imprecisas
 select NVL(sum(hc.imp_soles),0)
  into ln_rem_variable
  from historico_calculo hc,
       grupo_calculo_det gcd
 where hc.concep = gcd.concepto_calc
   and gcd.grupo_calculo = ls_grp_gan_var_ppto
   and hc.cod_trabajador = asi_codtra 
   AND hc.fec_calc_plan between ld_fecha_ini and ld_fecha_fin ;

-- Calcular la gratificación pagada
select NVL(sum(hc.imp_soles),0)
  into ln_gratificacion
  from historico_calculo hc
 where hc.cod_trabajador = asi_codtra 
   and hc.fec_calc_plan between ld_fecha_ini and ld_fecha_fin
   and (hc.concep in ( select g.concepto_gen 
                        from grupo_calculo g
                       where g.grupo_calculo in (ls_grp_grati_fin_ano, ls_grp_grati_medio_ano) )
        or hc.concep = ls_reint_gratif) ;

if ls_tipo_trabajador = ls_tipo_des then
  ln_rem_computable := (ln_rem_fija + ln_rem_variable) / 12 + ln_gratificacion / 6;
else
  ln_rem_computable := ln_rem_fija + ln_rem_variable / 6 + ln_gratificacion / 6;
end if;


  -- Calculo los días trabjados 
  
  IF ld_fec_ingreso < ld_fecha_ini THEN
     ld_fecha1 := ld_fecha_ini;
  ELSE
     ld_fecha1 := ld_fec_ingreso;
  END IF;
  
  if ld_fec_cese is not null then
     IF ld_fec_cese > ld_fecha_fin THEN
        ld_Fecha2 := ld_fecha_fin;
     ELSE
        ld_fecha2 := ld_fec_cese;
     END IF;
  else
     ld_fecha2 := ld_fecha_fin;
  end if;
  
  -- Para Los empleados
  if ls_tipo_trabajador = 'EMP' then
     ln_dias_trabaj := usf_rh_calc_dias_trabaj(ld_fecha1, ld_fecha2);
     ln_dias_inasistencia := 0;
      
     -- Calculo los días de inasistencia
     select NVL(sum(i.dias_inasist),0)
       INTO ln_dias
       FROM inasistencia i
      where i.cod_trabajador = asi_codtra
        and i.concep in ( select d.concepto_calc
                          from grupo_calculo_det d
                         where d.grupo_calculo = ls_grp_dias_descontar )
        and trunc(i.fec_movim) between trunc(ld_fecha_ini) and trunc(ld_fecha_fin) ;
      
     ln_dias_inasistencia := ln_dias_inasistencia + ln_dias;
     
     ln_dias_trabaj := ln_dias_trabaj - ln_dias_inasistencia;
     
  elsif ls_tipo_trabajador in ('DES', 'JOR') then
     -- PAra el caso de Obreros y destajeros tomare de la boleta mientras tanto
     select NVL(sum(s.dias_trabaj),0)
       into ln_dias_trabaj 
       from (select distinct hc.dias_trabaj, hc.fec_calc_plan
               from historico_calculo hc
              where hc.cod_trabajador = asi_codtra
                and hc.dias_trabaj  is not null
                and trunc(hc.fec_calc_plan) between ld_Fecha1 and ld_fecha2) s;
  elsif ls_tipo_trabajador = 'TRI' and asi_codtra = '40002785' then
     /*select count(distinct a.fecha)
       into ln_dias_trabaj
       from fl_asistencia a
      where a.tripulante = asi_codtra
         and trunc(a.fecha) between ld_Fecha1 and ld_Fecha2;*/
      ln_dias_trabaj := 180;
  else
     ln_dias_trabaj := 0;
  end if;
  
  
  IF ln_dias_trabaj > 180 THEN ln_dias_trabaj := 180; END IF;
  
  -- Para considerar el pago de CTS debe tener al menos un mes completo
  if ln_dias_trabaj < 30 then return; end if;
  
  --  Calcula C.T.S. del semestre
  if ls_tipo_trabajador = ls_tipo_des then
    ln_CTS_calculado := ln_rem_computable;
  else
    ln_CTS_calculado := ln_rem_computable / 360 * ln_dias_trabaj;
  end if;
  

  -- Lo ingreso al CTS_DCRETO_URGENCIA para el pago
  if ln_CTS_calculado <= 0 then return; end if;
      
  insert into CTS_DECRETO_URGENCIA(
         COD_TRABAJADOR, FEC_PROCESO, REMUNERACION, LIQUIDACION, CENCOS, dias_trabajados, 
         Gratificacion, Rem_Variable, Tipo_Trabajador)
  values(
         asi_codtra, adi_fec_proceso, ln_rem_fija, ln_cts_calculado, ls_cencos, ln_dias_trabaj,
         ln_gratificacion, ln_rem_variable, ls_tipo_trabajador); 

end usp_rh_cts_calculo_semestral ;
/
