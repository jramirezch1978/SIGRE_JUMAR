-- Create table 
create global temporary table tt_pla_concepto
(
  concep char(4),        -- concepto
  formula varchar2(200), -- fórmula a procesarce en pb65
  debe_haber char(1),    -- 'D' Debe, 'H' Haber 
  valor number (10,2)    -- Valor de la fórmula 
)
  ;
