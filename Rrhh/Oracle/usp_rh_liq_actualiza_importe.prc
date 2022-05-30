create or replace procedure usp_rh_liq_actualiza_importe (
  as_cod_trabajador in char ) is

ln_verifica            integer ;
ls_grp_indemn          char(6) ;
ls_grp_desben          char(6) ;
ls_grp_leysoc          char(6) ;
ls_grp_desrem          char(6) ;

ln_importe             number(13,2) ;
ln_importe_gan         number(13,2) ;
ln_importe_des         number(13,2) ;
ln_liq_bensoc          number(13,2) ;
ln_liq_remune          number(13,2) ;

begin

select p.grp_indemnizacion, p.grp_dscto_cta_cte, p.grp_dscto_leyes, p.grp_dscto_remun
  into ls_grp_indemn, ls_grp_desben, ls_grp_leysoc, ls_grp_desrem
  from rh_liqparam p where p.reckey = '1' ;
  
--  ********************************************************************
--  ***   ACTUALIZA IMPORTES DE LIQUIDACION DE BENEFICIOS SOCIALES   ***
--  ********************************************************************

ln_importe_gan := 0 ; ln_importe_des := 0 ;

--  Determina liquidacion por fondo de retiro
ln_verifica := 0 ; ln_importe := 0 ;
select count(*) into ln_verifica from rh_liq_fondo_retiro f
  where f.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then  
  select sum(nvl(f.imp_x_liq_anos,0) + nvl(f.imp_x_liq_meses,0) + nvl(f.imp_x_liq_dias,0))
    into ln_importe from rh_liq_fondo_retiro f
    where f.cod_trabajador = as_cod_trabajador ;
  ln_importe_gan := ln_importe_gan + nvl(ln_importe,0) ;
end if ;
  
--  Determina liquidacion por compensacion tiempo de servicio
ln_verifica := 0 ; ln_importe:= 0 ;
select count(*) into ln_verifica from rh_liq_cts c
  where c.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then  
  select sum(nvl(c.deposito,0) + nvl(c.interes,0))
    into ln_importe from rh_liq_cts c
    where c.cod_trabajador = as_cod_trabajador ;
  ln_importe_gan := ln_importe_gan + nvl(ln_importe,0) ;
end if ;

--  Determina liquidacion por compensacion adicional
ln_verifica := 0 ; ln_importe := 0 ;
select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
  where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_indemn ;
if ln_verifica > 0 then
  select sum(nvl(d.importe,0)) into ln_importe from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_indemn ;
  ln_importe_gan := ln_importe_gan + nvl(ln_importe,0) ;
end if ;  

--  Determina descuentos de beneficios sociales
ln_verifica := 0 ; ln_importe := 0 ;
select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
  where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_desben ;
if ln_verifica > 0 then
  select sum(nvl(d.importe,0)) into ln_importe from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_desben ;
  ln_importe_des := ln_importe_des + nvl(ln_importe,0) ;
end if ;

ln_liq_bensoc := nvl(ln_importe_gan,0) - nvl(ln_importe_des,0) ;

--  ***************************************************************
--  ***   ACTUALIZA IMPORTES DE LIQUIDACION DE REMUNERACIONES   ***
--  ***************************************************************

ln_importe_gan := 0 ; ln_importe_des := 0 ;

--  Determina liquidacion por remuneraciones
ln_verifica := 0 ; ln_importe := 0 ;
select count(*) into ln_verifica from rh_liq_remuneracion r
  where r.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then
  select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
    where r.cod_trabajador = as_cod_trabajador ;
  ln_importe_gan := ln_importe_gan + nvl(ln_importe,0) ;
end if ;  

--  Determina descuentos de leyes sociales
ln_verifica := 0 ; ln_importe := 0 ;
select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
  where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_leysoc ;
if ln_verifica > 0 then
  select sum(nvl(d.importe,0)) into ln_importe from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_leysoc ;
  ln_importe_des := ln_importe_des + nvl(ln_importe,0) ;
end if ;

--  Determina descuentos de remuneraciones
ln_verifica := 0 ; ln_importe := 0 ;
select count(*) into ln_verifica from rh_liq_dscto_leyes_aportes d
  where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_desrem ;
if ln_verifica > 0 then
  select sum(nvl(d.importe,0)) into ln_importe from rh_liq_dscto_leyes_aportes d
    where d.cod_trabajador = as_cod_trabajador and d.cod_grupo = ls_grp_desrem ;
  ln_importe_des := ln_importe_des + nvl(ln_importe,0) ;
end if ;

ln_liq_remune := nvl(ln_importe_gan,0) - nvl(ln_importe_des,0) ;

--  ***********************************************
--  ***   ACTUALIZA IMPORTES DE LIQUIDACIONES   ***
--  ***********************************************

update rh_liq_credito_laboral c
  set c.imp_liq_befef_soc = nvl(ln_liq_bensoc,0) ,
      c.imp_liq_remun     = nvl(ln_liq_remune,0)
  where c.cod_trabajador = as_cod_trabajador ;

end usp_rh_liq_actualiza_importe ;
/
