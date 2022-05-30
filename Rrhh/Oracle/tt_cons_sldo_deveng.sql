create global temporary table tt_cons_sldo_deveng
(
 cod_trabajador char(8),
 nombre varchar2(100),
 cod_area char(1),
 desc_area varchar2(30),
 cod_seccion char(3),
 desc_seccion varchar2(30),
 cencos char(10),
 desc_cencos varchar2(40),
 fec_proceso date,
 sldo_gratif_dev number(13,2),
 sldo_rem_dev number(13,2),
 sldo_racion number(13,2)
 );
  
