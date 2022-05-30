create global temporary table tt_rpt_prov_cts_gra
(
 codigo                 char(8),
 nombres                varchar2(40),
 cod_seccion            char(3),
 cencos                 char(10),
 desc_cencos            varchar2(40),
 imp_prov_cts           number(13,2),
 imp_prov_gra           number(13,2),
 fecha_proceso          date
 ) ;
  
