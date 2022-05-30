create or replace procedure usp_rh_liq_rpt_importe_bruto (
  as_cod_trabajador in char ) is

ln_verifica            integer ;
ls_grp_indemn          char(6) ;
ln_importe             number(13,2) ;
ln_importe_gan         number(13,2) ;
ls_empresa             char(8) ;
ls_nom_empresa         varchar2(200) ;

begin

--  **************************************************
--  ***   DETERMINA IMPORTE BRUTO DE LIQUIDACION   ***
--  **************************************************

delete from tt_liq_rpt_importe_bruto ;

select p.grp_indemnizacion into ls_grp_indemn
  from rh_liqparam p where p.reckey = '1' ;
  
ln_importe_gan := 0 ;

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

--  Determina liquidacion por remuneraciones
ln_verifica := 0 ; ln_importe := 0 ;
select count(*) into ln_verifica from rh_liq_remuneracion r
  where r.cod_trabajador = as_cod_trabajador ;
if ln_verifica > 0 then
  select sum(nvl(r.tm_ef_liq_anos,0)) into ln_importe from rh_liq_remuneracion r
    where r.cod_trabajador = as_cod_trabajador ;
  ln_importe_gan := ln_importe_gan + nvl(ln_importe,0) ;
end if ;  

--  Determina el nombre de la empresa
select p.cod_empresa into ls_empresa from genparam p
  where p.reckey = '1' ;
select e.nombre into ls_nom_empresa from empresa e
  where e.cod_empresa = ls_empresa ;

--  Inserta informacion en la tabla temporal
insert into tt_liq_rpt_importe_bruto (
  cod_empresa, nom_empresa, imp_bruto )
values (
  ls_empresa, ls_nom_empresa, nvl(ln_importe_gan,0) ) ;

end usp_rh_liq_rpt_importe_bruto ;
/
