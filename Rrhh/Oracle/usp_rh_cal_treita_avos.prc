create or replace procedure usp_rh_cal_treita_avos (
  as_codtra   in char, as_codusr in char, ad_fec_proceso in date,
  as_tipo_doc in char, as_origen in char, ac_tip_trab    in tipo_trabajador.tipo_trabajador%type ) is

lk_inasistencia        char(3) ;
lk_ganancia_fija       char(3) ;

ln_contador            integer ;
ln_verifica            integer ;
ld_ran_ini             date ;
ld_ran_fin             date ;
ld_falta               date ;
ld_fec_feriado         date ;
ls_concepto            char(4) ;
ln_dia_feriado         number(2) ;
ln_faltas              number(7,2) ;
ln_valor               number(13,2) ;

--  Lectura de inasistencias en un rango de fechas
cursor c_inasistencia is
  select i.fec_movim, i.fec_desde, i.fec_hasta, i.dias_inasist
  from inasistencia i
  where i.cod_trabajador = as_codtra and (trunc(i.fec_movim) between ld_ran_ini and
        ld_ran_fin) and i.concep in (select d.concepto_calc from grupo_calculo_det d
        where d.grupo_calculo = lk_inasistencia) ;

begin

--  ********************************************************************
--  ***   REALIZA CALCULO DE TREINTA AVOS POR DIAS DE INASISTENCIA   ***
--  ********************************************************************

select c.gan_fij_dsct_treintavo, c.inasist_treinta_avo
  into lk_ganancia_fija, lk_inasistencia
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select p.fec_inicio, p.fec_final into ld_ran_ini, ld_ran_fin
  from rrhh_param_org p 
 where (p.origen          = as_origen   ) and
       (p.tipo_trabajador = ac_tip_trab ) AND
       trunc(p.fec_proceso) = trunc(ad_fec_proceso);

--select p.fec_desde, p.fec_hasta into ld_ran_ini, ld_ran_fin
--  from rrhhparam p where p.reckey = '1' ;

ln_faltas := 0 ;
for rc_ina in c_inasistencia loop

  for x in 1 .. nvl(rc_ina.dias_inasist,0) loop
    ld_falta := rc_ina.fec_desde + x - 1 ;
    if ld_falta = rc_ina.fec_movim then
      ln_faltas := ln_faltas + nvl(rc_ina.dias_inasist,0) ;
    end if ;
    ln_contador := 0 ;
    select count(*) into ln_contador from calendario_feriado f
      where f.mes <= to_number(to_char(ld_falta,'mm')) ;
    if ln_contador > 0 then
      select max(f.dia) into ln_dia_feriado from calendario_feriado f
        where f.mes = to_number(to_char(ld_falta,'mm')) ;
      ld_fec_feriado := ad_fec_proceso - to_number(to_char(ad_fec_proceso,'dd')) +
                        ln_dia_feriado ;
      if (ld_falta < ld_fec_feriado) then
        ln_faltas := ln_faltas + 1 ;
      end if ;
    end if ;
  end loop ;

end loop ;

if ln_faltas > 0 and ln_faltas < 30 then

  ln_verifica := 0 ;
  select count(*) into ln_verifica from grupo_calculo g
    where g.grupo_calculo = lk_inasistencia ;

  if ln_verifica > 0 then

    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = lk_inasistencia ;

    select sum(nvl(gdf.imp_gan_desc,0)) into ln_valor
      from gan_desct_fijo gdf
      where gdf.cod_trabajador = as_codtra and gdf.flag_estado = '1' and
            gdf.concep in ( select d.concepto_calc from grupo_calculo_det d
            where d.grupo_calculo = lk_ganancia_fija ) ;

    ln_valor := ln_valor / 30 / 30 * ln_faltas ;

    ln_contador := 0 ;
    select count(*) into ln_contador from gan_desct_variable g
       where g.cod_trabajador = as_codtra and g.concep = ls_concepto and
             g.fec_movim = ad_fec_proceso ;
    if ln_contador > 0 then
      update gan_desct_variable
        set imp_var = imp_var + ln_valor,
           flag_replicacion = '1'
        where cod_trabajador = as_codtra and concep = ls_concepto and
              fec_movim = ad_fec_proceso ;
    else
      insert into gan_desct_variable (
        cod_trabajador, fec_movim, concep, imp_var,
        cod_usr, tipo_doc, flag_replicacion )
      values (
        as_codtra , ad_fec_proceso, ls_concepto, ln_valor,
        as_codusr, as_tipo_doc, '1' ) ;
    end if ;

  end if ;

end if ;

end usp_rh_cal_treita_avos ;
/
