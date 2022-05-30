create or replace procedure usp_rh_cal_afp (
  asi_codtra        in maestro.cod_trabajador%type,
  adi_fec_proceso   in date ,
  asi_origen        in origen.cod_origen%type,
  ani_tipcam        in number                     ,
  ani_tope_seg_inv  in rrhhparam.tope_ano_seg_inv%TYPE,
  adi_fec_nac       in DATE,
  asi_tipo_planilla in calculo.tipo_planilla%TYPE
) is

ls_grc_calc_rep        rrhhparam_cconcep.grp_calc_cbssp%TYPE;   --Calculo de Regimen Especial de Pensiones para Tripulantes
ls_grc_calc_afp        rrhhparam_cconcep.concep_calculo_afp%TYPE; -- Grupo de Calculo para la aFP

-- Conceptos para la AFP
ls_grc_jubilacion      rrhhparam_cconcep.afp_jubilacion%TYPE ;
ls_grc_invalidez       rrhhparam_cconcep.afp_invalidez%TYPE;
ls_grc_comision        rrhhparam_cconcep.afp_comision%TYPE;

-- Codigo para distinguir una AFP de la CBSSP (REP)
ls_cod_rep             rrhhparam.cod_cbssp%TYPE;

ln_imp_soles           calculo.imp_soles%TYPE;
ln_imp_dolar           calculo.imp_dolar%TYPE;
ln_anos                number(3)    ;
ln_mes_proceso         Number(2)    ;
ln_mes_nac             Number(2)    ;
ls_flag_algun_famil    maestro.flag_algun_famil%TYPE;
ln_porc_jubilac        number;
ln_porc_invalidez      number;
ln_porc_comision       number;
ln_imp_max_invalidez   calculo.imp_soles%TYPE;
ln_invalidez_mes       historico_calculo.imp_soles%TYPE;
ln_dscto_max_inval     number;
ln_year                number;

ln_imp_var_jubilac       calculo.imp_soles%TYPE;
ln_imp_var_jubilacd      calculo.imp_dolar%TYPE;
ln_imp_var_invalidez     calculo.imp_soles%TYPE;
ln_imp_var_invalidezd    calculo.imp_dolar%TYPE;
ln_imp_var_comision      calculo.imp_soles%TYPE;
ln_imp_var_comisiond     calculo.imp_dolar%TYPE;
ls_concepto              concepto.concep%TYPE ;
ls_cod_afp               maestro.cod_afp%TYPE ;
ls_flag_comision_afp     maestro.flag_comision_afp%TYPE;
ls_flag_estado           admin_afp.flag_estado%TYPE;
ln_porc_jubil_pesca      admin_afp.porc_jubilac_pesca%TYPE;
ls_tipo_trabaj           maestro.tipo_trabajador%TYPE;
ls_cnc_invalidez         concepto.concep%TYPE;

begin

--  ****************************************************
--  ***   REALIZA CALCULO POR DESCUENTOS DE A.F.P.   ***
--  ****************************************************
--edad del trabajador
ln_anos        := to_number(to_char(adi_fec_proceso,'YYYY')) - to_number(to_char(adi_fec_nac,'yyyy'))  ;
ln_mes_proceso := to_number(to_char(adi_fec_proceso,'MM')) ;
ln_mes_nac     := to_number(to_char(adi_fec_nac,'MM'))  ;
ln_year        := to_number(to_char(adi_fec_proceso,'YYYY'));

-- Obtengo la AFP y el tipo de comision asignado al trabajador
select m.cod_afp, NVL(m.flag_comision_afp,'0'), m.tipo_trabajador
  into ls_cod_afp, ls_flag_comision_afp, ls_tipo_trabaj
  from maestro m
 where m.cod_trabajador = asi_codtra ;
 
select c.afp_jubilacion, c.afp_invalidez, c.afp_comision, c.concep_calculo_afp,c.grp_calc_cbssp
  into ls_grc_jubilacion, ls_grc_invalidez, ls_grc_comision, ls_grc_calc_afp , ls_grc_calc_rep
  from rrhhparam_cconcep c
 where c.reckey = '1' ;

select r.cod_cbssp
  into ls_cod_rep
  from rrhhparam r
 where r.reckey = '1' ;

-- Obtengo el concepto de la invalidez
select g.concepto_gen 
  into ls_cnc_invalidez 
  from grupo_calculo g
 where g.grupo_calculo = ls_grc_invalidez ;


if ls_cod_afp <> ls_cod_rep then 
  
   select sum(nvl(c.imp_soles,0))
     into ln_imp_soles
     from calculo c
    where c.cod_trabajador = asi_codtra
      and c.tipo_planilla  = asi_tipo_planilla
      and c.concep IN ( select g.concepto_calc
                          from grupo_calculo_det g
                         WHERE g.grupo_calculo = ls_grc_calc_afp ) ;
      
else
  
   select sum(nvl(c.imp_soles,0))
     into ln_imp_soles
     from calculo c
    where c.cod_trabajador = asi_codtra
      and c.tipo_planilla  = asi_tipo_planilla
      and c.concep IN ( select g.concepto_calc
                          from grupo_calculo_det g
                         WHERE g.grupo_calculo = ls_grc_calc_rep ) ;
end if;                       

