create global temporary table tt_rpt_afecto_quinta
(
 codigo                 char(8),
 nombres                varchar2(40),
 cod_seccion            char(3),
 desc_seccion           varchar2(40),
 cencos                 char(10),
 desc_cencos            varchar2(40),
 importe_afe            number(13,2),
 importe_ret            number(13,2),
 fecha_proceso          date
 ) ;
  
