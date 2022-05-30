create or replace procedure USP_GEN_CNTA_PAGAR_LBS(
       asi_nro_liquidacion    in liquidacion_benef.nro_liquidacion%TYPE,
       asi_user               in usuario.cod_usr%TYPE
) is

  -- Cntas_Pagar
  ln_saldo_sol        cntas_pagar.saldo_sol%TYPE;
  ln_saldo_dol        cntas_pagar.saldo_dol%TYPE;
  ln_tasa_cambio      cntas_pagar.tasa_cambio%TYPE;
  ls_obs              cntas_pagar.descripcion%TYPE;
  ls_forma_pago       cntas_pagar.Forma_Pago%TYPE;
  ls_prov_SUNAT       rrhhparam_cconcep.prov_sunat%TYPE;
  ls_prov_ESSALUD     lbs_param.prov_essalud%TYPE;

  ln_saldo_doc        liquidacion_benef_det.importe%TYPE;
  ln_saldo_cta_cte    cnta_crrte.sldo_prestamo%TYPE;
  ln_monto_orig       cnta_crrte.mont_original%TYPE;
  ln_importe          cnta_crrte_detalle.imp_dscto%TYPE;
  ls_doc_lbs          lbs_param.doc_lbs%TYPE;
  ln_count            number;
  ln_item             number;


  -- Liquidacion
  ls_estado_lbs       liquidacion_benef.flag_estado%TYPE;
  ls_trabajador       liquidacion_benef.cod_trabajador%TYPE;
  ld_fec_proceso      liquidacion_benef.fec_proceso%TYPE;
  ld_fec_cese         liquidacion_benef.fec_salida%TYPE;
  ls_origen           liquidacion_benef.cod_origen%TYPE;

  -- Cntas Pagar
  ls_estado_cp        cntas_pagar.flag_estado%TYPE;

  --Logparam
  ls_soles            logparam.cod_soles%TYPE;
  ls_dolares          logparam.cod_dolares%TYPE;

  --FinParam
  ls_cencos_pgo_plla    centros_costo.cencos%Type             ;
  ls_cnta_prsp_pgo_plla presupuesto_cuenta.cnta_prsp%Type     ;


  -- Cursor para descuentos por AFP
  cursor c_datos_afp is
    select  lbd.nro_liquidacion,
            case 
              when m.cod_afp is null then ls_prov_SUNAT
              else a.cod_relacion
            end as proveedor,
            trunc(lb.fec_salida) as fec_salida,
            lb.cod_origen, 
            lb.cod_trabajador,
            sum(abs(lbd.importe)) as importe
      from liquidacion_benef_det lbd,
           liquidacion_benef     lb,
           maestro               m,
           admin_afp             a
     where lb.nro_liquidacion  = lbd.nro_liquidacion
       and lb.cod_trabajador   = m.cod_trabajador
       and m.cod_afp           = a.cod_afp                   (+)
       and lbd.nro_liquidacion = asi_nro_liquidacion
       and lbd.flag_titulo_lbs = '5' -- Descuentos de AFP;
       and abs(lbd.importe)    > 0
     group by lbd.nro_liquidacion,
            case 
              when m.cod_afp is null then ls_prov_SUNAT
              else a.cod_relacion
            end,
            trunc(lb.fec_salida),
            lb.cod_origen, 
            lb.cod_trabajador;

  -- Aportaciones de ESSALUD
  cursor c_datos_ESSALUD is
    select  lbd.nro_liquidacion,
            trunc(lb.fec_salida) as fec_salida,
            lb.cod_origen, 
            lb.cod_trabajador,
            sum(abs(lbd.importe)) as importe
      from liquidacion_benef_det lbd,
           liquidacion_benef     lb,
           maestro               m,
           admin_afp             a
     where lb.nro_liquidacion  = lbd.nro_liquidacion
       and lb.cod_trabajador   = m.cod_trabajador
       and m.cod_afp           = a.cod_afp                   (+)
       and lbd.nro_liquidacion = asi_nro_liquidacion
       and lbd.flag_titulo_lbs = '9' -- Aportaciones de ESSALUD
       and abs(lbd.importe)    > 0
     group by lbd.nro_liquidacion,
            trunc(lb.fec_salida),
            lb.cod_origen, 
            lb.cod_trabajador;

  -- Cursor para descuentos por CTA CTE
  cursor c_datos_cta_cte is
    select  lbd.nro_liquidacion, lbd.proveedor,
            lbd.tipo_doc_cta_cte, lbd.nro_doc_cta_cte,
            lb.fec_salida, lb.obs,
            abs(lbd.importe) as importe
      from liquidacion_benef_det lbd,
           liquidacion_benef     lb
     where lb.nro_liquidacion  = lbd.nro_liquidacion
       and lbd.nro_liquidacion = asi_nro_liquidacion
       and lbd.tipo_doc_cta_cte is not null
       and lbd.nro_doc_cta_cte is not null
       and abs(lbd.importe)    > 0 
       and lbd.flag_titulo_lbs = '6'; -- Descuentos de CNTA CORRIENTE;

  -- Cursor con los documentos por pagar relacionados con la liquidacion
  cursor c_doc_cntas_pagar is
     select lcp.cod_relacion, lcp.tipo_doc, lcp.nro_doc
       from lbs_cntas_pagar lcp
      where lcp.nro_liquidacion = asi_nro_liquidacion;

  -- Cursor con los periodos laborales de la liquidacion
  cursor c_lbs_periodos is
    select lp.cod_trabajador, lp.item, lb.fec_salida, lb.cod_tipo_extincion, lb.nro_liquidacion
      from lbs_periodos lp,
           liquidacion_benef  lb
     where lp.nro_liquidacion = lb.nro_liquidacion
       and lp.nro_liquidacion = asi_nro_liquidacion;
