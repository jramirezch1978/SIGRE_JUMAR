create global temporary table tt_liquidacion
(
 cod_trabajador         char(8),
 nombre                 varchar2(100),
 fec_ingreso            date,
 fec_cese               date,
 anios_tot              number(2),
 meses_tot              number(2),
 dias_tot               number(2),          
 desc_cese              varchar2(20),
 desc_cargo             varchar2(30),
 imp_basico             number(13,2),
 imp_gan_fij            number(13,2),
 anios_fr               number(2),
 meses_fr               number(2),
 dias_fr                number(2),
 anios_cts              number(2),
 meses_cts              number(2),
 dias_cts               number(2),   
 dias_trabaj            number(5,2),
 imp_cts_ant            number(13,2),--Sum del imp de CTS Ant 
 imp_int_cts            number(13,2),--Sum de Int leg de CTs 
 imp_cts_ult            number(13,2), 
 imp_remun_dev          number(13,2),
 imp_gratif_dev         number(13,2),
 imp_vac_tru_mes        number(13,2), 
 imp_vac_tru_dia        number(13,2),
 imp_rac_azuc           number(13,2),
 imp_cts_fin            number(13,2),
 imp_adeudo_fin         number(13,2),
 imp_total              number(13,2)  
  ) ;
  
