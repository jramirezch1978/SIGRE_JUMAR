create global temporary table tt_rpt_jub_saldos
(
 orden                  number(3,0),
 codigo                 char(8),
 secuencia              number(2,0),
 nombres                varchar2(35),
 saldo_01               number(13,2),
 saldo_02               number(13,2),
 saldo_03               number(13,2),
 saldo_04               number(13,2),
 saldo_05               number(13,2),
 saldo_06               number(13,2),
 saldo_07               number(13,2),
 saldo_08               number(13,2),
 saldo_09               number(13,2),
 saldo_10               number(13,2),
 saldo_11               number(13,2),
 saldo_12               number(13,2),
 saldo_13               number(13,2),
 saldo_total            number(13,2),
 fecha_proceso          date
 ) ;
  
