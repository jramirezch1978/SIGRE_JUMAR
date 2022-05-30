create or replace procedure usp_pla_adiciona_cts_mes (
  ad_fec_proceso in date, as_origen in char, ad_mensaje in out char ) is

--  Variables
lk_cnta_prsp_emp     constant char(10) := '2070.01.06' ;
lk_cnta_prsp_obr     constant char(10) := '2070.01.07' ;

ln_contador      integer ;
ls_cnta_prsp     char(10) ;
ls_cencos        char(10) ;
ls_tipo_t        char(03) ;
ln_importe       number(13,2) ;
ln_tipo_cambio   number(07,3) ;
ln_ano           number(04) ;
ls_descripcion   varchar2(100) ;

--  Lectura de C.T.S. decreto de urgencia mensual
cursor c_movimiento is
  select du.cod_trabajador, du.liquidacion, m.tipo_trabajador, m.cencos
  from cts_decreto_urgencia du, maestro m
  where du.cod_trabajador = m.cod_trabajador and
        to_char(du.fec_proceso,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY')
  order by m.cencos, m.tipo_trabajador, du.cod_trabajador ;
rc_mov c_movimiento%rowtype ;
  
begin

delete from presupuesto_ejec pe
  where to_char(pe.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') and
        pe.tipo_doc_ref = 'GCTS' ;

--  Determina el tipo de cambio a la fecha
ln_contador := 0 ; ln_tipo_cambio := 1 ;
select count(*)
  into ln_contador from calendario c
  where to_char(c.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,0)
    into ln_tipo_cambio from calendario c
    where to_char(c.fecha,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;
end if ;
  
ln_ano := to_number(to_char(ad_fec_proceso,'YYYY')) ;

--  **************************************************************
--  ***   ADICIONA C.T.S. AL PRESUPUESTO POR CENTRO DE COSTO   ***
--  **************************************************************
open c_movimiento ;
fetch c_movimiento into rc_mov ;

while c_movimiento%found loop

  ls_cencos := rc_mov.cencos ;
  ls_tipo_t := rc_mov.tipo_trabajador ;

  ln_importe := 0 ;
  while rc_mov.cencos = ls_cencos and rc_mov.tipo_trabajador = ls_tipo_t and
        c_movimiento%found loop
    ln_importe := ln_importe + nvl(rc_mov.liquidacion,0) ;
    fetch c_movimiento into rc_mov ;
  end loop ;

  ln_importe := ln_importe / ln_tipo_cambio ;
  ln_importe := ln_importe * -1 ;
  
  if ls_tipo_t = 'EMP' then
    ls_cnta_prsp := lk_cnta_prsp_emp ;
  elsif ls_tipo_t = 'OBR' then
    ls_cnta_prsp := lk_cnta_prsp_obr ;
  end if ;

  select nvl(pc.descripcion,' ')
    into ls_descripcion
    from presupuesto_cuenta pc
    where pc.cnta_prsp = ls_cnta_prsp ;
      
  --  Verifica centro de costo y cuenta presupuestal
  ln_contador := 0 ;
  select count(*)
    into ln_contador from presupuesto_partida pp
    where pp.ano = ln_ano and pp.cencos = ls_cencos and
          pp.cnta_prsp = ls_cnta_prsp ;

  if ln_contador > 0 then
    insert into presupuesto_ejec (
      cod_origen, ano, cencos, cnta_prsp, fecha,
      descripcion, importe, origen_ref, tipo_doc_ref, nro_doc_ref, item_ref )
    values (
      as_origen, ln_ano, ls_cencos, ls_cnta_prsp, ad_fec_proceso,
      ls_descripcion, ln_importe, as_origen, 'GCTS', '', 0 ) ;
  else
    ad_mensaje := 'Centro de Costo '||ls_cencos||' No Tiene Presupuesto' ;
  end if ;
     
end loop ;

end usp_pla_adiciona_cts_mes ;
/
