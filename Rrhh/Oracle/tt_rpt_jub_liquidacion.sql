create global temporary table tt_rpt_jub_liquidacion
(
 codigo                 char(8),
 secuencia              number(2,0),
 nombres                varchar2(35),
 fecha_cese             date,
 concepto               char(4),
 descripcion            varchar2(35),
 capital_importe        number(13,2),
 capital_adelanto       number(13,2),
 capital_saldo          number(13,2),
 interes_importe        number(13,2),
 interes_adelanto       number(13,2),
 interes_saldo          number(13,2),
 saldo_capital_interes  number(13,2),
 fecha_proceso          date
 ) ;
  
