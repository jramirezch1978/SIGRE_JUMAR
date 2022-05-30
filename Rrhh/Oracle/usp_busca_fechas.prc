create or replace procedure usp_busca_fechas (

   ani_sem in number, 
   ani_ano in number,
   aso_ini out string,
   aso_fin out string

) is
   ln_cuenta number(10);
begin
   select count(*)
      into ln_cuenta
      from calendario c 
      where c.ano_calc = ani_ano
         and c.semana_calc = ani_sem;
   if ln_cuenta >= 1 then
      select to_char(min(c.fecha), 'dd/mm/yyyy'), to_char(max(c.fecha), 'dd/mm/yyyy') 
         into aso_ini, aso_fin
         from calendario c 
         where c.ano_calc = ani_ano
            and c.semana_calc = ani_sem;
   end if;
         
end usp_busca_fechas;
/
