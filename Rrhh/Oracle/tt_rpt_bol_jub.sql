create global temporary table tt_rpt_bol_jub
(
 fecha_proceso          date,
 fecha_anterior         date,
 orden                  number(3),
 codigo                 char(8),
 secuencia              number(2,0),
 nombres                varchar2(35),
 importe                number(13,2),
 interes                number(13,2),
 total                  number(13,2),
 saldo_capital          number(13,2),
 saldo_interes          number(13,2),
 total_saldo            number(13,2)
 ) ;
  
