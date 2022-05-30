CREATE OR REPLACE TRIGGER TIB_RH_PROV_VACAC_GRATIF_CTS
  before insert on rh_prov_vacac_gratif_cts  
  for each row
declare
  -- local variables here
  ls_ano             char(4) ;
  ls_ano_next        char(4) ;
  ld_fecha           date ;
BEGIN

  -- Captura los años 
  ls_ano := TRIM(TO_CHAR(:new.ano)) ;
  ls_ano_next := TRIM(TO_CHAR(:new.ano + 1)) ;
  
  -- Verifica que se actualize la tabla historica de CTS, si ese fuera el caso
  IF :new.flag_provis='C' THEN
     
     -- Caso del periodo de Noviembre a Abril
     
     -- Noviembre
     IF :new.mes = 11 THEN 
        -- La fecha de cierre es del año próximo
        ld_fecha := TO_DATE('30/04/'||ls_ano_next,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = :new.importe, 
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  :new.importe, 0, 0, 0, 
                  0, 0) ;
         END IF ;
     END IF ;

     -- Diciembre     
     IF :new.mes = 12 THEN 
        -- La fecha de cierre es del año próximo     
        ld_fecha := TO_DATE('30/04/'||ls_ano_next,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = :new.importe, 
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, :new.importe, 0, 0, 
                  0, 0) ;
         END IF ;
     END IF ;
     
     -- Enero   
     IF :new.mes = 1 THEN 
        -- La fecha de cierre es del año en curso      
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = :new.importe, 
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
            VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, :new.importe, 0, 
                  0, 0) ;
         END IF ;
     END IF ;
     
     -- Febrero 
     IF :new.mes = 2 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = :new.importe, 
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, 0, :new.importe,
                  0, 0) ;
         END IF ;
     END IF ;
     
     -- Marzo 
     IF :new.mes = 3 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = :new.importe, 
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, 0, 0, 
                  :new.importe, 0) ;
         END IF ;
     END IF ;
     
     -- Abril 
     IF :new.mes = 4 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = :new.importe 
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, 0, 0, 
                  0, :new.importe ) ;
         END IF ;
     END IF ;
     
     -- Caso del periodo de Mayo a Octubre
     -- Mayo
     IF :new.mes = 5 THEN 
        ld_fecha := TO_DATE('30/10/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = :new.importe, 
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  :new.importe, 0, 0, 0, 
                  0, 0) ;
         END IF ;
     END IF ;
     
     -- Junio 
     IF :new.mes = 6 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = :new.importe, 
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, :new.importe, 0, 0, 
                  0, 0) ;
         END IF ;
     END IF ;
     
     -- Julio 
     IF :new.mes = 7 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = :new.importe, 
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, :new.importe, 0, 
                  0, 0) ;
         END IF ;
     END IF ;
     
     -- Agosoto
     IF :new.mes = 8 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = :new.importe, 
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, 0, :new.importe, 
                  0, 0) ;
         END IF ;
     END IF ;
     
     -- Setiembre
     IF :new.mes = 9 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = :new.importe, 
             h.cts_mes06 = NVL(h.cts_mes06,0)
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, 0, 0, 
                  :new.importe, 0) ;
         END IF ;
     END IF ;
     
     -- Octubre
     IF :new.mes = 1 THEN 
        ld_fecha := TO_DATE('30/04/'||ls_ano,'dd/mm/yyyy') ;
        
         UPDATE hist_prov_cts_gratif h 
         SET h.cts_mes01 = NVL(h.cts_mes01,0),
             h.cts_mes02 = NVL(h.cts_mes02,0),
             h.cts_mes03 = NVL(h.cts_mes03,0),
             h.cts_mes04 = NVL(h.cts_mes04,0),
             h.cts_mes05 = NVL(h.cts_mes05,0),
             h.cts_mes06 = :new.importe  
         WHERE TRUNC(h.fecha_proceso) = ld_fecha 
           AND h.cod_trabajador = :new.cod_trabajador ;
           
         IF SQL%NOTFOUND THEN
            INSERT INTO hist_prov_cts_gratif(
                   fecha_proceso, cod_trabajador, cod_origen, tipo_trabajador,
                   cts_mes01, cts_mes02, cts_mes03, cts_mes04, 
                   cts_mes05, cts_mes06) 
           VALUES(ld_fecha, :new.cod_trabajador, :new.cod_origen, :new.tipo_trabajador, 
                  0, 0, 0, 0, 
                  0, :new.importe) ;
         END IF ;
     END IF ;

  END IF ;
  
END TIB_RH_PROV_VACAC_GRATIF_CTS;
/
