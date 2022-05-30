create or replace procedure usp_rh_liq_selec_comp_pago (
  ad_fec_desde in date, ad_fec_hasta in date, as_usuario in char ) is

lk_descripcion      constant varchar(60) := '   Liquidación de Créditos Laborales' ;
ls_nombres          varchar2(60) ;

--  Lectura de comprobantes de pagos para los trabajadores
cursor c_pagos_pendientes is
  select l.cod_trabajador, l.item, l.tipo_doc, l.fec_pago, l.imp_pagado
  from rh_liq_cnta_crrte_cred_lab l
  where nvl(l.flag_estado,'0') = '1' and nvl(l.imp_pagado,0) > 0 and
        trunc(l.fec_pago) between ad_fec_desde and ad_fec_hasta
  order by l.cod_trabajador, l.item ;

begin

--  *********************************************************************
--  ***   SELECCION PARA GENERAR COMPROBANTES DE PAGOS A TRABAJADOR   ***
--  *********************************************************************

delete from tt_liq_selec_comp_pago ;

for rc_pag in c_pagos_pendientes loop

  ls_nombres := usf_rh_nombre_trabajador(rc_pag.cod_trabajador) ;

  insert into tt_liq_selec_comp_pago (
    cod_trabajador, nombres, item, descripcion, fec_proceso,
    imp_total, flag_aprobacion, tipo_doc, usuario )
  values (
    rc_pag.cod_trabajador, ls_nombres, rc_pag.item, lk_descripcion, rc_pag.fec_pago,
    nvl(rc_pag.imp_pagado,0), null, rc_pag.tipo_doc, as_usuario ) ;
  
end loop ;

end usp_rh_liq_selec_comp_pago ;
/
