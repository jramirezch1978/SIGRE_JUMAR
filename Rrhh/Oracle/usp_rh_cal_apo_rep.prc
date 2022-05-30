create or replace procedure usp_rh_cal_apo_rep(
       asi_codtra           in maestro.cod_trabajador%type  ,
       adi_fec_proceso      in date                         ,
       ani_tipcam           in calendario.vta_dol_prom%type ,
       asi_origen           in origen.cod_origen%type       ,
       asi_tipo_planilla    in calculo.tipo_planilla%TYPE   
) is

ls_grp_rep_aport          grupo_calculo.grupo_calculo%type  ;
ls_concepto               concepto.concep%type              ;
ln_count                  Number                            ;
ln_imp_soles              calculo.imp_soles%TYPE            ;
ln_imp_dolar              calculo.imp_dolar%TYPE            ;
ln_porc_aporte_armador    admin_afp.porc_aporte_armador%TYPE;
ls_cod_afp                maestro.cod_afp%TYPE              ;


begin

  select c.grp_calc_cbssp_aport
    into ls_grp_rep_aport
    from rrhhparam_cconcep c
   where c.reckey = '1' ;
   
  -- Obtengo el codigo de la afp del trabajador
  select cod_afp
    into ls_cod_afp
    from maestro m
   where m.cod_trabajador = asi_codtra;

  -- Si no tiene AFP entonces simplemente termino el procedure ya que no corresponde el aporte
  if ls_cod_afp is null or trim(nvl(ls_cod_afp,'')) = '' then return; end if;

  select NVL(a.porc_aporte_armador, 0)
    into ln_porc_aporte_armador
    from admin_afp a
   where a.cod_afp = ls_cod_afp;
  
  if ln_porc_aporte_armador = 0 then
     RAISE_APPLICATION_ERROR(-20000, 'NO SE HA ESPCIFICADO EL PORCENTAJE DEL APORTE DEL ARMADOR PARA EL REP, POR FAVOR VERIFIQUE!');
  end if;
     
  -- Verifico que exista el concepto de calculo
  select count(*)
    into ln_count
    from grupo_calculo g
   where g.grupo_calculo = ls_grp_rep_aport ;

  if ln_count = 0 then return ; end if ;
  
  if ls_cod_afp = USP_SIGRE_RRHH.is_afp_rep then
    
     select g.concepto_gen
       into ls_concepto
       from grupo_calculo g
      where g.grupo_calculo = ls_grp_rep_aport;
     
  else
     ls_concepto := PKG_CONFIG.USF_GET_PARAMETER('CONCEPTO_APORTE_SPP_PESCADOR', '3013');
  end if;

  
  -- Sumo el importe correspondiente para el aporte
  select sum(nvl(c.imp_soles,0))
    into ln_imp_soles
    from calculo c
   where c.cod_trabajador = asi_codtra
     and c.tipo_planilla  = asi_tipo_planilla
     and c.concep in ( select d.concepto_calc
                         from grupo_calculo_det d
                        where d.grupo_calculo = ls_grp_rep_aport ) ;

  if ln_imp_soles > 0 then
     ln_imp_soles := ln_imp_soles * ln_porc_aporte_armador / 100 ;
     ln_imp_dolar := ln_imp_soles / ani_tipcam ;
     
     insert into calculo (
            cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
            dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
            tipo_planilla )
     values (
            asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
            0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
            asi_tipo_planilla ) ;
  end if ;

end usp_rh_cal_apo_rep ;
/
