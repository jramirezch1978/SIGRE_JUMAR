CREATE OR REPLACE PROCEDURE USP_MM_REGULARIZA_CTACTE (
   as_user in usuario.cod_usr%type) is 

-- Primer proceso que debe realizarse, desactivando los trigger de cuenta corriente detalle

CURSOR c_cnta_crte_det IS
SELECT c.cod_trabajador, c.tipo_doc, c.nro_doc, c.nro_dscto, c.fec_dscto
  FROM cnta_crrte_detalle c 
 -- WHERE c.cod_trabajador='30000010' 
ORDER BY c.cod_trabajador  ; 

CURSOR c_monto IS
SELECT c.cod_trabajador, c.tipo_doc, c.nro_doc, c.mont_original, sum(nvl(cd.imp_dscto,0)) as descto  
  FROM cnta_crrte c, cnta_crrte_detalle cd
 WHERE c.cod_trabajador = cd.cod_trabajador and 
       c.tipo_doc = cd.tipo_doc and 
       c.nro_doc = cd.nro_doc and 
   --    c.cod_trabajador = '30000010' and 
       cd.flag_estado <> '0' 
GROUP BY c.cod_trabajador, c.tipo_doc, c.nro_doc, c.mont_original 
ORDER BY c.cod_trabajador;

ln_count                   number ;

BEGIN

-- Movimientos  
FOR rc_cta in c_cnta_crte_det LOOP 
    
    -- Verifica si lo ha aplicado en el historico
    SELECT count(*) 
      INTO ln_count 
      FROM historico_calculo hc 
     WHERE hc.cod_trabajador = rc_cta.cod_trabajador 
       AND hc.tipo_doc_cc = rc_cta.tipo_doc 
       AND hc.nro_doc_cc = rc_cta.nro_doc 
       AND trunc(hc.fec_calc_plan) = trunc(rc_cta.fec_dscto) ; 
    
    -- Actualiza en tabla historica, actualiza estado 1 y glosa
    IF ln_count > 0 THEN 
       UPDATE cnta_crrte_detalle c 
          SET c.flag_estado='1', 
              c.imp_dscto = (SELECT SUM(DECODE(cc.cod_moneda, 'S/.', NVL(hc.imp_soles,0), NVL(hc.imp_dolar,0))) 
                               FROM historico_calculo hc, cnta_crrte cc
                              WHERE hc.cod_trabajador = cc.cod_trabajador 
                                AND hc.tipo_doc_cc = cc.tipo_doc 
                                AND hc.nro_doc_cc = cc.nro_doc 
                                AND hc.cod_trabajador = rc_cta.cod_trabajador 
                                AND hc.tipo_doc_cc = rc_cta.tipo_doc 
                                AND hc.nro_doc_cc = rc_cta.nro_doc 
                                AND trunc(hc.fec_calc_plan) = trunc(rc_cta.fec_dscto) ), 
              --c.cod_usr = as_user, 
              c.flag_digitado = '0', 
              c.flag_proceso = 'P', 
              c.observaciones = 'Registrado por planilla histórica'
        WHERE c.cod_trabajador = rc_cta.cod_trabajador 
          AND c.tipo_doc = rc_cta.tipo_doc 
          AND c.nro_doc = rc_cta.nro_doc 
          AND trunc(c.fec_dscto) = trunc(rc_cta.fec_dscto) ;
    ELSE
        SELECT count(*) 
          INTO ln_count 
          FROM calculo hc 
         WHERE hc.cod_trabajador = rc_cta.cod_trabajador 
           AND hc.tipo_doc_cc = rc_cta.tipo_doc 
           AND hc.nro_doc_cc = rc_cta.nro_doc 
           AND trunc(hc.fec_proceso) = trunc(rc_cta.fec_dscto) ; 
        
        -- Si lo encuantra en tabla calculo, lo actualiza con estado 0 y glosa
        IF ln_count > 0 THEN 
           UPDATE cnta_crrte_detalle c 
              SET c.flag_estado='0', 
                  -- c.cod_usr = as_user, 
                  c.flag_digitado = '0', 
                  c.flag_proceso = 'P', 
                  c.imp_dscto = (SELECT SUM( DECODE( cc.cod_moneda, 'S/.', NVL(ca.imp_soles,0), NVL(ca.imp_dolar,0) ) )
                                   FROM calculo ca, cnta_crrte cc
                                  WHERE ca.cod_trabajador = cc.cod_trabajador 
                                    AND ca.tipo_doc_cc = cc.tipo_doc 
                                    AND ca.nro_doc_cc = cc.nro_doc 
                                    AND ca.cod_trabajador = rc_cta.cod_trabajador 
                                    AND ca.tipo_doc_cc = rc_cta.tipo_doc 
                                    AND ca.nro_doc_cc = rc_cta.nro_doc 
                                    AND TRUNC(ca.fec_proceso) = TRUNC(rc_cta.fec_dscto) ), 
                  c.observaciones = 'Generado pero aún falta cerrar por planilla'
            WHERE c.cod_trabajador = rc_cta.cod_trabajador 
              AND c.tipo_doc = rc_cta.tipo_doc 
              AND c.nro_doc = rc_cta.nro_doc 
              AND trunc(c.fec_dscto) = trunc(rc_cta.fec_dscto) ;
        ELSE
           UPDATE cnta_crrte_detalle c 
              SET c.flag_estado='2', 
                  c.cod_usr = as_user, 
                  c.flag_digitado = '1', 
                  --c.flag_proceso = ' ', 
                  c.observaciones = 'Ingreso manual. No esta registrado en tablas de planillas'
            WHERE c.cod_trabajador = rc_cta.cod_trabajador 
              AND c.tipo_doc = rc_cta.tipo_doc 
              AND c.nro_doc = rc_cta.nro_doc 
              AND c.nro_dscto = rc_cta.nro_dscto ;
        END IF ; 
    END IF ;
END LOOP;

-- Actualiza los saldos
FOR rc_m IN c_monto LOOP
    SELECT count(*) 
      INTO ln_count 
      FROM cntas_pagar cp 
     WHERE cp.cod_relacion = rc_m.cod_trabajador 
       AND cp.tipo_doc = rc_m.tipo_doc 
       AND cp.nro_doc = rc_m.nro_doc ;

    IF ln_count = 0 THEN 
      SELECT count(*) 
        INTO ln_count 
        FROM cntas_cobrar cc 
       WHERE cc.tipo_doc = rc_m.tipo_doc 
         AND cc.nro_doc = rc_m.nro_doc ; 
    END IF ;
    
    --IF ln_count = 1 THEN   (Desactivar triggers de cnta_crrte
      UPDATE cnta_crrte c
         SET c.sldo_prestamo = rc_m.mont_original - NVL(rc_m.descto,0) 
       WHERE c.cod_trabajador = rc_m.cod_trabajador and 
             c.tipo_doc = rc_m.tipo_doc and 
             c.nro_doc = rc_m.nro_doc ;
    --END IF ;
END LOOP ;
  
Commit ;
  
END USP_MM_REGULARIZA_CTACTE;
/
