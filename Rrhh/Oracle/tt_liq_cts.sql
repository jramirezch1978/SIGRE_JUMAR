create global temporary table tt_liq_cts (
 empresa_nom            varchar2(50),
 empresa_dir            char(30),
 empresa_dis            char(30),
 fecha                  date,
 fec_desde              date, 
 fec_hasta              date,
 codigo                 char(8),
 nombres                varchar2(40),
 seccion                char(3),
 desc_seccion           varchar2(40),
 fec_ingreso            date,
 dias                   number(5,2), 
 concepto               char(4),
 desc_concepto          varchar2(30),
 importe                number(13,2) ) ;
  
