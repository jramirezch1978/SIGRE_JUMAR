create or replace procedure esp_totreg(
   as_tabla   in varchar2, 
   an_totreg in number ) is
begin
  if an_totreg>0 then 
     insert into edg_totreg ( tabla, totreg ) 
        values( as_tabla, an_totreg );
  end if;
end esp_totreg;
/
