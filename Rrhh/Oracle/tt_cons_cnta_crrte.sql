create global temporary table tt_cons_cnta_crrte
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
 desc_concep char(25),
 tipo_doc char(4),
 nro_doc char(10),
 fec_prestamo date,
 mont_original number(13,2),
 mont_cuota number(13,2),
 sldo_prestamo number(13,2)
 );
  
