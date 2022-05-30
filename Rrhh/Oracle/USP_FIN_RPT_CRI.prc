create or replace procedure USP_FIN_RPT_CRI(
       adi_fecha_inicio date,
       adi_fecha_final  date 
)is

-- Cursor de los certificados de retencion
Cursor c_cri is
SELECT nro_certificado ,
       fecha_emision   ,
       origen          ,
       proveedor       ,
       nro_reg_caja_ban,
       flag_estado
  FROM retencion_igv_crt
 WHERE trunc(fecha_emision) between trunc(adi_fecha_inicio) and trunc(adi_fecha_final);
 
-- Cursor de facturas por pagar
Cursor c_cri_det (ac_origen origen.cod_origen%type,an_nro_registro caja_bancos.nro_registro%type,ac_cod_relacion proveedor.proveedor%type ) is
SELECT cb.cod_moneda  as moneda_cb  ,
       cb.tasa_cambio as t_cambio_cb,
       cbd.importe     ,
       cbd.impt_ret_igv,
       cb.ano,cb.mes,cb.nro_libro,cb.nro_asiento,
       pr.nom_proveedor, 
       pr.ruc,DECODE(cbd.factor,1,'+',-1,'-') AS flag_cxp,
       cp.cod_moneda                                           as moneda_cp
  FROM caja_bancos      cb ,
       caja_bancos_det  cbd,
       cntas_pagar      cp ,
       proveedor        pr
 WHERE ((cb.origen        = cbd.origen       )  AND
        (cb.nro_registro  = cbd.nro_registro )) AND
       ((cbd.flag_ret_igv = '1'              )) AND
       ((cbd.cod_relacion = cp.cod_relacion  )  AND
        (cbd.tipo_doc     = cp.tipo_doc      )  AND
        (cbd.nro_doc      = cp.nro_doc       )) AND
       ((cbd.cod_relacion = pr.proveedor  (+))) AND
       ((cb.origen        = ac_origen        )  AND
        (cb.nro_registro  = an_nro_registro  )  AND
        (cbd.cod_relacion = ac_cod_relacion  )) ;

Cursor c_cri_let(as_nro_certificado retencion_igv_crt.nro_certificado%type) is
Select c.cod_moneda, c.tasa_cambio,
       c.importe_doc, dr.imp_ret_igv,
       dr.importe, dr.tipo_ref,
       dr.nro_ref, c.cod_relacion,
       c.origen, c.ano,
       c.mes, c.nro_libro,
       c.nro_asiento, p.nom_proveedor,
       p.ruc ,DECODE(dr.factor,1,'+',-1,'-') AS flag_cxp
FROM cntas_pagar c,
     doc_referencias dr,
     proveedor p
WHERE ( c.cod_relacion    = dr.cod_relacion      and
        c.tipo_doc        = (select f.doc_letra_pagar from finparam f where reckey = '1') and
        c.nro_doc         = dr.nro_doc         ) and
        c.nro_certificado =  as_nro_certificado  and
        dr.flag_ret_igv   = '1'                  and
        c.cod_relacion    = p.proveedor          and
        c.nro_certificado is not null ;


Cursor c_cri_sg (as_nro_certificado retencion_igv_crt.nro_certificado%type) is
select sgld.cod_moneda ,sgld.tasa_cambio ,sgld.flag_ret_igv ,sgld.importe_ret_igv ,
       sgld.proveedor  ,pr.nom_proveedor ,sg.cnt_origen     ,sg.ano               ,
       sg.mes          ,sg.nro_libro     ,sg.nro_asiento    ,sgld.importe         ,
       pr.ruc          , sg.cod_moneda as cod_moneda_cp
  from solicitud_giro         sg,
       solicitud_giro_liq_det sgld,
       proveedor              pr
 where (sg.origen          = sgld.origen        ) and
       (sg.nro_solicitud   = sgld.nro_solicitud ) and
       (sgld.proveedor     = pr.proveedor       ) and
       (sgld.flag_ret_igv  = '1'                ) and
       (sgld.nro_retencion = as_nro_certificado ) ;




