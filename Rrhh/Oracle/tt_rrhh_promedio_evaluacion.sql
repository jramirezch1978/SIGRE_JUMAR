create global temporary table tt_rrhh_promedio_evaluacion
(
 area                char(1),
 desc_area           varchar2(30),
 fecha               date,
 codigo              char(8),
 nombres             varchar2(40),
 cargo               char(8),
 desc_cargo          varchar2(30),
 puntaje             number(5,1)
 ) ;
  
