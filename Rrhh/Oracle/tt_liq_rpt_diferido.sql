create global temporary table tt_liq_rpt_diferido (
  fec_desde             date,
  fec_hasta             date,
  cod_trabajador        char(8),
  nombres               varchar2(60),
  fec_pago              date,
  concepto              char(4),
  desc_concepto         varchar2(60),
  importe               number(13,2) ) ;
