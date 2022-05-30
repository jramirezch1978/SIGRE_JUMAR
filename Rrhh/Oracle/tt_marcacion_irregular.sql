create global temporary table tt_marcacion_irregular
(
 seccion                char(3),
 desc_seccion           varchar2(40),
 cencos                 char(10),
 desc_cencos            varchar2(40),
 carnet_trabajador      char(10),     
 cod_trabajador         char(8),
 nombres                varchar2(40),    
 fecha                  date,
 desc_dia               char(9),     
 turno                  char(4),
 marcacion_horario      number(2),
 marcacion_usuario      number(2)
 ) ;
  
