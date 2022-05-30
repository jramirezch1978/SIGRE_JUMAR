create global temporary table tt_fmt_snp_afp_remunerac
(
 ejercicio              number(4), 
 cod_trabajador         char(8),
 cod_origen             char(2), 
 fec_proceso            date,
 remunerac_snp          number(13,2),
 remun_otro_snp         number(13,2),
 remunerac_afp          number(13,2),
 remun_otro_afp         number(13,2),
 tipo_fmt               char(1)
  ) ;
  

  
