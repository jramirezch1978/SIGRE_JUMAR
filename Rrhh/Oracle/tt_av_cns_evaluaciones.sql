create global temporary table tt_av_cns_evaluaciones (
  ano                 number(4),
  mes                 number(2),
  cod_area            char(1),
  desc_area           varchar2(30),
  cod_seccion         char(3),
  desc_seccion        varchar2(30),
  cod_trabajador      char(8),
  nombres             varchar2(60),
  tipo_trabajador     char(3),
  desc_tipo_tra       varchar2(30),
  o_si_evaluado       number(1),
  o_con_puntaje       number(1),
  o_sin_puntaje       number(1),
  o_si_aprobado       number(1),
  o_no_aprobado       number(1),
  o_no_evaluado       number(1),
  o_con_pago          number(1),
  o_sin_pago          number(1),
  d_si_evaluado       number(1),
  d_con_puntaje       number(1),
  d_sin_puntaje       number(1),
  d_si_aprobado       number(1),
  d_no_aprobado       number(1),
  d_no_evaluado       number(1),
  d_con_pago          number(1),
  d_sin_pago          number(1),
  suspendido          number(1),
  faltas              number(1) ) ;
