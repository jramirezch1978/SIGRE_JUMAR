create global temporary table tt_rpt_deudas
(
 cod_trabajador         char(8),
 nombre                 varchar2(100),
 cod_seccion            char(3),
 desc_seccion           varchar2(30),
 cencos                 char(10),
 desc_cencos            varchar2(40),
 fecha                  date,
 imp_fdoret             number(13,2),
 imp_cts                number(13,2),
 imp_vacdev             number(13,2),
 imp_bondev             number(13,2),
 imp_gradev             number(13,2),
 imp_remdev             number(13,2),
 imp_racazu             number(13,2),
 imp_total              number(13,2)
 ) ;
  
