create global temporary table tt_liq_selec_comp_externo (
  cod_trabajador        char(8), 
  nombres               varchar2(60), 
  proveedor             char(8), 
  nom_proveedor         varchar2(50),
  descripcion           varchar2(60), 
  fec_proceso           date, 
  imp_total             number(13,2), 
  imp_aplicado          number(13,2), 
  flag_aprobacion       char(1),
  tipo_doc              char(4), 
  usuario               char(6) ) ;
