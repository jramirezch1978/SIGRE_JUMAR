create or replace trigger TUB_RH_CNTA_CRRTE
  before update on cnta_crrte  
  for each row
declare
  -- local variables here
  --ls_soles       moneda.cod_moneda%type ;
begin
    /***************************************************************************
         Actualiza el saldo de cuentas por cobrar y pagar
   ****************************************************************************/
-- Captura tipo de moneda soles
IF :new.sldo_prestamo = 0 THEN
   :new.cod_sit_prest := 'C' ;
ELSIF :new.sldo_prestamo < 0 THEN
    raise_application_error(-20000,'Saldo de documento no puede ser negativo '
    ||chr(13)||'Trabajador :'|| :new.cod_trabajador 
    ||chr(13)||'Tipo Docum :'|| :new.tipo_doc
    ||chr(13)||'Nro. Docum :'|| :new.nro_doc );
    return ; 
END IF ;

END TUB_RH_CNTA_CRRTE;
/
