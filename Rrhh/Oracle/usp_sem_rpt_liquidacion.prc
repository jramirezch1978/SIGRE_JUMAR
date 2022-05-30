create or replace procedure usp_sem_rpt_liquidacion (
  as_sembrador  in char, as_nombres   in char, as_corr_corte in char,
  as_desc_campo in char, ad_fec_desde in date, ad_fec_hasta  in date,
  as_cosechado in char, as_usuario in char ) is

--  Variables
lk_unidad               constant char(10) := 'Toneladas' ;
lk_ensaque              constant char(06) := 'SERENS' ;
lk_corte                constant char(06) := 'SERCTE' ;
lk_arrume               constant char(06) := 'SERACC' ;
lk_transporte           constant char(06) := 'SERTRA' ;
lk_reembolso            constant char(06) := 'SERPRC' ;
lk_cuenta1              constant char(10) := '16800100' ;
lk_cuenta2              constant char(10) := '16800200' ;
lk_cuenta3              constant char(10) := '16800300' ;

ln_contador             integer ;       ls_campo                char(7) ;
ls_nro_contrato         char(10) ;      ls_nro_ruc              char(11) ;
ls_flag_exonera         char(1) ;       ls_igv                  char(5) ;
ls_cod_azucar           char(12) ;      ls_cod_melaza           char(12) ;
ls_cod_empresa          char(8) ;       ls_empresa              char(8) ;
ls_habilitacion         char(8) ;       ln_sw                   integer ;
ls_insumos              char(8) ;       ld_fecha_doc            date ;
ls_cod_origen           char(2) ;       ln_nro_mov              number(10) ;
ls_cod_origen_am        char(2) ;       ls_nro_vale_am          char(10) ;
ls_cod_origen_gv        char(2) ;       ls_nro_guia             char(10) ;
ls_nro_vale             char(10) ;      ls_cod_relacion         char(8) ;
ls_tipo_doc             char(4) ;       ls_nro_doc              char(10) ;

ld_fecha_molienda_1     date ;          ld_fecha_molienda_2     date ;
ld_fecha_molienda_3     date ;          ld_fecha_molienda_4     date ;
ld_fecha_molienda_5     date ;          ld_fecha_molienda_6     date ;
ld_fecha_molienda_7     date ;          ld_fecha_molienda_8     date ;
ld_fecha_molienda_9     date ;          ld_fecha_molienda_10    date ;

ln_nro_liquidacion      number(10) ;    ln_distancia_km         number(6,2) ;
ln_hectarea             number(5,2) ;   ln_cana_limpia          number(10,3) ;
ln_sacarosa             number(6,2) ;   ln_importe              number(13,2) ;
ln_por_sembrador        number(10,3) ;  ln_azucar_recup         number(10,3) ;
ln_melaza               number(10,3) ;  ln_azucar_soles         number(10,2) ;
ln_melaza_soles         number(10,2) ;  ln_ensaque_soles        number(10,2) ;
ln_azucar_bls           number(10,3) ;  ln_azucar_total         number(10,2) ;
ln_melaza_total         number(10,2) ;  ln_precio_cana          number(10,2) ;
ln_ensaque_dscto        number(10,2) ;  ln_precio_neto          number(10,2) ;
ln_importe_cana         number(13,2) ;  ln_importe_igv          number(13,2) ;
ln_total_disponible     number(13,2) ;  ln_tasa_interes         number(5,2) ;
ln_nro_dias             number(4) ;     ln_tasa_impuesto        number(4,2) ;
ln_interes              number(13,2) ;  ln_descto_habilitacion  number(13,2) ;
ln_descto_gascosecha    number(13,2) ;  ln_descto_interes       number(13,2) ;
ln_importe_lpc          number(13,2) ;  ln_cortes               number(13,2) ;
ln_arrume               number(13,2) ;  ln_transporte           number(13,2) ;
ln_reembolso            number(13,2) ;  ln_total_descuento      number(13,2) ;
ln_total_saldo          number(13,2) ;  ln_cana_sucia           number(10,3) ;
ln_detraccion           number(13,2) ;  ls_nro_deposito         varchar2(30) ;

--  Lectura de las liquidaciones de molienda
cursor c_molienda is
  select lm.fecha_liquidac, lm.cana_limpia, lm.cana_sucia, lm.azucar_abonado,
         lm.azucar_recuperado, lm.sacarosa, lm.cantidad_melaza
  from sem_liq_molienda lm
  where lm.corr_corte = as_corr_corte and
        lm.fecha_liquidac between ad_fec_desde and ad_fec_hasta
  order by lm.fecha_liquidac ;

--  Lectura de documentos pendientes de pago
cursor c_pendientes is
  select cc.flag_debhab, cc.sldo_sol, cc.fecha_doc
  from doc_pendientes_cta_cte cc
  where cc.cod_relacion = as_sembrador and ( cc.cnta_ctbl = lk_cuenta1 or
        cc.cnta_ctbl = lk_cuenta2 or cc.cnta_ctbl = lk_cuenta3 ) and
        to_date(to_char(cc.fecha_doc,'dd/mm/yyyy'),'dd/mm/yyyy') <= ad_fec_hasta
  order by cc.cod_relacion, cc.tipo_doc, cc.nro_doc ;

--  Lectura de liquidaciones por servicios de cosecha
cursor c_precio_cosecha is
  select lpc.tipo_liq_precio, lpc.importe
  from sem_liq_precio_cosecha lpc
  where lpc.corr_corte = as_corr_corte and lpc.fecha_liquidacion = ad_fec_hasta
  order by lpc.corr_corte, lpc.fecha_liquidacion, lpc.tipo_liq_precio ;

