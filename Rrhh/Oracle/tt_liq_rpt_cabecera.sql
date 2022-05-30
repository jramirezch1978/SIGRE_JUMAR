create global temporary table tt_liq_rpt_cabecera (
  cod_trabajador          char(8),
  nombres                 varchar2(50),
  fec_ingreso             date,
  cod_motces              char(2),
  des_motces              varchar2(20),
  cod_cargo               char(8),
  des_cargo               varchar2(30),
  nro_liquidacion         char(10),
  fec_liquidacion         date,
  ts_ano                  number(2),
  ts_mes                  number(2),
  ts_dia                  number(2),
  ult_remun               number(13,2),
  liq_bensoc              number(13,2),
  liq_remune              number(13,2),
  imp_liquid              number(13,2),
  importe                 number(13,2) ) ;
