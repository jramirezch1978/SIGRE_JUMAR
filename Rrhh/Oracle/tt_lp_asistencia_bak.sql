create global temporary table tt_lp_asistencia_bak
(
 cod_trabajador         char(8),
 anio                   number(4),
 semestre               number(1),
 fec_movim              date,
 porc_inasist           number(4,2),
 flg_aprob              char(1),
 desc_concep            char(25),
 nro_dias               number(2),
 hras_sobret            number(5,2)
 ) ;
