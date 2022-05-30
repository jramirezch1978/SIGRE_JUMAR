-- Create table 
create global temporary table TT_pla_ina_tar_ins
(
  cod_trabajador char(8),
  concep char(4),
  mostrar number(4,2),  -- muestra 1 día
  calcular number (4,2) -- calcula sobre 8 horas.
)
  ;
