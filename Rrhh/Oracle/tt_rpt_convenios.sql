create global temporary table tt_rpt_convenios (
nro_convenio          char(10), 
nom_empresa           varchar2(40), 
ruc                   char(11), 
direccion_emp         varchar2(40),
nombre_jefe           varchar2(40), 
dni_jefe              char(8), 
nombres               varchar2(40), 
dni                   char(8), 
direccion             varchar2(40),
distrito              varchar2(40), 
provincia             varchar2(40), 
imp_a_cuenta          number(13,2), 
fec_proceso           date ) ;
