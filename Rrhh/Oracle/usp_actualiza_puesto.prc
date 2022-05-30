create or replace procedure usp_actualiza_puesto is

ln_verifica    integer ;

cursor c_puestos is
  select distinct(p.newcar), p.puesto
  from puestos p
  order by p.newcar ;

begin

for rc_pue in c_puestos loop

  ln_verifica := 0 ;
  select count(*) into ln_verifica from rh_cargo_compet_comport c
    where c.cod_cargo = rc_pue.newcar ;
    
  if ln_verifica > 0 then
  
    ln_verifica := 0 ;
    select count(*) into ln_verifica
      from rh_cargo_compet_comport c
      where c.cod_cargo = rc_pue.puesto ;
      
    if ln_verifica = 0 then
    
      update rh_cargo_compet_comport c
        set c.cod_cargo = rc_pue.puesto
        where c.cod_cargo = rc_pue.newcar ;

    end if ;
      
  end if ;
        
end loop ;

end usp_actualiza_puesto ;
/
