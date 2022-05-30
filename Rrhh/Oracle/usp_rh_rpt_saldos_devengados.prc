create or replace procedure usp_rh_rpt_saldos_devengados (
  as_tipo_trabajador in char, ad_fec_proceso in date, as_origen in char ) is

ln_imp_gra         sldo_deveng.sldo_gratif_dev%type ;
ln_imp_rem         sldo_deveng.sldo_rem_dev%type ;
ln_imp_rac         sldo_deveng.sldo_racion%type ;
ln_imp_total       number(13,2) ;

ls_nombres         varchar2(40) ;
ls_desc_seccion    varchar2(40) ;
ln_contador        integer ;

--  Cursor para leer a los trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.cod_seccion, m.cod_area
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador and m.cod_origen = as_origen
  order by m.cod_seccion, m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2 ;

begin

--  ******************************************************************
--  ***   EMITE REPORTE DE SALDOS POR DEVENGADOS DE TRABAJADORES   ***
--  ******************************************************************

delete from tt_rpt_devengados ;

for rc_mae in c_maestro loop

  ln_contador := 0 ;
  select count(*) into ln_contador from sldo_deveng sd
    where sd.cod_trabajador = rc_mae.cod_trabajador and sd.fec_proceso = ad_fec_proceso ;

  if ln_contador > 0 then

    ln_imp_gra   := 0 ; ln_imp_rem := 0 ; ln_imp_rac := 0 ;
    ln_imp_total := 0 ;
    select nvl(sd.sldo_gratif_dev,0), nvl(sd.sldo_rem_dev,0), nvl(sd.sldo_racion,0)
        into ln_imp_gra, ln_imp_rem, ln_imp_rac from sldo_deveng sd
        where sd.cod_trabajador = rc_mae.cod_trabajador and
              sd.fec_proceso = ad_fec_proceso ;
    ln_imp_total := ln_imp_gra + ln_imp_rem + ln_imp_rac ;

    if ln_imp_total <> 0 then

      ls_nombres := usf_rh_nombre_trabajador(rc_mae.cod_trabajador) ;
      select s.desc_seccion into ls_desc_seccion from seccion s
        where s.cod_area = rc_mae.cod_area and s.cod_seccion = rc_mae.cod_seccion ;

      insert into tt_rpt_devengados (
        cod_trabajador, nombre, cod_seccion, desc_seccion,
        fecha, imp_gradev, imp_remdev, imp_racazu, imp_total )
      values (
        rc_mae.cod_trabajador, ls_nombres, rc_mae.cod_seccion, ls_desc_seccion,
        ad_fec_proceso, ln_imp_gra, ln_imp_rem, ln_imp_rac, ln_imp_total ) ;

    end if ;

  end if ;

end loop ;

end usp_rh_rpt_saldos_devengados ;
/
