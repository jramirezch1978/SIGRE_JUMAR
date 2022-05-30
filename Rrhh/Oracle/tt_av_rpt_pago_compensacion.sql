create global temporary table tt_av_rpt_pago_compensacion (
  ano                   number(4),
  mes                   number(2),
  tipo_trabajador       varchar2(30),
  cod_seccion           char(3),
  desc_seccion          varchar2(30),
  cod_trabajador        char(8),
  nombres               varchar2(60),
  imp_obj               number(13,2),
  imp_des               number(13,2),
  imp_tot               number(13,2) ) ;
