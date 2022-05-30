create or replace procedure usp_rh_liq_rpt_diferidos (
  as_cod_trabajador in char, ad_fec_desde in date, ad_fec_hasta in date ) is

ls_desc_concepto      varchar2(60) ;
ls_nombres            varchar2(60) ;

--  Lectura de movimiento diferido de las liquidaciones
cursor c_diferidos is
  select d.cod_trabajador, d.nro_doc, d.fec_pago, d.imp_pagado
  from rh_liq_cnta_crrte_cred_lab d
  where d.cod_trabajador like as_cod_trabajador and nvl(d.flag_estado,'0') = '3' and
        trunc(d.fec_pago) between ad_fec_desde and ad_fec_hasta
  order by d.cod_trabajador, d.item ;

begin

--  ************************************************************
--  ***   TEMPORAL PARA GENERAR DIFRIDOS DE LA LIQUIDACION   ***
--  ************************************************************

delete from tt_liq_rpt_diferido ;

for rc_dif in c_diferidos loop

  select c.desc_concep into ls_desc_concepto from concepto c
    where c.concep = substr(rc_dif.nro_doc,1,4) ;

  ls_nombres := usf_rh_nombre_trabajador(rc_dif.cod_trabajador) ;

  insert into tt_liq_rpt_diferido (
    fec_desde, fec_hasta, cod_trabajador, nombres, fec_pago,
    concepto, desc_concepto, importe )
  values (
    ad_fec_desde, ad_fec_hasta, rc_dif.cod_trabajador, ls_nombres, rc_dif.fec_pago,
    substr(rc_dif.nro_doc,1,4), ls_desc_concepto, nvl(rc_dif.imp_pagado,0) ) ;
  
end loop ;

end usp_rh_liq_rpt_diferidos ;
/
