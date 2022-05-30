create or replace package PKG_SIGRE_FINANZAS is

  -- Author  : JRAMIREZ
  -- Created : 05/09/2014 11:39:13 a.m.
  -- Purpose : Funciones Financieras y Tesorerira
  
  -- Public type declarations
  --type <TypeName> is <Datatype>;
  
  -- Public constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  is_doc_dtrp      finparam.doc_detrac_cp%TYPE;
  is_doc_dtrc      finparam.doc_detrac_cc%TYPE;
  
  --Documentos para la parte contable
  is_doc_ncp        doc_tipo.tipo_doc%TYPE := 'NCP';
  is_doc_ndp        doc_tipo.tipo_doc%TYPE := 'NDP';
  is_doc_ncc        doc_tipo.tipo_doc%TYPE := 'NCC';
  is_doc_ndc        doc_tipo.tipo_doc%TYPE := 'NDC';
  is_doc_bvc        finparam.doc_bol_cobrar%TYPE;
  is_doc_fac        finparam.doc_fact_cobrar%TYPE;
  is_doc_cnc        doc_tipo.tipo_doc%TYPE := 'CNC';
  
  in_nro_decimales  number;
  
  -- Matrices contables / Conceptos Financieros
  is_confin_vta_vd_sol   concepto_financiero.confin%TYPE;     -- Venta con vale de descuento en soles
  is_confin_vta_vd_dol   concepto_financiero.confin%TYPE;     -- Venta con vale de descuento en dolares

  function of_confin_vta_vd_sol(asi_nada varchar2) return varchar2;
  function of_confin_vta_vd_dol(asi_nada varchar2) return varchar2;
  
  -- Obtiene el saldo anterior por una fecha especifica pero en dolares
  function of_fin_caja_saldo_anterior(
           adi_fecha in date, 
           asi_origen in origen.cod_origen%TYPE
  ) return number;
  -- Obtiene el saldo anterior a una fecha especifica, pero se elige el tipo de moneda
  function of_fin_caja_saldo_anterior(
           adi_fecha  in date,
           asi_origen in origen.cod_origen%TYPE,
           asi_moneda in moneda.cod_moneda%TYPE
  ) return number;
  -- Obtiene el saldo anterior a una fecha especifica, pero se elige un periodo
  function of_fin_caja_saldo_anterior(
           ani_year   in number,
           ani_mes    in number,
           asi_origen in origen.cod_origen%TYPE,
           asi_moneda in moneda.cod_moneda%TYPE
  ) return number;
  
  
  -- Fecha del primer ingreso por favor
  function of_fecha_primer_ingreso(
           asi_proveedor in proveedor.proveedor%TYPE, 
           asi_tipo_doc in cntas_pagar.tipo_doc%TYPE, 
           asi_nro_doc in cntas_pagar.nro_doc%TYPE
  ) return date;
  
  -- Obtiene el IGV de la transferencia Gratuita, solo cuando el valor de la boleta es cero
  -- y no deba incluir descuentos ni anticipos
  function of_IGV_gratuito(
           asi_tipo_doc    in cntas_cobrar.tipo_doc%TYPE, 
           asi_nro_doc     in cntas_cobrar.tipo_doc%TYPE 
  ) return number;
  
  -- Procedimiento para actualizar saldo de cuentas por cobrar
  procedure of_actualiza_saldo_cc(asi_nada in varchar2);
  
  -- Procedimiento para actualizar saldo de cuentas por pagar
  procedure of_actualiza_saldo_cp(asi_nada in varchar2);

  -- Procedimiento para cambiar el periodo de una factura
  procedure sp_cambiar_periodo(asi_proveedor in proveedor.proveedor%TYPE, 
                               asi_tipo_doc  in cntas_pagar.tipo_doc%TYPE, 
                               asi_nro_doc   in cntas_pagar.nro_doc%TYPE,
                               ani_new_year  in number,
                               ani_new_mes   in number);
                               
	-- Procedimiento para cambiar el periodo de una factura de cntas_cobrar
  procedure sp_cambiar_periodo_vta(asi_proveedor in proveedor.proveedor%TYPE, 
                                   asi_tipo_doc  in cntas_cobrar.tipo_doc%TYPE, 
                                   asi_nro_doc   in cntas_cobrar.nro_doc%TYPE,
                                   ani_new_year  in number,
                                   ani_new_mes   in number);
                                                                  
  --procedimiento para cambiar el tipo y nro de documento de una cuenta por pagar
  procedure sp_change_nro_doc(
            asi_cod_rel        in cntas_pagar.cod_relacion%type ,
            asi_tipo_doc       in cntas_pagar.tipo_doc%type     ,
            asi_nro_doc        in cntas_pagar.nro_doc%type      ,
            asi_new_cod_rel    in cntas_pagar.cod_relacion%type ,
            asi_new_tipo_doc   in cntas_pagar.tipo_doc%Type     ,
            asi_new_nro_doc    in cntas_pagar.nro_doc%type);
  
