create global temporary table tt_rpt_adelanto_cuenta_cts (
flag                char(1),
cod_trabajador      char(8),
nro_convenio        char(10),
nombres             varchar2(40),
fecha_cab           date,
fecha_det           date,
imp_cuenta          number(13,2),
adelantos           number(13,2),
saldos              number(13,2) ) ;
