create or replace procedure usp__max_cod_trabaj
( as_ult_cod in string ,
  as_max_cod out string   
 )
is 
begin
--Obtenemos el maximo valor del codigo trabajador 
/*select max(m.cod_trabajador)
into max_cod_trabaj
from maestro m
where  length(rtrim(m.cod_trabajador)) = 8 ;*/


/*select u.last_number
into max_cod_trabaj
from user_sequences u
where u.sequence_name ='SEQ_COD_TRABAJ';*/

--Caso Codigo de Trabajador es Nulo
as_max_cod := NVL(as_ult_cod,'10000000');
   
end usp__max_cod_trabaj;
/
