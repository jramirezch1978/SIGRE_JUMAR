create or replace procedure usp_cierre_inicializa
 ( ad_fec_desde     in date,
   ad_fec_hasta     in date,
   ad_fec_proceso   in date ) is
  
begin

  --  Elimina registros del movimiento del que se proceso
  --  Sobretiempos y turnos
  --  Ganancias y descuentos variables
  --  Inasistencias del personal

  DELETE FROM sobretiempo_turno st
    WHERE st.fec_movim between ad_fec_desde and ad_fec_hasta ;
      
  DELETE FROM gan_desct_variable gdv
    WHERE gdv.fec_movim between ad_fec_desde and ad_fec_proceso ;
  
  DELETE FROM inasistencia i
    WHERE i.fec_movim between ad_fec_desde and ad_fec_hasta ;
  
  COMMIT;
  
end usp_cierre_inicializa ;
/
