create or replace procedure usp_rh_gen_doc_pago_quin(
       asi_tipo_trab    in maestro.tipo_trabajador%type ,
       asi_origen       in origen.cod_origen%Type       ,
       adi_fec_proceso  in date                         ,
       asi_cod_usr      in usuario.cod_usr%type         ,
       asi_empresa      in empresa.cod_empresa%TYPE
) is

  ln_imp_soles          calculo.imp_soles%TYPE            ;
  lc_nro_doc            cntas_pagar.nro_doc%type          ;
  lc_forma_pago         forma_pago.forma_pago%type        ;
  ln_tasa_cambio        calendario.cmp_dol_libre%type     ;
  lc_cencos_pgo_plla    centros_costo.cencos%type         ;
  lc_cnta_prsp_pgo_plla presupuesto_cuenta.cnta_prsp%Type ;
  ln_count              Number                            ;
  ln_nro                Number                            ;
  lc_obs                cntas_pagar.descripcion%type      ;
  ls_doc_quincena       rrhhparquin.doc_quincena%TYPE     ;

begin

  ln_imp_soles := 0.00 ;
  
  -- Parametros generales
  SELECT COUNT(*)
    INTO ln_count
    FROM rrhhparam t
   WHERE t.reckey = '1';
  
  IF ln_count = 0 THEN
     RAISE_APPLICATION_ERROR(-20000, 'No ha definido parametros en RRHHPARAM');
  END IF;
  
  SELECT t.cencos_pago_plla, t.cnta_prsp_pago_plla
    INTO lc_cencos_pgo_plla, lc_cnta_prsp_pgo_plla
    FROM rrhhparam t
   WHERE t.reckey = '1';
  
  IF lc_cencos_pgo_plla IS NULL THEN
     RAISE_APPLICATION_ERROR(-20000, 'No ha especificado Centro de Costos para Pago de Planilla');
  END IF;
  
  IF lc_cnta_prsp_pgo_plla IS NULL THEN
     RAISE_APPLICATION_ERROR(-20000, 'No ha especificado cuenta presupuestal para Pago de Planilla');
  END IF;
  
  --parametros de la quincena
  select Count(*) into ln_count
    from rrhhparquin rh
   where rh.reckey = '1' ;
  
  IF ln_count = 0 THEN
     RAISE_APPLICATION_ERROR(-20000, 'No existen parametros de quincena, por favor verifique');
  END IF;   
  
  select rh.doc_quincena
    into ls_doc_quincena
    from rrhhparquin rh
   where rh.reckey = '1' ;
  
  IF ls_doc_quincena IS NULL THEN
     RAISE_APPLICATION_ERROR(-20000, 'No ha especificado el documento de quincena en parametros de Quincena');
  END IF;
  
  select COUNT(*) INTO ln_count 
    from genparam 
    where reckey = '1' ;
  
  IF ln_count = 0 THEN
     RAISE_APPLICATION_ERROR(-2000, 'No ha especificado parametros en GENPARAM');
  END IF;
  
  select forma_pago_contado 
    into lc_forma_pago 
    from genparam 
    where reckey = '1' ;
  
  IF lc_forma_pago IS NULL THEN
     RAISE_APPLICATION_ERROR(-20000, 'No ha especificado la forma de pago, al contado, en GENPARAM');
  END IF;
    
  --recuperar tipo de cambio
  ln_tasa_cambio := usf_fin_tasa_cambio(trunc(adi_fec_proceso)) ;
  --

  Select NVL(Sum(Nvl(aq.imp_adelanto,0)),0)
    into ln_imp_soles 
    from adelanto_quincena aq,
         maestro m
   where aq.cod_trabajador     = m.cod_trabajador 
     AND m.cod_origen          = asi_origen        
     AND m.tipo_trabajador     = asi_tipo_trab    
     AND Trunc(aq.fec_proceso)  = Trunc(adi_fec_proceso);

  if ln_imp_soles = 0 then
     raise_application_error(-20000,'No Existe Monto a Pagar en Planilla') ;
  end if ;

  ---recupero numero
  select count(*)
    into ln_count
    from num_doc_tipo
    where tipo_doc = ls_doc_quincena;

  if ln_count = 0 then
     insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
     values(ls_doc_quincena, 1, 1);
  end if;

  select ultimo_numero
    into ln_nro
    from num_doc_tipo
   where tipo_doc = ls_doc_quincena for update;

  --CONSTRUIR NUMERO
  lc_nro_doc := asi_origen||lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;

  lc_obs := 'AQDELANTE DE QUINCENA DE '||asi_tipo_trab||'-'||asi_origen||'-'||TO_CHAR(adi_fec_proceso,'dd/mm/yyyy') ;

  --inserta registro cabecera
  Insert Into cntas_pagar(
         cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
         vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
         descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
  VALUES(
         asi_empresa       ,ls_doc_quincena   ,lc_nro_doc   ,'1'            ,trunc(SYSDATE) ,trunc(SYSDATE),
         adi_fec_proceso   ,lc_forma_pago , pkg_sigre_finanzas.is_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
         lc_obs,'D'        ,ln_imp_soles ,ln_imp_soles   ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;

  --inserta registro detalle
  Insert Into cntas_pagar_det(
         cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
         cencos       ,cnta_prsp )
  VALUES(
         asi_empresa        ,ls_doc_quincena, lc_nro_doc ,'1','ADELANTO DE QUINCENA' ,1,ln_imp_soles,
         lc_cencos_pgo_plla ,lc_cnta_prsp_pgo_plla ) ;

  --registralo en documentos de pago de planilla
  Insert Into calc_doc_pagar_plla(
         cod_origen,tipo_trabajador ,fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado)
  VALUES(
         asi_origen,asi_tipo_trab,adi_fec_proceso,asi_empresa,ls_doc_quincena, lc_nro_doc,'1');

  ln_nro := ln_nro + 1 ;

  update num_doc_tipo
     set ultimo_numero = ln_nro
   where (tipo_doc = ls_doc_quincena) ;

end usp_rh_gen_doc_pago_quin;
/
