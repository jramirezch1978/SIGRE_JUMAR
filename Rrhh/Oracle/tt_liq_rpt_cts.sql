create global temporary table tt_liq_rpt_cts (
  cod_trabajador        char(8),
  cod_grupo             char(6),
  cod_sub_grupo         char(6),
  descripcion           varchar2(60),
  fec_desde             date,
  fec_hasta             date,
  te_anos               number(2),
  te_meses              number(2),
  te_dias               number(2),
  prdo_ini              date,
  prdo_fin              date,
  deposito              number(13,2),
  factor                number(13,6),
  interes               number(13,2) ) ;
