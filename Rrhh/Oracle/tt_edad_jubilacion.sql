create global temporary table tt_edad_jubilacion
(
 cod_area               char(1) ,
 desc_area              varchar2(30) ,
 cod_seccion            char(3) ,
 desc_seccion           varchar2(30) ,
 cencos                 char(10) ,
 desc_cencos            varchar2(30),
 cod_trabajador         char(8) ,
 nombre_trabaj          varchar2(90) ,
 flag_sexo              char(1) ,
 fec_ingreso            date ,
 fec_nacimiento         date
 );
  
