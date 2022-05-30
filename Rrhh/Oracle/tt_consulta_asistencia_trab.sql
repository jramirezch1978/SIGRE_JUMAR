create global temporary table tt_consulta_asistencia_trab
( cod_area               char(1),
  desc_area              varchar2(40),
  cod_seccion            char(3),     
  desc_seccion           varchar2(40),
  cod_cencos             char(10),    
  desc_cencos            varchar2(40),
  cod_trabajador         char(8),
  nombres                varchar2(40),
  cod_carnet             char(10),
  fecha_marcacion        date,
  r_min_tardanza         number(11,2),
  r_hor_inasistencia     number(11,2),
  r_hor_sobretiempo      number(11,2),
  r_hor_trabajadas       number(11,2),
  fecha_digitacion       date,
  concepto               char(4),
  desc_concepto          varchar2(40),
  fecha_desde            date,
  fecha_hasta            date,
  nro_horas              number(11,2),
  nro_dias               number(11,2),
  flag                   number(1) ) ;
