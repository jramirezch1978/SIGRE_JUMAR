create global temporary table tt_liq_seleccion_pago (
  nro_liquidacion       char(10), 
  cod_trabajador        char(8), 
  nombres               varchar2(60), 
  fec_proceso           date, 
  imp_bensoc            number(13,2),
  imp_remune            number(13,2), 
  imp_total             number(13,2), 
  forma_pago            char(1), 
  nro_cuotas            number(2), 
  tipo_doc              char(4), 
  usuario               char(6) ) ;