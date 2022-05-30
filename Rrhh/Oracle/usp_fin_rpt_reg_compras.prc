create or replace procedure usp_fin_rpt_reg_compras(
       as_ano     in string ,
       as_mes     in string ,
       as_origen  in origen.cod_origen%TYPE
)is

ls_tipo_credito    credito_fiscal.tipo_cred_fiscal%type ;
ls_nro_deposito    detraccion.nro_deposito%type         ;
ld_fecha_deposito  detraccion.fecha_deposito%type       ;
lc_flag_detraccion Char(1)                              ;
ls_nro_detracc     detraccion.nro_detraccion%type       ;
ln_base01          tt_fin_rpt_reg_compras.ln_base01%TYPE :=0;
ln_base02          tt_fin_rpt_reg_compras.ln_base02%TYPE :=0;
ln_base03          tt_fin_rpt_reg_compras.ln_base03%TYPE :=0;
ln_base04          tt_fin_rpt_reg_compras.ln_base04%TYPE :=0;
ln_base05          tt_fin_rpt_reg_compras.ln_base05%TYPE :=0;
ln_base06          tt_fin_rpt_reg_compras.ln_base06%TYPE :=0;
ln_igv             tt_fin_rpt_reg_compras.ln_igv01%TYPE :=0;
ln_igv01           tt_fin_rpt_reg_compras.ln_igv01%TYPE :=0;
ln_igv02           tt_fin_rpt_reg_compras.ln_igv02%TYPE :=0;
ln_igv03           tt_fin_rpt_reg_compras.ln_igv03%TYPE :=0;
ln_igv04           tt_fin_rpt_reg_compras.ln_igv04%TYPE :=0;
ln_igv05           tt_fin_rpt_reg_compras.ln_igv05%TYPE :=0;
ln_igv06           tt_fin_rpt_reg_compras.ln_igv06%TYPE :=0;
ln_total           tt_fin_rpt_reg_compras.ln_total%TYPE :=0;
ls_soles           moneda.cod_moneda%TYPE;
ls_percepcion      logparam.cod_percepcion%TYPE;
ln_percepcion      tt_fin_rpt_reg_compras.ln_percepcion%TYPE := 0;
ln_count           number ;
ld_fec_dua         oc_importacion.dua_fecha%TYPE;
ls_cod_aduana      oc_importacion.cod_aduana%TYPE;
ls_doc_oc          logparam.doc_oc%TYPE;
ls_tipo_ref        doc_referencias.tipo_ref%TYPE;
ls_nro_ref         doc_referencias.nro_ref%TYPE;
ld_fec_emi_ref     cntas_pagar.fec_impresion%TYPE;

--- Cursor Ctas pagar Cabecera ---
Cursor c_cpc is
select cp.cod_relacion   , p.nom_proveedor   , cp.tipo_doc   ,
       cp.nro_doc        , trunc(cp.fecha_emision)  AS fecha_emision, DECODE(p.ruc, NULL, p.nro_doc_ident, p.ruc) AS ruc ,
       cp.nro_asiento    , cp.cod_moneda     ,
       cp.origen         , cp.nro_detraccion , cp.vencimiento,
       cp.cod_aduana     , cp.nro_correlativo, dc.cod_sunat   ,
       p.tipo_doc_ident  , cp.tasa_cambio
from   cntas_pagar cp,
       proveedor   p,
       doc_tipo    dc
where  cp.cod_relacion            = p.proveedor
  AND  cp.tipo_doc                = dc.tipo_doc
  AND  cp.flag_estado             <> '0'
  AND  to_char(cp.ano)            = as_ano
  AND  trim(to_char(cp.mes,'09')) = as_mes
  AND  cp.nro_libro               = (select f.libro_compras from finparam f where f.reckey = '1')
  AND  cp.origen                  like as_origen
 ORDER BY dc.cod_sunat, cp.nro_asiento;

