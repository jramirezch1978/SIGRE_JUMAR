create global temporary table tt_rpt_jub_intereses
(
 orden                  number(3,0),
 codigo                 char(8),
 secuencia              number(2,0),
 nombres                varchar2(35),
 interes_01             number(13,2),
 interes_02             number(13,2),
 interes_03             number(13,2),
 interes_04             number(13,2),
 interes_05             number(13,2),
 interes_06             number(13,2),
 interes_07             number(13,2),
 interes_08             number(13,2),
 interes_09             number(13,2),
 interes_10             number(13,2),
 interes_11             number(13,2),
 interes_12             number(13,2),
 interes_13             number(13,2),
 interes_total          number(13,2),
 fecha_proceso          date
 ) ;
  
