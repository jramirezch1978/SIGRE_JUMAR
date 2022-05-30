create global temporary table tt_rpt_inasistencia
(
 cod_trabajador char(8),
 nombre varchar2(100),
 concep char(4),
 fec_movim date,
 dias_inasist number(4,2)
 ); 