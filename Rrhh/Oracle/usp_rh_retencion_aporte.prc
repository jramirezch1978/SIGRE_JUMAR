create or replace procedure usp_rh_retencion_aporte (
  asi_cod_trabajador in string,
  as_ano in char,
  aso_fecha_reporte out string ) is

ls_cod_trabajador maestro.cod_trabajador%type ;
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


ls_concep_snp char(4);
ls_concep_afp_jubilacion char(4);
ls_concep_afp_invalidez char(4);
ls_concep_afp_comision char(4);
ls_concep_seguro_agrario char(4);
ls_concep_sctr_ipss char(4);
ls_concep_sctr_onp char(4);

--  Cursor para leer todos los activos del maestro
cursor c_maestro is
  select m.cod_trabajador, m.fec_ingreso, m.dni, m.nro_ipss, m.cod_afp, 
     m.nro_afp_trabaj, m.cod_seccion, a.desc_afp, m.tipo_trabajador, tt.desc_tipo_tra,
     m.cod_origen, o.nombre, m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2, s.desc_seccion
     from maestro m
        inner join admin_afp a on m.cod_afp = a.cod_afp
        inner join tipo_trabajador tt on m.tipo_trabajador = tt.tipo_trabajador
        inner join origen o on m.cod_origen = o.cod_origen
        inner join seccion s on m.cod_seccion = s.cod_seccion and m.cod_area = s.cod_area
     where m.flag_estado = '1' 
        and m.flag_cal_plnlla = '1'
        and m.cod_trabajador = asi_cod_trabajador ;

--  Cursor para leer aportes al sistema de pensiones
cursor c_historico is
  select hc.concep, hc.fec_calc_plan, hc.imp_soles
  from historico_calculo hc
  where hc.cod_trabajador = ls_cod_trabajador 
     and to_char(hc.fec_calc_plan,'MM') = ls_nro_mes 
     and to_char(hc.fec_calc_plan,'YYYY') = as_ano
  order by hc.cod_trabajador, hc.fec_calc_plan, hc.concep ;

begin

delete from tt_rh_retencion_importe ;

select gc.concepto_gen 
   into ls_concep_snp
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.snp from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_afp_jubilacion
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.afp_jubilacion from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_afp_invalidez
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.afp_invalidez from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_afp_comision
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.afp_comision from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_seguro_agrario
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.concep_seguro_agrario from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_sctr_ipss
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.concep_sctr_ipss from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_sctr_onp
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.concep_sctr_onp from rrhhparam_cconcep rc where rc.reckey = '1');

for rc_mae in c_maestro loop

  ls_cod_trabajador := rc_mae.cod_trabajador ;

  for x in 1 .. 12 loop

    ln_rem_asegurable := 0 ; ln_fdo_pensiones := 0 ;
    ln_seg_invalidez  := 0 ; ln_apo_comision  := 0 ;
    ln_aportes_onp    := 0 ; ln_seg_agrario   := 0 ;
    ln_seg_sctr       := 0 ;

    ls_nro_mes := lpad(rtrim(to_char(x)),2,'0') ;

    for rc_his in c_historico loop

      ls_concepto      := rc_his.concep ;
      ln_importe       := nvl(rc_his.imp_soles,0) ;

      if ls_concepto = ls_concep_afp_jubilacion then
        ln_fdo_pensiones  := ln_fdo_pensiones + ln_importe ;
        ln_rem_asegurable := ln_fdo_pensiones / 0.08 ;
      elsif ls_concepto = ls_concep_afp_invalidez then
        ln_seg_invalidez := ln_seg_invalidez + ln_importe ;
      elsif ls_concepto = ls_concep_afp_comision then
        ln_apo_comision := ln_apo_comision + ln_importe ;
      elsif ls_concepto = ls_concep_snp then
        ln_aportes_onp    := ln_aportes_onp + ln_importe ;
        ln_rem_asegurable := ln_aportes_onp / 0.13 ;
      elsif ls_concepto = ls_concep_seguro_agrario then
        ln_seg_agrario := ln_seg_agrario + ln_importe ;
      elsif ls_concepto = ls_concep_sctr_ipss then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      elsif ls_concepto = ls_concep_sctr_onp then
        ln_seg_sctr := ln_seg_sctr + ln_importe ;
      end if ;

    end loop ;

    if ln_rem_asegurable <> 0 then
      insert into tt_rh_retencion_importe (
        cod_trabajador, nro_mes, rem_asegurable, fdo_pensiones, seg_invalidez, 
        apo_comision, aportes_onp, seg_agrario, seg_sctr, desc_afp, cod_origen, 
        nomb_origen, cod_seccion, desc_seccion, nom_trab, dni, nro_afp, nro_ipss, 
        fec_ingreso, tipo_trab, desc_tipo_tra )
      values (
        ls_cod_trabajador, ls_nro_mes, ln_rem_asegurable, ln_fdo_pensiones,
        ln_seg_invalidez, ln_apo_comision, ln_aportes_onp, 
        ln_seg_agrario, ln_seg_sctr, rc_mae.desc_afp,  rc_mae.cod_origen,
        rc_mae.nombre, rc_mae.cod_seccion, rc_mae.desc_seccion,
        trim(nvl(rc_mae.apel_paterno,'')) || ' / ' || trim(nvl(rc_mae.apel_materno,'')) || ', ' || trim(nvl(rc_mae.nombre1,'')) || ' ' || trim(nvl(rc_mae.nombre2,'')),
        rc_mae.dni, rc_mae.nro_afp_trabaj, rc_mae.nro_ipss, rc_mae.fec_ingreso, rc_mae.tipo_trabajador, rc_mae.desc_tipo_tra);
    end if ;

  end loop ;

end loop ;
select to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss') into aso_fecha_reporte from dual;
end usp_rh_retencion_aporte ;
/
