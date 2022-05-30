-- drop table rrhh_archivo_texto
-- Q = quincena
-- S = semana
-- G = Gratificacion
-- T = CTS
-- M = Mensual


create table rrhh_archivo_texto (
 cod_banco              char(3),
 cod_origen             char(3),
 tipo_trabajador        char(3),
 tipo_archivo           char(1), 
 dato_inicial           varchar2(4), 
 cuenta_banco           varchar2(15),
 moneda_banco           char(3),
 monto_total            number(13,2), 
 fecha_pago             date,
 descipcion_pago        varchar2(18),
 descripcion_final      varchar2(20) ) ;