--  Cursor de cuenta corriente de otros sembradores
cursor c_sembradores is
  select o.oper_sec, o.cod_labor, o.fec_inicio, d.importe
  from operaciones o, oper_desembolsos d
  where o.oper_sec = d.oper_sec and o.corr_corte = as_corr_corte
  order by o.corr_corte, o.fec_inicio ;

begin

delete from tt_sem_rpt_liquidacion ;

select g.cod_empresa into ls_cod_empresa from genparam g where g.reckey = '1' ;
select c.empresa_pagadora into ls_empresa from sem_contrato c
  where c.corr_corte = as_corr_corte ;

select p.labor_habilitacion, p.labor_insumos
  into ls_habilitacion, ls_insumos from semparam p where p.reckey = '1' ;

select (nvl(cc.ult_nro,0) + 1) into ln_nro_liquidacion
  from num_sem_liq_compra_cana cc where cc.reckey = '1' ;

select l.cod_igv into ls_igv from logparam l where l.reckey = '1' ;
select (nvl(it.tasa_impuesto,0) / 100)
  into ln_tasa_impuesto from impuestos_tipo it
  where it.tipo_impuesto = ls_igv ;

select p.ruc into ls_nro_ruc from proveedor p
   where p.proveedor = as_sembrador ;

ls_flag_exonera := null ; ln_contador     := 0 ; ln_distancia_km := 0 ;
ls_nro_contrato := null ; ln_tasa_interes := 0 ;
select count(*) into ln_contador from sem_contrato c
  where c.corr_corte = as_corr_corte ;
if ln_contador > 0 then
  select c.nro_contrato, c.flag_exonera_interes, nvl(c.tasa_interes,0),
         c.nro_deposito_banco
    into ls_nro_contrato, ls_flag_exonera, ln_tasa_interes,
         ls_nro_deposito
    from sem_contrato c where c.corr_corte = as_corr_corte ;
end if ;

select nvl(c.distancia_fabrica,0)
  into ln_distancia_km
  from campo_ciclo cc, campo c
  where cc.cod_campo = c.cod_campo and cc.corr_corte = as_corr_corte ;

ln_hectarea := 0 ; ls_campo := substr(as_corr_corte,1,7) ;
select nvl(cam.has_totales,0)
  into ln_hectarea from campo cam where cam.cod_campo = ls_campo ;

--  Determina datos de la liquidacion de molienda
ln_cana_limpia := 0 ; ln_importe      := 0 ; ln_sacarosa      := 0 ;
ln_melaza      := 0 ; ln_azucar_recup := 0 ; ln_por_sembrador := 0 ;
ln_cana_sucia  := 0 ; ln_contador     := 0 ;

ld_fecha_molienda_1 := null ; ld_fecha_molienda_2 := null ;
ld_fecha_molienda_3 := null ; ld_fecha_molienda_4 := null ;
ld_fecha_molienda_5 := null ; ld_fecha_molienda_6 := null ;
ld_fecha_molienda_7 := null ; ld_fecha_molienda_8 := null ;
ld_fecha_molienda_9 := null ; ld_fecha_molienda_10:= null ;

for rc_mol in c_molienda loop

  ln_contador      := ln_contador + 1 ;
  ln_cana_limpia   := ln_cana_limpia + nvl(rc_mol.cana_limpia,0) ;
  ln_cana_sucia    := ln_cana_sucia + nvl(rc_mol.cana_sucia,0) ;
  ln_por_sembrador := ln_por_sembrador + nvl(rc_mol.azucar_abonado,0) ;
  ln_azucar_recup  := ln_azucar_recup + nvl(rc_mol.azucar_recuperado,0) ;
  ln_melaza        := ln_melaza + nvl(rc_mol.cantidad_melaza,0) ;
  ln_importe       := ln_importe + (nvl(rc_mol.cana_limpia,0) * nvl(rc_mol.sacarosa,0)) ;

  if ln_contador = 1 then
    ld_fecha_molienda_1 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 2 then
    ld_fecha_molienda_2 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 3 then
    ld_fecha_molienda_3 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 4 then
    ld_fecha_molienda_4 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 5 then
    ld_fecha_molienda_5 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 6 then
    ld_fecha_molienda_6 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 7 then
    ld_fecha_molienda_7 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 8 then
    ld_fecha_molienda_8 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 9 then
    ld_fecha_molienda_9 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 10 then
    ld_fecha_molienda_10 := rc_mol.fecha_liquidac ;
  end if ;

end loop ;
ln_sacarosa := ln_importe / ln_cana_limpia ;

--  ******************************************************
--  ***   DETERMINA PRECIO NETO POR TONELADA DE CANA   ***
--  ******************************************************

select p.cod_art_azucar, p.cod_art_melaza
  into ls_cod_azucar, ls_cod_melaza
  from semparam p where p.reckey = '1' ;

--  Determina precio promedio del azucar
ln_contador := 0 ; ln_azucar_soles := 0 ;
select count(*) into ln_contador from sem_historico_precios p
  where p.cod_art = ls_cod_azucar and p.fecha between ad_fec_desde and
        ad_fec_hasta ;
if ln_contador > 0 then
  select sum(nvl(p.precio,0)) into ln_azucar_soles from sem_historico_precios p
    where p.cod_art = ls_cod_azucar and p.fecha between ad_fec_desde and
          ad_fec_hasta ;
  ln_azucar_soles := ln_azucar_soles / ln_contador ;
  ln_azucar_soles := ln_azucar_soles / (ln_tasa_impuesto + 1) ;
end if ;

--  Determina precio promedio de la melaza
ln_contador := 0 ; ln_melaza_soles := 0 ;
select count(*) into ln_contador from sem_historico_precios p
  where p.cod_art = ls_cod_melaza and p.fecha between ad_fec_desde and
        ad_fec_hasta ;
