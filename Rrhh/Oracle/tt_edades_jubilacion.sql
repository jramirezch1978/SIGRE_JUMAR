create global temporary table tt_edades_jubilacion
(
 cod_trabajador         char(8) ,
 nombre_trabaj          varchar2(100) ,
 cod_area               char(1) ,
 desc_area              varchar2(30) ,
 cod_seccion            char(3) ,
 desc_seccion           varchar2(30) ,
 cencos                 char(10) ,
 desc_cencos            varchar2(40) ,
 flag_sexo              char(1) ,
 desc_sexo              varchar2(15) ,
 fec_ingreso            date ,     
 fec_nacimiento         date ,      
 indicador             number(1) ,
 importe                number(13,2)
 );
