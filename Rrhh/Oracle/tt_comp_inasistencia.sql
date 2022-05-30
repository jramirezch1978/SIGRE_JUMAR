create global temporary table tt_comp_sobretiempo
(
 seccion                char(3),
 desc_seccion           varchar2(40),
 cencos                 char(10),
 desc_cencos            varchar2(40),
 carnet_trabajador      char(10),     
 cod_trabajador         char(8),
 nombres                varchar2(40),    
 horas_reloj            number(11,2),
 fecha_digitado         date,
 concepto               char(4),
 desc_concepto          varchar2(40),
 fecha_desde            date,
 fecha_hasta            date,
 horas_digitado         number(11,2)
 ) ;
  
