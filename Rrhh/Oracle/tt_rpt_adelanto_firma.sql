create global temporary table tt_rpt_adelanto_firma
(
 codigo                 char(8),
 secuencia              number(2,0),
 nombres                varchar2(35),
 nombres_apoderados     varchar2(35),
 importe                number(13,2),
 fecha_proceso          date
 ) ;
  
