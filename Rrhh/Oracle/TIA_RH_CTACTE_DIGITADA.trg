create or replace trigger TIA_RH_CTACTE_DIGITADA
  after insert on rh_ctacte_digitada  
  for each row
declare
  -- local variables here
begin
  INSERT INTO gan_desct_variable(cod_trabajador, fec_movim, concep,
              tipo_doc, nro_doc, imp_var, cod_usr)
  VALUES (:new.cod_trabajador, :new.fecha_proceso_calculo, :new.concep, 
          :new.tipo_doc, :new.nro_doc, :new.importe, :new.cod_usr) ;
end TIA_RH_CTACTE_DIGITADA;
/
