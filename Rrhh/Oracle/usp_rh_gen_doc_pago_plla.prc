create or replace procedure usp_rh_gen_doc_pago_plla(
       asi_tipo_trab       in maestro.tipo_trabajador%type ,
       asi_origen          in origen.cod_origen%Type       ,
       adi_fec_proceso     in date                         ,
       asi_tipo_planilla   in calculo.tipo_planilla%TYPE   ,
       asi_cod_usr         in usuario.cod_usr%type
) is

  ln_imp_soles          calculo.imp_soles%TYPE            ;
  lc_concep_npagar      concepto.concep%type              ;
  lc_tipo_doc           doc_tipo.tipo_doc%type            ;
  lc_nro_doc            cntas_pagar.nro_doc%type          ;
  lc_forma_pago         forma_pago.forma_pago%type        ;
  lc_soles              moneda.cod_moneda%type            ;
  ln_tasa_cambio        calendario.cmp_dol_libre%type     ;
  lc_cencos_pgo_plla    centros_costo.cencos%type         ;
  lc_cnta_prsp_pgo_plla presupuesto_cuenta.cnta_prsp%Type ;
  lc_cod_relacion       proveedor.proveedor%type          ;
  ln_count              Number                            ;
  ln_nro                Number                            ;
  lc_obs                cntas_pagar.descripcion%type      ;

begin

  ln_imp_soles := 0.00 ;

  --parametros
  select rh.cnc_total_pgd    ,rh.doc_pago_plla       ,
         rh.cencos_pago_plla ,rh.cnta_prsp_pago_plla
    into lc_concep_npagar   ,lc_tipo_doc ,
         lc_cencos_pgo_plla ,lc_cnta_prsp_pgo_plla
    from rrhhparam rh
   where rh.reckey = '1' ;

  --buscar codigo de responsablepor tipo de trabajador/FECHA DE PROCESO
  select Count(*) 
    into ln_count
    from rrhh_param_org rpo
   where rpo.origen          = asi_origen
     AND rpo.tipo_trabajador = asi_tipo_trab
     AND trunc(rpo.fec_proceso) = trunc(adi_fec_proceso)
     and rpo.tipo_planilla      = asi_tipo_planilla;

  if ln_count = 0 then
     Raise_Application_Error(-20000,'No Existe Parametros para Proceso por Tipo de Trabajador'
                              || chr(13) || 'Origen: ' || asi_origen
                              || chr(13) || 'Tipo Trabj: ' || asi_tipo_trab
                              || chr(13) || 'Fec Proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy') 
                              || chr(13) || 'Tipo Planilla: ' || asi_tipo_planilla) ;
  ELSIF ln_count > 1 THEN

     Raise_Application_Error(-20000,'Hay muchos Parametros para Proceso por Tipo de Trabajador en la Fecha de proceso'
                              || chr(13) || 'Origen: ' || asi_origen
                              || chr(13) || 'Tipo Trabj: ' || asi_tipo_trab
                              || chr(13) || 'Fec Proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy') 
                              || chr(13) || 'Tipo Planilla: ' || asi_tipo_planilla) ;
                                    
  ELSE
   select cod_relacion
     into lc_cod_relacion
     from RRHH_PARAM_ORG RPO
    where rpo.origen             = asi_origen
      AND rpo.tipo_trabajador    = asi_tipo_trab
      AND trunc(rpo.fec_proceso) = trunc(adi_fec_proceso)
      and rpo.tipo_planilla      = asi_tipo_planilla;
  end if ;

  select forma_pago_contado into lc_forma_pago from genparam where reckey = '1' ;
  select cod_soles          into lc_soles      from logparam where reckey = '1' ;

  --recuperar tipo de cambio
  ln_tasa_cambio := usf_fin_tasa_cambio(adi_fec_proceso) ;
  --

  Select nvl(Sum(Nvl(c.imp_soles,0)),0)
    into ln_imp_soles 
    from calculo c ,
         maestro m
   where c.cod_trabajador     = m.cod_trabajador 
     and m.cod_origen         = asi_origen        
     and m.tipo_trabajador    = asi_tipo_trab    
     and c.concep             = lc_concep_npagar 
     and c.tipo_planilla      = asi_tipo_planilla
     and Trunc(c.fec_proceso) = Trunc(adi_fec_proceso);

  if ln_imp_soles = 0 then
     raise_application_error(-20000,'No Existe Monto a Pagar en Planilla') ;
  end if ;

  ---recupero numero
  select count(*)
    into ln_count
    from num_doc_tipo
    where tipo_doc = lc_tipo_doc;

  if ln_count = 0 then
     insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
     values(lc_tipo_doc, 1, 1);
  end if;

  select ultimo_numero
    into ln_nro
    from num_doc_tipo
   where tipo_doc = lc_tipo_doc for update;

  --CONSTRUIR NUMERO
  lc_nro_doc := asi_origen||lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;

  lc_obs := 'PAGO DE PLANILLA DE '||asi_tipo_trab||'-'||asi_origen||'-'||TO_CHAR(adi_fec_proceso,'dd/mm/yyyy') ;

  --inserta registro cabecera
  Insert Into cntas_pagar(
         cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
         vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
         descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
  VALUES(
         lc_cod_relacion   ,lc_tipo_doc   ,lc_nro_doc   ,'1'            ,adi_fec_proceso ,adi_fec_proceso ,
         adi_fec_proceso   ,lc_forma_pago ,lc_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
         lc_obs,'D'        ,ln_imp_soles ,ln_imp_soles   ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;

  --inserta registro detalle
  Insert Into cntas_pagar_det(
         cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
         cencos       ,cnta_prsp )
  Values(
         lc_cod_relacion    ,lc_tipo_doc           ,lc_nro_doc,'1','PAGO DE PLANILLA' ,1,ln_imp_soles,
         lc_cencos_pgo_plla ,lc_cnta_prsp_pgo_plla ) ;

  --registralo en documentos de pago de planilla
  Insert Into calc_doc_pagar_plla(
         cod_origen,tipo_trabajador ,fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado, tipo_planilla)
  Values(
         asi_origen,asi_tipo_trab,adi_fec_proceso,lc_cod_relacion,lc_tipo_doc,lc_nro_doc,'1', asi_tipo_planilla);

  ln_nro := ln_nro + 1 ;

  update num_doc_tipo
     set ultimo_numero = ln_nro
   where (tipo_doc = lc_tipo_doc) ;

end usp_rh_gen_doc_pago_plla;
/
