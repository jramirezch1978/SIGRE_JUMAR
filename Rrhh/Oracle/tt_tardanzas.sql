create global temporary table tt_tardanzas
(
 seccion                char(3),
 desc_seccion           varchar2(40),
 cencos                 char(10),
 desc_cencos            varchar2(40),
 carnet_trabajador      char(10),     
 cod_trabajador         char(8),
 nombres                varchar2(40),    
 fecha                  date ,
 desc_dia               char(9),     
 minutos                number(11,2),
 quiebre                number(1)
 ) ;
  
