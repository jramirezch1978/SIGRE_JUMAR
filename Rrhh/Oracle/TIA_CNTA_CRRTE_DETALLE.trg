create or replace trigger TIA_CNTA_CRRTE_DETALLE
  after insert on cnta_crrte_detalle  
  for each row
declare
  -- local variables here
begin
  
    IF :new.flag_estado <> '0' THEN
       UPDATE cnta_crrte c 
          SET c.sldo_prestamo = c.sldo_prestamo - :new.imp_dscto
        WHERE c.cod_trabajador = :new.cod_trabajador and 
              c.tipo_doc       = :new.tipo_doc       and 
              c.nro_doc        = :new.nro_doc ;
  END IF ;
  
end TIA_CNTA_CRRTE_DETALLE;
/
