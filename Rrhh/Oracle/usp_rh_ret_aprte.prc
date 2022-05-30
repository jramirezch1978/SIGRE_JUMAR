create or replace procedure usp_rh_ret_aprte (
  asi_cod_trabajador in string,
  asi_ano in string,
  asi_concep_snp in string,
  asi_concep_afp_jubilacion in string, 
  asi_concep_afp_invalidez in string,
  asi_concep_afp_comision in string,
  asi_concep_seguro_agrario in string,
  asi_concep_sctr_ipss in string,
  asi_concep_sctr_onp in string
  
) is

   ls_nro_mes char(2) ;
   ln_rem_asegurable number(13,2) ;
   ln_fdo_pensiones number(13,2) ;
   ln_seg_invalidez number(13,2) ;
   ln_apo_comision number(13,2) ;
   ln_aportes_onp number(13,2) ;
   ln_seg_agrario number(13,2) ;
   ln_seg_sctr number(13,2) ;

ls_concepto            concepto.concep%type ;
ln_importe             historico_calculo.imp_soles%type ;

cursor c_historico is
  select hc.concep, hc.fec_calc_plan, hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = asi_cod_trabajador
     and to_char(hc.fec_calc_plan,'MM') = ls_nro_mes 
     and to_char(hc.fec_calc_plan,'YYYY') = asi_ano
     and hc.concep in (asi_concep_afp_jubilacion, asi_concep_afp_invalidez, asi_concep_afp_comision, asi_concep_snp, asi_concep_seguro_agrario, asi_concep_sctr_ipss, asi_concep_sctr_onp);

begin


for x in 1 .. 12 loop

    ln_rem_asegurable := 0 ; ln_fdo_pensiones := 0 ;
    ln_seg_invalidez  := 0 ; ln_apo_comision  := 0 ;
    ln_aportes_onp    := 0 ; ln_seg_agrario   := 0 ;
    ln_seg_sctr       := 0 ;

    ls_nro_mes := lpad(rtrim(to_char(x)),2,'0') ;

    for rc_his in c_historico loop

      ls_concepto      := rc_his.concep ;
      ln_importe       := nvl(rc_his.imp_soles,0) ;

      if ls_concepto = asi_concep_afp_jubilacion then
        ln_fdo_pensiones  := ln_fdo_pensiones + ln_importe ;
        ln_rem_asegurable := ln_fdo_pensiones / 0.08 ;
      elsif ls_concepto = asi_concep_afp_invalidez then
        ln_seg_invalidez := ln_seg_invalidez + ln_importe ;
      elsif ls_concepto = asi_concep_afp_comision then
        ln_apo_comision := ln_apo_comision + ln_importe ;
      elsif ls_concepto = asi_concep_snp then
        ln_aportes_onp    := ln_aportes_onp + ln_importe ;
        ln_rem_asegurable := ln_aportes_onp / 0.13 ;
      elsif ls_concepto = asi_concep_seguro_agrario then
        ln_seg_agrario := ln_seg_agrario + ln_importe ;
      elsif ls_concepto = asi_concep_sctr_ipss then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      elsif ls_concepto = asi_concep_sctr_onp then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      end if ;

    end loop ;

    if ln_rem_asegurable <> 0 then
    
        
      insert into tt_rh_retencion_importe (
        cod_trabajador, nro_mes, rem_asegurable, fdo_pensiones, seg_invalidez, 
        apo_comision, aportes_onp, seg_agrario, seg_sctr, cod_afp, desc_afp, cod_origen, 
        nomb_origen, cod_seccion, desc_seccion, nom_trab, dni, nro_afp, nro_ipss, 
        fec_ingreso, tipo_trab, desc_tipo_tra )

      select m.cod_trabajador, ls_nro_mes, ln_rem_asegurable, ln_fdo_pensiones, ln_seg_invalidez, 
            ln_apo_comision, ln_aportes_onp, ln_seg_agrario, ln_seg_sctr, m.cod_afp, a.desc_afp, m.cod_origen,
            o.nombre, m.cod_seccion, s.desc_seccion, trim(nvl(m.apel_paterno, '')) ||' / '|| trim(nvl(m.apel_materno, '')) ||', '|| trim(nvl(m.nombre1, '')) ||' '|| trim(nvl(m.nombre2, '')),
            m.dni, m.nro_afp_trabaj, m.nro_ipss, m.fec_ingreso, m.tipo_trabajador, tt.desc_tipo_tra            
         from maestro m
            inner join admin_afp a on m.cod_afp = a.cod_afp
            inner join tipo_trabajador tt on m.tipo_trabajador = tt.tipo_trabajador
            inner join origen o on m.cod_origen = o.cod_origen
            inner join seccion s on m.cod_seccion = s.cod_seccion and m.cod_area = s.cod_area
         where m.cod_trabajador = asi_cod_trabajador ;

    end if ;

end loop ;

end usp_rh_ret_aprte ;
/
