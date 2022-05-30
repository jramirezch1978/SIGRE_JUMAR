create or replace procedure USP_RH_CALC_TOTALES(
       asi_tipo_Trabajador IN tipo_trabajador.tipo_trabajador%TYPE,
       asi_origen          IN origen.cod_origen%TYPE,
       adi_Fec_proceso     IN DATE,
       asi_tipo_planilla   in calculo.tipo_planilla%TYPE
) IS
  
  ls_grp_afp_jub        rrhhparam_cconcep.afp_jubilacion%type ;
  ls_grp_afp_inv        rrhhparam_cconcep.afp_jubilacion%type ;
  ls_grp_afp_com        rrhhparam_cconcep.afp_jubilacion%type ;
  ls_doc_pago_afp       rrhhparam.doc_pago_afp%TYPE;
  
  CURSOR c_datos IS
    SELECT DISTINCT m.cod_trabajador
      FROM maestro m,
           calculo c
     WHERE m.cod_trabajador = c.cod_trabajador
       AND trunc(c.fec_proceso) = trunc(adi_fec_proceso)
       AND m.tipo_trabajador = asi_tipo_Trabajador
       AND m.cod_origen = asi_origen;
  
  CURSOR c_tot_afps IS
     SELECT m.cod_afp,af.cod_relacion, Sum(c.imp_soles) as imp_soles ,Sum(c.imp_dolar) as imp_dolar
       FROM calculo c,
            maestro m,
            admin_afp af
      where m.cod_trabajador     = c.cod_trabajador     
        AND m.cod_afp            = af.cod_afp           
        AND m.cod_origen         = asi_origen            
        AND m.tipo_trabajador    = asi_tipo_Trabajador             
        AND trunc(c.fec_proceso) = Trunc(adi_fec_proceso)
        AND m.cod_afp            IS NOT NULL
        AND c.concep in ( (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = ls_grp_afp_jub),
                          (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = ls_grp_afp_inv),
                          (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = ls_grp_afp_com) ) 
group by m.cod_afp,af.cod_relacion ;
       
  
  ls_cnc_total_ingreso             rrhhparam.cnc_total_ing%TYPE;
  ls_cnc_total_dscto               rrhhparam.cnc_total_dsct%TYPE;
  ls_cnc_total_pagado              rrhhparam.cnc_total_pgd%TYPE;
  ls_cnc_total_aportes             rrhhparam.cnc_total_aport%TYPE;
  ls_cod_relacion                  calc_doc_pagar_plla.cod_relacion%TYPE;
  ls_doc_pago_plla                 rrhhparam.doc_pago_plla%TYPE;
  ls_nro_doc                       calc_doc_pagar_plla.nro_doc%TYPE;
  ln_count                         NUMBER;
  ln_tasa_cambio                   cntas_pagar.tasa_cambio%TYPE;
  ln_imp_soles                     cntas_pagar_det.importe%TYPE;
  ln_imp_dolares                   cntas_pagar_det.importe%TYPE;
  ls_flag_estado                   cntas_pagar.flag_estado%TYPE;
  
