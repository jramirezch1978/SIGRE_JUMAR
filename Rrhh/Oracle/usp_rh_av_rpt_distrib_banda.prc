create or replace procedure usp_rh_av_rpt_distrib_banda (
  as_origen in char, as_tipo_trabajador in char, an_ano in number,
  an_mes in number ) is

lk_administrativo     constant char(3) := 'ADM' ;
lk_operativo          constant char(3) := 'OPE' ;
lk_ganancias_fijas    char(3) ;

ln_verifica           integer ;
ls_grupo_calculo      char(3) ;
ls_cod_area           char(1) ;
ls_desc_area          varchar2(30) ;
ls_banda              char(6) ;
ls_desc_banda         varchar2(60) ;

ln_por_adm            number(6,3) ;
ln_por_ope            number(6,3) ;
ln_basico_adm         number(13,2) ;
ln_nro_adm            number(4) ;
ln_basico_ope         number(13,2) ;
ln_nro_ope            number(4) ;
ln_basico_tot         number(13,2) ;
ln_nro_tot            number(4) ;
ln_imp_por_adm        number(13,2) ;
ln_imp_por_ope        number(13,2) ;
ln_contador           integer ;
ln_importe_adm        number(13,2) ;
ln_importe_ope        number(13,2) ;

ln_adm_porc           number(6,3) ;
ln_adm_soles          number(13,2) ;
ln_adm_tope           number(13,2) ;
ln_ope_porc           number(6,3) ;
ln_ope_soles          number(13,2) ;
ln_ope_tope           number(13,2) ;

--  Lectura de gerencias de la empresa
cursor c_gerencias is
  select a.cod_area, a.desc_area
  from area a
  where a.cod_area <= '9'
  order by a.cod_area ;

--  Lectura de las bandas salariales
cursor c_banda_salarial is
  select bs.banda, bs.descripcion
  from rrhh_banda_salarial bs
  where bs.flag_estado = '1'
  order by bs.banda ;
  
--  Lectura para distribuciones de administrativos y operativos
cursor c_distribucion is
  select d.ano, d.mes, d.cod_area, d.banda, d.basico_adm, d.nro_adm,
         d.basico_ope, d.nro_ope
  from tt_av_rpt_distribucion d
  where d.ano = an_ano and d.mes = an_mes and d.cod_area = ls_cod_area
  order by d.banda ;
  
begin

--  ***************************************************************
--  ***   GENERA DISTRIBUCION DE BANDA SALARIAL POR SECCIONES   ***
--  ***************************************************************

delete from tt_av_rpt_distribucion ;

select c.concep_gan_fij into lk_ganancias_fijas
   from rrhhparam_cconcep c where c.reckey = '1';
    
ln_por_adm := 0 ; ln_por_ope := 0 ;
select (nvl(ct.porcentaje,0) / 100)
  into ln_por_adm from rrhh_condicion_trabajador ct
  where ct.contra = lk_administrativo ;
select (nvl(ct.porcentaje,0) / 100)
  into ln_por_ope from rrhh_condicion_trabajador ct
  where ct.contra = lk_operativo ;
  
