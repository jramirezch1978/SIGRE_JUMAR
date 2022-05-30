create or replace trigger TUA_CNTA_CRRTE_DETALLE
  after update on cnta_crrte_detalle  
  for each row
declare
  -- local variables here
  ln_sldo_prestamo   cnta_crrte.sldo_prestamo%type ;
  ls_cod_sit_prest   cnta_crrte.cod_sit_prest%type ;
  
BEGIN 
  
  SELECT c.sldo_prestamo 
    INTO ln_sldo_prestamo 
    FROM cnta_crrte c 
   WHERE c.cod_trabajador = :new.cod_trabajador and 
         c.tipo_doc       = :new.tipo_doc       and 
         c.nro_doc        = :new.nro_doc ;     
  
  IF ln_sldo_prestamo - :new.imp_dscto <=0 THEN
      ls_cod_sit_prest := 'C' ;
  ELSE
      ls_cod_sit_prest := 'A' ;
  END IF ;
  
  IF :old.flag_estado = '0' AND :new.flag_estado <> '0' THEN      
     UPDATE cnta_crrte c 
        SET c.sldo_prestamo = c.sldo_prestamo - :new.imp_dscto, 
            c.cod_sit_prest = ls_cod_sit_prest 
      WHERE c.cod_trabajador = :new.cod_trabajador and 
            c.tipo_doc       = :new.tipo_doc       and 
            c.nro_doc        = :new.nro_doc ;     
  ELSE 
     UPDATE cnta_crrte c 
        SET c.sldo_prestamo = c.sldo_prestamo - (:new.imp_dscto - :old.imp_dscto ) 
      WHERE c.cod_trabajador = :new.cod_trabajador and 
            c.tipo_doc       = :new.tipo_doc       and 
            c.nro_doc        = :new.nro_doc ;
  END IF ;
  
end TUA_CNTA_CRRTE_DETALLE;
/
