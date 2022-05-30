create global temporary table tt_rpt_psicol_trabaj
(
 codigo                 char(8),
 nombre                 varchar2(100),
 edad                   number(4,2),
 cod_area               char(1),
 desc_area              varchar2(30),
 cod_cargo              char(8),
 desc_cargo             varchar2(30),
 cod_grado_inst         char(2),
 desc_instruc           varchar2(30),        
 ult_fecha              date,
 cod_plant_psi          char(20),
 tipo_eval_psi          char(2),
 desc_eval_psi          varchar2(50),
 cod_sit_eval           char(2),
 desc_sit_eval          varchar2(30)
  ) ;
  
