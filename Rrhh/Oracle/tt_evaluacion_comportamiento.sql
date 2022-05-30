create global temporary table tt_evaluacion_comportamiento
(
 fec_desde              date,
 fec_hasta              date,
 codigo                 char(8),
 nombres                varchar2(60),
 area                   char(1),
 desc_area              varchar2(30),
 seccion                char(3),
 desc_seccion           varchar2(30),
 cargo                  char(8),
 desc_cargo             varchar2(30),
 competencia            char(3),
 desc_competencia       varchar2(30),
 comportamiento         char(5),
 desc_comportamiento    varchar2(400),
 fec_evaluacion         date,
 puntaje                number(2)
 ) ;
  