BEGIN
  -- Obtengo los parametros correspondientes a los totales
  select r.cnc_total_ing		   , r.cnc_total_dsct	 , r.cnc_total_pgd	   , r.cnc_total_aport, r.doc_pago_plla
    into ls_cnc_total_ingreso  , ls_cnc_total_dscto  , ls_cnc_total_pagado , ls_cnc_total_aportes, ls_doc_pago_plla
    from rrhhparam r
   where r.reckey = '1' ;
  
  --recupero de parametros grupos deconceptos de afp
  select rhc.afp_jubilacion,rhc.afp_invalidez,rhc.afp_comision
    into ls_grp_afp_jub,ls_grp_afp_inv,ls_grp_afp_com
    from rrhhparam_cconcep rhc
   where rhc.reckey = '1' ;
  
  -- Obtengo el tipo de cambio correspondiente
  SELECT COUNT(*)
    INTO ln_count
    from calendario tc
   where trunc(tc.fecha) = adi_fec_proceso ;

  IF ln_count = 0 THEN
     RAISE_APPLICATION_ERROR(-20000, 'No existe tipo de cambio para ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
  END IF;
    
  select nvl(tc.vta_dol_prom,1)
    into ln_tasa_cambio
    from calendario tc
   where trunc(tc.fecha) = adi_fec_proceso ;

  IF ln_tasa_cambio = 0 THEN
     RAISE_APPLICATION_ERROR(-20000, 'No ha especificado tipo de cambio para ' || to_char(adi_fec_proceso, 'dd/mm/yyyy'));
  END IF;
  
  -- ACtualizo el importe en dolares de la tabla calculo
  UPDATE calculo c
     SET c.imp_dolar = c.imp_soles / ln_tasa_cambio
   WHERE trunc(c.fec_proceso) = adi_Fec_proceso
     AND c.cod_trabajador IN (SELECT cod_trabajador
                                FROM maestro m
                               WHERE m.tipo_trabajador = asi_tipo_Trabajador
                                 AND m.cod_origen      = asi_origen)
     and c.tipo_planilla = asi_tipo_planilla;

  FOR lc_reg IN c_datos LOOP
      -- Elimino los conceptos totales
      DELETE calculo c
      WHERE c.cod_trabajador = lc_reg.cod_trabajador
        AND trunc(c.fec_proceso) = trunc(adi_Fec_proceso)
        AND c.concep IN (ls_cnc_total_aportes, ls_cnc_total_dscto, ls_cnc_total_ingreso, ls_cnc_total_pagado)
        and c.tipo_planilla = asi_tipo_planilla;
      
      -- Calculo ahora el total de Ingresos
      usp_rh_cal_ganancia_total( lc_reg.cod_trabajador, adi_fec_proceso, asi_origen, ls_cnc_total_ingreso, asi_tipo_planilla) ;
      
      -- Calculo el Total de Descuentos
      usp_rh_cal_descuento_total( lc_reg.cod_trabajador, adi_fec_proceso, asi_origen, ls_cnc_total_dscto, asi_tipo_planilla ) ;
      
      -- Calculo el Neto a Pagar
      usp_rh_cal_total_pagado( lc_reg.cod_trabajador, adi_fec_proceso, asi_origen, ls_cnc_total_ingreso,
                               ls_cnc_total_dscto, ls_cnc_total_pagado, asi_tipo_planilla ) ;
      
      -- Calcular el Total de Aportes
      usp_rh_cal_apo_total( lc_reg.cod_trabajador, adi_fec_proceso, asi_origen, ls_cnc_total_aportes, asi_tipo_planilla ) ;
  END LOOP;
  
  -- Actualizo el monto del documento por pagar directo
  -- Detecto si existe un numero de documento
  
  SELECT COUNT(*)
    INTO ln_count
    FROM calc_doc_pagar_plla t
   WHERE t.tipo_trabajador    = asi_tipo_Trabajador
     AND trunc(t.fec_proceso) = trunc(adi_Fec_proceso)
     AND t.tipo_doc           = ls_doc_pago_plla
     AND t.flag_estado        = '1';
  
  IF ln_count > 0 THEN
     SELECT t.cod_relacion, t.nro_doc
       INTO ls_cod_relacion, ls_nro_doc
       FROM calc_doc_pagar_plla t
      WHERE t.tipo_trabajador    = asi_tipo_Trabajador
        AND trunc(t.fec_proceso) = trunc(adi_Fec_proceso)
        AND t.tipo_doc           = ls_doc_pago_plla
        AND t.flag_estado        = '1';
     
     -- Ahora busco si el documento existe en cntas_pagar
     SELECT COUNT(*)
       INTO ln_count
       FROM cntas_pagar t
      WHERE t.cod_relacion = ls_cod_relacion
        AND t.tipo_doc     = ls_doc_pago_plla
        AND t.nro_doc      = ls_nro_doc;
     
     IF ln_count = 0 THEN
        -- Si el documento no existe, entonces lanzo un error
        RAISE_APPLICATION_ERROR(-20000, 'Documento no existe en Cuentas por Pagar '
                          || chr(13) || 'Cod Relacion: ' || ls_cod_relacion
                          || chr(13) || 'Tipo Doc: '     || ls_doc_pago_plla
                          || chr(13) || 'Nro Doc: '      || ls_nro_doc);
     END IF;
     
     -- Obtengo los datos necesarios
     SELECT t.tasa_cambio, t.flag_estado
       INTO ln_tasa_cambio, ls_flag_estado
       FROM cntas_pagar t
      WHERE t.cod_relacion = ls_cod_relacion
        AND t.tipo_doc     = ls_doc_pago_plla
        AND t.nro_doc      = ls_nro_doc;
     
     -- Verifico los flag de estado del documento
     IF ls_flag_estado = '0' THEN
        -- Documento anulado
        RAISE_APPLICATION_ERROR(-20000, 'Documento en Cuentas por Pagar se encuentra anulado, por favor verifique.'
                          || chr(13) || 'Cod Relacion: ' || ls_cod_relacion
                          || chr(13) || 'Tipo Doc: '     || ls_doc_pago_plla
                          || chr(13) || 'Nro Doc: '      || ls_nro_doc);
     END IF;
     
     IF ls_flag_estado <> '1' THEN
        -- Documento anulado
        RAISE_APPLICATION_ERROR(-20000, 'Documento en Cuentas por Pagar se encuentra Cancelado, por favor verifique.'
                          || chr(13) || 'Cod Relacion: ' || ls_cod_relacion
                          || chr(13) || 'Tipo Doc: '     || ls_doc_pago_plla
                          || chr(13) || 'Nro Doc: '      || ls_nro_doc);
     END IF;
     
     -- Calculo el total neto a pagar
     SELECT NVL(SUM(c.imp_soles),0), NVL(SUM(c.imp_dolar),0)
       INTO ln_imp_soles, ln_imp_dolares
       FROM calculo c,
            maestro m
      WHERE m.cod_trabajador     = c.cod_trabajador
        AND c.concep             = ls_cnc_total_pagado
        AND trunc(c.fec_proceso) = trunc(adi_fec_proceso)
        AND m.tipo_trabajador    = asi_tipo_trabajador
        AND m.cod_origen         = asi_origen
        and c.tipo_planilla      = asi_tipo_planilla;
     
     -- Lo paso a dolares
     -- ln_imp_dolares := ln_imp_soles / ln_tasa_cambio;
     
     -- ahora actualizo el detalle de cntas_pagar_det
     UPDATE cntas_pagar_det t
        SET t.importe = ln_imp_soles
      WHERE t.cod_relacion = ls_cod_relacion
        AND t.tipo_doc     = ls_doc_pago_plla
        AND t.nro_doc      = ls_nro_doc;
     
     -- Ahora tambien actualizo la cabecera
     UPDATE cntas_pagar t
        SET t.importe_doc = ln_imp_soles,
            t.saldo_sol   = ln_imp_soles,
            t.saldo_dol   = ln_imp_dolares
      WHERE t.cod_relacion = ls_cod_relacion
        AND t.tipo_doc     = ls_doc_pago_plla
        AND t.nro_doc      = ls_nro_doc;
     

  END IF;
  
  -- ahora actualizo los documentos de las afp
  FOR lc_reg IN c_tot_afps LOOP
      SELECT COUNT(*)
        INTO ln_Count
        FROM calc_doc_pagar_plla t
        WHERE t.cod_origen   = asi_origen
          AND t.fec_proceso  = t.fec_proceso
          AND t.cod_relacion = t.cod_relacion
          AND t.tipo_doc     = ls_doc_pago_afp
          AND t.flag_estado  = '1';
  END LOOP;
  
  COMMIT;
     
end USP_RH_CALC_TOTALES;
/
