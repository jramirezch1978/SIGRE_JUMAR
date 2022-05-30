create or replace procedure USP_MM_ACT_DATOS_CTS(ad_fecha_proceso in date) is
-- Procedimiento para regularizar datos del detalle del historico de CTS
/* Lee datos para actualizar registros*/
CURSOR c_maestro is
SELECT distinct(h.cod_trabajador) 
  FROM hist_prov_cts_det h ;

CURSOR c_trabajador(as_trabajador in maestro.cod_trabajador%type) is
SELECT fecha_proceso, cod_trabajador, item 
  FROM hist_prov_cts_det h 
 WHERE h.cod_trabajador = as_trabajador and h.fecha_proceso = ad_fecha_proceso 
ORDER BY fecha_proceso, cod_trabajador, item desc ;

ln_item         number ;

BEGIN 

FOR r_mae IN c_maestro LOOP
    ln_item := 1 ;
    FOR r_tra IN c_trabajador(r_mae.cod_trabajador) LOOP
        IF ln_item = 1 THEN
           UPDATE hist_prov_cts_det h 
              SET h.item = 50 
            WHERE h.fecha_proceso = ad_fecha_proceso and 
                  h.cod_trabajador = r_tra.cod_trabajador and 
                  h.item = r_tra.item ;
        ELSIF ln_item = 2 THEN
           UPDATE hist_prov_cts_det h 
              SET h.item = 40 
            WHERE h.fecha_proceso = ad_fecha_proceso and 
                  h.cod_trabajador = r_tra.cod_trabajador and 
                  h.item = r_tra.item ;
        ELSIF ln_item = 3 THEN
           UPDATE hist_prov_cts_det h 
              SET h.item = 30 
            WHERE h.fecha_proceso = ad_fecha_proceso and 
                  h.cod_trabajador = r_tra.cod_trabajador and 
                  h.item = r_tra.item ;
        ELSIF ln_item = 4 THEN
           UPDATE hist_prov_cts_det h 
              SET h.item = 20 
            WHERE h.fecha_proceso = ad_fecha_proceso and 
                  h.cod_trabajador = r_tra.cod_trabajador and 
                  h.item = r_tra.item ;
        ELSE
            EXIT ;
        END IF ;
        
        ln_item := ln_item + 1 ;
    END LOOP ;
END LOOP ;

--commit ;

END USP_MM_ACT_DATOS_CTS;
/
