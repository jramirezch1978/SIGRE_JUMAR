CREATE OR REPLACE trigger TDA_RH_CTACTE_DIGITADA
  after delete on rh_ctacte_digitada  
  for each row
declare
  -- local variables here
  ls_cod_trabajador           maestro.cod_trabajador%type ;
  ls_concep                   concepto.concep%type ;
  ld_fec_proceso_calculo      date ;
  
BEGIN
  ls_cod_trabajador          := :old.cod_trabajador ;
  ls_concep                  := :old.concep ;
  ld_fec_proceso_calculo     := :old.fecha_proceso_calculo ;
  
  DELETE FROM gan_desct_variable g
   WHERE g.cod_trabajador = ls_cod_trabajador 
     AND g.fec_movim = ld_fec_proceso_calculo 
     AND g.concep = ls_concep ;  
  
END TDA_RH_CTACTE_DIGITADA;
/