--- Cursor Cuentas Pagar con Detalle ---
Cursor   c_cpd (as_cod_rel    in cntas_pagar.cod_relacion%TYPE,
                as_tipo_doc   in cntas_pagar.tipo_doc%TYPE,
                as_nro_doc    in cntas_pagar.nro_doc%TYPE,
                as_cod_moneda in moneda.cod_moneda%TYPE,
                an_tasa_cambio in number ) is
  SELECT cpd.item            ,
         cpd.tipo_cred_fiscal,
         ROUND(DECODE(as_cod_moneda , ls_soles , cpd.importe, cpd.importe*an_tasa_cambio),2) AS TOTAL
    from cntas_pagar_det cpd
   where cpd.cod_relacion = as_cod_rel
     AND cpd.tipo_doc     = as_tipo_doc
     AND cpd.nro_doc      = as_nro_doc ;


--- Cursor Parametros Reportes ---
Cursor c_TipoCreditoFiscal ( as_cred_fiscal in string ) is
  select RTRIM(rp.rpt_key) as num_col
  from   reportes r, rpt_prm rp
  where  r.reporte  = rp.reporte and
         r.reporte  = 'RPTCMP01' and
         r.sistema  = 'FINANZAS' and
         RTRIM(rp.rpt_key) = as_cred_fiscal;

