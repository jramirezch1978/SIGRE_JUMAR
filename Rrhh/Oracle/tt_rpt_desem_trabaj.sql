create global temporary table tt_rpt_desem_trabaj
(
 cod_trabaj             char(8),
 nomb_trabaj            varchar2(100),
 ult_fecha              date,
 cod_plant_desem        char(20),
 cod_grupo_ocup         char(2),
 punt_total             number(2),
 cod_area               char(1),
 desc_area              varchar2(30),
 cod_sit_eval           char(2),
 desc_sit_eval          varchar2(30),
 cod_evaluador          char(8),
 nomb_evaluador         varchar2(100) 
  ) ;
  
