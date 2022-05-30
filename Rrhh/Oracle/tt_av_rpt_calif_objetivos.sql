create global temporary table tt_av_rpt_calif_objetivos (
  usuario              char(6),
  desc_usuario         varchar2(60),
  area                 char(1),
  desc_area            varchar2(30),
  seccion              char(3),
  desc_seccion         varchar2(30),
  calif_concepto       char(6),
  desc_concepto        varchar2(60),
  porcentaje           number(5,3) ) ;