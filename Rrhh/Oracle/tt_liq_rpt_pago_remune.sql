create global temporary table tt_liq_rpt_pago_remune (
  cod_trabajador        char(8),
  cod_grupo             char(6),
  cod_sub_grupo         char(6),
  descripcion           varchar2(60),
  desc_subgrp           varchar2(60),
  fec_desde             date,
  fec_hasta             date,
  importe               number(13,2) ) ;
