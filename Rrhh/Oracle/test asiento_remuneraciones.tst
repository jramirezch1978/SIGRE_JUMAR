PL/SQL Developer Test script 3.0
9
begin
  -- Call the procedure
  usp_rh_asiento_remuneraciones(asi_ttrab => :asi_ttrab,
                                asi_origen => :asi_origen,
                                asi_usuario => :asi_usuario,
                                ani_year => :ani_year,
                                ani_mes => :ani_mes,
                                asi_veda => :asi_veda);
end;
6
asi_ttrab
1
TRI
5
asi_origen
1
PA
5
asi_usuario
1
jarch
5
ani_year
1
2013
4
ani_mes
1
10
4
asi_veda
1
0
5
0
