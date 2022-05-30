create or replace trigger TIUB_COD_TRABAJ
  before insert or update on maestro  
  for each row
declare
  -- local variables here
  ln_ult_cod number(8);
  ls_ult_cod char(8); 
begin

--Aumento del Nro Seq del Cod Trabaj  
 select substr(to_char(seq_cod_trabaj.NEXTVAL,'00000000'),2,8) 
 into :new.cod_trabajador
 from dual;
  
end TIUB_COD_TRABAJ;
/