ln_ano                     cntbl_asiento.ano%type         ;
ln_mes                     cntbl_asiento.mes%type         ;
ln_nro_libro               cntbl_asiento.nro_libro%type   ;
ln_nro_asiento             cntbl_asiento.nro_asiento%type ;
ln_importe                 Number (13,2) ;
lc_soles                   moneda.cod_moneda%type         ;
lc_dolares                 moneda.cod_moneda%type         ;
lc_cod_relacion            proveedor.proveedor%type       ;
ln_tot_importe             Number (13,2)                  ;
ln_tot_imp_ret             Number (13,2)                  ;
ln_tasa_cambio             calendario.cmp_dol_prom%type   ;
lc_razon_social            proveedor.nom_proveedor%type   ;
lc_ruc                     proveedor.ruc%type             ;
ls_moneda_ref              moneda.cod_moneda%type         ;
ls_moneda_cp               tt_fin_rpt_cri.cod_moneda_cp%TYPE;
begin

select l.cod_soles,l.cod_dolares 
  into lc_soles,lc_dolares 
from logparam l 
where reckey = '1' ;


For rc_cri in c_cri Loop
    ln_ano          := null ;
    ln_mes          := null ;
    ln_nro_libro    := null ;
    ln_nro_asiento  := null ;
    ln_importe      := 0.00 ;
    ln_tot_importe  := 0.00 ;
    ln_tot_imp_ret  := 0.00 ;
    ln_tasa_cambio  := 0.00 ;
    lc_cod_relacion := NULL ;
    lc_razon_social := 'ANULADO' ;
    lc_ruc          := null ;

    IF rc_cri.nro_reg_caja_ban is not null THEN
       --pago de documentos
       For rc_det_cri in c_cri_det (rc_cri.origen,rc_cri.nro_reg_caja_ban,rc_cri.proveedor) Loop
           ln_ano          := rc_det_cri.ano          ;
           ln_mes          := rc_det_cri.mes          ;
           ln_nro_libro    := rc_det_cri.nro_libro    ;
           ln_nro_asiento  := rc_det_cri.nro_asiento  ;
           ln_importe      := rc_det_cri.importe      ;
           lc_cod_relacion := rc_cri.proveedor        ;
           ln_tasa_cambio  := rc_det_cri.t_cambio_cb  ;
           lc_razon_social := rc_det_cri.nom_proveedor;
           lc_ruc          := rc_det_cri.ruc          ;
           ls_moneda_cp    := rc_det_cri.moneda_cb;

           IF rc_det_cri.moneda_cb <> rc_det_cri.moneda_cp  THEN
              IF rc_det_cri.moneda_cp = lc_soles           THEN --CONVERTIR A DOLARES
                 ln_importe := Round(rc_det_cri.importe / rc_det_cri.t_cambio_cb,2) ;
              ELSIF rc_det_cri.moneda_cp = lc_dolares         THEN --CONVERTIR A SOLES
                 ln_importe := Round(rc_det_cri.importe * rc_det_cri.t_cambio_cb,2) ;
              END IF;
           END IF ;


           IF rc_det_cri.flag_cxp = '-' THEN
              ln_tot_importe := ln_tot_importe - Nvl(ln_importe,0.00) ;
              ln_tot_imp_ret := ln_tot_imp_ret - Nvl(rc_det_cri.impt_ret_igv,0.00) ;
           ELSE
              ln_tot_importe := ln_tot_importe + Nvl(ln_importe,0.00) ;
              ln_tot_imp_ret := ln_tot_imp_ret + Nvl(rc_det_cri.impt_ret_igv,0.00) ;

           END IF ;


       End Loop ;

    ELSE
       ln_tot_importe := 0 ;
       ln_tot_imp_ret := 0 ;

       --canje de letras
       For rc_cri_let in c_cri_let(rc_cri.nro_certificado) Loop
           ln_ano          := rc_cri_let.ano          ;
           ln_mes          := rc_cri_let.mes          ;
           ln_nro_libro    := rc_cri_let.nro_libro    ;
           ln_nro_asiento  := rc_cri_let.nro_asiento  ;
           ln_importe      := rc_cri_let.importe      ;
           lc_cod_relacion := rc_cri_let.cod_relacion ;
           ln_tasa_cambio  := rc_cri_let.tasa_cambio  ;
           lc_razon_social := rc_cri_let.nom_proveedor;
           lc_ruc          := rc_cri_let.ruc          ;
           ls_moneda_cp    := rc_cri_let.cod_moneda;

           -- Verificando la moneda de la referencia
           SELECT cp.cod_moneda
             INTO ls_moneda_ref
             FROM cntas_pagar cp
            WHERE cp.cod_relacion = rc_cri_let.cod_relacion AND
                  cp.tipo_doc = rc_cri_let.tipo_ref AND
                  cp.nro_doc = rc_cri_let.nro_ref ;
                  
           IF rc_cri_let.cod_moneda <> ls_moneda_ref  THEN
              IF ls_moneda_ref = lc_soles           THEN --CONVERTIR A DOLARES
                 ln_importe := Round(rc_cri_let.importe / ln_tasa_cambio,2) ;
              ELSIF ls_moneda_ref = lc_dolares         THEN --CONVERTIR A SOLES
                 ln_importe := Round(rc_cri_let.importe * ln_tasa_cambio,2) ;
              END IF;
           END IF ;

           if rc_cri_let.flag_cxp = '+' THEN
              ln_tot_importe := ln_tot_importe + Nvl(ln_importe,0.00) ;
              ln_tot_imp_ret := ln_tot_imp_ret + Nvl(rc_cri_let.imp_ret_igv,0.00) ;
           elsif rc_cri_let.flag_cxp = '-' THEN
              ln_tot_importe := ln_tot_importe - Nvl(ln_importe,0.00) ;
              ln_tot_imp_ret := ln_tot_imp_ret - Nvl(rc_cri_let.imp_ret_igv,0.00) ;
           end if ;

       End Loop ;

    END IF ;



    --datos de comprobante de retencion en liquidacion de orden de giro
    For rc_sg in c_cri_sg (rc_cri.nro_certificado) Loop
        ln_ano          := rc_sg.ano          ;
        ln_mes          := rc_sg.mes          ;
        ln_nro_libro    := rc_sg.nro_libro    ;
        ln_nro_asiento  := rc_sg.nro_asiento  ;
        ln_importe      := rc_sg.importe      ;
        lc_cod_relacion := rc_sg.proveedor    ;
        ln_tasa_cambio  := rc_sg.tasa_cambio  ;
        lc_razon_social := rc_sg.nom_proveedor;
        lc_ruc          := rc_sg.ruc          ;
        ls_moneda_cp    := rc_sg.cod_moneda;

        ln_tot_importe := ln_tot_importe + Nvl(ln_importe,0.00) ;
        ln_tot_imp_ret := ln_tot_imp_ret + Nvl(rc_sg.importe_ret_igv,0.00) ;

    End Loop ;

    if rc_cri.flag_estado = '0' then
       ln_tot_importe := 0.00 ;
       ln_tot_imp_ret := 0.00 ;
    end if ;
    
    --datos de comprobante de retencion
    Insert Into tt_fin_rpt_cri(
           origen       ,          ano       ,
           mes          ,          nro_libro ,
           nro_asiento  ,          fec_cri   ,
           nro_cri      ,          c_relacion,
           r_social     ,          ruc       ,
           imp_operacion,          imp_ret   ,
           tasa_cambio  ,          cod_moneda_cp)
    Values(
           rc_cri.origen ,         ln_ano      ,
           ln_mes        ,         ln_nro_libro,
           ln_nro_asiento,         rc_cri.fecha_emision,
           rc_cri.nro_certificado, lc_cod_relacion,
           lc_razon_social,        lc_ruc,
           ln_tot_importe,         ln_tot_imp_ret,
           ln_tasa_cambio,         ls_moneda_cp);
End Loop ;

end USP_FIN_RPT_CRI;
/
