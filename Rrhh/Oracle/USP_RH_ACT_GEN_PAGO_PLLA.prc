create or replace procedure USP_RH_ACT_GEN_PAGO_PLLA(
       asi_tipo_trab    in maestro.tipo_trabajador%type ,
       asi_origen       in origen.cod_origen%Type       ,
       adi_fec_proceso  in date                         ,
       asi_cod_usr      in usuario.cod_usr%type
) is

  ln_imp_soles          calculo.imp_soles%TYPE            ;
  ls_concep_npagar      concepto.concep%type              ;
  ls_doc_pago_plla      rrhhparam.doc_pago_plla%TYPE      ;
  ls_nro_doc            cntas_pagar.nro_doc%type          ;
  ls_forma_pago         forma_pago.forma_pago%type        ;
  ls_soles              moneda.cod_moneda%type            ;
  ln_tasa_cambio        calendario.cmp_dol_libre%type     ;
  ls_cencos_pgo_plla    centros_costo.cencos%type         ;
  ls_cnta_prsp_pgo_plla presupuesto_cuenta.cnta_prsp%Type ;
  ls_cod_relacion       proveedor.proveedor%type          ;
  ln_count              Number                            ;
  ln_nro                Number                            ;
  ls_obs                cntas_pagar.descripcion%type      ;
  ls_flag_estado        cntas_pagar.flag_estado%TYPE      ;

