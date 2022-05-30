create or replace procedure usp_rpt_certificados
  ( ad_fec_proceso   in date ,
    as_tipo_trabajador  in maestro.tipo_trabajador%type ,
    as_codtra           in maestro.cod_trabajador%type ) is

ls_descripcion    varchar2(40) ;  ls_nombres        varchar2(40) ;
ln_imp_fijo       number(13,2) ;  ln_imp_gra_vac    number(13,2) ;
ln_imp_variables  number(13,2) ;  ln_imp_total      number(13,2) ;
ln_imp_uit        number(13,2) ;  ln_imp_afp1       number(13,2) ;
ln_imp_afp2       number(13,2) ;  ln_imp_neto       number(13,2) ;
ln_imp_renta      number(13,2) ;  ln_imp_retencion  number(13,2) ;
ls_dia            char(2) ;       ls_mes            char(10) ;
ls_anno           char(4) ;       ls_des_trabajador char(20) ;
ln_sw             number(2) ;     ln_contador       integer ;

--  Cursor para leer todos los Obreros o Empleados
cursor c_maestro is
  select m.cod_trabajador, m.dni, m.cod_seccion
  from maestro m
  where m.flag_estado = '1' and m.flag_cal_plnlla = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_seccion, m.cod_trabajador ;

--  Cursor para leer un solo trabajador
cursor c_maestro_codigo is
  Select t.cod_trabajador, t.dni, t.cod_seccion
  from maestro t
  where t.flag_estado = '1' and t.flag_cal_plnlla = '1' and
        t.tipo_trabajador = as_tipo_trabajador and t.cod_trabajador = as_codtra ;

begin

delete from tt_rpt_certificados ;

ln_sw := 0 ;
if (as_codtra is null or as_codtra = ' ') then ln_sw := 1 ;
else ln_sw := 0 ;
end if ;

if as_tipo_trabajador = 'OBR' then
  ls_des_trabajador := 'O B R E R O S       ' ;
else
  ls_des_trabajador := 'E M P L E A D O S   ' ;
end if ;

select nvl(rh.und_impos_tribut,0)
  into ln_imp_uit from rrhhparam rh where rh.reckey = '1' ;

ls_dia  := to_char(ad_fec_proceso, 'DD') ;
ls_mes  := to_char(ad_fec_proceso, 'MONTH') ;
ls_anno := to_char(ad_fec_proceso, 'YYYY') ;