if ln_contador > 0 then
  select sum(nvl(p.precio,0)) into ln_melaza_soles from sem_historico_precios p
    where p.cod_art = ls_cod_melaza and p.fecha between ad_fec_desde and
          ad_fec_hasta ;
  ln_melaza_soles := ln_melaza_soles / ln_contador ;
  ln_melaza_soles := ln_melaza_soles / (ln_tasa_impuesto + 1) ;
end if ;

--  Determia el precio promedio del ensaque
ln_contador := 0 ; ln_ensaque_soles := 0 ;
select count(*) into ln_contador from sem_liq_precio_cosecha e
  where e.corr_corte = as_corr_corte and e.tipo_liq_precio = lk_ensaque and
        e.fecha_liquidacion between ad_fec_desde and ad_fec_hasta ;
if ln_contador > 0 then
  select sum(nvl(e.importe,0)) into ln_ensaque_soles
    from sem_liq_precio_cosecha e
    where e.corr_corte = as_corr_corte and e.tipo_liq_precio = lk_ensaque and
          e.fecha_liquidacion between ad_fec_desde and ad_fec_hasta ;
  ln_ensaque_soles := ln_ensaque_soles / ln_contador ;
end if ;

--  Calculo para determinar el precio neto del azucar
ln_azucar_bls    := round(((ln_por_sembrador / 50) * 1000),0) ;
ln_azucar_total  := ln_azucar_bls * ln_azucar_soles ;
ln_melaza_total  := ln_melaza * ln_melaza_soles ;
ln_precio_cana   := (ln_azucar_total + ln_melaza_total) / ln_cana_limpia ;
ln_ensaque_dscto := (ln_azucar_bls * ln_ensaque_soles) / ln_cana_limpia ;
ln_precio_neto   := ln_precio_cana - ln_ensaque_dscto ;

--  ***********************************************************************
--  ***   DETERMINA HABILITACIONES E INTERESES SEGUN ESTADO DE CUENTA   ***
--  ***********************************************************************
ln_descto_habilitacion := 0 ; ln_descto_interes := 0 ;
if ls_cod_empresa = ls_empresa then

  for rc_pen in c_pendientes loop
    ln_importe := nvl(rc_pen.sldo_sol,0) ;
    if rc_pen.flag_debhab = 'H' then
      ln_importe := ln_importe * - 1 ;
    end if ;
    ln_descto_habilitacion := ln_descto_habilitacion + ln_importe ;
    ln_nro_dias := ad_fec_hasta - rc_pen.fecha_doc ;
    ln_interes  := (((ln_tasa_interes / 30) / 100) * ln_nro_dias) * ln_importe ;
    if ls_flag_exonera = 'N' then
      ln_interes := ln_interes + (ln_interes * ln_tasa_impuesto) ;
    end if ;
    ln_descto_interes := ln_descto_interes + ln_interes ;
  end loop ;

else

  for rc_sem in c_sembradores loop

    ls_cod_origen   := null ; ln_nro_mov       := 0 ;    ls_cod_origen_am := null ;
    ls_nro_vale     := null ; ls_cod_origen_gv := null ; ls_nro_guia      := null ;
    ls_cod_relacion := null ; ls_tipo_doc      := null ; ls_nro_doc       := null ;
    ld_fecha_doc    := null ; ln_importe       := 0 ;    ln_sw            := 0 ;

    if rc_sem.cod_labor = ls_habilitacion then
      ln_importe   := nvl(rc_sem.importe,0) ;
      ld_fecha_doc := rc_sem.fec_inicio ;
      ln_sw        := 1 ;
    elsif rc_sem.cod_labor = ls_insumos then
      ln_contador := 0 ;
      select count(*) into ln_contador from articulo_mov_proy p
        where p.oper_sec = rc_sem.oper_sec ;
      if ln_contador > 0 then
        select p.cod_origen, p.nro_mov into ls_cod_origen, ln_nro_mov
          from articulo_mov_proy p where p.oper_sec = rc_sem.oper_sec ;
      end if ;
      ln_contador := 0 ;
      select count(*)
        into ln_contador from articulo_mov m
        where m.origen_mov_proy = ls_cod_origen and m.nro_mov_proy = ln_nro_mov ;
      if ln_contador > 0 then
        select m.cod_origen, m.nro_mov into ls_cod_origen_am, ls_nro_vale_am
          from articulo_mov m where m.origen_mov_proy = ls_cod_origen and m.nro_mov_proy = ln_nro_mov ;
      end if ;
      ln_contador := 0 ;
      select count(*) into ln_contador from guia_vale v
        where v.origen_vale = ls_cod_origen_am and v.nro_vale = ls_nro_vale_am ;
      if ln_contador > 0 then
        select v.origen_guia, v.nro_guia into ls_cod_origen_gv, ls_nro_guia
          from guia_vale v where v.origen_vale = ls_cod_origen_am and v.nro_vale = ls_nro_vale_am ;
      end if ;
      ln_contador := 0 ;
      select count(*) into ln_contador from guia g
        where g.cod_origen = ls_cod_origen_gv and g.nro_guia = ls_nro_guia ;
      if ln_contador > 0 then
        select g.cliente, g.tipo_doc, g.nro_doc into ls_cod_relacion, ls_tipo_doc, ls_nro_doc
          from guia g where g.cod_origen = ls_cod_origen_gv and g.nro_guia = ls_nro_guia ;
      end if ;
      ln_contador := 0 ;
      select count(*) into ln_contador from cntas_cobrar cc
        where cc.tipo_doc = ls_tipo_doc and cc.nro_doc = ls_nro_doc and
              cc.cod_relacion = ls_cod_relacion ;
      if ln_contador > 0 then
        select cc.fecha_documento, cc.importe_a_cobrar into ld_fecha_doc, ln_importe
           from cntas_cobrar cc where cc.tipo_doc = ls_tipo_doc and cc.nro_doc = ls_nro_doc and
           cc.cod_relacion = ls_cod_relacion ;
      end if ;
      ln_sw := 1 ;
    end if ;

    if ln_sw = 1 then
      ln_descto_habilitacion := ln_descto_habilitacion + ln_importe ;
      ln_nro_dias := ad_fec_hasta - ld_fecha_doc ;
      ln_interes  := (((ln_tasa_interes / 30) / 100) * ln_nro_dias) * ln_importe ;
      if ls_flag_exonera = 'N' then
        ln_interes := ln_interes + (ln_interes * ln_tasa_impuesto) ;
      end if ;
      ln_descto_interes := ln_descto_interes + ln_interes ;
    end if ;

  end loop ;

