-- Create table
create global temporary table TT_INDICADOR
(
  INDICADOR CHAR(1)
)
on commit delete rows;