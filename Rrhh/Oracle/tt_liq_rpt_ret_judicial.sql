create global temporary table tt_liq_rpt_ret_judicial (
  cod_trabajador        char(8),
  cod_grupo             char(6),
  cod_sub_grupo         char(6),
  descripcion           varchar2(60),
  concepto              char(4),
  desc_concepto         varchar2(60),
  importe               number(13,2) ) ;
