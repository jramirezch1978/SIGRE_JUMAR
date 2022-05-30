create or replace procedure usp_jub_movimiento_pago
  ( ad_fec_proceso   in date
  ) is

--  Cursor para inicializar movimiento para pago del mes
Cursor c_movimiento is
Select mvj.cod_jubilado, mvj.nro_secuencial, mvj.flag_estado,
       mvj.fecha_proceso, mvj.imp_fijo, mvj.imp_interes,
       mvj.imp_variable, mvj.imp_adelanto_caja
  from mov_variable_jubilado mvj
  for update ;

begin

--  Inicializa movimiento para pago del mes
For rc_mov in c_movimiento Loop

  Update mov_variable_jubilado
  Set fecha_proceso     = ad_fec_proceso ,
      imp_variable      = 0 ,
      imp_adelanto_caja = 0
  where current of c_movimiento ;

End loop ;
      
End usp_jub_movimiento_pago ;
/
