create global temporary table tt_escala_categoria
(
 cod_trabajador         char(8) ,
 nombre_trabaj          varchar2(100) ,
 cod_area               char(1) ,
 desc_area              varchar2(30) ,
 cod_seccion            char(3) ,
 desc_seccion           varchar2(30) ,
 cencos                 char(10) ,
 desc_cencos            varchar2(40) ,
 categoria              char(2) ,
 importe                number(13,2)
 );