--  Lectura de las gerencias de la empresa
for rc_ger in c_gerencias loop

  ls_cod_area  := rc_ger.cod_area ;
  ls_desc_area := rc_ger.desc_area ;

  --  Lectura de las bandas salariales
  for rc_ban in c_banda_salarial loop

    ls_banda      := rc_ban.banda ;
    ls_desc_banda := rc_ban.descripcion ;

    ln_basico_tot  := 0 ; ln_nro_tot     := 0 ;
    ln_imp_por_adm := 0 ; ln_imp_por_ope := 0 ;

    --  Determina basico del personal administrativo por banda salarial
    ln_verifica := 0 ; ln_basico_adm := 0 ; ln_nro_adm := 0 ;
    select count(*) into ln_verifica from calculo c, maestro m
      where c.concep in ( select d.concepto_calc from grupo_calculo_det d
                          where d.grupo_calculo = lk_ganancias_fijas ) and
            c.cod_trabajador = m.cod_trabajador and
            m.banda = ls_banda and m.contra = lk_administrativo and
            m.cod_area = ls_cod_area and m.cod_origen = as_origen and
            m.tipo_trabajador like as_tipo_trabajador and
            to_number(to_char(c.fec_proceso,'yyyy')) = an_ano and
            to_number(to_char(c.fec_proceso,'mm')) = an_mes ;
    if ln_verifica > 0 then
      select sum(nvl(c.imp_soles,0)) into ln_basico_adm from calculo c, maestro m
        where c.concep in ( select d.concepto_calc from grupo_calculo_det d
                            where d.grupo_calculo = lk_ganancias_fijas ) and
              c.cod_trabajador = m.cod_trabajador and
              m.banda = ls_banda and m.contra = lk_administrativo and
              m.cod_area = ls_cod_area and m.cod_origen = as_origen and
              m.tipo_trabajador like as_tipo_trabajador and
              to_number(to_char(c.fec_proceso,'yyyy')) = an_ano and
              to_number(to_char(c.fec_proceso,'mm')) = an_mes ;
      ln_nro_adm := ln_verifica ;
    end if ;
          
    --  Determina basico del personal operativo por banda salarial
    ln_verifica := 0 ; ln_basico_ope := 0 ; ln_nro_ope := 0 ;
    select count(*) into ln_verifica from calculo c, maestro m
      where c.concep in ( select d.concepto_calc from grupo_calculo_det d
                          where d.grupo_calculo = lk_ganancias_fijas ) and
            c.cod_trabajador = m.cod_trabajador and
            m.banda = ls_banda and m.contra = lk_operativo and
            m.cod_area = ls_cod_area and m.cod_origen = as_origen and
            m.tipo_trabajador like as_tipo_trabajador and
            to_number(to_char(c.fec_proceso,'yyyy')) = an_ano and
            to_number(to_char(c.fec_proceso,'mm')) = an_mes ;
    if ln_verifica > 0 then
      select sum(nvl(c.imp_soles,0)) into ln_basico_ope from calculo c, maestro m
        where c.concep in ( select d.concepto_calc from grupo_calculo_det d
                            where d.grupo_calculo = lk_ganancias_fijas ) and
              c.cod_trabajador = m.cod_trabajador and
              m.banda = ls_banda and m.contra = lk_operativo and
              m.cod_area = ls_cod_area and m.cod_origen = as_origen and
              m.tipo_trabajador like as_tipo_trabajador and
              to_number(to_char(c.fec_proceso,'yyyy')) = an_ano and
              to_number(to_char(c.fec_proceso,'mm')) = an_mes ;
      ln_nro_ope := ln_verifica ;
    end if ;

    --  Determina importe basico por administrativos y operativos
    ln_basico_tot := ln_basico_adm + ln_basico_ope ;
    ln_nro_tot    := ln_nro_adm + ln_nro_ope ;

    if nvl(ln_basico_tot,0) <> 0 then
      insert into tt_av_rpt_distribucion (
        ano, mes, cod_area, desc_area, banda, desc_banda,
        basico_adm, nro_adm, basico_ope, nro_ope, basico_tot,
        nro_tot, imp_por_adm, imp_por_ope, adm_porc, adm_soles,
        adm_tope, ope_porc, ope_soles, ope_tope )
      values (
        an_ano, an_mes, ls_cod_area, ls_desc_area, ls_banda, ls_desc_banda,
        ln_basico_adm, ln_nro_adm, ln_basico_ope, ln_nro_ope, ln_basico_tot,
        ln_nro_tot, ln_imp_por_adm, ln_imp_por_ope, 0, 0,
        0, 0, 0, 0 ) ;
    end if ;

  end loop ;

  --  Determina porcentaje de distribucion de la planilla
  ln_verifica := 0 ; ln_importe_adm := 0 ; ln_importe_ope := 0 ;
  select count(*) into ln_verifica from tt_av_rpt_distribucion d
    where d. cod_area = ls_cod_area ;
  if ln_verifica > 0 then
    select sum(nvl(d.basico_adm,0)), sum(nvl(d.basico_ope,0))
      into ln_imp_por_adm, ln_imp_por_ope
      from tt_av_rpt_distribucion d
      where d. cod_area = ls_cod_area ;
    ln_imp_por_adm := ln_imp_por_adm * ln_por_adm ;
    ln_imp_por_ope := ln_imp_por_ope * ln_por_ope ;
    ln_importe_adm := ln_imp_por_adm ;
    ln_importe_ope := ln_imp_por_ope ;
  end if ;

  --  Lectura para distribuciones de administrativos y operativos
  ln_contador  := 0 ;
  for rc_dis in c_distribucion loop
    
    ln_contador := ln_contador + 1 ;
    if ln_contador > 1 then
      ln_importe_adm := 0 ;
      ln_importe_ope := 0 ;
    end if ;

    ln_adm_porc := 0 ; ln_adm_soles := 0 ; ln_adm_tope := 0 ;
    ln_ope_porc := 0 ; ln_ope_soles := 0 ; ln_ope_tope := 0 ;

    ln_adm_soles := nvl(rc_dis.basico_adm,0) * ln_por_adm ;
    ln_adm_porc  := ln_adm_soles / ln_imp_por_adm ;
    if nvl(rc_dis.nro_adm,0) <> 0 then
      ln_adm_tope := ln_adm_soles / nvl(rc_dis.nro_adm,0) ;
    end if ;
    ln_ope_soles := nvl(rc_dis.basico_ope,0) * ln_por_ope ;
    ln_ope_porc  := ln_ope_soles / ln_imp_por_ope ;
    if nvl(rc_dis.nro_ope,0) <> 0 then
      ln_ope_tope := ln_ope_soles / nvl(rc_dis.nro_ope,0) ;
    end if ;

    update tt_av_rpt_distribucion d
      set d.imp_por_adm = ln_importe_adm ,
          d.imp_por_ope = ln_importe_ope ,
          d.adm_porc    = ln_adm_porc ,
          d.adm_soles   = ln_adm_soles ,
          d.adm_tope    = ln_adm_tope ,
          d.ope_porc    = ln_ope_porc ,
          d.ope_soles   = ln_ope_soles ,
          d.ope_tope    = ln_ope_tope
      where d.ano = an_ano and d.mes = an_mes and d.cod_area = rc_dis.cod_area and
            d.banda = rc_dis.banda ;

  end loop ;
    
end loop ;

end usp_rh_av_rpt_distrib_banda ;
/
