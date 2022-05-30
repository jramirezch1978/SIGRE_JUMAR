create or replace procedure usp_rh_liq_genera_comp_adi (
  as_cod_trabajador in char, ad_fec_liquidacion in date,
  an_nro_sueldos in number, as_usuario in char ) is

ld_fec_proceso        date ;
ld_fec_promedio       date ;
ld_ran_ini            date ;
ld_ran_fin            date ;
ln_verifica           integer ;
ln_num_mes            integer ;

ls_grupo_gan          char(2) ;
ls_bonificacion       char(1) ;
ls_nivel              char(3) ;
ls_grp_raccoc         char(3) ;
ls_grp_25             char(3) ;
ls_grp_30             char(3) ;
ls_concepto           char(4) ;
ls_comp_adi           char(4) ;
ls_desc_concepto      varchar2(60) ;

ln_item               number(3) ;
ln_ult_remun          number(13,2) ;
ln_imp_racion         number(13,2) ;
ln_imp_variable       number(13,2) ;
ln_acum_sobret        number(13,2) ;
ln_prom_sobret        number(13,2) ;
ln_imp_bonif          number(13,2) ;
ln_factor             number(9,6) ;

--  Lectura de remuneraciones del trabajador
cursor c_ganancias is
  select g.concep, g.imp_gan_desc
  from gan_desct_fijo g
  where g.cod_trabajador = as_cod_trabajador and nvl(g.flag_estado,'0') = '1' and
        substr(g.concep,1,2) = ls_grupo_gan
  order by g.cod_trabajador, g.concep ;

--  Lectura de conceptos para promedios de sobretiempos
cursor c_conceptos is
  select d.concepto_calc
  from grupo_calculo_det d
  where d.grupo_calculo = ls_nivel ;

begin

--  ****************************************************************
--  ***   GENERA COMPENSACION ADICIONAL POR NUMEROS DE SUELDOS   ***
--  ****************************************************************

select p.cncp_comp_dic into ls_comp_adi from rh_liqparam p
  where p.reckey = '1' ;
  
delete from rh_liq_saldos_cnta_crrte s
  where s.cod_trabajador = as_cod_trabajador and s.concep = ls_comp_adi ;
  
ln_verifica := 0 ; ls_desc_concepto := null ;
select count(*) into ln_verifica from concepto c
  where c.concep = ls_comp_adi ;
if ln_verifica > 0 then
  select c.desc_concep into ls_desc_concepto from concepto c
    where c.concep = ls_comp_adi ;
end if ;
  
select p.grc_gnn_fija into ls_grupo_gan from rrhhparam p
  where p.reckey = '1' ;
  
select p.prom_remun_vacac, p.calculo_racion_cocida, p.bonificacion25, p.bonificacion30
  into ls_nivel, ls_grp_raccoc, ls_grp_25, ls_grp_30
  from rrhhparam_cconcep p where p.reckey = '1' ;

select nvl(m.bonif_fija_30_25,'0') into ls_bonificacion from maestro m
  where m.cod_trabajador = as_cod_trabajador ;

--  Acumula remuneraciones de ganancias fijas
ln_ult_remun := 0 ; ln_imp_racion := 0 ;
for rc_gan in c_ganancias loop
  ln_verifica := 0 ; ls_concepto := null ;
  select count(*) into ln_verifica from grupo_calculo g
    where g.grupo_calculo = ls_grp_raccoc ;
  if ln_verifica > 0 then
    select g.concepto_gen into ls_concepto from grupo_calculo g
      where g.grupo_calculo = ls_grp_raccoc ;
  end if ;
  if rc_gan.concep = ls_concepto then
    ln_imp_racion := ln_imp_racion + nvl(rc_gan.imp_gan_desc,0) ;
  else
    ln_ult_remun := ln_ult_remun + nvl(rc_gan.imp_gan_desc,0) ;
  end if ;
end loop ;

