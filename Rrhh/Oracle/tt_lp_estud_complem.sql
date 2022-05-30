create global temporary table tt_lp_estud_complem
(
 cod_trabajador         char(8),
 desc_categ_curso       varchar2(30),
 desc_curso             varchar2(50),
 desc_cen_estudio       varchar2(100),
 direccion              varchar2(100),
 flg_estudio            char(1),
 flg_nivel              char(1),
 fec_desde              date,
 fec_hasta              date
 ) ;
