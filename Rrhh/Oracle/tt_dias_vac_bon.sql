create global temporary table tt_dias_vac_bon
(
 cod_trabajador         char(8) ,
 nombre_trabaj          varchar2(100) ,
 cod_area               char(1) ,
 desc_area              varchar2(30) ,
 cod_seccion            char(3) ,
 desc_seccion           varchar2(30) ,
 cencos                 char(10) ,
 desc_cencos            varchar2(40) ,
 flag_vac_bon           char(1) ,
 desc_vac_bon           varchar2(15) ,
 nro_trabajador         number(4) ,
 nro_dias               number(6) , 
 importe                number(13,2)
 );
