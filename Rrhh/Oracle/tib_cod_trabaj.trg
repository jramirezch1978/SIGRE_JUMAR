CREATE OR REPLACE TRIGGER tib_cod_trabaj
  before insert on maestro  
  for each row

declare
   
   ln_numerador number;
   ln_maestro number;
   ln_new_cod_trabajador number;
   ls_cod_origen origen.cod_origen%type;
   
begin
  -- Edgar Morante Miercoles 10Jul2002, replicacion 
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

  --Debemos considerar el signo al momento de convertir
  --una variable de numero a cadena  
  if ORA_LOGIN_USER <> 'REPP5' then
    
    if :new.cod_trabajador is null or trim(:new.cod_trabajador) = '' then
       
       if :new.cod_origen is not null then
          
          ls_cod_origen := trim(:new.cod_origen);
          
          select count(*) 
             into ln_numerador
             from num_maestro nm
             where nm.origen = ls_cod_origen;
       
          if ln_numerador = 1 then
             select nm.ult_nro
                into ln_new_cod_trabajador
                from num_maestro nm 
                where trim(nm.origen) = trim(ls_cod_origen)
                for update;
          else
             select count(*) 
                into ln_maestro
                from maestro m
                where trim(m.cod_origen) = ls_cod_origen;
                
             if ln_maestro > 0 then
                
                select max(m.cod_trabajador)
                   into ln_new_cod_trabajador
                   from maestro m
                   where trim(m.cod_origen) = ls_cod_origen;
                   
             else
             
                ln_new_cod_trabajador := 0;
                
             end if;
             
          end if;
          
          ln_new_cod_trabajador := ln_new_cod_trabajador + 1;
          
          select lpad(trim(to_char(ln_new_cod_trabajador)), 8, '0')
             into :new.cod_trabajador
             from dual;
          
          if ln_numerador = 1 then
             update num_maestro nm
                set nm.ult_nro = ln_new_cod_trabajador
                where trim(nm.origen) = trim(:new.cod_origen);
          else
             insert into num_maestro (origen, ult_nro)
                values (ls_cod_origen, ln_new_cod_trabajador);
          end if;
          
       end if;      
    end if;
  end if ;
  
end tib_cod_trabaj ;


/*
CREATE OR REPLACE TRIGGER "PROD1".tib_cod_trabaj
  before insert on maestro  
  for each row

declare
 -- local variables here
begin
  -- Edgar Morante Miercoles 10Jul2002, replicacion 
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

  --Debemos considerar el signo al momento de convertir
  --una variable de numero a cadena  
  if ORA_LOGIN_USER <> 'REPP5' then
    SELECT substr(to_char(seq_cod_trabaj.NEXTVAL,'00000000'),2,8) 
       INTO :new.cod_trabajador 
    FROM dual;
  end if ;
  
end tib_cod_trabaj ;
*/
/
