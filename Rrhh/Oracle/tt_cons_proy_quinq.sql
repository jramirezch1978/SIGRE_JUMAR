create global temporary table tt_cons_proy_quinq
(
 cod_trabajador         char(8),
 tipo_trabaj            char(3), 
 cod_seccion            char(3),
 desc_seccion           varchar2(30),
 nombre                 varchar2(100),
 cod_mes                char(2),
 desc_mes               char(10),
 fec_ingreso            date ,
 quinquenio             number(2),
 imp_basico             number(13,2),
 jornal                 number(4,2),
 imp_quin               number(13,2)
 ) ;
