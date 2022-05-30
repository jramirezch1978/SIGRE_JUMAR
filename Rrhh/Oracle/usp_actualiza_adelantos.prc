create or replace procedure usp_actualiza_adelantos is

ls_codigo         char(8) ;
ld_fecha          date ;
ls_nrodoc         char(10) ;
ln_importe        number(13,2) ;

cursor c_movimiento is 
  select a.codigo, a.fecdoc, a.import, a.usuario, a.nrodoc, a.flag
  from adelan a
  order by a.codigo, a.fecdoc ;
rc_mov c_movimiento%rowtype ;

begin

delete from adel_cnta_cts ;

open c_movimiento ;
fetch c_movimiento into rc_mov ;
while c_movimiento%found loop

  ls_codigo := rc_mov.codigo ; ld_fecha := rc_mov.fecdoc ;
  ls_nrodoc := rc_mov.nrodoc ;
  
  ln_importe := 0 ;
  while rc_mov.codigo = ls_codigo and rc_mov.fecdoc = ld_fecha and
        rc_mov.nrodoc = ls_nrodoc and c_movimiento%found loop
    ln_importe := ln_importe + nvl(rc_mov.import,0) ;        
    fetch c_movimiento into rc_mov ;
  end loop ;
  
  insert into adel_cnta_cts (
    cod_trabajador, fec_proceso, imp_a_cuenta, cod_usr, nro_convenio, flag_replicacion )
  values (
    ls_codigo, ld_fecha, ln_importe, rc_mov.usuario, ls_nrodoc, rc_mov.flag ) ;
  
end loop ;

end usp_actualiza_adelantos ;
/
