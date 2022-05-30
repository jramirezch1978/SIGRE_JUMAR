PL/SQL Developer Test script 3.0
14
begin
  -- Call the procedure
  DELETE calculo;
  
  usp_rh_cal_calcula_planilla(asi_codtra => :asi_codtra,
                              asi_codusr => :asi_codusr,
                              adi_fec_proceso => :adi_fec_proceso,
                              asi_origen => :asi_origen,
                              adi_fec_anterior => :adi_fec_anterior,
                              asi_flag_control => :asi_flag_control,
                              asi_flag_cierre_mes => :asi_flag_cierre_mes,
                              adi_fec_grati => :adi_fec_grati);
  COMMIT; 
end;
8
asi_codtra
1
10000001
5
asi_codusr
1
jarch
5
adi_fec_proceso
1
03/09/2008
12
asi_origen
1
PA
5
adi_fec_anterior
0
12
asi_flag_control
1
1
5
asi_flag_cierre_mes
1
0
5
adi_fec_grati
0
12
10
ln_dias
ln_dias_trabajados
ln_dias_mes
ls_flag_fer_dom
lc_reg.fec_movim
ln_imp_soles
lc_reg.hor_diu_nor
ls_concepto
lc_reg.hor_ext_diu_1
lc_reg.hor_ext_noc_2