begin
  -- Primero los parametros necesarios
  select cod_soles, cod_dolares
    into ls_soles, ls_dolares
    from logparam l
   where reckey = '1';

  -- Obtengo los parametros para el documento lbs
  select doc_lbs, l.prov_essalud
    into ls_doc_lbs, ls_prov_ESSALUD
    from lbs_param l
   where reckey = '1';

  -- Obtengo los parametros financieros
  select f.pago_contado
    into ls_forma_pago
    from finparam f
   where reckey = '1';

  -- Parametros de rrhhparam
  select rhc.prov_sunat
  into ls_prov_SUNAT
  from rrhhparam_cconcep rhc
 where rhc.reckey = '1';

  -- Parametros de RRHH
  select rh.cencos_pago_plla ,rh.cnta_prsp_pago_plla
    into ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla
    from rrhhparam rh
   where rh.reckey = '1' ;
   
  -- Este procedimiento generar? o actualizara los documentos por pagar directo
  -- correspondiente a la liquidacion de beneficios
  select count(*)
    into ln_count
    from liquidacion_benef
   where nro_liquidacion = asi_nro_liquidacion;

  if ln_count = 0 then
     RAISE_APPLICATION_ERROR(-20000, 'Nro de Liquidacion de beneficios ' || asi_nro_liquidacion || ' no existe, por favor verifique!');
  end if;

  select flag_estado, lb.cod_trabajador, lb.fec_proceso, lb.cod_origen, lb.fec_salida
    into ls_estado_lbs, ls_trabajador, ld_fec_proceso, ls_origen, ld_fec_cese
    from liquidacion_benef lb
   where nro_liquidacion = asi_nro_liquidacion;

  if ls_estado_lbs = '0' then
     -- Si el documento esta anulado entonces anulo todo lo que esta relacionado con el documento
     -- Primero elimina el detalle de cuenta corriente si lo hubiera
     for lc_reg in c_datos_cta_cte loop
         -- Obtengo el monto original de la cnta_Corriente
         select cc.mont_original
           into ln_monto_orig
           from cnta_crrte cc
          where cc.cod_trabajador  = lc_reg.proveedor
            and cc.tipo_doc        = lc_reg.tipo_doc_cta_cte
            and cc.nro_doc         = lc_reg.nro_doc_cta_cte for update;

         delete cnta_crrte_detalle ccd
          where ccd.cod_trabajador = lc_reg.proveedor
            and ccd.tipo_doc       = lc_reg.tipo_doc_cta_cte
            and ccd.nro_doc        = lc_reg.nro_doc_cta_cte
            and ccd.nro_liquidacion  = lc_reg.nro_liquidacion;

         -- Obtengo el total del importe
         select sum(ccd.imp_dscto)
           into ln_importe
           from cnta_crrte_detalle ccd
          where ccd.cod_trabajador  = lc_reg.proveedor
            and ccd.tipo_doc        = lc_reg.tipo_doc_cta_cte
            and ccd.nro_doc         = lc_reg.nro_doc_cta_cte;

         ln_saldo_cta_cte := ln_monto_orig + ln_importe;

         if ln_saldo_cta_cte < 0 then ln_saldo_cta_cte := 0; end if;

         -- Actualizo el saldo de cuenta corriente
         update cnta_crrte cc
            set cc.sldo_prestamo   = ln_saldo_cta_cte
          where cc.cod_trabajador  = lc_reg.proveedor
            and cc.tipo_doc        = lc_reg.tipo_doc_cta_cte
            and cc.nro_doc         = lc_reg.nro_doc_cta_cte;
     end loop;

     -- Luego elimino los documentos por pagar directo relacionados con este documento, previamente
     -- Verifico que el estado de dichos documentos sea '1' para poderlos anular
     for lc_reg in c_doc_cntas_pagar loop
         select flag_estado
           into ls_estado_cp
           from cntas_pagar cp
          where cp.cod_relacion = lc_reg.cod_relacion
            and cp.tipo_doc     = lc_reg.tipo_doc
            and cp.nro_doc      = lc_reg.nro_doc for update;

         if ls_estado_cp in ('2', '3') then
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20000, 'Documento ' || lc_reg.tipo_doc || '-' || lc_reg.nro_doc
                                            || ' se encuentra pagado, no se puede anular. Por favor Verifique!!!!!');
         end if;

         if ls_estado_cp = '1' then
            -- anulo el detalle
            update cntas_pagar_det cpd
               set cpd.importe = 0
              where cpd.cod_relacion = lc_reg.cod_relacion
                and cpd.tipo_doc     = lc_reg.tipo_doc
                and cpd.nro_doc      = lc_reg.nro_doc;

            -- anulo la cabecera
            update cntas_pagar cp
               set cp.flag_estado = '0',
                   cp.importe_doc = 0,
                   cp.saldo_sol   = 0,
                   cp.saldo_dol   = 0
             where cp.cod_relacion = lc_reg.cod_relacion
               and cp.tipo_doc     = lc_reg.tipo_doc
               and cp.nro_doc      = lc_reg.nro_doc;
         end if;
     end loop;

     -- Actualizo los periodos laborales quitandoles la fecha de liquidacion
     for lc_reg in c_lbs_periodos loop
         update rrhh_periodos_laborales_rtps r
            set r.cod_tipo_extincion = null,
                r.fec_liquidacion    = null,
                r.flag_liquidacion   = '0',
                r.tipo_doc_liquidacion = null,
                r.nro_doc_liquidacion  = null
          where r.cod_trabajador = lc_reg.cod_trabajador
            and r.item           = lc_reg.item;
     end loop;

     -- Actualizo la fecha de cese del trabajo y lo inactivo del sistema
     update maestro m
        set m.fec_cese = null,
            m.flag_estado = '1'
      where m.cod_trabajador = ls_trabajador;

     return; -- No hay mas nada que hacer
  end if;

  -- Si el documento esta generado entonces
  if ls_estado_lbs = '1' then
     -- Primero actualizo el detalle de cuenta corriente
     for lc_reg in c_datos_cta_cte loop
         -- Obtengo el monto original de la cnta_Corriente
         select cc.mont_original
           into ln_monto_orig
           from cnta_crrte cc
          where cc.cod_trabajador  = lc_reg.proveedor
            and cc.tipo_doc        = lc_reg.tipo_doc_cta_cte
            and cc.nro_doc         = lc_reg.nro_doc_cta_cte for update;

         -- Actualizo el importe de la cuenta corriente, en caso de no existir lo
         -- inserto en el detalle
         update cnta_crrte_detalle ccd
            set ccd.imp_dscto = lc_reg.importe,
                ccd.flag_proceso = 'L'        -- Liquidaci?n
          where ccd.cod_trabajador  = lc_reg.proveedor
            and ccd.tipo_doc        = lc_reg.tipo_doc_cta_cte
            and ccd.nro_doc         = lc_reg.nro_doc_cta_cte
            and ccd.nro_liquidacion = lc_reg.nro_liquidacion;

         IF SQL%NOTFOUND then
            select nvl(max(ccd.nro_dscto), 0)
              into ln_item
              from cnta_crrte_detalle ccd
             where ccd.cod_trabajador  = lc_reg.proveedor
               and ccd.tipo_doc        = lc_reg.tipo_doc_cta_cte
               and ccd.nro_doc         = lc_reg.nro_doc_cta_cte;

            ln_item := ln_item + 1;

            insert into cnta_crrte_detalle(
                   cod_trabajador, tipo_doc, nro_doc, nro_dscto, fec_dscto, imp_dscto, cod_usr,
                   observaciones, flag_digitado, flag_estado, nro_liquidacion)
            values(
                   lc_reg.proveedor, lc_reg.tipo_doc_cta_cte, lc_reg.nro_doc_cta_cte, ln_item,
                   lc_reg.fec_salida, lc_reg.importe, asi_user, substr(lc_reg.obs,1,60), '0', '1',
                   lc_reg.nro_liquidacion);
         end if;

         -- Obtengo el total del importe
         select sum(ccd.imp_dscto)
           into ln_importe
           from cnta_crrte_detalle ccd
          where ccd.cod_trabajador  = lc_reg.proveedor
            and ccd.tipo_doc        = lc_reg.tipo_doc_cta_cte
            and ccd.nro_doc         = lc_reg.nro_doc_cta_cte;

         ln_saldo_cta_cte := ln_monto_orig - ln_importe;

         if ln_saldo_cta_cte < 0 then ln_saldo_cta_cte := 0; end if;

         -- Actualizo el saldo de cuenta corriente
         update cnta_crrte cc
            set cc.sldo_prestamo   = ln_saldo_cta_cte
          where cc.cod_trabajador  = lc_reg.proveedor
            and cc.tipo_doc        = lc_reg.tipo_doc_cta_cte
            and cc.nro_doc         = lc_reg.nro_doc_cta_cte;

     end loop;

     -- Luego genero los documentos necesarios para el descuento de AFP
     for lc_reg in c_datos_afp loop
         
         -- Preparo la observaci?n
         ls_obs := 'PAGO DE AFP-ONP, LIQUIDACION DE BENEFICIOS: ' || lc_reg.nro_liquidacion
                 ||', Origen: ' || lc_reg.cod_origen;

         -- Verifico si el documento ya existe, o esta relacionado para solamente actualizarlo
         select count(*)
           into ln_count
           from lbs_cntas_pagar lcp
          where lcp.cod_relacion = lc_reg.proveedor
            and lcp.tipo_doc     = ls_doc_lbs
            and lcp.nro_doc      = lc_reg.nro_liquidacion;

         if ln_count = 0 then
            -- Flag de estado activo por defecto
            ls_estado_cp := '1';

            -- Obtengo la tasa de cmabio
            ln_tasa_cambio := usf_fin_tasa_cambio(lc_reg.fec_salida) ;

            -- Importes
            ln_saldo_sol := lc_reg.importe;
            ln_saldo_dol := lc_reg.importe /ln_tasa_cambio;

            --inserta registro cabecera
            Insert Into cntas_pagar(
                   cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
                   vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
                   descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
            Values(
                   lc_reg.proveedor , ls_doc_lbs   ,asi_nro_liquidacion   ,ls_estado_cp  ,trunc(sysdate),lc_reg.fec_salida ,
                   lc_reg.fec_salida, ls_forma_pago,ls_soles     ,ln_tasa_cambio ,asi_user     ,lc_reg.cod_origen ,
                   ls_obs        ,'D',ln_saldo_sol ,ln_saldo_sol ,ln_saldo_dol,'0' ) ;

            -- ahora inserto el detalle de la cnta por pagar
            ln_item := 1;
            Insert Into cntas_pagar_det(
                   cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
                   cencos       ,cnta_prsp )
            Values(
                   lc_reg.proveedor ,ls_doc_lbs ,lc_reg.nro_liquidacion, ln_item,
                   substr(ls_obs, 1, 60), 1, lc_reg.importe, ls_cencos_pgo_plla, ls_cnta_prsp_pgo_plla ) ;

            -- Ahora inserto el documento creado en la tabla de referencia
            insert into lbs_cntas_pagar(
                   cod_relacion, tipo_doc, nro_doc, nro_liquidacion)
            values(
                   lc_reg.proveedor, ls_doc_lbs, lc_reg.nro_liquidacion, lc_reg.nro_liquidacion);

         else
            -- Obtengo el flag de estado, debe estar activo para hacer cambios sino nada que ver
            select flag_estado, cp.tasa_cambio
              into ls_estado_cp, ln_tasa_cambio
              from cntas_pagar cp
             where cp.cod_relacion = lc_reg.proveedor
               and cp.tipo_doc     = ls_doc_lbs
               and cp.nro_doc      = lc_reg.nro_liquidacion;

            if ls_estado_cp = '0' then
               RAISE_APPLICATION_ERROR(-20000, 'EL DOCUMENTO ' || ls_doc_lbs || '-' || lc_reg.nro_liquidacion
                                           || ' para el proveedor ' || lc_reg.proveedor || ' se encuentra anulado'
                                           || ' en cntas por pagar, por favor verifique');
            end if;

            if ls_estado_cp > '1' then
               RAISE_APPLICATION_ERROR(-20000, 'EL DOCUMENTO ' || ls_doc_lbs || '-' || lc_reg.nro_liquidacion
                                           || ' para el proveedor ' || lc_reg.proveedor || ' se encuentra pagado'
                                           || ' en cntas por pagar, por favor verifique');
            end if;

            update cntas_pagar_det cpd
               set cpd.importe = lc_reg.importe,
                   cpd.descripcion = substr(ls_obs,1, 60)
             where cpd.cod_relacion = lc_reg.proveedor
               and cpd.tipo_doc     = ls_doc_lbs
               and cpd.nro_doc      = lc_reg.nro_liquidacion;

            -- Obtengo los saldos en dolares, porque ya se que siempre la liquidacion es en soles
            ln_saldo_dol := lc_reg.importe / ln_tasa_cambio;

            update cntas_pagar cp
               set cp.importe_doc = lc_reg.importe,
                   cp.saldo_sol   = lc_reg.importe,
                   cp.saldo_dol   = ln_saldo_dol,
                   cp.cod_moneda  = ls_soles,
                   cp.descripcion = substr(ls_obs,1, 60)
             where cp.cod_relacion = lc_reg.proveedor
               and cp.tipo_doc     = ls_doc_lbs
               and cp.nro_doc      = lc_reg.nro_liquidacion;

         end if;
     end loop;

     -- Luego genero el documento de pago para essalud
     for lc_reg in c_datos_ESSALUD loop
         
         -- Preparo la observaci?n
         ls_obs := 'PAGO DE ESSALUD, LIQUIDACION DE BENEFICIOS: ' || lc_reg.nro_liquidacion
                 ||', Origen: ' || lc_reg.cod_origen;

         -- Verifico si el documento ya existe, o esta relacionado para solamente actualizarlo
         select count(*)
           into ln_count
           from lbs_cntas_pagar lcp
          where lcp.cod_relacion = ls_prov_ESSALUD
            and lcp.tipo_doc     = ls_doc_lbs
            and lcp.nro_doc      = lc_reg.nro_liquidacion;

         if ln_count = 0 then
            -- Flag de estado activo por defecto
            ls_estado_cp := '1';

            -- Obtengo la tasa de cmabio
            ln_tasa_cambio := usf_fin_tasa_cambio(lc_reg.fec_salida) ;

            -- Importes
            ln_saldo_sol := lc_reg.importe;
            ln_saldo_dol := lc_reg.importe /ln_tasa_cambio;

            --inserta registro cabecera
            Insert Into cntas_pagar(
                   cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
                   vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
                   descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
            Values(
                   ls_prov_ESSALUD , ls_doc_lbs   ,asi_nro_liquidacion   ,ls_estado_cp  ,trunc(sysdate),lc_reg.fec_salida ,
                   lc_reg.fec_salida, ls_forma_pago,ls_soles     ,ln_tasa_cambio ,asi_user     ,lc_reg.cod_origen ,
                   ls_obs        ,'D',ln_saldo_sol ,ln_saldo_sol ,ln_saldo_dol,'0' ) ;

            -- ahora inserto el detalle de la cnta por pagar
            ln_item := 1;
            Insert Into cntas_pagar_det(
                   cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
                   cencos       ,cnta_prsp )
            Values(
                   ls_prov_ESSALUD ,ls_doc_lbs ,lc_reg.nro_liquidacion, ln_item,
                   substr(ls_obs, 1, 60), 1, lc_reg.importe, ls_cencos_pgo_plla, ls_cnta_prsp_pgo_plla ) ;

            -- Ahora inserto el documento creado en la tabla de referencia
            insert into lbs_cntas_pagar(
                   cod_relacion, tipo_doc, nro_doc, nro_liquidacion)
            values(
                   ls_prov_ESSALUD, ls_doc_lbs, lc_reg.nro_liquidacion, lc_reg.nro_liquidacion);

         else
            -- Obtengo el flag de estado, debe estar activo para hacer cambios sino nada que ver
            select flag_estado, cp.tasa_cambio
              into ls_estado_cp, ln_tasa_cambio
              from cntas_pagar cp
             where cp.cod_relacion = ls_prov_ESSALUD
               and cp.tipo_doc     = ls_doc_lbs
               and cp.nro_doc      = lc_reg.nro_liquidacion;

            if ls_estado_cp = '0' then
               RAISE_APPLICATION_ERROR(-20000, 'EL DOCUMENTO ' || ls_doc_lbs || '-' || lc_reg.nro_liquidacion
                                           || ' para el proveedor ' || ls_prov_ESSALUD || ' se encuentra anulado'
                                           || ' en cntas por pagar, por favor verifique');
            end if;

            if ls_estado_cp > '1' then
               RAISE_APPLICATION_ERROR(-20000, 'EL DOCUMENTO ' || ls_doc_lbs || '-' || lc_reg.nro_liquidacion
                                           || ' para el proveedor ' || ls_prov_ESSALUD || ' se encuentra pagado'
                                           || ' en cntas por pagar, por favor verifique');
            end if;

            update cntas_pagar_det cpd
               set cpd.importe = lc_reg.importe,
                   cpd.descripcion = substr(ls_obs,1, 60)
             where cpd.cod_relacion = ls_prov_ESSALUD
               and cpd.tipo_doc     = ls_doc_lbs
               and cpd.nro_doc      = lc_reg.nro_liquidacion;

            -- Obtengo los saldos en dolares, porque ya se que siempre la liquidacion es en soles
            ln_saldo_dol := lc_reg.importe / ln_tasa_cambio;

            update cntas_pagar cp
               set cp.importe_doc = lc_reg.importe,
                   cp.saldo_sol   = lc_reg.importe,
                   cp.saldo_dol   = ln_saldo_dol,
                   cp.cod_moneda  = ls_soles,
                   cp.descripcion = substr(ls_obs,1, 60)
             where cp.cod_relacion = ls_prov_ESSALUD
               and cp.tipo_doc     = ls_doc_lbs
               and cp.nro_doc      = lc_reg.nro_liquidacion;

         end if;
     end loop;

     -- calculo el importe del documento
     select sum(lbd.importe)
       into ln_saldo_doc
       from liquidacion_benef_det lbd
      where lbd.nro_liquidacion = asi_nro_liquidacion
        and lbd.flag_titulo_lbs between '2' and '8';

     -- Verifico si existe el documento o no
     select count(*)
       into ln_count
       from lbs_cntas_pagar lcp
      where lcp.cod_relacion = ls_trabajador
        and lcp.tipo_doc     = ls_doc_lbs
        and lcp.nro_doc      = asi_nro_liquidacion;

     -- Si no existe entonces lo creo
     if ln_count = 0 then
        ls_obs := 'PAGO DE LIQUIDACION DE BENEFICIOS: ' || asi_nro_liquidacion
               ||', Origen: ' || ls_origen;

        -- Flag de estado activo por defecto
        ls_estado_cp := '1';

        -- Obtengo la tasa de cmabio
        ln_tasa_cambio := usf_fin_tasa_cambio(ld_fec_proceso) ;

        -- Importes
        ln_saldo_sol := ln_saldo_doc;
        ln_saldo_dol := ln_saldo_doc /ln_tasa_cambio;

        --inserta registro cabecera
        Insert Into cntas_pagar(
               cod_relacion ,tipo_doc          ,nro_doc   ,flag_estado ,fecha_registro ,fecha_emision    ,
               vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
               descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
        Values(
               ls_trabajador , ls_doc_lbs   ,asi_nro_liquidacion   ,ls_estado_cp  ,trunc(sysdate),ld_fec_proceso ,
               ld_fec_proceso, ls_forma_pago,ls_soles     ,ln_tasa_cambio ,asi_user     ,ls_origen ,
               ls_obs        ,'D',ln_saldo_sol ,ln_saldo_sol ,ln_saldo_dol,'0' ) ;

        -- ahora inserto el detalle de la cnta por pagar
        ln_item := 1;
        Insert Into cntas_pagar_det(
               cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
               cencos       ,cnta_prsp )
        Values(
               ls_trabajador ,ls_doc_lbs ,asi_nro_liquidacion, ln_item,
               'PAGO DE LIQUIDACION DE BENEFICIOS SOCIALES: ' || ls_trabajador,
               1, ln_saldo_doc, ls_cencos_pgo_plla, ls_cnta_prsp_pgo_plla ) ;

        -- Ahora inserto el documento creado en la tabla de referencia
        insert into lbs_cntas_pagar(
               cod_relacion, tipo_doc, nro_doc, nro_liquidacion)
        values(
               ls_trabajador, ls_doc_lbs, asi_nro_liquidacion, asi_nro_liquidacion);

     else
        -- Si existe entonces actualizo los importes nada mas
        -- Obtengo el flag de estado, debe estar activo para hacer cambios sino nada que ver
        select flag_estado, cp.tasa_cambio
          into ls_estado_cp, ln_tasa_cambio
          from cntas_pagar cp
         where cp.cod_relacion = ls_trabajador
           and cp.tipo_doc     = ls_doc_lbs
           and cp.nro_doc      = asi_nro_liquidacion;

        if ls_estado_cp = '0' then
           RAISE_APPLICATION_ERROR(-20000, 'EL DOCUMENTO ' || ls_doc_lbs || '-' || asi_nro_liquidacion
                                       || ' para el trabajador ' || ls_trabajador || ' se encuentra anulado'
                                       || ' en cntas por pagar, por favor verifique');
        end if;

        if ls_estado_cp > '1' then
           RAISE_APPLICATION_ERROR(-20000, 'EL DOCUMENTO ' || ls_doc_lbs || '-' || asi_nro_liquidacion
                                       || ' para el trabajador ' || ls_trabajador || ' se encuentra pagado'
                                       || ' en cntas por pagar, por favor verifique');
        end if;

        update cntas_pagar_det cpd
           set cpd.importe = ln_saldo_doc
         where cpd.cod_relacion = ls_trabajador
           and cpd.tipo_doc     = ls_doc_lbs
           and cpd.nro_doc      = asi_nro_liquidacion;

        -- Obtengo los saldos en dolares, porque ya se que siempre la liquidacion es en soles
        ln_saldo_dol := ln_saldo_doc / ln_tasa_cambio;

        update cntas_pagar cp
           set cp.importe_doc = ln_saldo_doc,
               cp.saldo_sol   = ln_saldo_doc,
               cp.saldo_dol   = ln_saldo_dol,
               cp.cod_moneda  = ls_soles
         where cp.cod_relacion = ls_trabajador
           and cp.tipo_doc     = ls_doc_lbs
           and cp.nro_doc      = asi_nro_liquidacion;

     end if;
     -- Actualizo los periodos laborales poniendoles la fecha de liquidacion
     for lc_reg in c_lbs_periodos loop
         update rrhh_periodos_laborales_rtps r
            set r.cod_tipo_extincion = lc_reg.cod_tipo_extincion,
                r.fec_liquidacion    = lc_reg.fec_salida,
                r.flag_liquidacion   = '1',
                r.tipo_doc_liquidacion = ls_doc_lbs,
                r.nro_doc_liquidacion  = lc_reg.nro_liquidacion
          where r.cod_trabajador = lc_reg.cod_trabajador
            and r.item           = lc_reg.item;
     end loop;

     -- Actualizo la fecha de cese del trabajo y lo inactivo del sistema
     update maestro m
        set m.fec_cese = ld_fec_cese,
            m.flag_estado = '0'
      where m.cod_trabajador = ls_trabajador;

  end if;


end USP_GEN_CNTA_PAGAR_LBS;
/
