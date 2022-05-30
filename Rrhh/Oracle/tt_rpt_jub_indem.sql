create global temporary table tt_rpt_jub_indem
(
 orden                  number(3),
 codigo                 char(8),
 secuencia              number(2),
 nombres                varchar2(40),
 fecha_cese             date ,
 indem_01               number(13,2),
 indem_02               number(13,2),
 indem_03               number(13,2),
 indem_04               number(13,2),
 indem_05               number(13,2),
 indem_06               number(13,2),
 indem_07               number(13,2),
 indem_08               number(13,2),
 fecha_proceso          date
 ) ;
  
