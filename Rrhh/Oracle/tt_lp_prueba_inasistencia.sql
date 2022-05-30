create global temporary table tt_lp_prueba_inasistencia
(
 cod_trabajador         char(8),
 concep                 char(4),
 cod_nivel              char(3),
 desc_nivel             varchar2(50), 
 fec_movim              date,
 semestre               char(1),
 dias_hras              number(5,2)
 ) ;
