create or replace trigger TUA_RH_CTACTE_DIGITADA
  after update on rh_ctacte_digitada  
  for each row
declare
 -- local variables here
BEGIN

  UPDATE gan_desct_variable g 
     SET g.tipo_doc = :new.tipo_doc, 
         g.nro_doc  = :new.nro_doc, 
         g.imp_var  = :new.importe, 
         g.cod_usr  = :new.cod_usr 
   WHERE g.cod_trabajador = :new.cod_trabajador   
     AND g.fec_movim      = :new.fecha_proceso_calculo
     AND g.concep         = :new.concep ;  
  
END TUA_RH_CTACTE_DIGITADA;
/
