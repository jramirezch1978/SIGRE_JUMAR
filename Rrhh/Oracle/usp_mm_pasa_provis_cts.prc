create or replace procedure usp_mm_pasa_provis_cts(as_nada in char) is

  CURSOR datos_cts IS
  SELECT p.cod_trabajador, p.dias_asist, p.cts_mes01, p.cts_mes02, p.cts_mes03, 
         p.cts_mes04, p.cts_mes05, p.cts_mes06, m.cencos, p.tipo_trabajador, 
         p.cod_origen
  FROM hist_prov_cts_gratif p, maestro m 
  WHERE p.cod_trabajador = m.cod_trabajador and 
        p.fecha_proceso = to_date('30/04/2008','dd/mm/yyyy');

BEGIN 
  
FOR c_dat IN datos_cts LOOP 
    IF c_dat.cts_mes01 > 0 THEN 
      INSERT INTO rh_prov_vacac_gratif_cts(
             ano, mes, cod_trabajador, flag_provis, 
             cencos, cod_origen, importe, tipo_trabajador,
             dias) 
      VALUES(2007, 11, c_dat.cod_trabajador, 'C', 
             c_dat.cencos, c_dat.cod_origen, c_dat.cts_mes01, c_dat.tipo_trabajador,
             30) ;
    END IF ;
    IF c_dat.cts_mes02 > 0 THEN 
      INSERT INTO rh_prov_vacac_gratif_cts(
             ano, mes, cod_trabajador, flag_provis, 
             cencos, cod_origen, importe, tipo_trabajador,
             dias) 
      VALUES(2007, 12, c_dat.cod_trabajador, 'C', 
             c_dat.cencos, c_dat.cod_origen, c_dat.cts_mes02, c_dat.tipo_trabajador,
             30) ;
    END IF ;
    IF c_dat.cts_mes03 > 0 THEN 
      INSERT INTO rh_prov_vacac_gratif_cts(
             ano, mes, cod_trabajador, flag_provis, 
             cencos, cod_origen, importe, tipo_trabajador,
             dias) 
      VALUES(2008, 1, c_dat.cod_trabajador, 'C', 
             c_dat.cencos, c_dat.cod_origen, c_dat.cts_mes03, c_dat.tipo_trabajador,
             30) ;    
    END IF ;
    IF c_dat.cts_mes04 > 0 THEN 
      INSERT INTO rh_prov_vacac_gratif_cts(
             ano, mes, cod_trabajador, flag_provis, 
             cencos, cod_origen, importe, tipo_trabajador,
             dias) 
      VALUES(2008, 2, c_dat.cod_trabajador, 'C', 
             c_dat.cencos, c_dat.cod_origen, c_dat.cts_mes04, c_dat.tipo_trabajador,
             30) ;    
    END IF ;
    IF c_dat.cts_mes05 > 0 THEN 
      INSERT INTO rh_prov_vacac_gratif_cts(
             ano, mes, cod_trabajador, flag_provis, 
             cencos, cod_origen, importe, tipo_trabajador,
             dias) 
      VALUES(2008, 5, c_dat.cod_trabajador, 'C', 
             c_dat.cencos, c_dat.cod_origen, c_dat.cts_mes05, c_dat.tipo_trabajador,
             30) ;    
    END IF ;
    IF c_dat.cts_mes06 > 0 THEN 
      INSERT INTO rh_prov_vacac_gratif_cts(
             ano, mes, cod_trabajador, flag_provis, 
             cencos, cod_origen, importe, tipo_trabajador,
             dias) 
      VALUES(2008, 4, c_dat.cod_trabajador, 'C', 
             c_dat.cencos, c_dat.cod_origen, c_dat.cts_mes06, c_dat.tipo_trabajador,
             30) ;    
    END IF ;
END LOOP ;

commit ;

END usp_mm_pasa_provis_cts;
/