if ln_imp_soles > 0 then
   ln_imp_dolar := ln_imp_soles / ani_tipcam;

   select nvl(m.flag_algun_famil, '0'), 
          nvl(aa.porc_jubilac,0), 
          nvl(aa.porc_invalidez,0),
          DECODE(ls_flag_comision_afp, 1, 
          nvl(aa.porc_comision1,0), 
          nvl(aa.porc_comision2,0)), 
          nvl(aa.imp_tope_invalidez,0), 
          aa.flag_estado,
          nvl(aa.porc_jubilac_pesca, 0)
     into ls_flag_algun_famil, 
          ln_porc_jubilac, 
          ln_porc_invalidez,
          ln_porc_comision, 
          ln_imp_max_invalidez,
          ls_flag_estado,
          ln_porc_jubil_pesca
     from maestro   m, 
          admin_afp aa
    where m.cod_afp        = aa.cod_afp
      and m.cod_trabajador = asi_codtra
      AND aa.flag_estado   = '1' ;
   
   if ls_flag_estado <> '1' then
      RAISE_APPLICATION_ERROR(-20000, 'EL TRABAJADOR ESTA ASIGNADO A LA AFP / CBSSP ' || ls_cod_afp || ' LA CUAL ESTA INACTVIDA, POR FAVOR VERIFIQUE!.');
   end if;
   
   if ls_flag_algun_famil = '0' then
      if ls_tipo_trabaj = USP_SIGRE_RRHH.is_tipo_trip then
         ln_imp_var_jubilac  := ln_imp_soles * ln_porc_jubil_pesca / 100 ;
         ln_imp_var_jubilacd := ln_imp_dolar * ln_porc_jubil_pesca / 100 ;
      else
          ln_imp_var_jubilac  := ln_imp_soles * ln_porc_jubilac / 100 ;
          ln_imp_var_jubilacd := ln_imp_dolar * ln_porc_jubilac / 100 ;
      end if;

      -- Calculo de la comision de la AFP
      ln_imp_var_comision  := ln_imp_soles * ln_porc_comision / 100 ;
      ln_imp_var_comisiond := ln_imp_dolar * ln_porc_comision / 100 ;
      
      -- Calculo de la invalidez para la AFP
      -- Ojo que el descuento no debe pasar el importe maximo permitido
      ln_dscto_max_inval   := ln_imp_max_invalidez  * ln_porc_invalidez / 100;
      ln_imp_var_invalidez := ln_imp_soles * ln_porc_invalidez / 100 ;
      
      -- Obtengo todo el descuento realizado en el mes para la invalidez
      select nvl(sum(hc.imp_soles),0)
        into ln_invalidez_mes
        from historico_calculo hc
       where hc.cod_trabajador = asi_codtra
         and hc.concep         = ls_cnc_invalidez
         and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ln_year
         and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ln_mes_proceso;
      
      if ln_invalidez_mes > ln_dscto_max_inval then
         ln_imp_var_invalidez  := 0;
      else
         if ln_dscto_max_inval - ln_invalidez_mes < ln_imp_var_invalidez then
            ln_imp_var_invalidez  := ln_dscto_max_inval - ln_invalidez_mes;
         end if;         
      end if ;
      ln_imp_var_invalidezd := (ln_imp_var_invalidez / ani_tipcam);


   elsif ls_flag_algun_famil = '1' then
      ln_imp_var_jubilac  := 0 ; 
      ln_imp_var_invalidez := 0 ;
      ln_imp_var_comision := 0 ;
   elsif ls_flag_algun_famil = '2' then
      ln_imp_var_invalidez := 0 ;
   end if ;

  if ln_imp_var_jubilac > 0 then

     if ls_cod_afp = ls_cod_rep then
        select g.concepto_gen
          into ls_concepto
          from grupo_calculo g
         where g.grupo_calculo = ls_grc_calc_rep ;
     else
        select g.concepto_gen
          into ls_concepto
          from grupo_calculo g
         where g.grupo_calculo = ls_grc_jubilacion ;
       
     end if ;
     
     insert into calculo (
            cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
            dias_trabaj, imp_soles, imp_dolar,  cod_origen, flag_replicacion, item,
            tipo_planilla )
     values (
            asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
            0, ln_imp_var_jubilac, ln_imp_var_jubilacd, asi_origen, '1', 1,
            asi_tipo_planilla ) ;
  end if ;

  --verificar parametros de edad tope para calculo de importe de invalidez
  if ln_imp_var_invalidez > 0 then

     if ln_anos < ani_tope_seg_inv then

        Insert into calculo(
                cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                dias_trabaj, imp_soles, imp_dolar,  cod_origen, flag_replicacion, item, 
                tipo_planilla )
        Values(
                asi_codtra, ls_cnc_invalidez, adi_fec_proceso, 0, 0,
                0, ln_imp_var_invalidez , ln_imp_var_invalidezd , asi_origen, '1', 1,
                asi_tipo_planilla ) ;

     elsif ln_anos = ani_tope_seg_inv then

         if ln_mes_proceso <= ln_mes_nac then
            Insert into calculo(
                   cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                   dias_trabaj, imp_soles, imp_dolar,  cod_origen, flag_replicacion, item,
                   tipo_planilla )
            Values(
                   asi_codtra, ls_cnc_invalidez, adi_fec_proceso, 0, 0,
                   0, ln_imp_var_invalidez , ln_imp_var_invalidezd , asi_origen, '1', 1,
                   asi_tipo_planilla ) ;
         end if ;
     end if ;

  end if ;
  
  -- Importe de Comision
  if ln_imp_var_comision > 0 then
     select g.concepto_gen 
       into ls_concepto 
       from grupo_calculo g
      where g.grupo_calculo = ls_grc_comision ;
      
     insert into calculo (
            cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
            dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
            tipo_planilla )
     values (
            asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
            0, ln_imp_var_comision, ln_imp_var_comisiond, asi_origen, '1', 1,
            asi_tipo_planilla ) ;
  end if ;

end if ;

end usp_rh_cal_afp ;
/
