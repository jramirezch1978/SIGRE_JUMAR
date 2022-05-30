create or replace procedure usp_tg_busca_semana_fecha (
   asi_fecha in string, 
   aso_fecha out string, 
   ano_ano out number, 
   ano_mes out number, 
   ano_semana out number
) is
   ln_cuenta number(10);
begin
   select count (*)
      into ln_cuenta
      from calendario c
      where c.fecha = to_date(asi_fecha, 'dd/mm/yyyy');
   ano_mes := null; 
   ano_ano := null;
   ano_semana := null;
   if ln_cuenta = 1 then
      select c.mes_calc, c.ano_calc, c.semana_calc 
         into ano_mes, ano_ano, ano_semana 
         from calendario c
         where c.fecha = to_date(asi_fecha, 'dd/mm/yyyy');
      aso_fecha := asi_fecha;
   else
      if ln_cuenta = 0 then
         select to_char(max(c.fecha), 'dd/mm/yyyy')
            into aso_fecha
            from calendario c;
      else
         aso_fecha := null;
      end if;
   end if;
end usp_tg_busca_semana_fecha;
/
