create global temporary table tt_rh_tarjetas_repetidas
(
 cod_trabajador char(8),
 cod_tarjeta    char(14),
 fecha_ini      date,
 fecha_fin      date,
 flag_estado    char(1),
 flag_repetido  char(1)
 ); 