if ln_sw = 1 then

  for rc_mae in c_maestro loop

    ls_nombres  := usf_nombre_trabajador(rc_mae.cod_trabajador) ;

    select nvl(s.desc_seccion,' ')
      into ls_descripcion from seccion s
      where s.cod_seccion = rc_mae.cod_seccion ;

    ln_imp_fijo := 0 ; ln_imp_gra_vac := 0 ; ln_imp_variables := 0 ;
    ln_imp_afp1 := 0 ; ln_imp_afp2 := 0 ;    ln_imp_total := 0 ;
    ln_imp_neto := 0 ; ln_imp_renta := 0 ;   ln_imp_retencion := 0 ;

    ln_contador := 0 ;
    select count(*)
      into ln_contador from historico_calculo h
      where h.concep = '1015' and h.cod_trabajador = rc_mae.cod_trabajador and
            to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    if ln_contador > 0 then
      select sum(h.imp_soles)
        into ln_imp_afp1 from historico_calculo h
        where h.concep = '1015' and h.cod_trabajador = rc_mae.cod_trabajador and
              to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    end if ;

    ln_contador := 0 ;
    select count(*)
      into ln_contador from historico_calculo h
      where h.concep = '1016' and h.cod_trabajador = rc_mae.cod_trabajador and
            to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    if ln_contador > 0 then
      select sum(h.imp_soles)
        into ln_imp_afp2 from historico_calculo h
        where h.concep = '1016' and h.cod_trabajador = rc_mae.cod_trabajador and
              to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    end if ;

    select sum(q.rem_proyectable), sum(q.rem_imprecisa), sum(q.rem_retencion),
           sum(q.rem_gratif)
      into ln_imp_fijo, ln_imp_variables, ln_imp_retencion,
           ln_imp_gra_vac
      from quinta_categoria q
      where q.cod_trabajador = rc_mae.cod_trabajador and
            to_char(q.fec_proceso,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;

    ln_imp_total := ln_imp_fijo + ln_imp_gra_vac + ln_imp_variables ;
    ln_imp_neto  := ln_imp_total - ( ln_imp_uit + ln_imp_afp1 + ln_imp_afp2 ) ;
    ln_imp_renta := ln_imp_retencion ;

    --  Insertar los Registro en la tabla tt_rpt_certificados
    insert into tt_rpt_certificados (
      seccion, descripcion, codigo, nombres,
      dni, imp_fijos, imp_gra_vac, imp_variables,
      imp_total, uit, imp_afp_1023, imp_afp_300,
      imp_neto, imp_renta, imp_retencion, dia,
      mes, anno, des_trabajador )
    values (
      rc_mae.cod_seccion, ls_descripcion, rc_mae.cod_trabajador, ls_nombres,
      rc_mae.dni, ln_imp_fijo, ln_imp_gra_vac, ln_imp_variables,
      ln_imp_total, ln_imp_uit, ln_imp_afp1, ln_imp_afp2,
      ln_imp_neto, ln_imp_renta, ln_imp_retencion, ls_dia,
      ls_mes, ls_anno, ls_des_trabajador) ;

  end loop ;

else

  for rc_mae in c_maestro_codigo loop

    ls_nombres  := usf_nombre_trabajador(rc_mae.cod_trabajador) ;

    select nvl(s.desc_seccion,' ')
      into ls_descripcion from seccion s
      where s.cod_seccion = rc_mae.cod_seccion ;

    ln_imp_fijo := 0 ; ln_imp_gra_vac := 0 ; ln_imp_variables := 0 ;
    ln_imp_afp1 := 0 ; ln_imp_afp2 := 0 ;    ln_imp_total := 0 ;
    ln_imp_neto := 0 ; ln_imp_renta := 0 ;   ln_imp_retencion := 0 ;

    ln_contador := 0 ;
    select count(*)
      into ln_contador from historico_calculo h
      where h.concep = '1015' and h.cod_trabajador = rc_mae.cod_trabajador and
            to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    if ln_contador > 0 then
      select sum(h.imp_soles)
        into ln_imp_afp1 from historico_calculo h
        where h.concep = '1015' and h.cod_trabajador = rc_mae.cod_trabajador and
              to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    end if ;

    ln_contador := 0 ;
    select count(*)
      into ln_contador from historico_calculo h
      where h.concep = '1016' and h.cod_trabajador = rc_mae.cod_trabajador and
            to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    if ln_contador > 0 then
      select sum(h.imp_soles)
        into ln_imp_afp2 from historico_calculo h
        where h.concep = '1016' and h.cod_trabajador = rc_mae.cod_trabajador and
              to_char(h.fec_calc_plan,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;
    end if ;

    select sum(q.rem_proyectable), sum(q.rem_imprecisa), sum(q.rem_retencion),
           sum(q.rem_gratif)
      into ln_imp_fijo, ln_imp_variables, ln_imp_retencion,
           ln_imp_gra_vac
      from quinta_categoria q
      where q.cod_trabajador = rc_mae.cod_trabajador and
            to_char(q.fec_proceso,'YYYY') = to_char(ad_fec_proceso,'YYYY') ;

    ln_imp_total := ln_imp_fijo + ln_imp_gra_vac + ln_imp_variables ;
    ln_imp_neto  := ln_imp_total - ( ln_imp_uit + ln_imp_afp1 + ln_imp_afp2 ) ;
    ln_imp_renta := ln_imp_retencion ;

    --  Insertar los Registro en la tabla tt_rpt_certificados
    insert into tt_rpt_certificados (
      seccion, descripcion, codigo, nombres,
      dni, imp_fijos, imp_gra_vac, imp_variables,
      imp_total, uit, imp_afp_1023, imp_afp_300,
      imp_neto, imp_renta, imp_retencion, dia,
      mes, anno, des_trabajador )
    values (
      rc_mae.cod_seccion, ls_descripcion, rc_mae.cod_trabajador, ls_nombres,
      rc_mae.dni, ln_imp_fijo, ln_imp_gra_vac, ln_imp_variables,
      ln_imp_total, ln_imp_uit, ln_imp_afp1, ln_imp_afp2,
      ln_imp_neto, ln_imp_renta, ln_imp_retencion, ls_dia,
      ls_mes, ls_anno, ls_des_trabajador) ;

  end loop ;

end if ;

end usp_rpt_certificados ;
/