--  Calcula promedio de sobretiempos de los ultimos seis meses
ln_verifica := 0 ; ld_fec_promedio := null ;
select count(*) into ln_verifica from calculo c
  where to_char(c.fec_proceso,'mm/yyyy') = to_char(ad_fec_liquidacion,'mm/yyyy') ;
if ln_verifica > 0 then
  ld_fec_promedio := ad_fec_liquidacion ;
else
  select max(c.fec_proceso) into ld_fec_promedio
    from calculo c ;
end if ;  

ln_prom_sobret := 0 ; ls_concepto := null ;
for rc_con in c_conceptos loop
  ld_fec_proceso := last_day(to_date('01'||'/'||to_char(ld_fec_promedio,'mm')||'/'||
                    to_char(ld_fec_promedio,'yyyy'),'dd/mm/yyyy')) ;
  ld_ran_ini := add_months(ld_fec_proceso, - 1) ;
  ln_num_mes := 0 ; ln_acum_sobret := 0 ;
  for x in reverse 1 .. 6 loop
    ld_ran_fin := ld_ran_ini ;
    ld_ran_ini := add_months( ld_ran_fin, -1 ) + 1 ;
    ln_verifica := 0 ; ln_imp_variable := 0 ;
    select count(*)
      into ln_verifica from historico_calculo hc
      where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = as_cod_trabajador and
            hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
    if ln_verifica > 0 then
      select sum(nvl(hc.imp_soles,0))
        into ln_imp_variable from historico_calculo hc
        where hc.concep = rc_con.concepto_calc and hc.cod_trabajador = as_cod_trabajador and
              hc.fec_calc_plan between ld_ran_ini and ld_ran_fin ;
    end if ;
    if ln_imp_variable <> 0 then
      ln_num_mes := ln_num_mes + 1 ;
      ln_acum_sobret := ln_acum_sobret + ln_imp_variable ;
    end if ;
    ld_ran_ini := ld_ran_ini - 1 ;
  end loop ;
  if ln_num_mes > 2 then
    ln_prom_sobret := ln_prom_sobret + (ln_acum_sobret / 6 ) ;
  end if ;
end loop ;
ln_ult_remun := ln_ult_remun + ln_prom_sobret ;

--  Calcula bonificacion del 30% o 25%
ln_imp_bonif := 0 ; ls_concepto := null ; ln_factor := 0 ;
if nvl(ls_bonificacion,'0') = '1' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_30 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_bonif := ln_ult_remun * ln_factor ;
elsif nvl(ls_bonificacion,'0') = '2' then
  select g.concepto_gen into ls_concepto from grupo_calculo g
    where g.grupo_calculo = ls_grp_25 ;
  select nvl(c.fact_pago,0) into ln_factor from concepto c
    where c.concep = ls_concepto ;
  ln_imp_bonif := ln_ult_remun * ln_factor ;
end if ;
ln_ult_remun := ln_ult_remun + ln_imp_bonif + ln_imp_racion ;

--  Determina importe de compensacion adicional por nro. de sueldos
ln_ult_remun := nvl(ln_ult_remun,0) * nvl(an_nro_sueldos,0) ;

--  Inserta movimiento de compensacion variable
ln_verifica := 0 ; ln_item := 1 ;
select count(*) into ln_verifica from rh_liq_saldos_cnta_crrte s
  where s.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then
  select max(nvl(s.item,0)) into ln_item from rh_liq_saldos_cnta_crrte s
    where s.cod_trabajador = as_cod_trabajador ;
  ln_item := ln_item + 1 ;
end if ;
  
insert into rh_liq_saldos_cnta_crrte (
  cod_trabajador, item, concep, descripcion, fec_registro,
  flag_estado, imp_total, imp_aplicado, flag_forma_reg, cod_usr )
values (
  as_cod_trabajador, ln_item, ls_comp_adi, ls_desc_concepto, ad_fec_liquidacion,
  '1', ln_ult_remun, 0, 'G', as_usuario ) ;

end usp_rh_liq_genera_comp_adi ;
/