begin

  Delete tt_fin_rpt_reg_compras;

  SELECT cod_soles, doc_oc, l.cod_percepcion
  INTO   ls_soles, ls_doc_oc, ls_percepcion
  FROM   logparam l
  WHERE  reckey = '1';

  FOR rc_cpc IN c_cpc LOOP
      ln_base01 :=0; ln_base02 :=0; ln_base03 :=0; ln_base04 :=0;
      ln_base05 :=0; ln_base06 :=0; ln_igv    :=0; ln_igv01  :=0;
      ln_igv02  :=0; ln_igv03  :=0; ln_igv04  :=0; ln_igv05  :=0;
      ln_igv06 :=0;

      -- Suma la percepci¿n correspondiente
      select ROUND(NVL(Sum(DECODE(rc_cpc.cod_moneda , ls_soles , cpi.importe, cpi.importe*rc_cpc.tasa_cambio)),0),2)
        into ln_percepcion
        from cp_doc_det_imp cpi
       where cpi.cod_relacion  = rc_cpc.cod_relacion
         AND cpi.tipo_doc      = rc_cpc.tipo_doc
         AND cpi.nro_doc       = rc_cpc.nro_doc
         AND cpi.tipo_impuesto = ls_percepcion;

      FOR rc_cpd IN c_cpd (rc_cpc.cod_relacion, rc_cpc.tipo_doc, rc_cpc.nro_doc , rc_cpc.cod_moneda , rc_cpc.tasa_cambio) LOOP

          FOR rc_r in c_TipoCreditoFiscal (rc_cpd.tipo_cred_fiscal) LOOP
              ls_tipo_credito := rc_r.num_col;
              ln_igv          := 0.00 ;

              IF ls_tipo_credito = '01' THEN
                 ln_base01 := ln_base01 + rc_cpd.total;

                 select COUNT(*)
                   into ln_count
                  from  cp_doc_det_imp cpi
                  where cpi.cod_relacion  = rc_cpc.cod_relacion
                    AND cpi.tipo_doc      = rc_cpc.tipo_doc
                    AND cpi.nro_doc       = rc_cpc.nro_doc
                    AND cpi.item          = rc_cpd.item
                    AND cpi.tipo_impuesto <> ls_percepcion;

                IF ln_count > 0 THEN
                   select ROUND(Sum(DECODE(rc_cpc.cod_moneda , ls_soles , cpi.importe, cpi.importe*rc_cpc.tasa_cambio)),2) AS TOTAL
                     into ln_igv
                     from cp_doc_det_imp cpi
                    where cpi.cod_relacion = rc_cpc.cod_relacion and
                          cpi.tipo_doc     = rc_cpc.tipo_doc     and
                          cpi.nro_doc      = rc_cpc.nro_doc      and
                          cpi.item         = rc_cpd.item         AND
                          cpi.tipo_impuesto <> ls_percepcion;
                END IF ;

                ln_igv01 := ln_igv01 + ln_igv;

             ELSIf ls_tipo_credito = '02' THEN
                ln_base02 := ln_base02 + rc_cpd.total;

                select COUNT(*)
                into   ln_count
                from   cp_doc_det_imp cpi
                where  cpi.cod_relacion = rc_cpc.cod_relacion and
                       cpi.tipo_doc     = rc_cpc.tipo_doc     and
                       cpi.nro_doc      = rc_cpc.nro_doc      and
                       cpi.item         = rc_cpd.item         AND
                       cpi.tipo_impuesto <> ls_percepcion;

                IF ln_count > 0 THEN
                   select ROUND(Sum(DECODE(rc_cpc.cod_moneda , ls_soles , cpi.importe, cpi.importe*rc_cpc.tasa_cambio)),2) AS TOTAL
                     into ln_igv
                     from cp_doc_det_imp cpi
                    where cpi.cod_relacion = rc_cpc.cod_relacion and
                          cpi.tipo_doc     = rc_cpc.tipo_doc     and
                          cpi.nro_doc      = rc_cpc.nro_doc      and
                          cpi.item         = rc_cpd.item         AND
                          cpi.tipo_impuesto <> ls_percepcion;
                END IF ;

                ln_igv02 := ln_igv02 + ln_igv;

             ELSIF ls_tipo_credito = '03' THEN
                ln_base03 := ln_base03 + rc_cpd.total;

                select COUNT(*)
                into   ln_count
                from   cp_doc_det_imp cpi
                where  cpi.cod_relacion = rc_cpc.cod_relacion and
                       cpi.tipo_doc     = rc_cpc.tipo_doc     and
                       cpi.nro_doc      = rc_cpc.nro_doc      and
                       cpi.item         = rc_cpd.item         AND
                       cpi.tipo_impuesto <> ls_percepcion;

                IF ln_count > 0 THEN
                   select ROUND(Sum(DECODE(rc_cpc.cod_moneda , ls_soles , cpi.importe, cpi.importe*rc_cpc.tasa_cambio)),2) AS TOTAL
                     into ln_igv
                     from cp_doc_det_imp cpi
                    where cpi.cod_relacion = rc_cpc.cod_relacion and
                          cpi.tipo_doc     = rc_cpc.tipo_doc     and
                          cpi.nro_doc      = rc_cpc.nro_doc      and
                          cpi.item         = rc_cpd.item         AND
                          cpi.tipo_impuesto <> ls_percepcion;
                END IF ;

                ln_igv03 := ln_igv03 + ln_igv;

             ELSIF ls_tipo_credito = '04' THEN
                ln_base04 := ln_base04 + rc_cpd.total;

                select COUNT(*)
                into   ln_count
                from   cp_doc_det_imp cpi
                where  cpi.cod_relacion = rc_cpc.cod_relacion and
                       cpi.tipo_doc     = rc_cpc.tipo_doc     and
                       cpi.nro_doc      = rc_cpc.nro_doc      and
                       cpi.item         = rc_cpd.item         AND
                       cpi.tipo_impuesto <> ls_percepcion;

                IF ln_count > 0 THEN
                   select ROUND(Sum(DECODE(rc_cpc.cod_moneda , ls_soles , cpi.importe, cpi.importe*rc_cpc.tasa_cambio)),2) AS TOTAL
                     into ln_igv
                     from cp_doc_det_imp cpi
                    where cpi.cod_relacion = rc_cpc.cod_relacion and
                          cpi.tipo_doc     = rc_cpc.tipo_doc     and
                          cpi.nro_doc      = rc_cpc.nro_doc      and
                          cpi.item         = rc_cpd.item         AND
                          cpi.tipo_impuesto <> ls_percepcion;
                END IF ;

                ln_igv04 := ln_igv04 + ln_igv;

             ELSIF ls_tipo_credito = '05' THEN
                ln_base05 := ln_base05 + rc_cpd.total;

                select COUNT(*)
                into   ln_count
                from   cp_doc_det_imp cpi
                where  cpi.cod_relacion = rc_cpc.cod_relacion and
                       cpi.tipo_doc     = rc_cpc.tipo_doc     and
                       cpi.nro_doc      = rc_cpc.nro_doc      and
                       cpi.item         = rc_cpd.item         AND
                       cpi.tipo_impuesto <> ls_percepcion;

                IF ln_count > 0 THEN
                   select ROUND(Sum(DECODE(rc_cpc.cod_moneda , ls_soles , cpi.importe, cpi.importe*rc_cpc.tasa_cambio) * DECODE(i.signo, '-', -1, 1) ),2)  AS TOTAL
                     into ln_igv
                     from cp_doc_det_imp cpi,
                          impuestos_tipo i
                    where cpi.tipo_impuesto = i.tipo_impuesto
                      and cpi.cod_relacion = rc_cpc.cod_relacion 
                      and cpi.tipo_doc     = rc_cpc.tipo_doc     
                      and cpi.nro_doc      = rc_cpc.nro_doc      
                      and cpi.item         = rc_cpd.item         
                      AND cpi.tipo_impuesto <> ls_percepcion;
                END IF ;

                ln_igv05 := ln_igv05 + ln_igv;

             ELSIF ls_tipo_credito = '06' THEN
                ln_base06 := ln_base06 + rc_cpd.total;

                -- IMPUESTO A LA RENTA DE 4ta CATEGORIA --
                select ROUND(Sum(DECODE(rc_cpc.cod_moneda , ls_soles , cpi.importe, cpi.importe*rc_cpc.tasa_cambio)),2)
                into   ln_igv
                from   cp_doc_det_imp cpi
                where  cpi.cod_relacion = rc_cpc.cod_relacion and
                       cpi.tipo_doc     = rc_cpc.tipo_doc     and
                       cpi.nro_doc      = rc_cpc.nro_doc      and
                       cpi.item         = rc_cpd.item         and
                       cpi.tipo_impuesto = 'IR4TA';

                  ln_igv06 := ln_igv06 + ln_igv;

                  IF ln_igv06 IS NULL THEN
                    ln_igv06 := 0;
                  END IF;

             END IF;
          END LOOP;
      END LOOP;

      ln_total := ln_base01 + ln_base02 + ln_base03 + ln_base04 +
                  ln_base05 + ln_base06 + ln_igv01  + ln_igv02  +
                  ln_igv03  + ln_igv04  + ln_igv05  - ln_igv06  + ln_percepcion;

      ls_nro_deposito := null ;
      ld_fecha_deposito := null ;
      ls_nro_detracc := null ;

      IF rc_cpc.nro_detraccion IS NOT NULL THEN
         SELECT d.nro_detraccion, d.nro_deposito, d.fecha_deposito
           INTO ls_nro_detracc, ls_nro_deposito, ld_fecha_deposito
           FROM detraccion d
          WHERE d.nro_detraccion = rc_cpc.nro_detraccion
            AND d.flag_estado <> '0' ;

         lc_flag_detraccion := '1' ;
      ELSE
         lc_flag_detraccion := '0' ;
      END IF ;

      -- Busco el documento de referencia
      ls_cod_aduana := NULL;
      ld_fec_dua := NULL;

      SELECT COUNT(*)
        INTO ln_count
        FROM doc_referencias dr
       WHERE dr.cod_relacion = rc_cpc.cod_relacion
         AND dr.tipo_doc     = rc_cpc.tipo_doc
         AND dr.nro_doc      = rc_cpc.nro_doc;

      IF ln_count > 0 THEN
         SELECT dr.tipo_ref, dr.nro_ref
           INTO ls_tipo_ref, ls_nro_ref
           FROM doc_referencias dr
          WHERE dr.cod_relacion = rc_cpc.cod_relacion
            AND dr.tipo_doc     = rc_cpc.tipo_doc
            AND dr.nro_doc      = rc_cpc.nro_doc
            AND rownum          = 1;  -- Tomo la primera referencia

         IF ls_tipo_ref = ls_doc_oc THEN
            SELECT COUNT(*)
              INTO ln_count
              FROM oc_importacion o
             WHERE o.nro_oc = ls_nro_ref;

            IF ln_count > 0 THEN
               SELECT o.dua_fecha, o.cod_aduana
                 INTO ld_fec_dua, ls_cod_aduana
                 FROM oc_importacion o
                WHERE o.nro_oc = ls_nro_ref
                  AND rownum = 1;  -- Tomo la primera dua
            END IF;
         END IF;

         -- Obtengo la fecha de emisi¿n
         if rc_cpc.tipo_doc in ('NCP', 'NDP') then
            select count(*)
              into ln_count
              from cntas_pagar cp
             where cp.cod_relacion = rc_cpc.cod_relacion
               and cp.tipo_doc     = ls_tipo_ref
               and cp.nro_doc      = ls_nro_ref
               and cp.flag_estado  <> '0';

            if ln_count > 0 then
                select cp.fecha_emision
                into ld_fec_emi_ref
                from cntas_pagar cp
               where cp.cod_relacion = rc_cpc.cod_relacion
                 and cp.tipo_doc     = ls_tipo_ref
                 and cp.nro_doc      = ls_nro_ref
                 and cp.flag_estado  <> '0';
            end if;

         end if;
      END IF;

      -- Si el tipo de documento no es nota de credito o nota de debito entonces no debo poner el documento de referencia
      if rc_cpc.tipo_doc not in ('NCP', 'NDP') then
         ls_tipo_ref := null;
         ls_nro_ref  := null;
         ld_fec_emi_ref := null;
      end if;

      INSERT INTO tt_fin_rpt_reg_compras(
             fec_emision    , tipo_doc             , nro_doc,
             cod_relacion   , razon_social         , ruc,
             nro_deposito   , fecha_deposito       , tasa_cambio,
             origen         , nro_provisional      ,
             ln_base01      , ln_base02            , ln_base03   ,
             ln_base04      , ln_base05            , ln_base06   ,
             ln_igv01       , ln_igv02             , ln_igv03,
             ln_igv04       , ln_igv05             , ln_igv06    ,
             ln_total       , flag_detrac          , nro_detraccion,
             vencimiento    , doc_tipo_sunat       , tipo_doc_ident,
             nro_correlativo, ano_dua              , cod_aduana,
             ln_percepcion  , tipo_ref             , nro_ref         ,
             fec_emision_ref)
      VALUES
            (rc_cpc.fecha_emision , rc_cpc.tipo_doc      , rc_cpc.nro_doc   ,
             rc_cpc.cod_relacion  , rc_cpc.nom_proveedor , rc_cpc.ruc       ,
             ls_nro_deposito      , ld_fecha_deposito    , rc_cpc.tasa_cambio,
             rc_cpc.origen        , rc_cpc.nro_asiento   ,
             ln_base01            , ln_base02            , ln_base03       ,
             ln_base04            , ln_base05            , ln_base06       ,
             ln_igv01             , ln_igv02             , ln_igv03,
             ln_igv04             , ln_igv05             , ln_igv06           ,
             ln_total             , lc_flag_detraccion   , ls_nro_detracc     ,
             rc_cpc.vencimiento   , rc_cpc.cod_sunat     , rc_cpc.tipo_doc_ident,
             rc_cpc.nro_correlativo, to_number(ld_fec_dua, 'yyyy'), ls_cod_aduana,
             ln_percepcion         , ls_tipo_ref,          ls_nro_ref         ,
       ld_fec_emi_ref) ;

  END LOOP;
end usp_fin_rpt_reg_compras;
/
