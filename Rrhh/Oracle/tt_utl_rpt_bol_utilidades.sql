create global temporary table tt_utl_rpt_bol_utilidades (
  direccion             varchar2(30),
  ruc                   char(11),
  periodo               number(4),
  cod_relacion          char(8),
  nombres               char(50),
  renta_neta            number(13,2),
  porc_distribucion     number(5,2),
  monto_distribuir      number(13,2),
  dias_ano              number(13,2),
  dias_ano_trabaj       number(13,2),
  remuner_ano           number(13,2),
  remuner_ano_trabaj    number(13,2),
  imp_util_dias         number(13,2),
  imp_utl_remuner       number(13,2),
  total_utilidades      number(13,2),
  adelantos             number(13,2),
  otros_adelantos       number(13,2),
  reten_judicial        number(13,2),
  neto_cobrado          number(13,2),
  ano_entrega           number(4) ) ;
