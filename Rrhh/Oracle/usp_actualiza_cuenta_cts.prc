create or replace procedure usp_actualiza_cuenta_cts is

ln_verifica    integer ;

cursor c_maestro is
  select c.codigo, c.cuenta
  from cts_caja c
  order by c.codigo ;
  
begin

for rc_mae in c_maestro loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica from maestro m
    where m.cod_trabajador = rc_mae.codigo ;
    
  if ln_verifica > 0 then
  
    update maestro m
      set m.nro_cnta_cts = rc_mae.cuenta ,
          m.cod_banco_cts = '012' ,
          m.moneda_cts = 'S/.'
      where m.cod_trabajador = rc_mae.codigo ;
      
  end if ;

end loop ;

end usp_actualiza_cuenta_cts ;
/
