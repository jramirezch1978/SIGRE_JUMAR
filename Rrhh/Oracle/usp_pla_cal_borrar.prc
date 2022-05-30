create or replace procedure USP_PLA_CAL_BORRAR
 ( ad_fec_proceso in date
  )
 is
  
 begin

  --  Elimina registros generados automaticamente
  --  Elimina registros de la tabla calculo

  DELETE FROM gan_desct_variable gdv
   WHERE gdv.nro_doc = 'autom'  ;
      
  DELETE FROM calculo 
   WHERE concep <> '    ';
  
  DELETE FROM cnta_crrte_detalle ccd
   WHERE ccd.fec_dscto = ad_fec_proceso ;
  
  DELETE FROM diferido d
   WHERE d.fec_proceso = ad_fec_proceso ;
  
  DELETE FROM quinta_categoria qc
   WHERE qc.fec_proceso = ad_fec_proceso ;
  
  COMMIT;
  
end USP_PLA_CAL_BORRAR;
/
