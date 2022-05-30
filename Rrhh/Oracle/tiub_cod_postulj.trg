create or replace trigger TIUB_COD_POSTULJ
  before insert or update on postulante  
  for each row
declare
  -- local variables here
  ln_ult_cod number(8);
  ls_ult_cod char(8); 
begin

--Aumento del Nro Seq del Cod Trabaj  
 select substr(to_char(seq_cod_postul.NEXTVAL,'00000000'),2,8) 
 into :new.cod_postulante                                      
 from dual;
  
end TIUB_COD_POSTUL;
/
