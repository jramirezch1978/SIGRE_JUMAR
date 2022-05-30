CREATE OR REPLACE VIEW VW_REGCOMPRAS AS
SELECT td.codigo AS tipo_doc,
       td.descripcion, cp.nro_doc,
       substr(trim(cp.idasiento), length(trim(cp.idasiento)) -4) AS correlativo,
       cp.fecha_emision,
       to_char(a.ano) AS ano,
       to_char(a.mes) AS mes,
       cp.idproveedor,
       '6' AS tipo_doc_identidad,
       p.razonsocial,
       cp.tasa_cambio,
       p.ruc,
       cp.fecha_vencimiento,
       cp.nro_const_deposito,
       to_char(cp.fecha_const_deposito, 'dd/mm/yyyy') AS fecha_const_deposito,
       (SELECT NVL(SUM(cpd.importe),0)
          FROM cntas_pagar_det cpd
         WHERE cpd.idproveedor = cp.idproveedor
           AND cpd.tipo_doc    = cp.tipo_doc
           AND cpd.nro_doc     = cp.nro_doc
           AND cpd.tipo_cred_fiscal = '01') AS importe_01,
       (SELECT NVL(SUM(cpd.importe),0)
          FROM cntas_pagar_det cpd
         WHERE cpd.idproveedor = cp.idproveedor
           AND cpd.tipo_doc    = cp.tipo_doc
           AND cpd.nro_doc     = cp.nro_doc
           AND cpd.tipo_cred_fiscal = '02') AS importe_02,
       (SELECT NVL(SUM(cpd.importe),0)
          FROM cntas_pagar_det cpd
         WHERE cpd.idproveedor = cp.idproveedor
           AND cpd.tipo_doc    = cp.tipo_doc
           AND cpd.nro_doc     = cp.nro_doc
           AND cpd.tipo_cred_fiscal = '03') AS importe_03,
       (SELECT NVL(SUM(cpd.importe),0)
          FROM cntas_pagar_det cpd
         WHERE cpd.idproveedor = cp.idproveedor
           AND cpd.tipo_doc    = cp.tipo_doc
           AND cpd.nro_doc     = cp.nro_doc
           AND cpd.tipo_cred_fiscal = '04') AS importe_04,
       (SELECT NVL(SUM(cpd.importe),0)
          FROM cntas_pagar_det cpd
         WHERE cpd.idproveedor = cp.idproveedor
           AND cpd.tipo_doc    = cp.tipo_doc
           AND cpd.nro_doc     = cp.nro_doc
           AND cpd.tipo_cred_fiscal = '05') AS importe_05,
       (SELECT NVL(SUM(cpd.importe),0)
          FROM cntas_pagar_det cpd
         WHERE cpd.idproveedor = cp.idproveedor
           AND cpd.tipo_doc    = cp.tipo_doc
           AND cpd.nro_doc     = cp.nro_doc
           AND cpd.tipo_cred_fiscal = '06') AS importe_06,
        (SELECT nvl(SUM(imp.importe),0)
           FROM cp_doc_det_imp imp,
                cntas_pagar_det cpd
          WHERE cpd.idproveedor = imp.idproveedor
            AND cpd.tipo_doc    = imp.tipo_doc
            AND cpd.nro_doc     = imp.nro_doc
            AND cpd.item        = imp.item
            AND cpd.idproveedor = cp.idproveedor
            AND cpd.tipo_doc    = cp.tipo_doc
            AND cpd.nro_doc     = cp.nro_doc
            AND cpd.tipo_cred_fiscal  ='01') AS impuesto_01,
        (SELECT nvl(SUM(imp.importe),0)
           FROM cp_doc_det_imp imp,
                cntas_pagar_det cpd
          WHERE cpd.idproveedor = imp.idproveedor
            AND cpd.tipo_doc    = imp.tipo_doc
            AND cpd.nro_doc     = imp.nro_doc
            AND cpd.item        = imp.item
            AND cpd.idproveedor = cp.idproveedor
            AND cpd.tipo_doc    = cp.tipo_doc
            AND cpd.nro_doc     = cp.nro_doc
            AND cpd.tipo_cred_fiscal  ='02') AS impuesto_02,
        (SELECT nvl(SUM(imp.importe),0)
           FROM cp_doc_det_imp imp,
                cntas_pagar_det cpd
          WHERE cpd.idproveedor = imp.idproveedor
            AND cpd.tipo_doc    = imp.tipo_doc
            AND cpd.nro_doc     = imp.nro_doc
            AND cpd.item        = imp.item
            AND cpd.idproveedor = cp.idproveedor
            AND cpd.tipo_doc    = cp.tipo_doc
            AND cpd.nro_doc     = cp.nro_doc
            AND cpd.tipo_cred_fiscal  ='03') AS impuesto_03,
        (SELECT nvl(SUM(imp.importe),0)
           FROM cp_doc_det_imp imp,
                cntas_pagar_det cpd
          WHERE cpd.idproveedor = imp.idproveedor
            AND cpd.tipo_doc    = imp.tipo_doc
            AND cpd.nro_doc     = imp.nro_doc
            AND cpd.item        = imp.item
            AND cpd.idproveedor = cp.idproveedor
            AND cpd.tipo_doc    = cp.tipo_doc
            AND cpd.nro_doc     = cp.nro_doc
            AND cpd.tipo_cred_fiscal  ='04') AS impuesto_04,
        (SELECT nvl(SUM(imp.importe),0)
           FROM cp_doc_det_imp imp,
                cntas_pagar_det cpd
          WHERE cpd.idproveedor = imp.idproveedor
            AND cpd.tipo_doc    = imp.tipo_doc
            AND cpd.nro_doc     = imp.nro_doc
            AND cpd.item        = imp.item
            AND cpd.idproveedor = cp.idproveedor
            AND cpd.tipo_doc    = cp.tipo_doc
            AND cpd.nro_doc     = cp.nro_doc
            AND cpd.tipo_cred_fiscal  ='05') AS impuesto_05,
        (SELECT nvl(SUM(imp.importe),0)
           FROM cp_doc_det_imp imp,
                cntas_pagar_det cpd
          WHERE cpd.idproveedor = imp.idproveedor
            AND cpd.tipo_doc    = imp.tipo_doc
            AND cpd.nro_doc     = imp.nro_doc
            AND cpd.item        = imp.item
            AND cpd.idproveedor = cp.idproveedor
            AND cpd.tipo_doc    = cp.tipo_doc
            AND cpd.nro_doc     = cp.nro_doc
            AND cpd.tipo_cred_fiscal  ='06') AS impuesto_06
FROM cntas_pagar cp,
     tipo_documento td,
     proveedores    p,
     asiento        a
WHERE cp.tipo_doc = td.id_tipodoc
  AND cp.idproveedor = p.idproveedor
  and cp.idasiento   = a.idasiento
  and cp.flag_estado <> '0'
ORDER BY correlativo;
