create global temporary table tt_turnos
(
 seccion                char(3),
 desc_seccion           varchar2(40),    
 codigo                 char(8),
 carnet                 char(10),
 nombres                varchar2(40),    
 mes                    char(9),
 ano                    char(4),
 semana_1               number(2),
 semana_2               number(2),
 semana_3               number(2),
 semana_4               number(2),
 semana_5               number(2)
 ) ;
  
