create or replace procedure usp_sem_aprueba_operaciones (
  as_origen in char, as_usuario in char ) is

--  Variables
ln_contador          integer ;
ln_sw                integer ;
ld_fecha             date ;
ls_cod_empresa       char(8) ;
ls_empresa           char(8) ;
ls_proveedor         char(8) ;
ls_cod_habilit       char(8) ;
ls_cencos            char(10) ;
ls_comp_egreso       char(4) ;
ls_nro_comp          char(10) ;
ln_nro_comp          number(10) ;
ln_item              number(3) ;
ln_tasa_cambio       number(7,3) ;
ln_imp_dolar         number(13,2) ;
ls_cnta_prsp         char(10) ;

--  Lectura de operaciones seleccionadas por sembrador
cursor c_operaciones is
  select o.fecha, o.corr_corte, o.oper_sec, o.cod_labor, o.desc_labor,
         o.imp_soles, o.flag_estado, l.cnta_prsp
  from tt_sem_genera_operaciones o, labor l
  where o.cod_labor = l.cod_labor and o.flag_estado = '1' ;

begin

--  Determina el codigo del comprobante de egreso
select f.comprobante_egr
  into ls_comp_egreso from finparam f
  where f.reckey = '1' ;
if ls_comp_egreso is null then
   RAISE_APPLICATION_ERROR( -20000, 'No existe comprobante de egreso en finparam' ) ;
end if ;

--  Determina el codigo de habilitaciones
select p.cencos, p.labor_habilitacion
  into ls_cencos, ls_cod_habilit from semparam p
  where p.reckey = '1' ;

--  Determina el tipo de cambio del dia
ld_fecha := sysdate ;
ln_contador := 0 ; ln_tasa_cambio := 0 ;
select count(*)
  into ln_contador from calendario c
  where to_char(c.fecha,'dd/mm/yyyy') = to_char(ld_fecha,'dd/mm/yyyy') ;
if ln_contador > 0 then
  select nvl(c.vta_dol_prom,0)
    into ln_tasa_cambio from calendario c
    where to_char(c.fecha,'dd/mm/yyyy') = to_char(ld_fecha,'dd/mm/yyyy') ;
else
   RAISE_APPLICATION_ERROR( -20001, 'Tasa de cambio no existe' ) ;
end if ;

--  Determina el codigo de la empresa
select g.cod_empresa
  into ls_cod_empresa from genparam g
  where g.reckey = '1' ;
if ls_cod_empresa is null then
   RAISE_APPLICATION_ERROR( -20002, 'Código de empresa no existe en genparam' ) ;
end if ;

--  ***************************************************
--  ***   OPERACIONES SELECCIONADAS POR SEMBRADOR   ***
--  ***************************************************
ln_item := 0 ; ln_sw := 0 ;
for rc_ope in c_operaciones loop

  if ln_sw = 0 then
    select c.empresa_pagadora
      into ls_empresa from sem_contrato c
      where c.corr_corte = rc_ope.corr_corte ;
    ln_sw := 1 ;
  end if ;
  if ls_empresa is null then
     RAISE_APPLICATION_ERROR( -20003, 'no existe empresa para el sembrador' ) ;
     return ;
  end if ;

  --  Genera comprobantes de egresos por habilitaciones
  if substr(rc_ope.cod_labor,1,3) = substr(ls_cod_habilit,1,3) and
     ls_empresa = ls_cod_empresa then

    select c.proveedor
      into ls_proveedor from campo c
      where c.cod_campo = substr(rc_ope.corr_corte,1,7) ;

    select nvl(ce.ult_nro,0)
      into ln_nro_comp
      from num_comprobante_egr ce
      where origen = as_origen for update ;

    ln_item     := ln_item + 1 ;
    ls_nro_comp := lpad(to_char(ln_nro_comp),10,'0') ;
    ls_nro_comp := as_origen||substr(ls_nro_comp,3,8) ;
    ln_imp_dolar := nvl(rc_ope.imp_soles,0) / ln_tasa_cambio ;

    insert into cntas_pagar (
      cod_relacion, tipo_doc, nro_doc, flag_estado, fecha_registro,
      fecha_emision, vencimiento, cod_moneda, tasa_cambio, flag_provisionado,
      importe_doc, saldo_sol, saldo_dol, cod_usr,
      origen, descripcion, flag_control_reg )
    values (
      ls_proveedor, ls_comp_egreso, ls_nro_comp, '1', ld_fecha,
      rc_ope.fecha, rc_ope.fecha, 'S/.', ln_tasa_cambio, 'D',
      rc_ope.imp_soles, rc_ope.imp_soles, ln_imp_dolar, as_usuario,
      as_origen, rc_ope.desc_labor, '1' ) ;

    insert into cntas_pagar_det (
      cod_relacion, tipo_doc, nro_doc, item,
      descripcion, cantidad, importe, cencos, cnta_prsp )
    values (
      ls_proveedor, ls_comp_egreso, ls_nro_comp, ln_item,
      rc_ope.desc_labor, 1, rc_ope.imp_soles, ls_cencos, rc_ope.cnta_prsp ) ;

    --  Actualiza numero de comprobante de egreso
    ln_nro_comp := ln_nro_comp + 1 ;
    update num_comprobante_egr
      set ult_nro = ln_nro_comp
      where origen = as_origen ;

  else

    ls_proveedor := null ; ls_comp_egreso := null ;
    ls_nro_comp  := null ;

  end if ;

  --  Inserta operaciones generadas por sembrador
  insert into oper_desembolsos (
    oper_sec, item, flag_estado, cod_moneda, importe,
    cod_relacion, tipo_doc, nro_doc )
  values (
    rc_ope.oper_sec, 1, rc_ope.flag_estado, 'S/.', rc_ope.imp_soles,
    ls_proveedor, ls_comp_egreso, ls_nro_comp ) ;

end loop ;

end usp_sem_aprueba_operaciones ;
/
