create or replace trigger tib_cod_postul
  before insert on postulante
  for each row

declare
 -- local variables here
begin
  --Debemos considerar el signo al momento de convertir
  --una variable de numero a cadena  
  SELECT substr(to_char(seq_cod_postul.NEXTVAL,'00000000'),2,8) 
     INTO :new.cod_postulante 
  FROM dual;
end tib_cod_postul;
/
