create global temporary table tt_rpt_aporte_afp (
 cod_trabajador     char(8),
 cod_empresa        char(8),  
 cod_afp            char(2),
 desc_afp           varchar2(30),
 nro_afp            char(12),
 nombre             varchar2(100),
 fec_proceso        date,
 remun_asegur       number(13,2),
 aporte_oblig       number(13,2),
 fondo_pension      number(13,2),
 aporte_seguro      number(13,2),
 aporte_comision    number(13,2), 
 retenc_distrib     number(13,2) ) ;
  
