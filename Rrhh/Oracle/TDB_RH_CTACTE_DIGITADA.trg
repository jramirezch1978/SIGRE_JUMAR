create or replace trigger TDB_RH_CTACTE_DIGITADA
  before delete on rh_ctacte_digitada  
  for each row
declare
  -- local variables here
  ls_cod_trabajador           maestro.cod_trabajador%type ;
  ls_concep                   concepto.concep%type ;
  ld_fec_proceso_calculo      date ;
  ln_count                    number ;
BEGIN
  ls_cod_trabajador          := :old.cod_trabajador ;
  ls_concep                  := :old.concep ;
  ld_fec_proceso_calculo     := :old.fecha_proceso_calculo ;
  
  SELECT COUNT(*) 
    INTO ln_count 
    FROM gan_desct_variable g
   WHERE g.cod_trabajador = ls_cod_trabajador 
     AND g.fec_movim = ld_fec_proceso_calculo 
     AND g.concep = ls_concep ;  
  
  IF ln_count = 0 THEN
     RAISE_APPLICATION_ERROR( -20000, 'Registro no puede borrarse, ya fue procesado' );
  END IF ;
  
end TDB_RH_CTACTE_DIGITADA;
/
