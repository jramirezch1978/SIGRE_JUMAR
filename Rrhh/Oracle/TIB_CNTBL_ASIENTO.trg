create or replace trigger TIB_CNTBL_ASIENTO
  before insert on cntbl_asiento  
  for each row
declare
  -- local variables here
  ln_count           number ;
  ln_libro_cierre    cntbl_libro.nro_libro%type ;
  ln_libro_apertura  cntbl_libro.nro_libro%type ;
begin
  
  IF trunc(:new.fecha_cntbl) > trunc(sysdate) OR trunc(:new.fec_registro) > trunc(sysdate) THEN 
     RAISE_APPLICATION_ERROR(-20000, 'Fecha de registro o fecha de asiento mayor a fecha de sistema') ;
  END IF ;
  
  IF :new.ano <> to_number(to_char(:new.fecha_cntbl,'yyyy')) THEN
     RAISE_APPLICATION_ERROR(-20001, 'Año de asiento contable no coincide con año de fecha de asiento contable') ;
  END IF ;
  
  SELECT count(*) 
    INTO ln_count 
    FROM cntbl_cierre c 
   WHERE c.ano=:new.ano and c.mes=:new.mes and c.flag_cierre_mes='1' ;
  
  SELECT c.libro_cierre, c.libro_apertura 
    INTO ln_libro_cierre, ln_libro_apertura 
    FROM cntblparam c
   WHERE c.reckey = '1' ;
  
  IF (:new.nro_libro <> ln_libro_cierre AND :new.nro_libro <> ln_libro_apertura) THEN 
      IF ln_count = 0 THEN
         RAISE_APPLICATION_ERROR(-20001, 'Año y mes de asiento contable no autorizado a registrar') ;
      END IF ;
  END IF ;
  
END TIB_CNTBL_ASIENTO;
/
