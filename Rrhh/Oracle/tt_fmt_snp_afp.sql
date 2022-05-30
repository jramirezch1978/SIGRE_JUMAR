create global temporary table tt_fmt_snp_afp
(
 ejercicio              number(4), 
 cod_trabajador         char(8),
 nombre                 varchar2(100),
 cod_origen             char(2), 
 fec_proceso            date,
 dni_cusp               char(12), 
 imp_retencion          number(13,2), 
 total_retenc_snp       number(13,2),
 total_comis_porc       number(13,2), 
 total_seguro_inv       number(13,2),
 total_aporte_indiv     number(13,2),
 tipo_fmt               char(1)
  ) ;
  
