create or replace procedure USP_FIN_PDB(
       ani_year in cntas_pagar.ano%type,
       ani_mes in cntas_pagar.mes%type
)

is

cursor c_exp_pdb is
  select distinct 
         DECODE(p.flag_nac_ext, 'N', '01', '02') || '|' -- 1.Tipo de Compra
         || dt.cod_sunat                            || '|' -- 2.Tipo de Comprobante
         || to_char(cp.fecha_emision, 'dd/mm/yyyy') || '|' -- 3.fecha de Emisión
         || case 
              when dt.cod_sunat in ('10', '12') then ''
              when instr(replace(cp.nro_doc, '.', ''), '-') > 0 then
                lpad(substr(cp.nro_doc, 1,instr(replace(cp.nro_doc, '.', ''), '-') - 1), 4, '0')
              else
               ''
            end || '|' -- 4.Serie del Documento
         || case 
              when dt.cod_sunat in ('50', '52', '53', '54') then ''
              when instr(replace(cp.nro_doc, '.', ''), '-') > 0 then
                lpad(substr(cp.nro_doc, instr(replace(cp.nro_doc, '.', ''), '-') + 1), 8, '0')
              when instr(replace(cp.nro_doc, '.', ''), '-') = 0 and length(cp.nro_doc) > 0 then
                lpad(trim(cp.nro_doc), 8, '0')
              else
               ''
            end || '|' -- 5.Nro del Documento
         || DECODE(p.flag_personeria, 'N', '01', 'J', '02', '03') || '|' -- 6.Tipo de Persona
         || p.tipo_doc_ident || '|' -- 7.Tipo de documento
         || DECODE(p.ruc, null, p.nro_doc_ident, p.ruc) || '|' -- 8.Nro de documento
         || case 
             when p.flag_personeria in ('J', 'E') then
               substr(p.nom_proveedor, 1, 40) 
             else  
               ''
            end || '|' -- 9.Nombre o Razon Social
         || DECODE(p.flag_personeria, 'N', p.apellido_pat, '') || '|' -- 10.Apellido Paterno
         || DECODE(p.flag_personeria, 'N', p.apellido_mat, '') || '|' -- 11.Apellido Materno
         || DECODE(p.flag_personeria, 'N', p.nombre1, '') || '|' -- 12.Nombre 1
         || DECODE(p.flag_personeria, 'N', p.nombre2, '') || '|' -- 13.Nombre 2
         || case 
              when cp.cod_moneda = (select cod_soles from logparam where reckey = '1') then
                '1'
              when cp.cod_moneda = (select cod_dolares from logparam where reckey = '1') then
                '2'
              else
                '9'
            end || '|' -- 14.Tipo de Moneda
         || case 
             when (select count(distinct trim(cf.cod_sunat))
                    from  cntas_pagar_det cpd,
                          credito_fiscal  cf
                    where cpd.tipo_cred_fiscal = cf.tipo_cred_fiscal
                      and cpd.cod_relacion     = cp.cod_relacion
                      and cpd.tipo_doc         = cp.tipo_doc
                      and cpd.nro_doc          = cp.nro_doc) > 1 then '5'
             else
                (select distinct trim(cf.cod_sunat)
                    from  cntas_pagar_det cpd,
                          credito_fiscal  cf
                    where cpd.tipo_cred_fiscal = cf.tipo_cred_fiscal
                      and cpd.cod_relacion     = cp.cod_relacion
                      and cpd.tipo_doc         = cp.tipo_doc
                      and cpd.nro_doc          = cp.nro_doc
                      and cpd.tipo_cred_fiscal in ('01', '02', '03', '04'))
            end || '|' -- 15.Codigo de destino
         || '1' || '|' -- 16.Numero de Destino
         || (select case when nvl(sum(cpd.importe), 0) = 0 then ''
                    else trim(to_char(nvl(sum(cpd.importe), 0), '9999999990.00')) end
               from cntas_pagar_det cpd
              where cpd.cod_relacion = cp.cod_relacion
                and cpd.tipo_doc     = cp.tipo_doc
                and cpd.nro_doc      = cp.nro_doc
                and cpd.tipo_cred_fiscal in ('01', '02', '03', '04'))  || '|'  -- 17.base imponible
         || (select case when nvl(sum(i.importe),0) = 0 then ''
                    else trim(to_char(nvl(sum(i.importe),0), '9999999990.00')) end
               from cntas_pagar_det cpd,
                    cp_doc_det_imp  i,
                    impuestos_tipo  it
              where cpd.cod_relacion = cp.cod_relacion
                and cpd.tipo_doc     = cp.tipo_doc
                and cpd.nro_doc      = cp.nro_doc
                and i.cod_relacion   = cpd.cod_relacion
                and i.tipo_doc       = cpd.tipo_doc
                and i.nro_doc        = cpd.nro_doc
                and i.item           = cpd.item
                and i.tipo_impuesto  = it.tipo_impuesto
                and cpd.tipo_cred_fiscal in ('01', '02', '03', '04')
                and trim(it.tipo_impuesto) = 'ISC') || '|' -- 18.Monto ISC
         || (select case when nvl(sum(i.importe),0) = 0 then ''
                    else trim(to_char(nvl(sum(i.importe),0), '9999999990.00')) end
               from cntas_pagar_det cpd,
                    cp_doc_det_imp  i,
                    impuestos_tipo  it
              where cpd.cod_relacion = cp.cod_relacion
                and cpd.tipo_doc     = cp.tipo_doc
                and cpd.nro_doc      = cp.nro_doc
                and i.cod_relacion   = cpd.cod_relacion
                and i.tipo_doc       = cpd.tipo_doc
                and i.nro_doc        = cpd.nro_doc
                and i.item           = cpd.item
                and i.tipo_impuesto  = it.tipo_impuesto
                and cpd.tipo_cred_fiscal in ('01', '02', '03', '04')
                and it.flag_igv            = '1') || '|' -- 19.Monto IGV
         || (select case when nvl(sum(i.importe),0) = 0 then ''
                    else trim(to_char(nvl(sum(i.importe),0), '9999999990.00')) end
               from cntas_pagar_det cpd,
                    cp_doc_det_imp  i,
                    impuestos_tipo  it
              where cpd.cod_relacion = cp.cod_relacion
                and cpd.tipo_doc     = cp.tipo_doc
                and cpd.nro_doc      = cp.nro_doc
                and i.cod_relacion   = cpd.cod_relacion
                and i.tipo_doc       = cpd.tipo_doc
                and i.nro_doc        = cpd.nro_doc
                and i.item           = cpd.item
                and i.tipo_impuesto  = it.tipo_impuesto
                and cpd.tipo_cred_fiscal in ('01', '02', '03', '04')
                and trim(it.tipo_impuesto) <> 'ISC'
                and it.flag_igv            <> '1') || '|' -- 20.Monto Otros
         || cp.flag_detraccion || '|' -- 21.flag_detraccion 
         || DECODE(cp.flag_detraccion, '0', '', trim(dbs.codigo_sunat)) || '|'      -- 22.Codigo de la tasa de detraccion
         || DECODE(cp.flag_detraccion, '0', '', d.nro_deposito) || '|'              -- 23.Numero de la constancia de deposito
         || DECODE(cp.flag_detraccion, '1', '0', Nvl(cp.flag_retencion,'0')) || '|' -- 24.Indicador de retencion 
         || dt2.cod_sunat || '|'                                                    -- 25.Tipo Doc de referencia
         || case 
              when dt2.cod_sunat in ('10', '12') or dt.cod_sunat not in ('07', '08', '87', '88', '97', '98', '91') or dt2.cod_sunat is null then ''
              when dr.nro_ref is not null and instr(replace(dr.nro_ref, '.', ''), '-') > 0 then
                lpad(substr(dr.nro_ref, 1,instr(replace(dr.nro_ref, '.', ''), '-') - 1), 4, '0')
              else
               ''
            end || '|' -- 26.Serie del Documento de referencia
         || case 
              when dt2.cod_sunat in ('10', '12') or dt.cod_sunat not in ('07', '08', '87', '88', '97', '98', '91') or dt2.cod_sunat is null then ''
              when instr(replace(dr.nro_ref, '.', ''), '-') > 0 then
                substr(dr.nro_ref, instr(replace(dr.nro_ref, '.', ''), '-') + 1)
              when instr(replace(dr.nro_ref, '.', ''), '-') = 0 and length(dr.nro_ref) > 0 then
                trim(dr.nro_ref)
              else
               ''
            end || '|' -- 27.Nro del Documento de referencia
         || decode(cp2.fecha_emision, null, '', to_char(cp2.fecha_emision, 'dd/mm/yyyy')) || '|' -- 28.Fecha de Emision de la referencia
         || case 
              when cp2.fecha_emision is null then ''
              else (select trim(to_char(nvl(sum(cpd.importe), 0), '9999999990.00'))
                      from cntas_pagar_det cpd
                     where cpd.cod_relacion = cp2.cod_relacion
                       and cpd.tipo_doc     = cp2.tipo_doc
                       and cpd.nro_doc      = cp2.nro_doc
                       and cpd.tipo_cred_fiscal in ('01', '02', '03', '04'))
            end || '|' -- 29.Base imponible de la referencia
          || case 
              when cp2.fecha_emision is null then ''
              else (select trim(to_char(nvl(sum(i.importe),0), '9999999990.00')) 
                      from cntas_pagar_det cpd,
                           cp_doc_det_imp  i,
                           impuestos_tipo  it
                     where cpd.cod_relacion = cp.cod_relacion
                       and cpd.tipo_doc     = cp.tipo_doc
                       and cpd.nro_doc      = cp.nro_doc
                       and i.cod_relacion   = cpd.cod_relacion
                       and i.tipo_doc       = cpd.tipo_doc
                       and i.nro_doc        = cpd.nro_doc
                       and i.item           = cpd.item
                        and i.tipo_impuesto  = it.tipo_impuesto
                       and cpd.tipo_cred_fiscal in ('01', '02', '03', '04')
                       and it.flag_igv            = '1')
            end  || '|' -- 30.IGV de la referencia
            as texto
  from cntas_pagar     cp,
       proveedor       p,
       doc_tipo        dt,
       detr_bien_serv  dbs,
       doc_referencias dr,
       doc_tipo        dt2,
       cntas_pagar     cp2,
       detraccion      d
  where cp.cod_relacion      = p.proveedor
    and cp.tipo_doc          = dt.tipo_doc
    and cp.bien_serv         = dbs.bien_serv        (+)
    and cp.cod_relacion      = dr.cod_relacion      (+)
    and cp.tipo_doc          = dr.tipo_doc          (+)
    and cp.nro_doc           = dr.nro_doc           (+)
    and dr.tipo_ref          = dt2.tipo_doc         (+)
    and dr.proveedor_ref     = cp2.cod_relacion     (+)
    and dr.tipo_ref          = cp2.tipo_doc         (+) 
    and dr.nro_ref           = cp2.nro_doc          (+)
    and cp.nro_detraccion    = d.nro_detraccion     (+)
    and (select nvl(sum(cpd.importe),0) 
           from cntas_pagar_det cpd
          where cpd.cod_relacion = cp.cod_relacion
            and cpd.tipo_doc     = cp.tipo_doc
            and cpd.nro_doc      = cp.nro_doc
            and cpd.tipo_cred_fiscal in ('01', '02', '03', '04') ) > 0
    and cp.flag_estado  <> '0'    
    and cp.flag_provisionado = 'R'
    and cp.tipo_doc not in ('RE')
    and cp.ano      = ani_year
    and cp.mes      = ani_mes
    and cp.flag_tipo_ltr is null
 order by 1; --p.nom_proveedor, cp.tipo_doc, cp.nro_doc;

begin

delete from tt_fin_exp_file ;

For lc_reg in c_exp_pdb Loop
    Insert into tt_fin_exp_file(exp_row)
    Values (lc_reg.texto) ;

End Loop ;
End USP_FIN_PDB;
/
