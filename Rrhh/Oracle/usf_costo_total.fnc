create or replace function usf_costo_total(as_corr_corte in char )
  return number is
  
  ln_total number;
  ln_operaciones number;
  ln_insumos number;
  ln_otros number;
begin
  SELECT SUM(O.CANT_REAL*LE.COSTO_UNITARIO)
  INTO ln_operaciones
  FROM operaciones O, LABOR_EJECUTOR LE, LABOR LB, LABOR_ETAPA LT
  WHERE O.CORR_CORTE = as_corr_corte AND
      O.COD_LABOR=LE.COD_LABOR AND O.COD_EJECUTOR=LE.COD_EJECUTOR
      and O.COD_LABOR = LB.COD_LABOR and LB.COD_ETAPA = LT.COD_ETAPA;
  IF ln_operaciones IS NULL THEN
     ln_operaciones:= 0;
  END IF;
--Calculamos Total de insumos por Fase
  SELECT SUM( A.CANT_PROCESADA * A.PRECIO_UNIT)
  INTO ln_insumos
  FROM articulo_mov A, OPERACIONES O, LABOR L, LABOR_ETAPA LE
  WHERE A.CORR_CORTE = as_corr_corte AND O.CORR_CORTE = as_corr_corte
      AND A.NRO_OPERACION = O.NRO_OPERACION AND O.COD_LABOR = L.COD_LABOR
      AND L.COD_ETAPA = LE.COD_ETAPA;
  IF ln_insumos IS NULL THEN
     ln_insumos:= 0;
  END IF ;  
--Calculamos Total otros gastos por Fase
  SELECT SUM(C.IMPORTE)
  INTO ln_otros
  FROM costo_x_centro C, LABOR_ETAPA LE
  WHERE C.CORR_CORTE = as_corr_corte AND C.COD_ETAPA = LE.COD_ETAPA;
  IF ln_otros IS NULL THEN
     ln_otros:= 0;
  END IF;  
  ln_total := ln_operaciones + ln_insumos + ln_otros;
  return(ln_total);
end usf_costo_total;
/
