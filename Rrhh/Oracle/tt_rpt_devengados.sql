create global temporary table tt_rpt_devengados
(
 cod_trabajador         char(8),
 nombre                 varchar2(100),
 cod_seccion            char(3),
 desc_seccion           varchar2(30),
 fecha                  date,
 imp_gradev             number(13,2),
 imp_remdev             number(13,2),
 imp_racazu             number(13,2),
 imp_total              number(13,2)
 ) ;
  
