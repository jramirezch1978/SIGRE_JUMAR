create global temporary table tt_cons_inasistencia
(
 cod_trabajador char(8),
 nombre varchar2(100),
 cod_area char(1),
 desc_area varchar2(30),
 cod_seccion char(3),
 desc_seccion varchar2(30),
 cencos char(10),
 desc_cencos varchar2(40),
 concep char(4),  
 fec_desde date,
 dias_inasist number(4,2)
 );
  
