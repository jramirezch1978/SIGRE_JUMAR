--drop table TT_HAYDUK_CTS
-- Create table
create global temporary table TT_HAYDUK_CTS
(
  COD_TRABAJADOR     CHAR(8),
  DNI                CHAR(11),
  NOMBRE             VARCHAR2(80),
  PERIODO            CHAR(6),
  LUGAR_CTS          CHAR(2),
  LUGAR_PROCESO_CTS  CHAR(2),
  TIPO_MONEDA        CHAR(2),
  TIPO_PLANILLA      CHAR(2),
  DIAS_TRAB          NUMBER(3),
  REMUN_COMPUT       NUMBER(12,2),
  CTS_SOLES          NUMBER(12,2),
  HABER_BASICO       NUMBER(12,2),
  INC_AFP_3          NUMBER(12,2),
  ASIG_ALIM          NUMBER(12,2),
  ASIG_FAM           NUMBER(12,2),
  PROM_GRATIF        NUMBER(12,2),
  ASIG_VACAC         NUMBER(12,2),
  PROM_HE            NUMBER(12,2),
  PROM_BTN           NUMBER(12,2),
  BANCO_CTS          CHAR(2),
  NRO_CUENTA_BCO_CTS VARCHAR2(20),
  TASA_INT_CTS       NUMBER(2),
  DIAS_ATRASADOS     NUMBER(3),
  TASA_CAMBIO        NUMBER(7,4)
)
on commit preserve rows;