end if ;

--  ********************************************************
--  ***   DETERMINA IMPORTES POR LOS GASTOS DE COSECHA   ***
--  ********************************************************

ln_transporte := 0 ; ln_cortes := 0 ; ln_arrume := 0 ; ln_reembolso := 0 ;
for rc_pre in c_precio_cosecha loop
  ln_importe_lpc := nvl(rc_pre.importe,0) ;
  if rc_pre.tipo_liq_precio = lk_corte then
    ln_cortes := ln_cortes + ln_importe_lpc ;
  elsif rc_pre.tipo_liq_precio = lk_arrume then
    ln_arrume := ln_arrume + ln_importe_lpc ;
  elsif rc_pre.tipo_liq_precio = lk_transporte then
    ln_transporte := ln_transporte + ln_importe_lpc ;
  elsif rc_pre.tipo_liq_precio = lk_reembolso then
    ln_reembolso := ln_reembolso + ln_importe_lpc ;
  end if ;
end loop ;
ln_cortes := (ln_cortes * ln_cana_limpia) * (ln_tasa_impuesto + 1) ;
ln_arrume := (ln_arrume * ln_cana_limpia) * (ln_tasa_impuesto + 1) ;
ln_transporte := (ln_transporte * ln_cana_sucia) * (ln_tasa_impuesto + 1) ;
ln_descto_gascosecha := ln_cortes + ln_arrume + ln_transporte + ln_reembolso ;

--  ********************************************************
--  ***   CALCULO DE LA LIQUIDACION POR COMPRA DE CANA   ***
--  ********************************************************

ln_importe_cana := ln_cana_limpia * ln_precio_neto ;
ln_importe_igv := ln_importe_cana * ln_tasa_impuesto ;
ln_total_disponible := ln_importe_cana + ln_importe_igv ;
ln_detraccion := ln_total_disponible * 0.12 ;
ln_total_descuento := ln_descto_habilitacion + ln_descto_interes +
                      ln_descto_gascosecha + ln_detraccion ;
ln_total_saldo := ln_total_disponible - ln_total_descuento ;

--  Graba registro de liquidacion de molienda de cana
insert into tt_sem_rpt_liquidacion (
  corr_corte, nro_liquidacion, sembrador, desc_sembrador,
  nro_contrato, nro_ruc, campo, desc_campo, hectarea,
  tonelada_cana, sacarosa, fecha_liquidacion, fecha_molienda_1,
  fecha_molienda_2, fecha_molienda_3, fecha_molienda_4,
  fecha_molienda_5, fecha_molienda_6, fecha_molienda_7,
  fecha_molienda_8, fecha_molienda_9, fecha_molienda_10,
  distancia_km, unidad, precio_unitario, importe_cana,
  importe_igv, total_disponible, habilitaciones, intereses,
  serv_cosecha, detraccion, total_descuento, total_saldo,
  nro_deposito )
values (
  as_corr_corte, to_char(ln_nro_liquidacion), as_sembrador, as_nombres,
  ls_nro_contrato, ls_nro_ruc, ls_campo, as_desc_campo, ln_hectarea,
  ln_cana_limpia, ln_sacarosa, sysdate, ld_fecha_molienda_1,
  ld_fecha_molienda_2, ld_fecha_molienda_3, ld_fecha_molienda_4,
  ld_fecha_molienda_5, ld_fecha_molienda_6, ld_fecha_molienda_7,
  ld_fecha_molienda_8, ld_fecha_molienda_9, ld_fecha_molienda_10,
  ln_distancia_km, lk_unidad, ln_precio_neto, ln_importe_cana,
  ln_importe_igv, ln_total_disponible, ln_descto_habilitacion, ln_descto_interes,
  ln_descto_gascosecha, ln_detraccion, ln_total_descuento, ln_total_saldo,
  ls_nro_deposito ) ;

--  ***************************************************************
--  ***   GRABA LIQUIDACIONES DE CAMPOS COSECHADOS TOTALMENTE   ***
--  ***************************************************************

if as_cosechado = 'S' then

  ln_contador := 0 ;
  select count(*) into ln_contador from sem_liq_compra_cana lcc
    where lcc.corr_corte = as_corr_corte and
          to_char(lcc.fecha_liquidacion,'dd/mm/yyyy') = to_char(ad_fec_hasta,'dd/mm/yyyy') ;
  if ln_contador > 0 then
    delete from sem_liq_compra_cana l
      where l.corr_corte = as_corr_corte and
            to_char(l.fecha_liquidacion,'dd/mm/yyyy') = to_char(ad_fec_hasta,'dd/mm/yyyy') ;
  end if ;

  insert into sem_liq_compra_cana (
    nro_liquidacion, corr_corte, fecha_liquidacion, importe, cod_usr )
  values (
    ln_nro_liquidacion, as_corr_corte, sysdate, ln_total_saldo, as_usuario ) ;

  update num_sem_liq_compra_cana
    set ult_nro = ln_nro_liquidacion where reckey = '1' ;

end if ;

