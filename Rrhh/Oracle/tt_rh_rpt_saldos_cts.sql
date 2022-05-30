create global temporary table tt_rh_rpt_saldos_cts (
  fec_proceso           date, 
  codigo                char(8), 
  nombres               varchar2(60), 
  cencos                char(10), 
  desc_cencos           varchar2(40),
  seccion               char(3), 
  desc_seccion          varchar2(30), 
  deposito              number(13,2), 
  interes               number(13,2), 
  adelanto              number(13,2),
  int_adelanto          number(13,2), 
  saldo                 number(13,2), 
  saldo_50              number(13,2) ) ;
