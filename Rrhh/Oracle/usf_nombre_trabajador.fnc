create or replace function usf_nombre_trabajador(
    as_cod_trabajador in maestro.cod_trabajador%type)
return varchar2 is
ls_cadena VARCHAR2(100);
--Declaramos las variables del nombre 

begin
  select rtrim(apel_paterno)||' '||rtrim(apel_materno)||' '||
         nvl(rtrim(nombre1),' ')||' '||nvl(rtrim(nombre2),' ')
  into ls_cadena
  from maestro
  where cod_trabajador = as_cod_trabajador;
  
  --Retornamos el nombre completo del trabajador
  
  return(ls_cadena);
end usf_nombre_trabajador;
/
