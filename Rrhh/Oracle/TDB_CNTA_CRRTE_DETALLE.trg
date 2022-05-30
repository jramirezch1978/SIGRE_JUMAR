create or replace trigger TDB_CNTA_CRRTE_DETALLE
  before delete on cnta_crrte_detalle  
  for each row
declare
  -- local variables here
BEGIN 

IF :old.flag_estado = '1' and :old.imp_dscto>0 THEN
     RAISE_APPLICATION_ERROR(-20000, 'Documento ha sido aplicado en planilla historica '
                                     || chr(13) || 'Trabajador : ' || :old.cod_trabajador
                                     || chr(13) || 'Tipo Doc.  : ' || :old.tipo_doc 
                                     || chr(13) || 'Nro Doc.   : ' || :old.nro_doc ) ;      
END IF ;

end TDB_CNTA_CRRTE_DETALLE;
/
