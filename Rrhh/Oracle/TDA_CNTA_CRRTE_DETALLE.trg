create or replace trigger TDA_CNTA_CRRTE_DETALLE
  after delete on cnta_crrte_detalle  
  for each row
declare
  -- local variables here
  --ln_count           number ;
BEGIN 
  
  IF :old.flag_estado <> '0' THEN
     IF :old.flag_estado='1' and :old.imp_dscto>0 THEN
         RAISE_APPLICATION_ERROR(-20000, 'Documento ha sido aplicado en planilla historica '
                                         || chr(13) || 'Trabajador : ' || :old.cod_trabajador
                                         || chr(13) || 'Tipo Doc.  : ' || :old.tipo_doc 
                                         || chr(13) || 'Nro Doc.   : ' || :old.nro_doc ) ;      
     ELSE
         UPDATE cnta_crrte c 
            SET c.sldo_prestamo = c.sldo_prestamo + :old.imp_dscto  
          WHERE c.cod_trabajador = :old.cod_trabajador and 
                c.tipo_doc       = :old.tipo_doc       and 
                c.nro_doc        = :old.nro_doc ; 
     END IF ;
END IF ;

  
end TDA_CNTA_CRRTE_DETALLE;
/
