create global temporary table tt_cons_hist_inasist
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
 fec_desde date,
 dias_inasist number(4,2)
 );
  
