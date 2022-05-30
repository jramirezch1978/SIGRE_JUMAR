create or replace trigger TUB_CNTA_CRRTE_DETALLE
  before update on cnta_crrte_detalle  
  for each row
declare
  -- local variables here
  ln_saldo           cnta_crrte.sldo_prestamo%type ;
BEGIN
  
    SELECT c.sldo_prestamo 
      INTO ln_saldo  
      FROM cnta_crrte c 
     WHERE c.cod_trabajador = :new.cod_trabajador and 
           c.tipo_doc       = :new.tipo_doc       and 
           c.nro_doc        = :new.nro_doc ;
  
  IF ln_saldo < (:new.imp_dscto - :old.imp_dscto) THEN
     RAISE_APPLICATION_ERROR(-20000, 'Saldo es menor a monto a descontar de '
                                     || chr(13) || 'Trabajador : ' || :new.cod_trabajador
                                     || chr(13) || 'Tipo Doc.  : ' || :new.tipo_doc 
                                     || chr(13) || 'Nro Doc.   : ' || :new.nro_doc ) ;      
  END IF ;
 
end TUB_CNTA_CRRTE_DETALLE;
/
