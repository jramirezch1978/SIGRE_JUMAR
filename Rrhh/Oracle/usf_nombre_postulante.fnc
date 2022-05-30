create or replace function usf_nombre_postulante(
    as_cod_postulante in postulante.cod_postulante%type)
return varchar2 is
ls_cadena VARCHAR2(100);
--Declaramos las variables del nombre 

begin
  select rtrim(apel_paterno)||' '||rtrim(apel_materno)||' '||
         nvl(rtrim(nombre1),' ')||' '||nvl(rtrim(nombre2),' ')
  into ls_cadena
  from postulante
  where cod_postulante = as_cod_postulante;
  
  --Retornamos el nombre completo del trabajador
  
  return(ls_cadena);
end usf_nombre_postulante;
/
