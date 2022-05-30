create or replace procedure usp_rh_del_doc_quincena(
       asi_ttrab       in maestro.tipo_trabajador%type,
       asi_origen      in maestro.cod_origen%type     ,
       adi_fec_proceso in date                        
) is

ls_flag_estado     cntas_pagar.flag_estado%TYPE;
ls_doc_quincena    rrhhparquin.doc_quincena%TYPE;
ln_count           NUMBER;

Cursor c_doc_quincena is
 select cdpp.cod_relacion,cdpp.tipo_doc,cdpp.nro_doc
   from calc_doc_pagar_plla cdpp
  where cdpp.cod_origen         = asi_origen            
    AND cdpp.tipo_trabajador    = asi_ttrab             
    AND trunc(cdpp.fec_proceso) = trunc(adi_fec_proceso)
    AND cdpp.flag_estado        = '1'                  
    AND cdpp.tipo_doc = ls_doc_quincena;
BEGIN

SELECT t.doc_quincena
  INTO ls_doc_quincena
  FROM rrhhparquin t
 WHERE t.reckey = '1';

for lc_quinc in c_doc_quincena loop
    -- Verifico si el documento no ha sido pagado
    SELECT COUNT(*) 
      INTO ln_count
      FROM cntas_pagar cp
     where cp.cod_relacion = lc_quinc.cod_relacion 
       AND cp.tipo_doc     = lc_quinc.tipo_doc     
       AND cp.nro_doc      = lc_quinc.nro_doc;
       
    IF ln_count > 0 THEN 
       SELECT flag_estado
         INTO ls_flag_estado
         FROM cntas_pagar cp
        where cp.cod_relacion = lc_quinc.cod_relacion 
          AND cp.tipo_doc     = lc_quinc.tipo_doc     
          AND cp.nro_doc      = lc_quinc.nro_doc;
    
       IF ls_flag_estado NOT IN ('1', '0') THEN
          RAISE_APPLICATION_ERROR(-20000, 'El documento: ' || lc_quinc.tipo_doc || ' ' || lc_quinc.nro_doc 
                                         || ' ha sido cancelado, por favor verifique');
       END IF;
       
       --actualizo detalle
       update cntas_pagar_det cpd
          set cpd.importe = 0.00,cpd.cantidad = 0.00
        where (cpd.cod_relacion = lc_quinc.cod_relacion ) and
              (cpd.tipo_doc     = lc_quinc.tipo_doc     ) and
              (cpd.nro_doc      = lc_quinc.nro_doc      ) ;
              
       --actualizo cabecera, por trigger se anula el documento en calc_doc_pagar_plla 
       update cntas_pagar cp
          set cp.flag_estado = '0'  ,cp.importe_doc = 0.00,
              cp.saldo_sol   = 0.00 ,cp.saldo_dol = 0.00
        where (cp.cod_relacion = lc_quinc.cod_relacion ) and
              (cp.tipo_doc     = lc_quinc.tipo_doc     ) and
              (cp.nro_doc      = lc_quinc.nro_doc      ) ;
       
    END IF;
    
 
end loop ;

end usp_rh_del_doc_quincena;
/