end PKG_SIGRE_FINANZAS;
/
create or replace package body PKG_SIGRE_FINANZAS is

  -- Private type declarations
  --type <TypeName> is <Datatype>;
  
  -- Private constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Private variable declarations
  --<VariableName> <Datatype>;

  -- Function and procedure implementations
  function of_confin_vta_vd_sol(asi_nada varchar2) 
    return varchar2 is
  begin
    return PKG_SIGRE_FINANZAS.is_confin_vta_vd_sol;
  end ;
  
  function of_confin_vta_vd_dol(asi_nada varchar2) 
    return varchar2 is
  begin
    return PKG_SIGRE_FINANZAS.is_confin_vta_vd_dol;
  end ;

  function of_fin_caja_saldo_anterior(
           adi_fecha date,
           asi_origen origen.cod_origen%TYPE
  ) return number is
  
    ln_return       number;
    ln_tasa_cambio  calendario.vta_dol_prom%TYPE;
    
  begin
   select	nvl(
            sum(
                case 
                  when vw.cod_moneda = pkg_logistica.of_soles(null) then
                    vw.imp_neto / ln_tasa_cambio
                  else
                    vw.imp_neto
                end
               ), 0
            ) as importe
     into ln_return
     from vw_fin_flujo_caja vw
    where trunc(vw.fecha_emision) < trunc(adi_fecha)
      and vw.origen          like asi_origen;

    return ln_return;
  end;

  function of_fin_caja_saldo_anterior(
           adi_fecha  in date,
           asi_origen in origen.cod_origen%TYPE,
           asi_moneda in moneda.cod_moneda%TYPE
  ) return number is
  
    ln_return       number;
    
  begin
   select	nvl(
            sum(
                case 
                  when asi_moneda = pkg_logistica.of_soles(null) then
                    vw.ingresos_sol + vw.egresos_sol
                  else
                    vw.ingresos_dol + vw.egresos_dol
                end
               ), 0
            ) as importe
     into ln_return
     from vw_fin_flujo_caja vw
    where trunc(vw.fecha_emision) < trunc(adi_fecha)
      and vw.origen          like asi_origen;

    return ln_return;
  end;

  function of_fin_caja_saldo_anterior(
           ani_year   in number,
           ani_mes    in number,
           asi_origen in origen.cod_origen%TYPE,
           asi_moneda in moneda.cod_moneda%TYPE
  ) return number is
  
    ln_return       number;
    
  begin
   select	nvl(
            sum(
                case 
                  when asi_moneda = pkg_logistica.of_soles(null) then
                    vw.ingresos_sol + vw.egresos_sol
                  else
                    vw.ingresos_dol + vw.egresos_dol
                end
               ), 0
            ) as importe
     into ln_return
     from vw_fin_flujo_caja vw
    where vw.periodo < trim(to_char(ani_year, '0000')) || trim(to_char(ani_mes, '00'))
      and vw.origen          like asi_origen;

    return ln_return;
  end;

  function of_fecha_primer_ingreso(
          asi_proveedor in proveedor.proveedor%TYPE, 
          asi_tipo_doc  in cntas_pagar.tipo_doc%TYPE, 
          asi_nro_doc   in cntas_pagar.nro_doc%TYPE
  ) return date is
    
    ld_fecha date;
    ln_count number;
    
  begin
    
    select count(*)
      into ln_count
      from vale_mov        vm,
           articulo_mov    am,
           cntas_pagar_det cpd
     where vm.nro_vale = am.nro_vale
       and cpd.org_am         = am.cod_origen
       and cpd.nro_am         = am.nro_mov
       and vm.flag_estado     <> '0'
       and am.flag_estado     <> '0'
       and cpd.cod_relacion   = asi_proveedor
       and cpd.tipo_doc       = asi_tipo_doc
       and cpd.nro_doc        = asi_nro_doc;
    
    if ln_count > 0 then
       -- Si es una cuenta por pagar, busco la primera fecha de ingreso
       select min(vm.fec_registro)
         into ld_fecha
         from vale_mov        vm,
              articulo_mov    am,
              cntas_pagar_det cpd
        where vm.nro_vale = am.nro_vale
          and cpd.org_am         = am.cod_origen
          and cpd.nro_am         = am.nro_mov
          and vm.flag_estado     <> '0'
          and am.flag_estado     <> '0'
          and cpd.cod_relacion   = asi_proveedor
          and cpd.tipo_doc       = asi_tipo_doc
          and cpd.nro_doc        = asi_nro_doc;
    else
       select count(*)
         into ln_count
        from cntas_cobrar     cc,
             cntas_cobrar_det ccd,
             articulo_mov     am,
             vale_mov         vm
        where cc.tipo_doc     = ccd.tipo_doc
          and cc.nro_doc      = ccd.nro_doc
          and ccd.org_amp_ref = am.origen_mov_proy
          and ccd.nro_amp_ref = am.nro_mov_proy
          and am.nro_vale     = vm.nro_Vale
          and am.flag_estado  <> '0'
          and vm.flag_estado  <> '0'
          and cc.tipo_doc     = asi_tipo_doc
          and cc.nro_doc      = asi_nro_doc;
       
       if ln_count > 0 then
          select max(vm.fec_registro)
            into ld_fecha
           from cntas_cobrar     cc,
                cntas_cobrar_det ccd,
                articulo_mov     am,
                vale_mov         vm
           where cc.tipo_doc     = ccd.tipo_doc
             and cc.nro_doc      = ccd.nro_doc
             and ccd.org_amp_ref = am.origen_mov_proy
             and ccd.nro_amp_ref = am.nro_mov_proy
             and am.nro_vale     = vm.nro_Vale
             and am.flag_estado  <> '0'
             and vm.flag_estado  <> '0'
             and cc.tipo_doc     = asi_tipo_doc
             and cc.nro_doc      = asi_nro_doc;
       else
          ld_fecha := null;
       end if;
    end if;
    
    return ld_fecha;
  
  end;
  
  -- Obtiene el IGV de la transferencia Gratuita, solo cuando el valor de la boleta es cero
  -- y no deba incluir descuentos ni anticipos
  function of_IGV_gratuito(
           asi_tipo_doc    in cntas_cobrar.tipo_doc%TYPE, 
           asi_nro_doc     in cntas_cobrar.tipo_doc%TYPE 
  ) return number is
  
    ln_return       number;
    
  begin
   select	nvl(sum(ccd.cantidad * ccd.precio_unitario), 0) 
     into ln_return
     from cntas_cobrar_det ccd
    where ccd.tipo_doc     = asi_tipo_doc
      and ccd.nro_doc      = asi_nro_doc;
   
   -- Si tiene importe entonces no es una transferencia gratuita
   if ln_return > 0 then return 0; end if;
   
   -- De lo contrario cojo el IGV de lo que sea como transferencia gratuita
   select nvl(sum(ci.importe) , 0) * -1
     into ln_return
     from cntas_cobrar_det ccd,
          cc_doc_det_imp   ci
    where ccd.tipo_doc     = ci.tipo_doc
      and ccd.nro_doc      = ci.nro_doc
      and ccd.item         = ci.item
      and ccd.tipo_doc     = asi_tipo_doc
      and ccd.nro_doc      = asi_nro_doc
      and ccd.tipo_cred_fiscal = '09'    -- Venta nacional gravada
      and ccd.descripcion  like '%GRATUITA%';
      
   return ln_return;
  end;


  procedure sp_cambiar_periodo(asi_proveedor in proveedor.proveedor%TYPE, 
                               asi_tipo_doc  in cntas_pagar.tipo_doc%TYPE, 
                               asi_nro_doc   in cntas_pagar.nro_doc%TYPE,
                               ani_new_year  in number,
                               ani_new_mes   in number) is
                               
    ln_new_asiento cntbl_libro_mes.nro_asiento%TYPE;
    ln_old_asiento cntbl_asiento.nro_asiento%TYPE;
    ln_nro_libro   cntbl_libro_mes.nro_libro%TYPE;
    ls_origen      cntbl_libro_mes.origen%TYPE;
    ln_year        cntbl_libro_mes.ano%TYPE;
    ln_mes         cntbl_libro_mes.mes%TYPE;
    ln_count       number;
                
  begin
    select count(*)
      into ln_count
      from cntas_pagar cp
     where cp.cod_relacion = asi_proveedor
       and cp.tipo_doc     = asi_tipo_doc
       and cp.nro_doc      = asi_nro_doc;
    
    if ln_count = 0 then
       RAISE_APPLICATION_ERROR(-20000, 'El comprobante por pagar ' || asi_proveedor || ' ' || asi_tipo_doc || ' ' || asi_nro_doc 
                                    || ', no existe en cntas_pagar, por favor verifique!');
    end if; 
    
    -- Obtengo los datos actuales
    select cp.origen, cp.ano, cp.mes, cp.nro_libro, cp.nro_asiento
      into ls_origen, ln_year, ln_mes, ln_nro_libro, ln_old_asiento
      from cntas_pagar cp
     where cp.cod_relacion = asi_proveedor
       and cp.tipo_doc     = asi_tipo_doc
       and cp.nro_doc      = asi_nro_doc;
    
    if ln_nro_libro is null or ln_year is null or ln_mes is null then
      return;
    end if;
    
    select count(*)
      into ln_count
      from cntbl_libro_mes c
     where c.origen    = ls_origen
       and c.ano       = ani_new_year
       and c.mes       = ani_new_mes
       and c.nro_libro = ln_nro_libro;
    
    if ln_count = 0 then
       insert into cntbl_libro_mes(
              origen, ano, mes, nro_libro, nro_asiento)
       values(
              ls_origen, ani_new_year, ani_new_mes, ln_nro_libro, 1);
    end if;
    
    select c.nro_asiento
      into ln_new_asiento
      from cntbl_libro_mes c
     where c.origen    = ls_origen
       and c.ano       = ani_new_year
       and c.mes       = ani_new_mes
       and c.nro_libro = ln_nro_libro for update;
     
    
    -- Creo un duplicado de la cabecera del asiento
    insert into cntbl_asiento(
           origen, ano, mes, nro_libro, nro_asiento, cod_moneda, tasa_cambio, tipo_nota, nro_proceso, desc_glosa, 
           fecha_cntbl, fec_registro, cod_usr, flag_estado, flag_tabla, tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab, 
           flag_replicacion, flag_asnt_transf)
    select ca.origen, ani_new_year, ani_new_mes, ca.nro_libro, ln_new_asiento, ca.cod_moneda, ca.tasa_cambio, ca.tipo_nota, ca.nro_proceso, ca.desc_glosa, 
           ca.fecha_cntbl, sysdate, ca.cod_usr, ca.flag_estado, ca.flag_tabla, ca.tot_soldeb, ca.tot_solhab, ca.tot_doldeb, ca.tot_dolhab, 
           '1', ca.flag_asnt_transf
      from cntbl_asiento ca
     where ca.origen      = ls_origen
       and ca.ano         = ln_year
       and ca.mes         = ln_mes
       and ca.nro_libro   = ln_nro_libro
       and ca.nro_asiento = ln_old_asiento;
    
    -- Cambio el detalle del asiento para que apunte a la nueva cabecera
    update cntbl_asiento_det cad
       set cad.ano          = ani_new_year,
           cad.mes          = ani_new_mes,
           cad.nro_asiento  = ln_new_asiento
     where cad.origen      = ls_origen
       and cad.ano         = ln_year
       and cad.mes         = ln_mes
       and cad.nro_libro   = ln_nro_libro
       and cad.nro_asiento = ln_old_asiento;
    
    -- cambio en la cabecera de la cartera de pagos
    update cntas_pagar cp
       set cp.ano          = ani_new_year,
           cp.mes          = ani_new_mes,
           cp.nro_asiento  = ln_new_asiento
     where cp.origen      = ls_origen
       and cp.ano         = ln_year
       and cp.mes         = ln_mes
       and cp.nro_libro   = ln_nro_libro
       and cp.nro_asiento = ln_old_asiento;
    
    -- Elimino la cabecera del asiento que ya no la necesito
    delete cntbl_Asiento ca
     where ca.origen      = ls_origen
       and ca.ano         = ln_year
       and ca.mes         = ln_mes
       and ca.nro_libro   = ln_nro_libro
       and ca.nro_asiento = ln_old_asiento;
    

    -- Actualizo el numerador del asiento
    update cntbl_libro_mes c
       set c.nro_asiento = ln_new_asiento + 1
     where c.origen    = ls_origen
       and c.ano       = ani_new_year
       and c.mes       = ani_new_mes
       and c.nro_libro = ln_nro_libro;
    
    -- Actualizo los cambios
    commit;
    
  end sp_cambiar_periodo;  

  procedure sp_cambiar_periodo_vta(asi_proveedor in proveedor.proveedor%TYPE, 
                                   asi_tipo_doc  in cntas_cobrar.tipo_doc%TYPE, 
                                   asi_nro_doc   in cntas_cobrar.nro_doc%TYPE,
                                   ani_new_year  in number,
                                   ani_new_mes   in number) is
                               
    ln_new_asiento cntbl_libro_mes.nro_asiento%TYPE;
    ln_old_asiento cntbl_asiento.nro_asiento%TYPE;
    ln_nro_libro   cntbl_libro_mes.nro_libro%TYPE;
    ls_origen      cntbl_libro_mes.origen%TYPE;
    ln_year        cntbl_libro_mes.ano%TYPE;
    ln_mes         cntbl_libro_mes.mes%TYPE;
    ls_nro_reg     cntas_cobrar.nro_registro%TYPE;
    ln_count       number;
                
  begin
    select count(*)
      into ln_count
      from cntas_cobrar cc
     where cc.tipo_doc     = asi_tipo_doc
       and cc.nro_doc      = asi_nro_doc;
    
    if ln_count = 0 then
       RAISE_APPLICATION_ERROR(-20000, 'El comprobante por cobrar ' || asi_tipo_doc || ' ' || asi_nro_doc 
                                    || ', no existe en cntas_cobrar, por favor verifique!');
    end if; 
    
    -- Obtengo los datos actuales
    select cc.origen, cc.ano, cc.mes, cc.nro_libro, cc.nro_asiento, cc.nro_registro
      into ls_origen, ln_year, ln_mes, ln_nro_libro, ln_old_asiento, ls_nro_reg
      from cntas_cobrar cc
     where cc.tipo_doc     = asi_tipo_doc
       and cc.nro_doc      = asi_nro_doc;
    
    if ln_nro_libro is null or ln_year is null or ln_mes is null then
      return;
    end if;
    
    select count(*)
      into ln_count
      from cntbl_libro_mes c
     where c.origen    = ls_origen
       and c.ano       = ani_new_year
       and c.mes       = ani_new_mes
       and c.nro_libro = ln_nro_libro;
    
    if ln_count = 0 then
       insert into cntbl_libro_mes(
              origen, ano, mes, nro_libro, nro_asiento)
       values(
              ls_origen, ani_new_year, ani_new_mes, ln_nro_libro, 1);
    end if;
    
    select c.nro_asiento
      into ln_new_asiento
      from cntbl_libro_mes c
     where c.origen    = ls_origen
       and c.ano       = ani_new_year
       and c.mes       = ani_new_mes
       and c.nro_libro = ln_nro_libro for update;
     
    
    -- Creo un duplicado de la cabecera del asiento
    insert into cntbl_asiento(
           origen, ano, mes, nro_libro, nro_asiento, cod_moneda, tasa_cambio, tipo_nota, nro_proceso, desc_glosa, 
           fecha_cntbl, fec_registro, cod_usr, flag_estado, flag_tabla, tot_soldeb, tot_solhab, tot_doldeb, tot_dolhab, 
           flag_replicacion, flag_asnt_transf)
    select ca.origen, ani_new_year, ani_new_mes, ca.nro_libro, ln_new_asiento, ca.cod_moneda, ca.tasa_cambio, ca.tipo_nota, ca.nro_proceso, ca.desc_glosa, 
           ca.fecha_cntbl, sysdate, ca.cod_usr, ca.flag_estado, ca.flag_tabla, ca.tot_soldeb, ca.tot_solhab, ca.tot_doldeb, ca.tot_dolhab, 
           '1', ca.flag_asnt_transf
      from cntbl_asiento ca
     where ca.origen      = ls_origen
       and ca.ano         = ln_year
       and ca.mes         = ln_mes
       and ca.nro_libro   = ln_nro_libro
       and ca.nro_asiento = ln_old_asiento;
    
    -- Cambio el detalle del asiento para que apunte a la nueva cabecera
    update cntbl_asiento_det cad
       set cad.ano          = ani_new_year,
           cad.mes          = ani_new_mes,
           cad.nro_asiento  = ln_new_asiento
     where cad.origen      = ls_origen
       and cad.ano         = ln_year
       and cad.mes         = ln_mes
       and cad.nro_libro   = ln_nro_libro
       and cad.nro_asiento = ln_old_asiento;
    
    -- cambio en la cabecera de la cartera de pagos
    update cntas_cobrar cc
       set cc.ano          = ani_new_year,
           cc.mes          = ani_new_mes,
           cc.nro_asiento  = ln_new_asiento
     where cc.origen      = ls_origen
       and cc.ano         = ln_year
       and cc.mes         = ln_mes
       and cc.nro_libro   = ln_nro_libro
       and cc.nro_asiento = ln_old_asiento;

    -- cambio en la cabecera de la facturacion simplicada
    update fs_factura_simpl f
       set f.ano          = ani_new_year,
           f.mes          = ani_new_mes,
           f.nro_asiento  = ln_new_asiento
     where f.cod_origen   = ls_origen
       and f.ano         = ln_year
       and f.mes         = ln_mes
       and f.nro_libro   = ln_nro_libro
       and f.nro_asiento = ln_old_asiento;
           
    -- Elimino la cabecera del asiento que ya no la necesito
    delete cntbl_Asiento ca
     where ca.origen      = ls_origen
       and ca.ano         = ln_year
       and ca.mes         = ln_mes
       and ca.nro_libro   = ln_nro_libro
       and ca.nro_asiento = ln_old_asiento;
    

    -- Actualizo el numerador del asiento
    update cntbl_libro_mes c
       set c.nro_asiento = ln_new_asiento + 1
     where c.origen    = ls_origen
       and c.ano       = ani_new_year
       and c.mes       = ani_new_mes
       and c.nro_libro = ln_nro_libro;
    
    -- Actualizo los cambios
    commit;
    
  end sp_cambiar_periodo_vta;  

  procedure of_actualiza_saldo_cc(
       asi_nada in varchar2
  ) is

    cursor c_datos_dtrc is
      select cc.tipo_doc, cc.nro_doc, cc.flag_estado, cc.importe_doc, cc.saldo_sol, cc.saldo_dol
        from cntas_cobrar cc
       where cc.tipo_doc = 'DTRC'
         and cc.flag_estado <> '0';

    cursor c_datos is
      select cc.cod_relacion, cc.tipo_doc, cc.nro_doc, cc.tasa_cambio, cc.importe_doc, cc.cod_moneda,
             cc.flag_control_reg, cc.flag_provisionado,
             cc.fecha_documento as fec_emision,
             cc.fecha_vencimiento,
             'CC' as referencia,
             cc.flag_estado
        from cntas_cobrar cc
       where ((cc.flag_provisionado = 'D' and cc.flag_control_reg in ('0', '1')) 
           or (cc.flag_provisionado = 'R'))
         --and cc.nro_doc = '004-000185'
    order by referencia, tipo_doc, nro_doc;

    cursor c_caja_bancos_det (as_tipo_doc  cntas_cobrar.tipo_doc%TYPE,
                              as_nro_doc   cntas_cobrar.nro_doc%TYPE) is
      select cb.fecha_emision, cb.nro_registro, cbd.cod_moneda, cb.flag_tiptran, cb.tasa_cambio,
             cbd.importe
      from caja_bancos_det cbd,
           caja_bancos     cb
      where cb.origen    = cbd.origen
        and cb.nro_registro  = cbd.nro_registro
        and cbd.tipo_doc     = as_tipo_doc
        and cbd.nro_doc      = as_nro_doc
        and cb.flag_estado   <> '0'
        and ((cb.flag_tiptran = '3'         and cbd.factor = 1)
          or (cb.flag_tiptran in ('2', '4') and cbd.factor = -1)
          or (cbd.tipo_doc = 'NCC'          and ((cbd.factor = 1  and cb.flag_tiptran = '2') 
                                              or (cbd.factor = -1 and cb.flag_tiptran = '3')
                                              or (cbd.factor = 1 and cb.flag_tiptran = '4'))));

    cursor c_canje_documentos(as_tipo_doc  cntas_cobrar.tipo_doc%TYPE,
                              as_nro_doc   cntas_cobrar.nro_doc%TYPE) is
      select cc.cod_moneda, dr.importe, cc.tasa_cambio
      from cntas_cobrar cc,
           doc_referencias dr
      where cc.tipo_doc      = dr.tipo_ref
        and cc.nro_doc       = dr.nro_ref
        and dr.tipo_ref      = as_tipo_doc
        and dr.nro_ref       = as_nro_doc
        and cc.flag_estado   <> '0'
        and dr.tipo_mov      = 'C'
        and dr.tipo_doc      in ('LTC', 'NCNC');


    ln_saldo_sol            cntas_cobrar.saldo_sol%TYPE;
    ln_saldo_dol            cntas_cobrar.saldo_dol%TYPE;
    ln_imp_sol              cntas_cobrar.saldo_sol%TYPE;
    ln_imp_dol              cntas_cobrar.saldo_dol%TYPE;
    ls_flag_estado          cntas_cobrar.flag_estado%TYPE;
    ln_count                number;
    ln_importe_doc          cntas_cobrar.importe_doc%TYPE;
    ln_tasa_cambio          cntas_cobrar.tasa_cambio%TYPE;
    ls_moneda               cntas_cobrar.cod_moneda%TYPE;
    ln_imp_detraccion       cntas_cobrar.imp_detraccion%TYPE;
    ls_flag_detraccion      cntas_cobrar.flag_detraccion%TYPE;
    ln_porc_detraccion      cntas_cobrar.porc_detraccion%TYPE;
    ln_temp_sol             cntas_cobrar.saldo_sol%TYPE;
    ln_temp_dol             cntas_cobrar.saldo_dol%TYPE;
    ls_cnta_cntbl           doc_pendientes_cta_cte.cnta_ctbl%TYPE;
    ls_flag_debhab          cntbl_asiento_det.flag_debhab%TYPE;
    
  begin
    
    -- Borro lo que no esta doc_pendientes_Cnta_cnta
    delete doc_pendientes_cta_cte d
     where d.sldo_sol = 0
       and d.saldo_dol = 0;
   
    --Recorro el cursor de datos con la detracción
    for lc_reg in c_datos_dtrc loop
        select count(*)
          into ln_count
          from cntas_cobrar cc
         where cc.nro_detraccion = lc_reg.nro_doc;
        
        if ln_count = 0 then
           -- Si no existe entoces lo anulo
           update cntas_cobrar_det ccd
              set ccd.precio_unitario = 0
            where ccd.tipo_doc   = lc_reg.tipo_doc
              and ccd.nro_doc    = lc_reg.nro_doc;
              
           update cntas_cobrar cc
              set cc.importe_doc = 0, 
                  cc.saldo_sol   = 0,
                  cc.saldo_dol   = 0,
                  cc.flag_estado = '0'
            where cc.tipo_doc  = lc_reg.tipo_doc
              and cc.nro_doc   = lc_reg.nro_doc;
        end if;
        
        if ln_count > 0 then
            -- Verifico el estado del comprobante original y de ser activo calculo el importe de detraccion
            select cc.flag_estado, cc.tasa_cambio, cc.cod_moneda,
                   cc.flag_detraccion, cc.porc_detraccion,
                   ((select nvl(sum(ccd.cantidad * ccd.precio_unitario), 0)
                       from cntas_cobrar_det ccd
                      where ccd.tipo_doc = cc.tipo_doc
                        and ccd.nro_doc  = cc.nro_doc) +
                    (select nvl(sum(ci.importe), 0)
                       from cc_doc_det_imp ci
                      where ci.tipo_doc = cc.tipo_doc
                        and ci.nro_doc  = cc.nro_doc))
              into ls_flag_estado, ln_tasa_cambio, ls_moneda,
                   ls_flag_detraccion, ln_porc_detraccion,
                   ln_importe_doc
              from cntas_cobrar cc
             where cc.nro_detraccion = lc_reg.nro_doc;
           
            if ls_flag_estado = '0' or ls_flag_detraccion = '0' then
               -- Si no existe entoces lo anulo
               update cntas_cobrar_det ccd
                  set ccd.precio_unitario = 0
                where ccd.tipo_doc   = lc_reg.tipo_doc
                  and ccd.nro_doc    = lc_reg.nro_doc;
                  
               update cntas_cobrar cc
                  set cc.importe_doc = 0, 
                      cc.saldo_sol   = 0,
                      cc.saldo_dol   = 0,
                      cc.flag_estado = '0'
                where cc.tipo_doc  = lc_reg.tipo_doc
                  and cc.nro_doc   = lc_reg.nro_doc;
            end if;
            
            -- Calculo el importe de la detraccion
            if ls_moneda = PKG_LOGISTICA.of_dolares(null) then
               ln_imp_sol := ln_importe_doc * ln_tasa_cambio;
            else
               ln_imp_sol := ln_importe_doc;
            end if;
            
            ln_imp_detraccion := round(ln_imp_sol * ln_porc_detraccion / 100, in_nro_decimales);
            
            -- Calculo la diferencia
            if ls_moneda = PKG_LOGISTICA.of_soles(null) then
               ln_importe_doc := ln_importe_doc - ln_imp_detraccion;
               ln_saldo_sol   := ln_importe_doc;
               ln_saldo_dol   := ln_importe_doc / ln_tasa_cambio ;
            else
               ln_importe_doc := ln_importe_doc - ln_imp_detraccion / ln_tasa_cambio;
               ln_saldo_dol   := ln_importe_doc;
               ln_saldo_sol   := ln_importe_doc * ln_tasa_cambio ;
            end if;
            
            -- Actualizo el importe del documento
            update cntas_cobrar cc
               set cc.importe_doc = ln_importe_doc,
                   cc.saldo_sol   = ln_saldo_sol,
                   cc.saldo_dol   = ln_saldo_dol,
                   cc.flag_estado = '1'
             where cc.Nro_Detraccion = lc_reg.nro_doc;
            
            -- Actualizo el importe de la detraccion
            ln_saldo_sol := ln_imp_detraccion;
            ln_saldo_dol := ln_saldo_sol / ln_tasa_cambio;
            
            -- Actualizo el documetno de detracción
            update cntas_cobrar_det ccd
               set ccd.precio_unitario = ln_imp_detraccion
             where ccd.tipo_doc        = lc_reg.tipo_doc
               and ccd.nro_doc         = lc_Reg.nro_doc;
               
            update cntas_cobrar cc
               set cc.importe_doc   = ln_imp_detraccion,
                   cc.saldo_sol     = ln_saldo_sol,
                   cc.saldo_dol     = ln_saldo_dol,
                   cc.flag_estado   = '1',
                   cc.flag_provisionado = 'D',
                   cc.flag_control_reg  = '0'
             where cc.tipo_doc      = lc_Reg.Tipo_Doc
               and cc.nro_doc       = lc_reg.nro_doc;
        end if;        
    end loop;
    
    for lc_reg in c_datos loop
        if lc_reg.flag_estado in ('0', '4') then

           -- Si el documento esta anulado simplemente lo elimino de la tabla de cuenta corriente
           delete doc_pendientes_cta_cte t
           where t.tipo_doc     = lc_Reg.Tipo_Doc
             and t.nro_doc      = lc_reg.nro_doc;

        elsif lc_reg.flag_provisionado = 'R' or (lc_reg.flag_provisionado = 'D' and lc_reg.flag_control_reg = '0') then
          
          -- si el documento esta activo verifico el saldo del artículo
          if lc_reg.cod_moneda = pkg_logistica.is_soles then
             ln_saldo_sol := lc_reg.importe_doc;
             ln_saldo_dol := lc_reg.importe_doc / lc_reg.tasa_cambio;
          else
             ln_saldo_sol := lc_reg.importe_doc * lc_reg.tasa_cambio;
             ln_saldo_dol := lc_reg.importe_doc;
          end if;

          -- Detalle en Cartera de Cobros
          for lc_caja in c_caja_bancos_det(lc_reg.tipo_doc, lc_reg.nro_doc) loop
              if lc_caja.cod_moneda = pkg_logistica.is_soles then
                 ln_imp_sol := lc_caja.importe;
                 ln_imp_dol := lc_caja.importe / lc_caja.tasa_cambio;
              else
                 ln_imp_sol := lc_caja.importe * lc_caja.tasa_cambio;
                 ln_imp_dol := lc_caja.importe;
              end if;

              ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
              ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
          end loop;

          if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
          if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;

          -- detalle en Canje de Documentos
          if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
             for lc_reg2 in c_canje_documentos(lc_reg.tipo_doc, lc_reg.nro_doc) loop
                 if lc_reg2.cod_moneda = pkg_logistica.is_soles then
                    ln_imp_sol := lc_reg2.importe;
                    ln_imp_dol := lc_reg2.importe / lc_reg2.tasa_cambio;
                 else
                    ln_imp_sol := lc_reg2.importe * lc_reg2.tasa_cambio;
                    ln_imp_dol := lc_reg2.importe;
                 end if;

                 ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
                 ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
             end loop;

             if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
             if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
          end if;

          -- Detalle en Cuenta Corriente
          if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
             select NVL(sum(usf_fl_conv_mon(ccd.imp_dscto, cc.mont_original, pkg_logistica.is_soles, ccd.fec_dscto)), 0),
                    NVL(sum(usf_fl_conv_mon(ccd.imp_dscto, cc.mont_original, pkg_logistica.is_dolares, ccd.fec_dscto)), 0)
               into ln_imp_sol, ln_imp_dol
               from cnta_crrte_detalle ccd,
                    cnta_crrte         cc
              where cc.cod_trabajador  = ccd.cod_trabajador
                and cc.tipo_doc        = ccd.tipo_doc
                and cc.nro_doc         = ccd.nro_doc
                and cc.cod_trabajador  = lc_reg.cod_relacion
                and cc.tipo_doc        = lc_reg.tipo_doc
                and cc.nro_doc         = lc_reg.nro_doc;
             
             ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
             ln_saldo_dol := ln_saldo_dol - ln_imp_dol;

             if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
             if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
          end if;          

          -- Actualizo los datos en cntas_cobrar
          -- Si es un gasto directo entonces simplemente actualizo el flag de estado según el saldo
          if lc_reg.cod_moneda = pkg_logistica.is_soles then
            
             if ln_saldo_sol <= 0 then --pagado totalmente
                ls_flag_estado := '3' ;
             elsif lc_reg.importe_doc = ln_saldo_sol then --generado
                ls_flag_estado := '1';
             elsif ln_saldo_sol > 0 then    --pagado parcialmente
                ls_flag_estado := '2';
             end if ;
             
          elsif lc_reg.cod_moneda = pkg_logistica.is_dolares then
            
             if ln_saldo_dol <= 0 then --pagado totalmente
                ls_flag_estado := '3' ;
             elsif lc_reg.importe_doc = ln_saldo_dol then --generado
                ls_flag_estado := '1';
             elsif ln_saldo_dol > 0 then    --pagado parcialmente
                ls_flag_estado := '2';
             end if ;
             
          end if;

          -- Actualizo las cuentas por cobrar
          UPDATE cntas_cobrar
             SET flag_estado = ls_flag_estado ,
                 saldo_sol   = ln_saldo_sol,
                 saldo_dol   = ln_saldo_dol
           WHERE tipo_doc     = lc_reg.tipo_doc
             AND nro_doc      = lc_reg.nro_doc;
          
          -- Actualizo el saldo en soles y dolares
          if (lc_reg.cod_moneda = pkg_logistica.is_soles   and ln_saldo_sol <= 0) or 
             (lc_reg.cod_moneda = pkg_logistica.is_dolares and ln_saldo_dol <= 0) then
                
             delete doc_pendientes_cta_cte d
              where d.tipo_doc     = lc_reg.tipo_doc
                and d.nro_doc      = lc_reg.nro_doc;
          else
             
             select count(*)
               into ln_count
               from doc_pendientes_cta_cte t
              WHERE t.tipo_doc     = lc_reg.tipo_doc
                AND t.nro_doc      = lc_reg.nro_doc;
             
             if ln_count > 1 then
                delete doc_pendientes_cta_cte t
                 WHERE t.tipo_doc     = lc_reg.tipo_doc
                   AND t.nro_doc      = lc_reg.nro_doc;
             end if;
             
             -- Indico el flag adecuado
             if lc_reg.tipo_doc = 'NCC' then
                ls_flag_debhab := 'H';
             else
                ls_flag_debhab := 'D';
             end if;
             
             -- Busco la cuenta contable para la cuenta contable
             select count(distinct cad.cnta_ctbl)
               into ln_count
               from cntas_cobrar cc,
                    cntbl_asiento_det cad
              where cc.origen = cad.origen
                and cc.ano    = cad.ano
                and cc.mes    = cad.mes
                and cc.nro_libro = cad.nro_libro
                and cc.nro_asiento = cad.nro_asiento
                and cad.cod_relacion = lc_reg.cod_relacion
                and cad.tipo_docref1 = lc_reg.tipo_doc
                and cad.nro_docref1  = lc_reg.nro_doc
                and cad.flag_debhab  = ls_flag_debhab;
             
             if ln_count = 1 then
                select distinct cad.cnta_ctbl
                  into ls_cnta_cntbl
                  from cntas_cobrar cc,
                       cntbl_asiento_det cad
                 where cc.origen = cad.origen
                   and cc.ano    = cad.ano
                   and cc.mes    = cad.mes
                   and cc.nro_libro = cad.nro_libro
                   and cc.nro_asiento = cad.nro_asiento
                   and cad.cod_relacion = lc_reg.cod_relacion
                   and cad.tipo_docref1 = lc_reg.tipo_doc
                   and cad.nro_docref1  = lc_reg.nro_doc
                   and cad.flag_debhab  = ls_flag_debhab;
                   
             elsif ln_count > 1 then
                RAISE_APPLICATION_ERROR(-20000, 'El documento ' || trim(lc_reg.tipo_doc) || ' / ' 
                                             || lc_reg.nro_doc 
                                             || ' tiene mas de una cuenta contable en el DEBE / HABER en el asiento de provision.');
             else
                ls_cnta_cntbl := null;
             end if;  
             
             -- Actualizo el monto del documento pendiente
             update doc_pendientes_cta_cte t
                set t.sldo_sol     = ln_saldo_sol,
                    t.saldo_dol    = ln_saldo_dol,
                    t.cod_relacion = lc_reg.cod_relacion,
                    t.flag_debhab  = ls_flag_debhab,
                    t.cnta_ctbl    = ls_cnta_cntbl
              WHERE tipo_doc     = lc_reg.tipo_doc
                AND nro_doc      = lc_reg.nro_doc;
              
             if SQL%NOTFOUND then
                insert into doc_pendientes_cta_cte(
                       cod_relacion, tipo_doc, nro_doc, flag_tabla, cnta_ctbl, cod_moneda, flag_debhab, 
                       sldo_sol, saldo_dol, fecha_doc, factor, flag_replicacion, fecha_vencimiento)
                values(
                       lc_reg.cod_relacion, lc_reg.tipo_doc, lc_reg.nro_doc, '1', ls_cnta_cntbl, lc_reg.cod_moneda, ls_flag_debhab,
                       ln_saldo_sol, ln_saldo_dol, lc_reg.fec_emision, 1, '1', lc_reg.fecha_vencimiento);
             end if;
            
          end if;

        else
          -- Para documentos que son Cuentas por Cobrar Directo tipo cuenta corriente  
          
          -- Verifico si lo han cobrado
          select nvl(sum(case 
                           when cbd.cod_moneda = PKG_LOGISTICA.of_soles(null) then 
                             cbd.importe 
                           else 
                             cbd.importe * cb.tasa_cambio 
                         end), 0),
                 nvl(sum(case 
                           when cbd.cod_moneda = PKG_LOGISTICA.of_dolares(null) then 
                             cbd.importe 
                           else 
                             cbd.importe / cb.tasa_cambio 
                         end), 0)
            into ln_temp_sol,
                 ln_temp_dol
            from caja_bancos cb,
                 caja_bancos_det cbd
           where cb.origen = cbd.origen
             and cb.nro_registro = cbd.nro_registro
             and cbd.cod_relacion = lc_reg.cod_relacion
             and cbd.tipo_doc     = lc_reg.tipo_doc
             and cbd.nro_doc      = lc_reg.nro_doc
             and cb.flag_estado   <> '0'
             and ((cb.flag_tiptran = '3' and cbd.factor = 1) 
               or (cb.flag_tiptran in ('2', '4') and cbd.factor = -1));
          
          ln_Saldo_sol := ln_temp_sol;
          ln_saldo_dol := ln_temp_dol;
          
          -- No lo han pagado por lo tanto los saldos originales son los que determina el documento
          if ln_Saldo_sol = 0 and ln_saldo_dol = 0 then
             if lc_reg.cod_moneda = pkg_logistica.is_soles then
                ln_saldo_sol := lc_reg.importe_doc;
                ln_saldo_dol := lc_reg.importe_doc / lc_reg.tasa_cambio;
             else
                ln_saldo_sol := lc_reg.importe_doc * lc_reg.tasa_cambio;
                ln_saldo_dol := lc_reg.importe_doc;
             end if;
              
             update cntas_cobrar cc
                set cc.saldo_sol = ln_saldo_sol,
                    cc.saldo_dol = ln_saldo_dol,
                    cc.flag_caja_bancos = '0',
                    cc.flag_estado      = '1'
              where cc.tipo_doc = lc_reg.tipo_doc
                and cc.nro_doc  = lc_reg.nro_doc;

          else
             -- Actualizo el estado de la cuenta por cobrar
             update cntas_cobrar cc
                set cc.saldo_sol = ln_saldo_sol,
                    cc.saldo_dol = ln_saldo_dol,
                    cc.flag_caja_bancos = '1',
                    cc.flag_estado      = '1'
              where cc.tipo_doc = lc_reg.tipo_doc
                and cc.nro_doc  = lc_reg.nro_doc;
            
            -- Verifico si lo han cobrado o aplicado
            select nvl(sum(case when cbd.cod_moneda = PKG_LOGISTICA.of_soles(null) then cbd.importe else cbd.importe * cb.tasa_cambio end), 0),
                   nvl(sum(case when cbd.cod_moneda = PKG_LOGISTICA.of_dolares(null) then cbd.importe else cbd.importe / cb.tasa_cambio end), 0)
              into ln_temp_sol,
                   ln_temp_dol
              from caja_bancos cb,
                   caja_bancos_det cbd
             where cb.origen = cbd.origen
               and cb.nro_registro = cbd.nro_registro
               and cbd.cod_relacion = lc_reg.cod_relacion
               and cbd.tipo_doc     = lc_reg.tipo_doc
               and cbd.nro_doc      = lc_reg.nro_doc
               and cb.flag_estado   <> '0'
               and ((cb.flag_tiptran = '3' and cbd.factor = -1) 
                 or (cb.flag_tiptran in ('2', '4') and cbd.factor = 1));
            
            ln_saldo_sol := ln_saldo_sol - ln_temp_sol;
            ln_saldo_dol := ln_saldo_dol - ln_temp_dol;
            
            if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
            if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
            
            if (lc_reg.cod_moneda = PKG_LOGISTICA.is_soles and ln_saldo_sol = 0) 
              or (lc_reg.cod_moneda = PKG_LOGISTICA.is_dolares and ln_saldo_dol = 0) then
               ls_flag_estado := '3';
            else
               ls_flag_estado := '1';
            end if;
             
             update cntas_cobrar cc
                set cc.saldo_sol = ln_saldo_sol,
                    cc.saldo_dol = ln_saldo_dol,
                    cc.flag_caja_bancos = '1',
                    cc.flag_estado      = ls_flag_estado
              where cc.tipo_doc = lc_reg.tipo_doc
                and cc.nro_doc  = lc_reg.nro_doc;
            
            if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
               select count(*)
                 into ln_count
                 from caja_bancos cb,
                      caja_bancos_det cbd,
                      cntbl_Asiento_det cad
                where cb.origen         = cbd.origen
                  and cb.nro_registro   = cbd.nro_registro
                  and cb.origen         = cad.origen
                  and cb.ano            = cad.ano
                  and cb.mes            = cad.mes
                  and cb.nro_libro      = cad.nro_libro
                  and cb.nro_Asiento    = cad.nro_Asiento
                  and cad.cod_relacion  = lc_reg.cod_relacion
                  and cad.tipo_docref1  = lc_reg.tipo_doc
                  and cad.nro_docref1   = lc_reg.nro_doc
                  and cb.flag_estado   <> '0'
                  and ((cb.flag_tiptran = '3' and cbd.factor = 1) 
                    or (cb.flag_tiptran in ('2', '4') and cbd.factor = -1));
               
               if ln_count > 0 then
                  -- Obtengo la cuenta contable
                  select s.cnta_ctbl, s.flag_debhab
                    into ls_cnta_cntbl, ls_flag_debhab
                    from (select distinct cad.item, cad.cnta_ctbl, cad.flag_debhab
                           from caja_bancos cb,
                                caja_bancos_det cbd,
                                cntbl_Asiento_det cad
                          where cb.origen         = cbd.origen
                            and cb.nro_registro   = cbd.nro_registro
                            and cb.origen         = cad.origen
                            and cb.ano            = cad.ano
                            and cb.mes            = cad.mes
                            and cb.nro_libro      = cad.nro_libro
                            and cb.nro_Asiento    = cad.nro_Asiento
                            and cad.cod_relacion  = lc_reg.cod_relacion
                            and cad.tipo_docref1  = lc_reg.tipo_doc
                            and cad.nro_docref1   = lc_reg.nro_doc
                            and cb.flag_estado   <> '0'
                            and ((cb.flag_tiptran = '3' and cbd.factor = 1) 
                              or (cb.flag_tiptran in ('2', '4') and cbd.factor = -1))
                          order by cad.item) s
                     where rownum = 1;
               else
                  ls_cnta_cntbl := null;
                  ls_flag_debhab := null;
               end if; 
               
               update doc_pendientes_cta_cte t
                  set t.cnta_ctbl = ls_cnta_cntbl
                where t.cod_relacion         = lc_reg.cod_relacion
                  and t.tipo_doc             = lc_Reg.tipo_Doc
                  and t.nro_Doc              = lc_reg.nro_doc; 
            end if; 
            
          end if;
        
        end if;
    end loop;
    
    commit;

  end of_actualiza_saldo_cc;

  procedure of_actualiza_saldo_cp(
         asi_nada in varchar2
  ) is

    cursor c_datos_dtrp is
      select cp.cod_relacion, cp.tipo_doc, cp.nro_doc, cp.flag_estado, cp.importe_doc, cp.saldo_sol, cp.saldo_dol
        from cntas_pagar cp
       where cp.tipo_doc = PKG_SIGRE_FINANZAS.is_doc_dtrp
         and cp.flag_estado <> '0';

    cursor c_datos is
      select cp.cod_relacion, cp.tipo_doc, cp.nro_doc, cp.tasa_cambio, cp.importe_doc, cp.cod_moneda,
             cp.flag_control_reg, cp.flag_provisionado,
             'CP' as referencia,
             cp.flag_estado
        from cntas_pagar cp
       where ((cp.flag_provisionado = 'D' and cp.flag_control_reg in ('0', '1')) or (cp.flag_provisionado = 'R'))
      union
      select cri.proveedor as cod_relacion,
             'CRI' as tipo_doc,
             cri.nro_certificado as nro_doc,
             cri.tasa_cambio,
             cri.importe_doc,
             (select cod_soles from logparam where reckey = '1') as cod_moneda,
             '0' as flag_control_reg,
             '0' as flag_provisionado,
             'CRI' as referencia,
             cri.flag_estado
        from retencion_igv_crt cri
       where cri.flag_estado <> '0'
    order by referencia, tipo_doc, nro_doc;

    cursor c_og_det (as_proveedor cntas_pagar.cod_relacion%TYPE,
                     as_tipo_doc  cntas_pagar.tipo_doc%TYPE,
                     as_nro_doc   cntas_pagar.nro_doc%TYPE) is
      select s.tasa_cambio, s.cod_moneda, s.importe
        from solicitud_giro_liq_det s
       where s.proveedor = as_proveedor
         and s.tipo_doc  = as_tipo_doc
         and s.nro_doc   = as_nro_doc;

    cursor c_caja_bancos_det (as_proveedor cntas_pagar.cod_relacion%TYPE,
                              as_tipo_doc  cntas_pagar.tipo_doc%TYPE,
                              as_nro_doc   cntas_pagar.nro_doc%TYPE) is
      select cb.fecha_emision, cb.nro_registro, cbd.cod_moneda, cb.flag_tiptran, cb.tasa_cambio,
             cbd.importe
      from caja_bancos_det cbd,
           caja_bancos     cb
      where cb.origen    = cbd.origen
        and cb.nro_registro  = cbd.nro_registro
        and cbd.cod_relacion = as_proveedor
        and cbd.tipo_doc     = as_tipo_doc
        and cbd.nro_doc      = as_nro_doc
        and cb.flag_estado   <> '0'
        and ((cb.flag_tiptran= '3'          and cbd.factor = -1)
          or (cb.flag_tiptran in ('2', '4') and cbd.factor = 1)
          or (cbd.tipo_doc = 'NCP'          and cbd.factor = -1));

    cursor c_canje_documentos(as_proveedor cntas_pagar.cod_relacion%TYPE,
                              as_tipo_doc  cntas_pagar.tipo_doc%TYPE,
                              as_nro_doc   cntas_pagar.nro_doc%TYPE) is
      select cp.cod_moneda, dr.importe, cp.tasa_cambio
      from cntas_pagar cp,
           doc_referencias dr
      where cp.cod_relacion  = dr.proveedor_ref
        and cp.tipo_doc      = dr.tipo_ref
        and cp.nro_doc       = dr.nro_ref
        and dr.proveedor_ref = as_proveedor
        and dr.tipo_ref      = as_tipo_doc
        and dr.nro_ref       = as_nro_doc
        and cp.flag_estado   <> '0'
        and dr.tipo_mov      = 'P'
        and dr.flag_provisionado is not null;

    ln_count                number;
    ln_tasa_cambio          cntas_pagar.tasa_cambio%TYPE;
    ln_imp_detraccion       cntas_pagar.imp_detraccion%TYPE;
    ls_flag_detraccion      cntas_pagar.flag_detraccion%TYPE;
    ln_porc_detraccion      cntas_pagar.porc_detraccion%TYPE;
    ln_importe_doc          cntas_pagar.importe_doc%TYPE;
    ls_moneda               cntas_pagar.cod_moneda%TYPE;
    ln_saldo_sol            cntas_pagar.saldo_sol%TYPE;
    ln_saldo_dol            cntas_pagar.saldo_dol%TYPE;
    ln_imp_sol              cntas_pagar.saldo_sol%TYPE;
    ln_imp_dol              cntas_pagar.saldo_dol%TYPE;
    ls_flag_estado          cntas_pagar.flag_estado%TYPE;
    
  begin

    --Recorro el cursor de datos con la detracción
    for lc_reg in c_datos_dtrp loop
        select count(*)
          into ln_count
          from cntas_pagar cp
         where cp.nro_detraccion = lc_reg.nro_doc;
        
        if ln_count = 0 then
           -- Si no existe entoces lo anulo
           update cntas_pagar_det cpd
              set cpd.precio_unit = 0
            where cpd.cod_relacion = lc_reg.cod_relacion
              and cpd.tipo_doc     = lc_reg.tipo_doc
              and cpd.nro_doc      = lc_reg.nro_doc;
              
           update cntas_pagar cp
              set cp.importe_doc = 0, 
                  cp.saldo_sol   = 0,
                  cp.saldo_dol   = 0,
                  cp.flag_estado = '0'
            where cp.cod_relacion = lc_reg.cod_relacion
              and cp.tipo_doc     = lc_reg.tipo_doc
              and cp.nro_doc      = lc_reg.nro_doc;
        end if;
        
        if ln_count > 0 then
            -- Verifico el estado del comprobante original y de ser activo calculo el importe de detraccion
            select cp.flag_estado, cp.tasa_cambio, cp.cod_moneda,
                   cp.flag_detraccion, cp.porc_detraccion,
                   ((select nvl(sum(cpd.cantidad * cpd.precio_unit), 0)
                       from cntas_pagar_det cpd
                      where cpd.cod_relacion = cp.cod_relacion
                        and cpd.tipo_doc     = cp.tipo_doc
                        and cpd.nro_doc      = cp.nro_doc) +
                    (select nvl(sum(ci.importe), 0)
                       from cp_doc_det_imp ci
                      where ci.cod_relacion = cp.cod_relacion
                        and ci.tipo_doc     = cp.tipo_doc
                        and ci.nro_doc      = cp.nro_doc))
              into ls_flag_estado, ln_tasa_cambio, ls_moneda,
                   ls_flag_detraccion, ln_porc_detraccion,
                   ln_importe_doc
              from cntas_pagar cp
             where cp.nro_detraccion = lc_reg.nro_doc;
           
            if ls_flag_estado = '0' or ls_flag_detraccion = '0' then
               -- Si no existe entoces lo anulo
               update cntas_pagar_det cpd
                  set cpd.precio_unit = 0
                where cpd.cod_relacion = lc_reg.cod_relacion
                  and cpd.tipo_doc     = lc_reg.tipo_doc
                  and cpd.nro_doc      = lc_reg.nro_doc;
                  
               update cntas_pagar cp
                  set cp.importe_doc = 0, 
                      cp.saldo_sol   = 0,
                      cp.saldo_dol   = 0,
                      cp.flag_estado = '0'
                where cp.cod_relacion = lc_reg.cod_relacion
                  and cp.tipo_doc     = lc_reg.tipo_doc
                  and cp.nro_doc      = lc_reg.nro_doc;
            end if;
            
            -- Calculo el importe de la detraccion
            if ls_moneda = PKG_LOGISTICA.of_dolares(null) then
               ln_imp_sol := ln_importe_doc * ln_tasa_cambio;
            else
               ln_imp_sol := ln_importe_doc;
            end if;
            
            ln_imp_detraccion := round(ln_imp_sol * ln_porc_detraccion / 100, in_nro_decimales);
            
            -- Calculo la diferencia
            if ls_moneda = PKG_LOGISTICA.of_soles(null) then
               ln_importe_doc := ln_importe_doc - ln_imp_detraccion;
               ln_saldo_sol   := ln_importe_doc;
               ln_saldo_dol   := ln_importe_doc / ln_tasa_cambio ;
            else
               ln_importe_doc := ln_importe_doc - ln_imp_detraccion / ln_tasa_cambio;
               ln_saldo_dol   := ln_importe_doc;
               ln_saldo_sol   := ln_importe_doc * ln_tasa_cambio ;
            end if;
            
            -- Actualizo el importe del documento
            update cntas_pagar cp
               set cp.importe_doc = ln_importe_doc,
                   cp.saldo_sol   = ln_saldo_sol,
                   cp.saldo_dol   = ln_saldo_dol,
                   cp.flag_estado = '1'
             where cp.Nro_Detraccion = lc_reg.nro_doc;
            
            -- Actualizo el importe de la detraccion
            ln_saldo_sol := ln_imp_detraccion;
            ln_saldo_dol := ln_saldo_sol / ln_tasa_cambio;
            
            -- Actualizo el documento de detracción
            update cntas_pagar_det cpd
               set cpd.precio_unit    = ln_imp_detraccion
             where cpd.cod_relacion    = lc_reg.cod_relacion
               and cpd.tipo_doc        = lc_reg.tipo_doc
               and cpd.nro_doc         = lc_Reg.nro_doc;
               
            update cntas_pagar cp
               set cp.importe_doc   = ln_imp_detraccion,
                   cp.saldo_sol     = ln_saldo_sol,
                   cp.saldo_dol     = ln_saldo_dol,
                   cp.flag_estado   = '1',
                   cp.flag_control_reg = '0'
             where cp.cod_relacion  = lc_reg.cod_relacion
               and cp.tipo_doc      = lc_Reg.Tipo_Doc
               and cp.nro_doc       = lc_reg.nro_doc;
               
        end if;        
        
        
    end loop;
    

    for lc_reg in c_datos loop
        if lc_reg.flag_estado in ('0', '4') then

           -- Si el documento esta anulado o Cerrado manualmente por el usuario
           delete doc_pendientes_cta_cte t
           where t.cod_relacion = lc_reg.cod_relacion
             and t.tipo_doc     = lc_Reg.Tipo_Doc
             and t.nro_doc      = lc_reg.nro_doc;

        else
          -- si el documento esta activo verifico el saldo del artículo

          if lc_reg.cod_moneda = pkg_logistica.is_soles then
             ln_saldo_sol := lc_reg.importe_doc;
             ln_saldo_dol := lc_reg.importe_doc / lc_reg.tasa_cambio;
          else
             ln_saldo_sol := lc_reg.importe_doc * lc_reg.tasa_cambio;
             ln_saldo_dol := lc_reg.importe_doc;
          end if;

          -- Detalle en Cartera de Pagos
          for lc_reg2 in c_caja_bancos_det(lc_reg.cod_relacion, lc_reg.tipo_doc, lc_reg.nro_doc) loop
              if lc_reg2.cod_moneda = pkg_logistica.is_soles then
                 ln_imp_sol := lc_reg2.importe;
                 ln_imp_dol := lc_reg2.importe / lc_reg2.tasa_cambio;
              else
                 ln_imp_sol := lc_reg2.importe * lc_reg2.tasa_cambio;
                 ln_imp_dol := lc_reg2.importe;
              end if;

              ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
              ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
          end loop;

          if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
          if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;

          -- detalle en Orden de Giro
          if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
             for lc_reg2 in c_og_det(lc_reg.cod_relacion, lc_reg.tipo_doc, lc_reg.nro_doc) loop
                 if lc_reg2.cod_moneda = pkg_logistica.is_soles then
                    ln_imp_sol := lc_reg2.importe;
                    ln_imp_dol := lc_reg2.importe / lc_reg2.tasa_cambio;
                 else
                    ln_imp_sol := lc_reg2.importe * lc_reg2.tasa_cambio;
                    ln_imp_dol := lc_reg2.importe;
                 end if;

                 ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
                 ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
             end loop;

             if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
             if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
          end if;

          -- detalle en Canje de Documentos
          if ln_saldo_sol > 0 or ln_saldo_dol > 0 then
             for lc_reg2 in c_canje_documentos(lc_reg.cod_relacion, lc_reg.tipo_doc, lc_reg.nro_doc) loop
                 if lc_reg2.cod_moneda = pkg_logistica.is_soles then
                    ln_imp_sol := lc_reg2.importe;
                    ln_imp_dol := lc_reg2.importe / lc_reg2.tasa_cambio;
                 else
                    ln_imp_sol := lc_reg2.importe * lc_reg2.tasa_cambio;
                    ln_imp_dol := lc_reg2.importe;
                 end if;

                 ln_saldo_sol := ln_saldo_sol - ln_imp_sol;
                 ln_saldo_dol := ln_saldo_dol - ln_imp_dol;
             end loop;

             if ln_saldo_sol < 0 then ln_saldo_sol := 0; end if;
             if ln_saldo_dol < 0 then ln_saldo_dol := 0; end if;
          end if;

          -- Actualizo los datos en cntas_pagar
          -- Si es un gasto directo entonces simplemente actualizo el flag de estado según el saldo
          if lc_reg.flag_control_reg = '0' then
             if lc_reg.cod_moneda = pkg_logistica.is_soles then
                if ln_saldo_sol <= 0 then --pagado totalmente
                   ls_flag_estado := '3' ;
                elsif lc_reg.importe_doc = ln_saldo_sol then --generado
                   ls_flag_estado := '1';
                elsif ln_saldo_sol > 0 then    --pagado parcialmente
                   ls_flag_estado := '2';
                end if ;
             end if;

             if lc_reg.cod_moneda = pkg_logistica.is_dolares then
                if ln_saldo_dol <= 0 then --pagado totalmente
                   ls_flag_estado := '3' ;
                elsif lc_reg.importe_doc = ln_saldo_dol then --generado
                   ls_flag_estado := '1';
                elsif ln_saldo_dol > 0 then    --pagado parcialmente
                   ls_flag_estado := '2';
                end if ;
             end if;

             if lc_reg.referencia = 'CP' then
                UPDATE cntas_pagar
                   SET flag_estado = ls_flag_estado ,
                       saldo_sol   = ln_saldo_sol,
                       saldo_dol   = ln_saldo_dol,
                       flag_replicacion = '0'
                 WHERE cod_relacion = lc_reg.cod_relacion
                   AND tipo_doc     = lc_reg.tipo_doc
                   AND nro_doc      = lc_reg.nro_doc;

             elsif lc_reg.referencia = 'CRI' then

                UPDATE retencion_igv_crt cri
                    SET flag_estado = ls_flag_estado ,
                       saldo_sol   = ln_saldo_sol,
                       saldo_dol   = ln_saldo_dol,
                       flag_replicacion = '0'
                 WHERE cri.nro_certificado = lc_reg.nro_doc;
             end if;

             if (lc_reg.cod_moneda = pkg_logistica.is_soles and ln_saldo_sol = 0) or (lc_reg.cod_moneda = pkg_logistica.is_dolares and ln_saldo_dol = 0) then
                delete doc_pendientes_cta_cte d
                 where d.cod_relacion = lc_reg.cod_relacion
                   and d.tipo_doc     = lc_reg.tipo_doc
                   and d.nro_doc      = lc_reg.nro_doc;
             end if;
          end if;
        end if;
    end loop;

    commit;

  end of_actualiza_saldo_cp;
  
  --procedimiento para cambiar el tipo y nro de documento de una cuenta por pagar
  procedure sp_change_nro_doc(
            asi_cod_rel        in cntas_pagar.cod_relacion%type ,
            asi_tipo_doc       in cntas_pagar.tipo_doc%type     ,
            asi_nro_doc        in cntas_pagar.nro_doc%type      ,
            asi_new_cod_rel    in cntas_pagar.cod_relacion%type ,
            asi_new_tipo_doc   in cntas_pagar.tipo_doc%Type     ,
            asi_new_nro_doc    in cntas_pagar.nro_doc%type) is
    
  
  -- Datos del asiento contable
  ls_origen            cntas_pagar.origen%TYPE;
  ln_ano               cntas_pagar.ano%TYPE;
  ln_mes               cntas_pagar.mes%TYPE;
  ln_nro_libro         cntas_pagar.nro_libro%TYPE;
  ln_nro_asiento       cntas_pagar.nro_asiento%TYPE;

  begin
    -- Obtengo los datos del asiento
    select cp.origen, cp.ano, cp.mes, cp.nro_libro, cp.nro_asiento
      into ls_origen, ln_ano, ln_mes, ln_nro_libro, ln_nro_asiento
      from cntas_pagar cp
     where cp.cod_relacion = asi_cod_rel
       and cp.tipo_doc     = asi_tipo_doc
       and cp.nro_doc      = asi_nro_doc;


    --actualiza detalle del asiento x nro documento de cuentas por pagar
    update cntbl_asiento_det cad  
       set cad.nro_docref1  = asi_new_cod_rel   ,
           cad.tipo_docref1 = asi_new_tipo_doc,
           cad.cod_relacion = asi_new_nro_doc
     where cad.cod_relacion       = asi_cod_rel
       and cad.tipo_docref1       = asi_tipo_doc
       and trim(cad.nro_docref1)  = trim(asi_nro_doc);


    --nuevo numero
    Insert Into cntas_pagar(
           cod_relacion, tipo_doc, nro_doc, 
           flag_estado, fecha_registro, fecha_emision, vencimiento,
           forma_pago, cod_moneda, tasa_cambio, total_pagar, total_pagado, cod_usr, job, motivo,
           origen, ano, mes, nro_libro, nro_asiento, descripcion, porc_ret_igv, nro_const_deposito,
           fecha_const_deposito, flag_retencion, nro_detraccion, flag_detraccion, porc_detraccion,
           flag_situacion_ltr, banco_ltr, nro_ren_ltr, flag_tipo_ltr, flag_provisionado, importe_doc,
           saldo_sol, saldo_dol, nro_certificado, flag_replicacion, flag_control_reg, flag_caja_bancos,
           saldo_aplicado_sol, saldo_aplicado_dol, oper_detr, bien_serv, fecha_presentacion, nro_sol_cred_rrhh,
           flag_cntr_almacen, importe_doc_referencial, fecha_pago_rtps, flag_ret_4categ, cod_aduana, 
           nro_correlativo, nom_proveedor, tipo_doc_ident, nro_doc_ident, fec_impresion, imp_detraccion, 
           flag_redondear, confin, serie_cp, numero_cp, clase_bien_serv)
    select asi_new_cod_rel, asi_new_tipo_doc, asi_new_nro_doc, 
           flag_estado, fecha_registro, fecha_emision, vencimiento,
           forma_pago, cod_moneda, tasa_cambio, total_pagar, total_pagado, cod_usr, job, motivo,
           origen, ano, mes, nro_libro, nro_asiento, descripcion, porc_ret_igv, nro_const_deposito,
           fecha_const_deposito, flag_retencion, nro_detraccion, flag_detraccion, porc_detraccion,
           flag_situacion_ltr, banco_ltr, nro_ren_ltr, flag_tipo_ltr, flag_provisionado, importe_doc,
           saldo_sol, saldo_dol, nro_certificado, flag_replicacion, flag_control_reg, flag_caja_bancos,
           saldo_aplicado_sol, saldo_aplicado_dol, oper_detr, bien_serv, fecha_presentacion, nro_sol_cred_rrhh,
           flag_cntr_almacen, importe_doc_referencial, fecha_pago_rtps, flag_ret_4categ, cod_aduana, 
           nro_correlativo, nom_proveedor, tipo_doc_ident, nro_doc_ident, fec_impresion, imp_detraccion, 
           flag_redondear, confin, serie_cp, numero_cp, clase_bien_serv
      from cntas_pagar a
     where a.cod_relacion = asi_cod_rel
       and a.tipo_doc     = asi_tipo_doc     
       and a.nro_doc      = asi_nro_doc      ;


    --inserto linea adicional en cntas_pagar_det
    insert into cntas_pagar_det(
          cod_relacion, tipo_doc,nro_doc,
          item, descripcion, cod_art, confin, cantidad, importe, cencos, cnta_prsp, 
          tipo_cred_fiscal, flag_replicacion, org_amp_ref, nro_amp_ref, centro_benef, 
          origen_ref, tipo_ref, nro_ref, item_ref, fec_movilidad, mov_desde, mov_hasta, 
          org_os, nro_os, item_os, org_am, nro_am, nro_vale_trans, item_vale_trans, precio_unit)
    select asi_new_cod_rel, asi_new_tipo_doc, asi_new_nro_doc,
           item, descripcion, cod_art, confin, cantidad, importe, cencos, cnta_prsp, 
           tipo_cred_fiscal, flag_replicacion, org_amp_ref, nro_amp_ref, centro_benef, 
           origen_ref, tipo_ref, nro_ref, item_ref, fec_movilidad, mov_desde, mov_hasta, 
           org_os, nro_os, item_os, org_am, nro_am, nro_vale_trans, item_vale_trans, precio_unit
      from cntas_pagar_det cpd
     where cpd.cod_relacion = asi_cod_rel 
       and cpd.tipo_doc     = asi_tipo_doc     
       and cpd.nro_doc      = asi_nro_doc      ;


    --cambio en tabla impuestos
    update cp_doc_det_imp cpi
       set cpi.cod_relacion = asi_new_cod_rel,
           cpi.tipo_doc     = asi_new_tipo_doc,
           cpi.nro_doc      = asi_new_nro_doc
     where cpi.cod_relacion = asi_cod_rel 
       and cpi.tipo_doc     = asi_tipo_doc     
       and cpi.nro_doc      = asi_nro_doc       ;


    --cambio el documento de referencia
    update doc_referencias dr
       set dr.cod_relacion = asi_new_cod_rel,
           dr.tipo_doc     = asi_new_tipo_doc,
           dr.nro_doc      = asi_new_nro_doc
     where dr.cod_relacion = asi_cod_rel 
       and dr.tipo_doc     = asi_tipo_doc     
       and dr.nro_doc      = asi_nro_doc      ;


    --Elimino el detalle de cntas_pagar
    delete cntas_pagar_det cpd
     where cpd.cod_relacion = asi_cod_rel
       and cpd.tipo_doc     = asi_tipo_doc     
       and cpd.nro_doc      = asi_nro_doc      ;

    --actualiza caja bancos detalle
    update caja_bancos_det cbd
       set cbd.cod_relacion = asi_new_cod_rel  ,
           cbd.tipo_doc     = asi_new_tipo_doc  ,
           cbd.nro_doc      = asi_new_nro_doc
     where cbd.cod_relacion = asi_cod_rel
       and cbd.tipo_doc     = asi_tipo_doc     
       and cbd.nro_doc      = asi_nro_doc      ;


    --actuliza de doc_referencias
    update doc_referencias dr
       set dr.cod_relacion = asi_new_cod_rel   ,
           dr.tipo_ref     = asi_new_tipo_doc   ,
           dr.nro_ref      = asi_new_nro_doc
     where dr.cod_relacion = asi_cod_rel 
       and dr.tipo_ref     = asi_tipo_doc    
       and dr.nro_ref      = asi_nro_doc      
       and dr.tipo_mov     in ('C','P')      ;


    --actualiza solictud giro
    update solicitud_giro_liq_det sgld
       set sgld.nro_doc   = asi_new_nro_doc,
           sgld.proveedor = asi_new_cod_rel  ,
           sgld.tipo_doc  = asi_new_tipo_doc
     where sgld.proveedor     = asi_cod_rel  
       and sgld.tipo_doc      = asi_tipo_doc      
       and sgld.nro_doc       = asi_nro_doc       ;



    --actualiza liquidacion pesca
    update liquidacion_det lqd
       set lqd.cxp_cod_rel  = asi_new_cod_rel,
           lqd.cxp_tipo_doc = asi_new_tipo_doc,
           lqd.cxp_nro_doc  = asi_new_nro_doc
     where lqd.cxp_cod_rel  = asi_cod_rel 
       and lqd.cxp_tipo_doc = asi_tipo_doc    
       and lqd.cxp_nro_doc  = asi_nro_doc     ;
    ---


    --actualiza programacion pago
    update programacion_pagos_det_doc pp
       set pp.prov_cnta_pagar = asi_new_cod_rel ,
           pp.doc_cnta_pagar  = asi_new_tipo_doc ,
           pp.nro_cnta_pagar  = asi_new_nro_doc
     where pp.prov_cnta_pagar = asi_cod_rel 
       and pp.doc_cnta_pagar  = asi_tipo_doc     
       and pp.nro_cnta_pagar  = asi_nro_doc      ;


    --actualiza planilla cobranza
    update pln_cobranza_det pcd
       set pcd.nro_doc_cxp = asi_new_nro_doc   ,
           pcd.cod_rel_cxp = asi_new_cod_rel ,
           pcd.doc_cxp     = asi_new_tipo_doc
     where pcd.cod_rel_cxp = asi_cod_rel 
       and pcd.doc_cxp     = asi_tipo_doc     
       and pcd.nro_doc_cxp = asi_nro_doc      ;


    --elimino cntas pagar
    delete from cntas_pagar cp
     where cp.cod_relacion = asi_cod_rel 
       and cp.tipo_doc     = asi_tipo_doc     
       and cp.nro_doc      = asi_nro_doc     ;
  
  
  end;

