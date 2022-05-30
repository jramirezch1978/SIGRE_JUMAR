create global temporary table tt_rpt_certificados
(
 empresa_nom            varchar2(50),
 empresa_dir            char(30),
 ruc                    char(11),
 seccion                char(3),
 descripcion            varchar2(40),
 codigo                 char(8),
 nombres                varchar2(40),
 dni                    char(8),
 imp_fijos              number(13,2),
 imp_gra_vac            number(13,2),
 imp_variables          number(13,2),
 imp_total              number(13,2),
 uit                    number(13,2),
 imp_afp_1023           number(13,2),
 imp_afp_300            number(13,2),
 imp_neto               number(13,2),
 imp_renta              number(13,2),
 imp_retencion          number(13,2),
 dia                    char(2),
 mes                    char(10),
 anno                   char(4),
 des_trabajador         char(20)
 ) ;
  
