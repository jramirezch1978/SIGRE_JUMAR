create or replace function usf_pla_ina_tar_ins(
   as_cod_trabajador in maestro.cod_trabajador%type, 
   as_concep in concepto.concep%type, 
   an_mostrar in number, -- utilizado para mostrar e% 1dia
   an_calcular in number -- utilizado para calculos 1d=8horas
   ) return integer is
  ln_Result integer;
begin
  ln_Result := 0;
  Select count(*)
     Into ln_result
     from tt_ina_tar_pre i
     where i.cod_trabajador = as_cod_trabajador;
  
  If ln_result > 0 Then
     update tt_ina_tar_pre
        set mostrar = mostrar + an_mostrar, 
            calcular = calcular + an_calcular
        where cod_trabajador = as_cod_trabajador;
  Else
     Insert into tt_ina_tar_pre 
        ( cod_trabajador, concep, mostrar, calcular ) values
        ( as_cod_trabajador, as_concep, an_mostrar, an_calcular);  
  End If;
   
  return(ln_Result);
end usf_pla_ina_tar_ins;
/