begin
  
  -- Documentos esenciales
  select f.doc_detrac_cp, f.doc_fact_cobrar, f.doc_bol_cobrar
    into is_doc_dtrp, is_doc_fac, is_doc_bvc
    from finparam f
   where f.reckey = '1';
   
  
  is_confin_vta_vd_sol := PKG_CONFIG.USF_GET_PARAMETER('CONFIN_VTA_CON_VALES_DCTO_SOL', 'CC-008');
  is_confin_vta_vd_dol := PKG_CONFIG.USF_GET_PARAMETER('CONFIN_VTA_CON_VALES_DCTO_DOL', 'CC-008');
  in_nro_decimales     := PKG_CONFIG.USF_GET_PARAMETER( 'NRO_DECIMALES_DETRACCION', 0);
  
  -- Documentos de notas de Credito / Debito
  is_doc_ncp        := PKG_CONFIG.USF_GET_PARAMETER('DOC_NCP', 'NCP');
  is_doc_ndp        := PKG_CONFIG.USF_GET_PARAMETER('DOC_NDP', 'NCP');
  is_doc_dtrc       := PKG_CONFIG.USF_GET_PARAMETER('DOC_DTRC', 'DTRC');
  is_doc_ncc        := PKG_CONFIG.USF_GET_PARAMETER('DOC_NOTA_CREDITO_X_COBRAR', 'NCC');
  is_doc_ndc        := PKG_CONFIG.USF_GET_PARAMETER('DOC_NOTA_debito_X_COBRAR', 'NDC');
   
end PKG_SIGRE_FINANZAS;
/
