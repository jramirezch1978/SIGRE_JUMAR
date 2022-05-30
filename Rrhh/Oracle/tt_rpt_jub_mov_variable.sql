create global temporary table tt_rpt_jub_mov_variable
(
 codigo                 char(8),
 secuencia              number(2,0),
 nombres                varchar2(35),
 nombres_apoderados     varchar2(35),
 importe_fijo           number(13,2),
 importe_interes        number(13,2),
 importe_variable       number(13,2),
 importe_caja           number(13,2),
 importe_total          number(13,2),
 importe_saldo          number(13,2),
 importe_diferencia     number(13,2),
 fecha_proceso          date
 ) ;
