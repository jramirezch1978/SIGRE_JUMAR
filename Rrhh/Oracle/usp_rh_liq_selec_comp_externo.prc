create or replace procedure usp_rh_liq_selec_comp_externo (
  as_cod_trabajador in char, as_usuario in char ) is

ls_tipo_doc         char(4) ;
ls_nombres          varchar2(60) ;

--  Lectura de comprobantes de pagos a externos
cursor c_cuenta_corriente is
  select s.cod_trabajador, s.descripcion, s.proveedor, s.imp_total, p.nom_proveedor
  from rh_liq_saldos_cnta_crrte s, proveedor p
  where s.proveedor = p.proveedor and s.cod_trabajador = as_cod_trabajador and
        nvl(s.flag_estado,'0') = '1' and nvl(s.imp_aplicado,0) = 0 and
        s.proveedor is not null
  order by s.cod_trabajador, s.proveedor ;

begin

--  *******************************************************************
--  ***   SELECCION PARA GENERAR COMPROBANTES DE PAGOS A EXTERNOS   ***
--  *******************************************************************

delete from tt_liq_selec_comp_externo ;

select p.tipo_doc into ls_tipo_doc from rh_liqparam p
  where p.reckey = '1' ;
  
for rc_cta in c_cuenta_corriente loop

  ls_nombres := usf_rh_nombre_trabajador(rc_cta.cod_trabajador) ;

  insert into tt_liq_selec_comp_externo (
    cod_trabajador, nombres, proveedor, nom_proveedor,
    descripcion, fec_proceso, imp_total, imp_aplicado, flag_aprobacion,
    tipo_doc, usuario )
  values (
    rc_cta.cod_trabajador, ls_nombres, rc_cta.proveedor, rc_cta.nom_proveedor,
    rc_cta.descripcion, sysdate, nvl(rc_cta.imp_total,0), 0, null,
    ls_tipo_doc, as_usuario ) ;
  
end loop ;

end usp_rh_liq_selec_comp_externo ;
/