end usp_sem_rpt_liquidacion ;

/*
create or replace procedure usp_sem_rpt_liquidacion (
  as_sembrador  in char, as_nombres   in char, as_corr_corte in char,
  as_desc_campo in char, ad_fec_desde in date, ad_fec_hasta  in date,
  as_cosechado in char, as_usuario in char ) is

--  Variables
lk_unidad               constant char(10) := 'Toneladas' ;
lk_ensaque              constant char(06) := 'SERENS' ;
lk_corte                constant char(06) := 'SERCTE' ;
lk_arrume               constant char(06) := 'SERACC' ;
lk_transporte           constant char(06) := 'SERTRA' ;
lk_reembolso            constant char(06) := 'SERPRC' ;
lk_cuenta1              constant char(10) := '16800100' ;
lk_cuenta2              constant char(10) := '16800200' ;
lk_cuenta3              constant char(10) := '16800300' ;

ln_contador             integer ;       ls_campo                char(7) ;
ls_nro_contrato         char(10) ;      ls_nro_ruc              char(11) ;
ls_flag_exonera         char(1) ;       ls_igv                  char(5) ;
ls_cod_azucar           char(12) ;      ls_cod_melaza           char(12) ;
ls_cod_empresa          char(8) ;       ls_empresa              char(8) ;
ls_habilitacion         char(8) ;       ln_sw                   integer ;
ls_insumos              char(8) ;       ld_fecha_doc            date ;
ls_cod_origen           char(2) ;       ln_nro_mov              number(10) ;
ls_cod_origen_am        char(2) ;       ls_nro_vale_am          char(10) ;
ls_cod_origen_gv        char(2) ;       ls_nro_guia             char(10) ;
ls_nro_vale             char(10) ;      ls_cod_relacion         char(8) ;
ls_tipo_doc             char(4) ;       ls_nro_doc              char(10) ;

ld_fecha_molienda_1     date ;          ld_fecha_molienda_2     date ;
ld_fecha_molienda_3     date ;          ld_fecha_molienda_4     date ;
ld_fecha_molienda_5     date ;          ld_fecha_molienda_6     date ;
ld_fecha_molienda_7     date ;          ld_fecha_molienda_8     date ;
ld_fecha_molienda_9     date ;          ld_fecha_molienda_10    date ;

ln_nro_liquidacion      number(10) ;    ln_distancia_km         number(6,2) ;
ln_hectarea             number(5,2) ;   ln_cana_limpia          number(10,3) ;
ln_sacarosa             number(6,2) ;   ln_importe              number(13,2) ;
ln_por_sembrador        number(10,3) ;  ln_azucar_recup         number(10,3) ;
ln_melaza               number(10,3) ;  ln_azucar_soles         number(10,2) ;
ln_melaza_soles         number(10,2) ;  ln_ensaque_soles        number(10,2) ;
ln_azucar_bls           number(10,3) ;  ln_azucar_total         number(10,2) ;
ln_melaza_total         number(10,2) ;  ln_precio_cana          number(10,2) ;
ln_ensaque_dscto        number(10,2) ;  ln_precio_neto          number(10,2) ;
ln_importe_cana         number(13,2) ;  ln_importe_igv          number(13,2) ;
ln_total_disponible     number(13,2) ;  ln_tasa_interes         number(5,2) ;
ln_nro_dias             number(4) ;     ln_tasa_impuesto        number(4,2) ;
ln_interes              number(13,2) ;  ln_descto_habilitacion  number(13,2) ;
ln_descto_gascosecha    number(13,2) ;  ln_descto_interes       number(13,2) ;
ln_importe_lpc          number(13,2) ;  ln_cortes               number(13,2) ;
ln_arrume               number(13,2) ;  ln_transporte           number(13,2) ;
ln_reembolso            number(13,2) ;  ln_total_descuento      number(13,2) ;
ln_total_saldo          number(13,2) ;  ln_cana_sucia           number(10,3) ;
ln_detraccion           number(13,2) ;  ls_nro_deposito         varchar2(30) ;

--  Lectura de las liquidaciones de molienda
cursor c_molienda is
  select lm.fecha_liquidac, lm.cana_limpia, lm.cana_sucia, lm.azucar_abonado,
         lm.azucar_recuperado, lm.sacarosa, lm.cantidad_melaza
  from sem_liq_molienda lm
  where lm.corr_corte = as_corr_corte and
        lm.fecha_liquidac between ad_fec_desde and ad_fec_hasta
  order by lm.fecha_liquidac ;

--  Lectura de documentos pendientes de pago
cursor c_pendientes is
  select cc.flag_debhab, cc.sldo_sol, cc.fecha_doc
  from doc_pendientes_cta_cte cc
  where cc.cod_relacion = as_sembrador and ( cc.cnta_ctbl = lk_cuenta1 or
        cc.cnta_ctbl = lk_cuenta2 or cc.cnta_ctbl = lk_cuenta3 ) and
        to_date(to_char(cc.fecha_doc,'dd/mm/yyyy'),'dd/mm/yyyy') <= ad_fec_hasta
  order by cc.cod_relacion, cc.tipo_doc, cc.nro_doc ;

--  Lectura de liquidaciones por servicios de cosecha
cursor c_precio_cosecha is
  select lpc.tipo_liq_precio, lpc.importe
  from sem_liq_precio_cosecha lpc
  where lpc.corr_corte = as_corr_corte and lpc.fecha_liquidacion = ad_fec_hasta
  order by lpc.corr_corte, lpc.fecha_liquidacion, lpc.tipo_liq_precio ;

--  Cursor de cuenta corriente de otros sembradores
cursor c_sembradores is
  select o.oper_sec, o.cod_labor, o.fec_inicio, d.importe
  from operaciones o, oper_desembolsos d
  where o.oper_sec = d.oper_sec and o.corr_corte = as_corr_corte
  order by o.corr_corte, o.fec_inicio ;

begin

delete from tt_sem_rpt_liquidacion ;

select g.cod_empresa into ls_cod_empresa from gen_param g where g.reckey = '1' ;
select c.empresa_pagadora into ls_empresa from sem_contrato c
  where c.corr_corte = as_corr_corte ;

select p.labor_habilitacion, p.labor_insumos
  into ls_habilitacion, ls_insumos from semparam p where p.reckey = '1' ;

select (nvl(cc.ult_nro,0) + 1) into ln_nro_liquidacion
  from num_sem_liq_compra_cana cc where cc.reckey = '1' ;

select l.cod_igv into ls_igv from logparam l where l.reckey = '1' ;
select (nvl(it.tasa_impuesto,0) / 100)
  into ln_tasa_impuesto from impuestos_tipo it
  where it.tipo_impuesto = ls_igv ;

select p.ruc into ls_nro_ruc from proveedor p
   where p.proveedor = as_sembrador ;

ls_flag_exonera := null ; ln_contador     := 0 ; ln_distancia_km := 0 ;
ls_nro_contrato := null ; ln_tasa_interes := 0 ;
select count(*) into ln_contador from sem_contrato c
  where c.corr_corte = as_corr_corte ;
if ln_contador > 0 then
  select c.nro_contrato, c.flag_exonera_interes, nvl(c.tasa_interes,0),
         c.nro_deposito_banco
    into ls_nro_contrato, ls_flag_exonera, ln_tasa_interes,
         ls_nro_deposito
    from sem_contrato c where c.corr_corte = as_corr_corte ;
end if ;

select nvl(c.distancia_fabrica,0)
  into ln_distancia_km
  from campo_ciclo cc, campo c
  where cc.cod_campo = c.cod_campo and cc.corr_corte = as_corr_corte ;

ln_hectarea := 0 ; ls_campo := substr(as_corr_corte,1,7) ;
select nvl(cam.has_totales,0)
  into ln_hectarea from campo cam where cam.cod_campo = ls_campo ;

--  Determina datos de la liquidacion de molienda
ln_cana_limpia := 0 ; ln_importe      := 0 ; ln_sacarosa      := 0 ;
ln_melaza      := 0 ; ln_azucar_recup := 0 ; ln_por_sembrador := 0 ;
ln_cana_sucia  := 0 ; ln_contador     := 0 ;

ld_fecha_molienda_1 := null ; ld_fecha_molienda_2 := null ;
ld_fecha_molienda_3 := null ; ld_fecha_molienda_4 := null ;
ld_fecha_molienda_5 := null ; ld_fecha_molienda_6 := null ;
ld_fecha_molienda_7 := null ; ld_fecha_molienda_8 := null ;
ld_fecha_molienda_9 := null ; ld_fecha_molienda_10:= null ;

for rc_mol in c_molienda loop

  ln_contador      := ln_contador + 1 ;
  ln_cana_limpia   := ln_cana_limpia + nvl(rc_mol.cana_limpia,0) ;
  ln_cana_sucia    := ln_cana_sucia + nvl(rc_mol.cana_sucia,0) ;
  ln_por_sembrador := ln_por_sembrador + nvl(rc_mol.azucar_abonado,0) ;
  ln_azucar_recup  := ln_azucar_recup + nvl(rc_mol.azucar_recuperado,0) ;
  ln_melaza        := ln_melaza + nvl(rc_mol.cantidad_melaza,0) ;
  ln_importe       := ln_importe + (nvl(rc_mol.cana_limpia,0) * nvl(rc_mol.sacarosa,0)) ;

  if ln_contador = 1 then
    ld_fecha_molienda_1 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 2 then
    ld_fecha_molienda_2 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 3 then
    ld_fecha_molienda_3 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 4 then
    ld_fecha_molienda_4 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 5 then
    ld_fecha_molienda_5 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 6 then
    ld_fecha_molienda_6 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 7 then
    ld_fecha_molienda_7 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 8 then
    ld_fecha_molienda_8 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 9 then
    ld_fecha_molienda_9 := rc_mol.fecha_liquidac ;
  elsif ln_contador = 10 then
    ld_fecha_molienda_10 := rc_mol.fecha_liquidac ;
  end if ;

end loop ;
ln_sacarosa := ln_importe / ln_cana_limpia ;

--  ******************************************************
--  ***   DETERMINA PRECIO NETO POR TONELADA DE CANA   ***
--  ******************************************************

select p.cod_art_azucar, p.cod_art_melaza
  into ls_cod_azucar, ls_cod_melaza
  from semparam p where p.reckey = '1' ;

--  Determina precio promedio del azucar
ln_contador := 0 ; ln_azucar_soles := 0 ;
select count(*) into ln_contador from sem_historico_precios p
  where p.cod_art = ls_cod_azucar and p.fecha between ad_fec_desde and
        ad_fec_hasta ;
if ln_contador > 0 then
  select sum(nvl(p.precio,0)) into ln_azucar_soles from sem_historico_precios p
    where p.cod_art = ls_cod_azucar and p.fecha between ad_fec_desde and
          ad_fec_hasta ;
  ln_azucar_soles := ln_azucar_soles / ln_contador ;
  ln_azucar_soles := ln_azucar_soles / (ln_tasa_impuesto + 1) ;
end if ;

--  Determina precio promedio de la melaza
ln_contador := 0 ; ln_melaza_soles := 0 ;
select count(*) into ln_contador from sem_historico_precios p
  where p.cod_art = ls_cod_melaza and p.fecha between ad_fec_desde and
        ad_fec_hasta ;
if ln_contador > 0 then
  select sum(nvl(p.precio,0)) into ln_melaza_soles from sem_historico_precios p
    where p.cod_art = ls_cod_melaza and p.fecha between ad_fec_desde and
          ad_fec_hasta ;
  ln_melaza_soles := ln_melaza_soles / ln_contador ;
  ln_melaza_soles := ln_melaza_soles / (ln_tasa_impuesto + 1) ;
end if ;

--  Determia el precio promedio del ensaque
ln_contador := 0 ; ln_ensaque_soles := 0 ;
select count(*) into ln_contador from sem_liq_precio_cosecha e
  where e.corr_corte = as_corr_corte and e.tipo_liq_precio = lk_ensaque and
        e.fecha_liquidacion between ad_fec_desde and ad_fec_hasta ;
if ln_contador > 0 then
  select sum(nvl(e.importe,0)) into ln_ensaque_soles
    from sem_liq_precio_cosecha e
    where e.corr_corte = as_corr_corte and e.tipo_liq_precio = lk_ensaque and
          e.fecha_liquidacion between ad_fec_desde and ad_fec_hasta ;
  ln_ensaque_soles := ln_ensaque_soles / ln_contador ;
end if ;

--  Calculo para determinar el precio neto del azucar
ln_azucar_bls    := round(((ln_por_sembrador / 50) * 1000),0) ;
ln_azucar_total  := ln_azucar_bls * ln_azucar_soles ;
ln_melaza_total  := ln_melaza * ln_melaza_soles ;
ln_precio_cana   := (ln_azucar_total + ln_melaza_total) / ln_cana_limpia ;
ln_ensaque_dscto := (ln_azucar_bls * ln_ensaque_soles) / ln_cana_limpia ;
ln_precio_neto   := ln_precio_cana - ln_ensaque_dscto ;

--  ***********************************************************************
--  ***   DETERMINA HABILITACIONES E INTERESES SEGUN ESTADO DE CUENTA   ***
--  ***********************************************************************
ln_descto_habilitacion := 0 ; ln_descto_interes := 0 ;
if ls_cod_empresa = ls_empresa then

  for rc_pen in c_pendientes loop
    ln_importe := nvl(rc_pen.sldo_sol,0) ;
    if rc_pen.flag_debhab = 'H' then
      ln_importe := ln_importe * - 1 ;
    end if ;
    ln_descto_habilitacion := ln_descto_habilitacion + ln_importe ;
    ln_nro_dias := ad_fec_hasta - rc_pen.fecha_doc ;
    ln_interes  := (((ln_tasa_interes / 30) / 100) * ln_nro_dias) * ln_importe ;
    if ls_flag_exonera = 'N' then
      ln_interes := ln_interes + (ln_interes * ln_tasa_impuesto) ;
    end if ;
    ln_descto_interes := ln_descto_interes + ln_interes ;
  end loop ;

else

  for rc_sem in c_sembradores loop

    ls_cod_origen   := null ; ln_nro_mov       := 0 ;    ls_cod_origen_am := null ;
    ls_nro_vale     := null ; ls_cod_origen_gv := null ; ls_nro_guia      := null ;
    ls_cod_relacion := null ; ls_tipo_doc      := null ; ls_nro_doc       := null ;
    ld_fecha_doc    := null ; ln_importe       := 0 ;    ln_sw            := 0 ;

    if rc_sem.cod_labor = ls_habilitacion then
      ln_importe   := nvl(rc_sem.importe,0) ;
      ld_fecha_doc := rc_sem.fec_inicio ;
      ln_sw        := 1 ;
    elsif rc_sem.cod_labor = ls_insumos then
      ln_contador := 0 ;
      select count(*) into ln_contador from articulo_mov_proy p
        where p.oper_sec = rc_sem.oper_sec ;
      if ln_contador > 0 then
        select p.cod_origen, p.nro_mov into ls_cod_origen, ln_nro_mov
          from articulo_mov_proy p where p.oper_sec = rc_sem.oper_sec ;
      end if ;
      ln_contador := 0 ;
      select count(*)
        into ln_contador from articulo_mov m
        where m.origen_mov_proy = ls_cod_origen and m.nro_mov_proy = ln_nro_mov ;
      if ln_contador > 0 then
        select m.cod_origen, m.nro_mov into ls_cod_origen_am, ls_nro_vale_am
          from articulo_mov m where m.origen_mov_proy = ls_cod_origen and m.nro_mov_proy = ln_nro_mov ;
      end if ;
      ln_contador := 0 ;
      select count(*) into ln_contador from guia_vale v
        where v.origen_vale = ls_cod_origen_am and v.nro_vale = ls_nro_vale_am ;
      if ln_contador > 0 then
        select v.origen_guia, v.nro_guia into ls_cod_origen_gv, ls_nro_guia
          from guia_vale v where v.origen_vale = ls_cod_origen_am and v.nro_vale = ls_nro_vale_am ;
      end if ;
      ln_contador := 0 ;
      select count(*) into ln_contador from guia g
        where g.cod_origen = ls_cod_origen_gv and g.nro_guia = ls_nro_guia ;
      if ln_contador > 0 then
        select g.cliente, g.tipo_doc, g.nro_doc into ls_cod_relacion, ls_tipo_doc, ls_nro_doc
          from guia g where g.cod_origen = ls_cod_origen_gv and g.nro_guia = ls_nro_guia ;
      end if ;
      ln_contador := 0 ;
      select count(*) into ln_contador from cntas_cobrar cc
        where cc.tipo_doc = ls_tipo_doc and cc.nro_doc = ls_nro_doc and
              cc.cod_relacion = ls_cod_relacion ;
      if ln_contador > 0 then
        select cc.fecha_documento, cc.importe_a_cobrar into ld_fecha_doc, ln_importe
           from cntas_cobrar cc where cc.tipo_doc = ls_tipo_doc and cc.nro_doc = ls_nro_doc and
           cc.cod_relacion = ls_cod_relacion ;
      end if ;
      ln_sw := 1 ;
    end if ;

    if ln_sw = 1 then
      ln_descto_habilitacion := ln_descto_habilitacion + ln_importe ;
      ln_nro_dias := ad_fec_hasta - ld_fecha_doc ;
      ln_interes  := (((ln_tasa_interes / 30) / 100) * ln_nro_dias) * ln_importe ;
      if ls_flag_exonera = 'N' then
        ln_interes := ln_interes + (ln_interes * ln_tasa_impuesto) ;
      end if ;
      ln_descto_interes := ln_descto_interes + ln_interes ;
    end if ;

  end loop ;

end if ;

--  ********************************************************
--  ***   DETERMINA IMPORTES POR LOS GASTOS DE COSECHA   ***
--  ********************************************************

ln_transporte := 0 ; ln_cortes := 0 ; ln_arrume := 0 ; ln_reembolso := 0 ;
for rc_pre in c_precio_cosecha loop
  ln_importe_lpc := nvl(rc_pre.importe,0) ;
  if rc_pre.tipo_liq_precio = lk_corte then
    ln_cortes := ln_cortes + ln_importe_lpc ;
  elsif rc_pre.tipo_liq_precio = lk_arrume then
    ln_arrume := ln_arrume + ln_importe_lpc ;
  elsif rc_pre.tipo_liq_precio = lk_transporte then
    ln_transporte := ln_transporte + ln_importe_lpc ;
  elsif rc_pre.tipo_liq_precio = lk_reembolso then
    ln_reembolso := ln_reembolso + ln_importe_lpc ;
  end if ;
end loop ;
ln_cortes := (ln_cortes * ln_cana_limpia) * (ln_tasa_impuesto + 1) ;
ln_arrume := (ln_arrume * ln_cana_limpia) * (ln_tasa_impuesto + 1) ;
ln_transporte := (ln_transporte * ln_cana_sucia) * (ln_tasa_impuesto + 1) ;
ln_descto_gascosecha := ln_cortes + ln_arrume + ln_transporte + ln_reembolso ;

--  ********************************************************
--  ***   CALCULO DE LA LIQUIDACION POR COMPRA DE CANA   ***
--  ********************************************************

ln_importe_cana := ln_cana_limpia * ln_precio_neto ;
ln_importe_igv := ln_importe_cana * ln_tasa_impuesto ;
ln_total_disponible := ln_importe_cana + ln_importe_igv ;
ln_detraccion := ln_total_disponible * 0.12 ;
ln_total_descuento := ln_descto_habilitacion + ln_descto_interes +
                      ln_descto_gascosecha + ln_detraccion ;
ln_total_saldo := ln_total_disponible - ln_total_descuento ;

--  Graba registro de liquidacion de molienda de cana
insert into tt_sem_rpt_liquidacion (
  corr_corte, nro_liquidacion, sembrador, desc_sembrador,
  nro_contrato, nro_ruc, campo, desc_campo, hectarea,
  tonelada_cana, sacarosa, fecha_liquidacion, fecha_molienda_1,
  fecha_molienda_2, fecha_molienda_3, fecha_molienda_4,
  fecha_molienda_5, fecha_molienda_6, fecha_molienda_7,
  fecha_molienda_8, fecha_molienda_9, fecha_molienda_10,
  distancia_km, unidad, precio_unitario, importe_cana,
  importe_igv, total_disponible, habilitaciones, intereses,
  serv_cosecha, detraccion, total_descuento, total_saldo,
  nro_deposito )
values (
  as_corr_corte, to_char(ln_nro_liquidacion), as_sembrador, as_nombres,
  ls_nro_contrato, ls_nro_ruc, ls_campo, as_desc_campo, ln_hectarea,
  ln_cana_limpia, ln_sacarosa, sysdate, ld_fecha_molienda_1,
  ld_fecha_molienda_2, ld_fecha_molienda_3, ld_fecha_molienda_4,
  ld_fecha_molienda_5, ld_fecha_molienda_6, ld_fecha_molienda_7,
  ld_fecha_molienda_8, ld_fecha_molienda_9, ld_fecha_molienda_10,
  ln_distancia_km, lk_unidad, ln_precio_neto, ln_importe_cana,
  ln_importe_igv, ln_total_disponible, ln_descto_habilitacion, ln_descto_interes,
  ln_descto_gascosecha, ln_detraccion, ln_total_descuento, ln_total_saldo,
  ls_nro_deposito ) ;

--  ***************************************************************
--  ***   GRABA LIQUIDACIONES DE CAMPOS COSECHADOS TOTALMENTE   ***
--  ***************************************************************

if as_cosechado = 'S' then

  ln_contador := 0 ;
  select count(*) into ln_contador from sem_liq_compra_cana lcc
    where lcc.corr_corte = as_corr_corte and
          to_char(lcc.fecha_liquidacion,'dd/mm/yyyy') = to_char(ad_fec_hasta,'dd/mm/yyyy') ;
  if ln_contador > 0 then
    delete from sem_liq_compra_cana l
      where l.corr_corte = as_corr_corte and
            to_char(l.fecha_liquidacion,'dd/mm/yyyy') = to_char(ad_fec_hasta,'dd/mm/yyyy') ;
  end if ;

  insert into sem_liq_compra_cana (
    nro_liquidacion, corr_corte, fecha_liquidacion, importe, cod_usr )
  values (
    ln_nro_liquidacion, as_corr_corte, sysdate, ln_total_saldo, as_usuario ) ;

  update num_sem_liq_compra_cana
    set ult_nro = ln_nro_liquidacion where reckey = '1' ;

end if ;

end usp_sem_rpt_liquidacion ;
*/
/
