create global temporary table tt_lp_datos_famil
(
 cod_trabajador         char(8),
 apel_paterno           varchar2(30),
 apel_materno           varchar2(30),
 nombre1                varchar2(30),
 nombre2                varchar2(30),
 fec_nacim              date,
 desc_parent            varchar2(20),
 flg_sexo               char(1),
 flg_vida               char(1),
 ocupacion              varchar2(30),
 flg_trabaj_emp         char(1),
 desc_area              varchar2(30),
 flg_depen              char(1),
 flg_algun_famil        char(1)
 ) ;
  