begin

  ln_imp_soles := 0.00 ;

  --parametros
  select rh.cnc_total_pgd    ,rh.doc_pago_plla       ,
         rh.cencos_pago_plla ,rh.cnta_prsp_pago_plla
    into ls_concep_npagar   ,ls_doc_pago_plla ,
         ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla
    from rrhhparam rh
   where rh.reckey = '1' ;

  --buscar codigo de responsablepor tipo de trabajador/FECHA DE PROCESO
  select Count(*) into ln_count
    from rrhh_param_org rpo
   where rpo.origen          = asi_origen
     AND rpo.tipo_trabajador = asi_tipo_trab
     AND trunc(rpo.fec_proceso) = trunc(adi_fec_proceso);

  if ln_count = 0 then
     Raise_Application_Error(-20000,'No Existe Parametros para Proceso por Tipo de Trabajador'
                              || chr(13) || 'Origen: ' || asi_origen
                              || chr(13) || 'Tipo Trabj: ' || asi_tipo_trab
                              || chr(13) || 'Fec Proceso: ' || to_char(adi_fec_proceso, 'dd/mm/yyyy') ) ;
  ELSIF ln_count > 1 THEN
     Raise_Application_Error(-20000,'Hay muchos Parametros para Proceso por Tipo de Trabajador en la Fecha de proceso') ;
  ELSE
   select cod_relacion
     into ls_cod_relacion
     from RRHH_PARAM_ORG RPO
    where rpo.origen          = asi_origen
      AND rpo.tipo_trabajador = asi_tipo_trab
      AND trunc(rpo.fec_proceso) = trunc(adi_fec_proceso);
  end if ;

  select forma_pago_contado 
    into ls_forma_pago 
    from genparam 
   where reckey = '1' ;
   
  select cod_soles          
    into ls_soles      
    from logparam 
   where reckey = '1' ;

  --recuperar tipo de cambio
  ln_tasa_cambio := usf_fin_tasa_cambio(adi_fec_proceso) ;
  --

  Select sum(imp_soles) 
    into ln_imp_soles
  from(  Select NVL(Sum(Nvl(c.imp_soles,0)),0) as imp_soles
           from calculo c ,
                maestro m
          where c.cod_trabajador     = m.cod_trabajador 
            and m.cod_origen         = asi_origen        
            and m.tipo_trabajador    = asi_tipo_trab    
            and c.concep             = ls_concep_npagar 
            and Trunc(c.fec_proceso) = Trunc(adi_fec_proceso)
         union
         Select NVL(Sum(Nvl(hc.imp_soles,0)),0) as imp_soles
           from historico_calculo hc ,
                maestro           m
          where hc.cod_trabajador       = m.cod_trabajador 
            and m.cod_origen            = asi_origen        
            and m.tipo_trabajador       = asi_tipo_trab    
            and hc.concep               = ls_concep_npagar 
            and Trunc(hc.fec_calc_plan) = Trunc(adi_fec_proceso)
  );

  if ln_imp_soles = 0 then
     raise_application_error(-20000,'No Existe Monto a Pagar en Planilla') ;
  end if ;

  ---recupero numero
  select count(*)
    into ln_count
    from num_doc_tipo
    where tipo_doc = ls_doc_pago_plla;

  if ln_count = 0 then
     insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
     values(ls_doc_pago_plla, 1, 1);
  end if;

  select ultimo_numero
    into ln_nro
    from num_doc_tipo
   where tipo_doc = ls_doc_pago_plla for update;

  --CONSTRUIR NUMERO
  ls_nro_doc := asi_origen||lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;

  ls_obs := 'PAGO DE PLANILLA DE '||asi_tipo_trab||'-'||asi_origen||'-'||TO_CHAR(adi_fec_proceso,'dd/mm/yyyy') ;
  
  -- Primero verifico si ya existe el documento o no existe
  select count(*)
    into ln_count
    from calc_doc_pagar_plla cdpp
   where cdpp.cod_origen         = asi_origen            
     AND cdpp.tipo_trabajador    = asi_tipo_trab             
     AND trunc(cdpp.fec_proceso) = trunc(adi_fec_proceso)
     AND cdpp.tipo_doc           = ls_doc_pago_plla
     and cdpp.cod_relacion       = ls_cod_relacion
     and cdpp.flag_estado        <> '0';
        
  if ln_count > 0 then          
     -- Si existe el documento verifico el estado del mismo
     select cdpp.nro_doc
       into ls_nro_doc
       from calc_doc_pagar_plla cdpp
      where cdpp.cod_origen         = asi_origen            
        AND cdpp.tipo_trabajador    = asi_tipo_trab             
        AND trunc(cdpp.fec_proceso) = trunc(adi_fec_proceso)
        AND cdpp.tipo_doc           = ls_doc_pago_plla
        and cdpp.cod_relacion       = ls_cod_relacion
        and cdpp.flag_estado        <> '0';
              
     -- Verifico si el documento existe o no   
     SELECT COUNT(*) 
       INTO ln_count
       FROM cntas_pagar cp
      where cp.cod_relacion = ls_cod_relacion
        AND cp.tipo_doc     = ls_doc_pago_plla
        AND cp.nro_doc      = ls_nro_doc;
       
     IF ln_count > 0 THEN 
        SELECT flag_estado
          INTO ls_flag_estado
          FROM cntas_pagar cp
         where cp.cod_relacion = ls_cod_relacion 
           AND cp.tipo_doc     = ls_doc_pago_plla
           AND cp.nro_doc      = ls_nro_doc;
    
        IF ls_flag_estado NOT IN ('1', '0') THEN
           RAISE_APPLICATION_ERROR(-20000, 'El documento: ' || ls_doc_pago_plla || ' ' || ls_nro_doc 
                                   || ' ha sido cancelado, por favor verifique');
        END IF;
     else
        ls_nro_doc := null;
     END IF;
  else
     ls_nro_doc := null;
  end if;
  
  -- Si no existe el documento entonces creo 
  if ls_nro_doc is null then
     --CONSTRUIR NUMERO
     ls_nro_doc := asi_origen||lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;
     ln_nro := ln_nro + 1 ;
  end if;

  -- Actualizo la informacion
  update cntas_pagar cp
     set cp.fecha_emision = adi_fec_proceso,
         cp.vencimiento   = adi_fec_proceso,
         cp.forma_pago    = ls_forma_pago,
         cp.cod_moneda    = ls_soles,
         cp.tasa_cambio   = ln_tasa_cambio,
         cp.cod_usr       = asi_cod_usr,
         cp.origen        = asi_origen,
         cp.descripcion   = ls_obs,
         cp.flag_provisionado = 'D',
         cp.importe_doc       = ln_imp_soles,
         cp.saldo_sol         = ln_imp_soles,
         cp.saldo_dol         = Round(ln_imp_soles / ln_tasa_cambio,2),
         cp.flag_control_reg  = '0'
   where cp.cod_relacion = ls_cod_relacion 
     and cp.tipo_doc     = ls_doc_pago_plla     
     and cp.nro_doc      = ls_nro_doc;

  if SQL%NOTFOUND then
     --inserta registro cabecera
     Insert Into cntas_pagar(
               cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
               vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
               descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
     VALUES(
               ls_cod_relacion   ,ls_doc_pago_plla ,ls_nro_doc   ,'1'            ,adi_fec_proceso ,adi_fec_proceso ,
               adi_fec_proceso   ,ls_forma_pago    ,ls_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
               ls_obs,'D'        ,ln_imp_soles     ,ln_imp_soles   ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;
  END IF;
  
  -- Actualizo el detalle del documento
  ls_obs := 'PAGO DE PLANILLA ' || asi_tipo_trab;
  
  update cntas_pagar_det cpd
     set cpd.descripcion = ls_obs,
         cpd.cantidad    = 1,
         cpd.importe     = ln_imp_soles,
         cpd.cencos      = ls_cencos_pgo_plla,
         cpd.cnta_prsp   = ls_cnta_prsp_pgo_plla
   where cpd.cod_relacion = ls_cod_relacion 
     and cpd.tipo_doc     = ls_doc_pago_plla     
     and cpd.nro_doc      = ls_nro_doc
     and cpd.item         = 1;
            
  if SQL%NOTFOUND then
     --inserta registro detalle
     Insert Into cntas_pagar_det(
             cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
             cencos       ,cnta_prsp )
     Values(
             ls_cod_relacion    ,ls_doc_pago_plla      ,ls_nro_doc,'1', ls_obs ,1,ln_imp_soles,
             ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla ) ;
  end if;

  -- Actualizo en la tabla calc_doc_pagar_plla
  select count(*)
    into ln_count
    from calc_doc_pagar_plla c
   where c.cod_relacion       = ls_cod_relacion
     and c.tipo_doc           = ls_doc_pago_plla
     and c.nro_doc            = ls_nro_doc;
            
  if ln_count = 0 then
     --registralo en documentos de pago de planilla
     Insert Into calc_doc_pagar_plla(
             cod_origen,tipo_trabajador ,fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado)
     Values(
             asi_origen,asi_tipo_trab,adi_fec_proceso,ls_cod_relacion,ls_doc_pago_plla,ls_nro_doc,'1');
  end if;

  update num_doc_tipo
     set ultimo_numero = ln_nro
   where (tipo_doc = ls_doc_pago_plla) ;

end USP_RH_ACT_GEN_PAGO_PLLA;
/
