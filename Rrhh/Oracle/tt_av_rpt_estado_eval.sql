create global temporary table tt_av_rpt_estado_eval (
  usuario           char(6),
  nom_usuario       varchar2(60),
  seccion           char(3),
  desc_seccion      varchar2(30),
  codtra            char(8),
  nombres           varchar2(60),
  flag_eval_o       char(1),
  flag_apro_o       char(1),
  flag_gere_o       char(1),
  flag_eval_d       char(1),
  flag_apro_d       char(1),
  flag_gere_d       char(1) ) ;
