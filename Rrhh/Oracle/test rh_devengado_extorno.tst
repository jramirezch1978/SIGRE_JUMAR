PL/SQL Developer Test script 3.0
7
begin
  -- Call the procedure
  usp_rh_devengado_extorno(asi_origen => :asi_origen,
                           ani_year => :ani_year,
                           ani_nro_libro => :ani_nro_libro,
                           asi_usuario => :asi_usuario);
end;
4
asi_origen
1
PA
5
ani_year
1
2013
4
ani_nro_libro
1
34
3
asi_usuario
1
jarch
5
8
lc_trab.cod_trabajador
ln_imp_variable
ln_imp_fijo
lc_reg.grp_variable
ln_imp_soles
lc_reg.grp_fijo
lc_reg.reckey
ln_mes
