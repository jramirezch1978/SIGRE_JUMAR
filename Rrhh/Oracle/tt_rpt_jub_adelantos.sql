create global temporary table tt_rpt_jub_adelantos
(
 orden                  number(3,0),
 codigo                 char(8),
 secuencia              number(2,0),
 nombres                varchar2(35),
 adelant_01             number(13,2),
 adelant_02             number(13,2),
 adelant_03             number(13,2),
 adelant_04             number(13,2),
 adelant_05             number(13,2),
 adelant_06             number(13,2),
 adelant_07             number(13,2),
 adelant_08             number(13,2),
 adelant_09             number(13,2),
 adelant_10             number(13,2),
 adelant_11             number(13,2),
 adelant_12             number(13,2),
 adelant_13             number(13,2),
 adelant_total          number(13,2),
 fecha_proceso          date
 ) ;
  
