create or replace trigger "AIPSA".tua_maestro
  after update on maestro  
  for each row

declare
-- local variables here
begin
  
  IF :new.flag_estado <> :old.flag_estado THEN

    --  Actualiza cuenta corriente
     UPDATE cnta_crrte 
        SET flag_estado = :new.flag_estado
            WHERE cod_trabajador = :new.cod_trabajador ;            
     --  Actualiza judiciales
     UPDATE judicial 
        SET flag_estado = :new.flag_estado
            WHERE cod_trabajador = :new.cod_trabajador ;
     --  Actualiza deudas laborales
     UPDATE deuda
        SET flag_estado = :new.flag_estado
            WHERE cod_trabajador = :new.cod_trabajador ;
     --  Actualiza provisiones de C.T.S. y gratificaciones 
     UPDATE prov_cts_gratif       
        SET flag_estado = :new.flag_estado
            WHERE cod_trabajador = :new.cod_trabajador ;
     --  Actualiza ganancias y descuentos fijos
     UPDATE gan_desct_fijo  
        SET flag_estado = :new.flag_estado
            WHERE cod_trabajador = :new.cod_trabajador ;
     --  Actualiza maestro de remuneraciones y gratificaciones devengadas
     UPDATE maestro_remun_gratif_dev
        SET flag_estado = :new.flag_estado
            WHERE cod_trabajador = :new.cod_trabajador ;
     --  Actualiza vacaciones y bonificaciones devengadas
     UPDATE vacac_bonif_deveng
        SET flag_estado = :new.flag_estado
            WHERE cod_trabajador = :new.cod_trabajador ;
   
  END IF;
  
end tua_maestro ;
/
