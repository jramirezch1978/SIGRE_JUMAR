create global temporary table tt_rpt_deposito_cts
(
 codigo                 char(8),
 nombres                varchar2(40),
 cod_seccion            char(3),
 desc_seccion           varchar2(40),
 cencos                 char(10),
 desc_cencos            varchar2(40),
 imp_cts                number(13,2),
 dias                   number(6,2),
 fecha_proceso          date
 ) ;
  
