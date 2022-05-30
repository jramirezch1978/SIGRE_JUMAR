-- drop table tt_archivo_texto_det ;
-- Q = quincena
-- S = semana
-- G = Gratificacion
-- T = CTS
-- M = Mensual


create global temporary table tt_archivo_texto_det (
 cod_banco              char(3),
 cod_origen             char(3),
 tipo_trabajador        char(3),
 tipo_archivo           char(1), 
 fecha_proceso          date,
 dato_inicial           varchar2(2),
 libreta_ahorro         varchar2(20),
 nombre                 varchar2(50),
 moneda                 char(3), 
 sueldo                 number(12,2),
 descipcion_pago        varchar2(18),
 indicador_doc          char(1),
 documento              varchar2(10),
 indicador_final        char(1) ) ;

