create global temporary table tt_lp_exp_laboral
(
 cod_trabajador         char(8),
 nro_secuencial         number(2),
 desc_empresa           varchar2(200),
 direccion              char(16),
 desc_giro_neg          varchar2(30),
 imp_sueldo             number(13,2),
 desc_cargo             varchar2(30),
 nombre_jefe            varchar2(50),
 fec_desde              date,
 fec_hasta              date
 ) ;
