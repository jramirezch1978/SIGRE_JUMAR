create or replace procedure usp_rh_del_doc_cal_plla(
       asi_tipo_trab        in maestro.tipo_trabajador%type,
       asi_origen           in maestro.cod_origen%type     ,
       adi_fec_proceso      in date,
       asi_tipo_planilla    in calculo.tipo_planilla%TYPE                        
) is

ls_flag_estado     cntas_pagar.flag_estado%TYPE;
ls_doc_pago_plan   rrhhparam.doc_pago_plla%TYPE;
ls_doc_pago_afp    rrhhparam.doc_pago_afp%TYPE;
ln_count           NUMBER;

Cursor c_doc_plla is
 select cdpp.cod_relacion,cdpp.tipo_doc,cdpp.nro_doc
   from calc_doc_pagar_plla cdpp
  where cdpp.cod_origen         = asi_origen            
    AND cdpp.tipo_trabajador    = asi_tipo_trab             
    AND trunc(cdpp.fec_proceso) = trunc(adi_fec_proceso)
    and cdpp.tipo_planilla      = asi_tipo_planilla
    AND cdpp.flag_estado        = '1'                  
    AND cdpp.tipo_doc IN (ls_doc_pago_afp, ls_doc_pago_plan);
BEGIN

SELECT t.doc_pago_afp, t.doc_pago_plla
  INTO ls_doc_pago_afp, ls_doc_pago_plan
  FROM rrhhparam t
 WHERE t.reckey = '1';

for rc_doc_plla in c_doc_plla loop
    -- Verifico si el documento no ha sido pagado
    SELECT COUNT(*) 
      INTO ln_count
      FROM cntas_pagar cp
     where cp.cod_relacion = rc_doc_plla.cod_relacion 
       AND cp.tipo_doc     = rc_doc_plla.tipo_doc     
       AND cp.nro_doc      = rc_doc_plla.nro_doc;
       
    IF ln_count > 0 THEN 
       SELECT flag_estado
         INTO ls_flag_estado
         FROM cntas_pagar cp
        where cp.cod_relacion = rc_doc_plla.cod_relacion 
          AND cp.tipo_doc     = rc_doc_plla.tipo_doc     
          AND cp.nro_doc      = rc_doc_plla.nro_doc;
    
       IF ls_flag_estado NOT IN ('1', '0') THEN
          RAISE_APPLICATION_ERROR(-20000, 'El documento: ' || rc_doc_plla.tipo_doc || ' ' || rc_doc_plla.nro_doc 
                                         || ' no se encuentra activo, por favor verifique si ha sido pagado por tesorería, por favor verifique');
       END IF;
       
       --actualizo detalle
       update cntas_pagar_det cpd
          set cpd.importe = 0.00,cpd.cantidad = 0.00
        where (cpd.cod_relacion = rc_doc_plla.cod_relacion ) and
              (cpd.tipo_doc     = rc_doc_plla.tipo_doc     ) and
              (cpd.nro_doc      = rc_doc_plla.nro_doc      ) ;
              
       --actualizo cabecera, por trigger se anula el documento en calc_doc_pagar_plla 
       update cntas_pagar cp
          set cp.flag_estado = '0'  ,cp.importe_doc = 0.00,
              cp.saldo_sol   = 0.00 ,cp.saldo_dol = 0.00
        where (cp.cod_relacion = rc_doc_plla.cod_relacion ) and
              (cp.tipo_doc     = rc_doc_plla.tipo_doc     ) and
              (cp.nro_doc      = rc_doc_plla.nro_doc      ) ;
       
    END IF;
    
 
end loop ;

end usp_rh_del_doc_cal_plla;
/
