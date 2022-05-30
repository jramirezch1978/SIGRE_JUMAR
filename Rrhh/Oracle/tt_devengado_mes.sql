create global temporary table tt_devengado_mes
(
 cod_trabajador         char(8),
 nombre                 varchar2(100),
 cod_seccion            char(3),
 desc_seccion           varchar2(30),
 fec_hasta              date,
 importe1               number(13,2),
 importe2               number(13,2),
 importe3               number(13,2),
 importet               number(13,2)
 ) ;
  
