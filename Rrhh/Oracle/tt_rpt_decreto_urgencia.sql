create global temporary table tt_rpt_decreto_urgencia (
 empresa_nom            varchar2(50),
 empresa_dir            char(30),
 empresa_dis            char(30),
 fec_desde              date,
 fec_hasta              date,
 fec_proceso            date,
 cod_trabajador         char(8),
 nombres                varchar2(40),    
 seccion                char(3),
 desc_seccion           varchar2(40),
 remuneracion           number(13,2),
 liquidacion            number(13,2),
 desc_trabajador        varchar2(30) ) ;
  
