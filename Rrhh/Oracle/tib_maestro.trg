create or replace trigger tib_maestro
  before insert on maestro  
  for each row
declare
  -- local variables here
  ln_ult_nro         num_maestro.ult_nro%TYPE;
  ln_count           number;
begin
  
  if :new.cod_trabajador is null then
     select count(*)
       into ln_count
       from num_maestro m
      where m.origen = :new.cod_origen;
     
     if ln_count = 0 then
        insert into num_maestro(origen, ult_nro)
        values(:new.cod_origen, 1);
     end if;
     
     select ult_nro
       into ln_ult_nro
       from num_maestro m
      where m.origen = :new.cod_origen for update;
     
     :new.cod_trabajador := ln_ult_nro;
     
     ln_ult_nro := ln_ult_nro + 1;
     
     update num_maestro m
        set ult_nro = ln_ult_nro
      where origen = :new.cod_origen;
     
  end if;  
end tib_maestro;
/
