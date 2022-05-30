create or replace procedure usp_rh_liq_rpt_cabecera (
  as_cod_trabajador in char, as_nombres in char ) is

ld_fec_ingreso        date ;
ls_cod_motces         char(2) ;
ls_des_motces         varchar2(20) ;
ls_cod_cargo          char(8) ;
ls_des_cargo          varchar2(30) ;
ls_nro_liquidacion    char(10) ;
ld_fec_liquidacion    date ;
ln_ts_ano             number(2) ;
ln_ts_mes             number(2) ;
ln_ts_dia             number(2) ;
ln_ult_remun          number(13,2) ;
ln_liq_bensoc         number(13,2) ;
ln_liq_remune         number(13,2) ;
ln_imp_liquid         number(13,2) ;

ls_concepto           char(4) ;
ls_grat_jul           char(3) ;
ls_grat_dic           char(3) ;
ld_fec_gratif         date ;
ls_year               char(4) ;
ln_verifica           integer ;
ln_imp_gratif         number(13,2) ;
ln_importe            number(13,2) ;

begin

--  *********************************************************
--  ***   TEMPORAL PARA GENERAR CABECERA DE LIQUIDACION   ***
--  *********************************************************

delete from tt_liq_rpt_cabecera ;

select p.grati_medio_ano, p.grati_fin_ano
  into ls_grat_jul, ls_grat_dic
  from rrhhparam_cconcep p where p.reckey = '1' ;

select m.fec_ingreso, m.cod_motiv_cese, mc.desc_motiv_cese, m.cod_cargo, 
       c.desc_cargo, cl.nro_liquidacion, cl.fec_liquidacion, cl.tm_anos,
       cl.tm_meses, cl.tm_dias, cl.ult_remuneracion, cl.imp_liq_befef_soc,
       cl.imp_liq_remun
  into ld_fec_ingreso, ls_cod_motces, ls_des_motces, ls_cod_cargo,
       ls_des_cargo, ls_nro_liquidacion, ld_fec_liquidacion, ln_ts_ano,
       ln_ts_mes, ln_ts_dia, ln_ult_remun, ln_liq_bensoc,
       ln_liq_remune
  from maestro m, motivo_cese mc, cargo c, rh_liq_credito_laboral cl
  where m.cod_trabajador = as_cod_trabajador and
        m.cod_trabajador = cl.cod_trabajador and
        m.cod_motiv_cese = mc.cod_motiv_cese(+) and
        m.cod_cargo = c.cod_cargo(+) ;

ln_imp_liquid := nvl(ln_liq_bensoc,0) + nvl(ln_liq_remune,0) ;
  
--  Halla promedio de la ultima gratificacion
ls_concepto := null ;
if to_number(to_char(ld_fec_liquidacion,'mm')) <= 07 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grat_dic ;
  ls_year := to_char(to_number(to_char(ld_fec_liquidacion,'yyyy')) - 1) ;
  ld_fec_gratif := to_date('31'||'/'||'12'||'/'||ls_year,'dd/mm/yyyy') ;
elsif to_number(to_char(ld_fec_liquidacion,'mm')) > 07 or
      to_number(to_char(ld_fec_liquidacion,'mm')) < 12 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grat_jul ;
  ls_year := to_char (ld_fec_liquidacion,'yyyy') ;
  ld_fec_gratif := to_date('31'||'/'||'07'||'/'||ls_year,'dd/mm/yyyy') ;
elsif to_number(to_char(ld_fec_liquidacion,'mm')) = 12 then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grat_jul ;
  ls_year := to_char(ld_fec_liquidacion,'yyyy') ;
  ld_fec_gratif := to_date('31'||'/'||'07'||'/'||ls_year,'dd/mm/yyyy') ;
end if ;

ln_verifica := 0 ; ln_imp_gratif := 0 ;
select count(*) into ln_verifica from historico_calculo hc
  where hc.concep = ls_concepto and hc.cod_trabajador = as_cod_trabajador and
        hc.fec_calc_plan = ld_fec_gratif ;
if ln_verifica > 0 then
  select sum(nvl(hc.imp_soles,0)) into ln_imp_gratif from historico_calculo hc
    where hc.concep = ls_concepto and hc.cod_trabajador = as_cod_trabajador and
          hc.fec_calc_plan = ld_fec_gratif ;
  ln_imp_gratif := ln_imp_gratif / 6 ;
else
  ln_verifica := 0 ;
  select count(*) into ln_verifica from calculo c
    where c.concep = ls_concepto and c.cod_trabajador = as_cod_trabajador ;
  if ln_verifica > 0 then
    select nvl(c.imp_soles,0) into ln_imp_gratif from calculo c
      where c.concep = ls_concepto and c.cod_trabajador = as_cod_trabajador ;
    ln_imp_gratif := ln_imp_gratif / 6 ;
  end if ;
end if ;

ln_importe := nvl(ln_ult_remun,0) - nvl(ln_imp_gratif,0) ;

--  Inserta informacion en la tabla temporal
insert into tt_liq_rpt_cabecera (
  cod_trabajador, nombres, fec_ingreso, cod_motces, des_motces,
  cod_cargo, des_cargo, nro_liquidacion, fec_liquidacion, ts_ano,
  ts_mes, ts_dia, ult_remun, liq_bensoc, liq_remune, imp_liquid,
  importe )
values (
  as_cod_trabajador, as_nombres, ld_fec_ingreso, ls_cod_motces, ls_des_motces,
  ls_cod_cargo, ls_des_cargo, ls_nro_liquidacion, ld_fec_liquidacion, ln_ts_ano,
  ln_ts_mes, ln_ts_dia, ln_ult_remun, ln_liq_bensoc, ln_liq_remune, ln_imp_liquid,
  ln_importe ) ;

end usp_rh_liq_rpt_cabecera ;
/
