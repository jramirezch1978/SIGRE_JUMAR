create global temporary table tt_carnet
(
 cod_trabajador         char(8),
 nombres                varchar2(40),    
 seccion                char(3),
 cencos                 char(10),
 carnet_valido          char(10),     
 carnet_no_valido       char(10),     
 fecha                  date,
 desc_dia               char(9)
 ) ;
  
