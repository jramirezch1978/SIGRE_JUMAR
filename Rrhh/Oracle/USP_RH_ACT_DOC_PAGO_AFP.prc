create or replace procedure USP_RH_ACT_DOC_PAGO_AFP(
       asi_tipo_trab    in maestro.tipo_trabajador%type ,
       asi_origen       in origen.cod_origen%Type       ,
       adi_fec_proceso  in date                         ,
       asi_cod_usr      in usuario.cod_usr%type
) is

lc_grp_afp_jub        rrhhparam_cconcep.afp_jubilacion%type ;
lc_grp_afp_inv        rrhhparam_cconcep.afp_invalidez%type ;
lc_grp_afp_com        rrhhparam_cconcep.afp_comision%type ;
lc_forma_pago         forma_pago.forma_pago%Type            ;
lc_soles              moneda.cod_moneda%Type                ;
ln_tasa_cambio        calendario.cmp_dol_libre%type         ;
lc_cencos_pgo_plla    centros_costo.cencos%Type             ;
lc_cnta_prsp_pgo_plla presupuesto_cuenta.cnta_prsp%Type     ;
ls_doc_afp            doc_tipo.tipo_doc%Type                ;
ln_imp_soles          calculo.imp_soles%type                ;
ln_imp_dolar          calculo.imp_soles%type                ;
ln_nro                number                                ;
lc_obs                cntas_pagar.descripcion%type          ;
ln_count              number                                ;

ls_nro_doc            calc_doc_pagar_plla.nro_doc%TYPE;
ls_flag_estado        calc_doc_pagar_plla.flag_estado%TYPE;
lb_continue           boolean;

Cursor c_maestro_plla is
select distinct cod_afp, cod_relacion, desc_afp
from(
    select m.cod_afp,af.cod_relacion,af.desc_afp
      from maestro    m ,
           calculo    c,
           admin_afp  af
     where m.cod_trabajador     = c.cod_trabajador
       and m.cod_afp            = af.cod_afp
       and m.cod_origen         = asi_origen
       and m.tipo_trabajador    = asi_tipo_trab
       and trunc(c.fec_proceso) = Trunc(adi_fec_proceso)
       and af.cod_relacion      is not null
       and m.flag_pensionista   = '0'
    group by m.cod_afp,af.cod_relacion,af.desc_afp
    union
    select m.cod_afp, af.cod_relacion, af.desc_afp
      from maestro              m ,
           historico_calculo    hc,
           admin_afp            af
     where m.cod_trabajador     = hc.cod_trabajador
       and m.cod_afp            = af.cod_afp
       and m.cod_origen         = asi_origen
       and m.tipo_trabajador    = asi_tipo_trab
       and trunc(hc.fec_calc_plan) = Trunc(adi_fec_proceso)
       and af.cod_relacion         is not null
       and m.flag_pensionista   = '0'
       
    group by m.cod_afp, af.cod_relacion, af.desc_afp
);

Cursor c_pago_afp (as_cod_afp admin_afp.cod_afp%type) is
  select sum(imp_soles) as imp_soles, sum(imp_dolar) as imp_dolar
  from(
    select Sum(c.imp_soles) as imp_soles ,Sum(c.imp_dolar) as imp_dolar
      from calculo c,maestro m
     where c.cod_trabajador     = m.cod_trabajador
       and m.cod_origen         = asi_origen
       and m.tipo_trabajador    = asi_tipo_trab
       and m.cod_afp            = as_cod_afp
       and c.concep in ( (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_jub),
                         (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_inv),
                         (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_com) )
       and trunc(c.fec_proceso) = Trunc(adi_fec_proceso)
    group by m.cod_afp
    union
    select Sum(hc.imp_soles) as imp_soles ,Sum(hc.imp_dolar) as imp_dolar
      from historico_calculo hc,
           maestro           m
     where hc.cod_trabajador    = m.cod_trabajador
       and m.cod_origen         = asi_origen
       and m.tipo_trabajador    = asi_tipo_trab
       and m.cod_afp            = as_cod_afp
       and hc.concep in ( (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_jub),
                          (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_inv),
                          (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_com) )
       and trunc(hc.fec_calc_plan) = Trunc(adi_fec_proceso)
    group by m.cod_afp
  );

begin
--recupero de parametros grupos deconceptos de afp
select rhc.afp_jubilacion, rhc.afp_invalidez, rhc.afp_comision
  into lc_grp_afp_jub, lc_grp_afp_inv, lc_grp_afp_com
  from rrhhparam_cconcep rhc
 where rhc.reckey = '1' ;

select forma_pago_contado
  into lc_forma_pago
  from genparam
 where reckey = '1' ;

select cod_soles
  into lc_soles
  from logparam
 where reckey = '1' ;

--recuperar tipo de cambio
ln_tasa_cambio := usf_fin_tasa_cambio(adi_fec_proceso) ;
--

--parametros
select rh.cencos_pago_plla ,rh.cnta_prsp_pago_plla ,rh.doc_pago_afp
  into lc_cencos_pgo_plla ,lc_cnta_prsp_pgo_plla,ls_doc_afp
  from rrhhparam rh
 where rh.reckey = '1' ;

--recupero numero
select count(*)
  into ln_count
  from num_doc_tipo
 where tipo_doc = ls_doc_afp;

  if ln_count = 0 then
     insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
     values(ls_doc_afp, 1, 1);
  end if;

  select ultimo_numero
    into ln_nro
    from num_doc_tipo
   where tipo_doc = ls_doc_afp for update;

lc_obs := 'PAGO DE AFP DE '||asi_tipo_trab||'-'||asi_origen||'-'||TO_CHAR(adi_fec_proceso,'dd/mm/yyyy') ;

For rc_maestro_plla in c_maestro_plla Loop
    if rc_maestro_plla.cod_relacion is null then
       RAISE_APPLICATION_ERROR(-20000, 'La Afp ' || rc_maestro_plla.cod_afp || ', no tiene asignado un codigo de relacion. Por favor verifique!');
    end if;
    For rc_pago_afp in c_pago_afp (rc_maestro_plla.cod_afp ) Loop
      
        lb_continue := true;

        -- Primero verifico si ya existe el documento o no existe
        select count(*)
          into ln_count
          from calc_doc_pagar_plla cdpp
         where cdpp.cod_origen         = asi_origen
           AND cdpp.tipo_trabajador    = asi_tipo_trab
           AND trunc(cdpp.fec_proceso) = trunc(adi_fec_proceso)
           AND cdpp.tipo_doc           = ls_doc_afp
           and cdpp.cod_relacion       = rc_maestro_plla.cod_relacion
           and cdpp.flag_estado        <> '0';

        if ln_count > 0 then
           -- Si existe el documento verifico el estado del mismo
           select cdpp.nro_doc
             into ls_nro_doc
             from calc_doc_pagar_plla cdpp
            where cdpp.cod_origen         = asi_origen
              AND cdpp.tipo_trabajador    = asi_tipo_trab
              AND trunc(cdpp.fec_proceso) = trunc(adi_fec_proceso)
              AND cdpp.tipo_doc           = ls_doc_afp
              and cdpp.cod_relacion       = rc_maestro_plla.cod_relacion
              and cdpp.flag_estado        = '1';

           -- Verifico si el documento existe o no
           SELECT COUNT(*)
             INTO ln_count
             FROM cntas_pagar cp
            where cp.cod_relacion = rc_maestro_plla.cod_relacion
              AND cp.tipo_doc     = ls_doc_afp
              AND cp.nro_doc      = ls_nro_doc;

           IF ln_count > 0 THEN
              SELECT flag_estado
                INTO ls_flag_estado
                FROM cntas_pagar cp
               where cp.cod_relacion = rc_maestro_plla.cod_relacion
                 AND cp.tipo_doc     = ls_doc_afp
                 AND cp.nro_doc      = ls_nro_doc;

              IF ls_flag_estado NOT IN ('1', '0') THEN
                 /*RAISE_APPLICATION_ERROR(-20000, 'El documento: ' || rc_doc_plla.tipo_doc || ' ' || rc_doc_plla.nro_doc
                                         || ' ha sido cancelado, por favor verifique');*/
                 lb_continue := false;
              END IF;
           else
              ls_nro_doc := null;
           END IF;
        else
           ls_nro_doc := null;
        end if;

        -- Si el documento no ha sido pagado entonces continuo
        if lb_continue then

            -- Si no existe el documento entonces creo
            if ls_nro_doc is null then
               --CONSTRUIR NUMERO
               ls_nro_doc := asi_origen||lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;
               ln_nro := ln_nro + 1 ;
            end if;

            -- Obtengo los totales
            ln_imp_soles := rc_pago_afp.imp_soles ;
            ln_imp_dolar := rc_pago_afp.imp_dolar ;

            lc_obs := rc_maestro_plla.desc_afp ||' '||asi_tipo_trab||'-'||asi_origen||'-'||TO_CHAR(adi_fec_proceso,'dd/mm/yyyy') ;

            -- Actualizo la informacion
            update cntas_pagar cp
               set cp.fecha_emision = adi_fec_proceso,
                   cp.vencimiento   = adi_fec_proceso,
                   cp.forma_pago    = lc_forma_pago,
                   cp.cod_moneda    = lc_soles,
                   cp.tasa_cambio   = ln_tasa_cambio,
                   cp.cod_usr       = asi_cod_usr,
                   cp.origen        = asi_origen,
                   cp.descripcion   = lc_obs,
                   cp.flag_provisionado = 'D',
                   cp.importe_doc       = ln_imp_soles,
                   cp.saldo_sol         = ln_imp_soles,
                   cp.saldo_dol         = Round(ln_imp_soles / ln_tasa_cambio,2),
                   cp.flag_control_reg  = '0'
             where cp.cod_relacion = rc_maestro_plla.cod_relacion
               and cp.tipo_doc     = ls_doc_afp
               and cp.nro_doc      = ls_nro_doc;

            if SQL%NOTFOUND then
                --inserta registro cabecera
                Insert Into cntas_pagar(
                       cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
                       vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
                       descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
                Values(
                       rc_maestro_plla.cod_relacion ,ls_doc_afp    ,ls_nro_doc   ,'1'            ,adi_fec_proceso ,adi_fec_proceso ,
                       adi_fec_proceso              ,lc_forma_pago ,lc_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
                       lc_obs     ,'D'       ,ln_imp_soles  ,ln_imp_soles ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;
            end if;

            -- Actualizo el detalle del documento
            update cntas_pagar_det cpd
               set cpd.descripcion = rc_maestro_plla.desc_afp,
                   cpd.cantidad    = 1,
                   cpd.importe     = ln_imp_soles,
                   cpd.cencos      = lc_cencos_pgo_plla,
                   cpd.cnta_prsp   = lc_cnta_prsp_pgo_plla
             where cpd.cod_relacion = rc_maestro_plla.cod_relacion
               and cpd.tipo_doc     = ls_doc_afp
               and cpd.nro_doc      = ls_nro_doc
               and cpd.item         = 1;

            if SQL%NOTFOUND then
               --inserta registro detalle
               Insert Into cntas_pagar_det(
                       cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
                       cencos       ,cnta_prsp )
               Values(
                       rc_maestro_plla.cod_relacion ,ls_doc_afp ,ls_nro_doc,'1',rc_maestro_plla.desc_afp ,1,ln_imp_soles,
                       lc_cencos_pgo_plla ,lc_cnta_prsp_pgo_plla ) ;
            end if;

            -- Actualizo en la tabla calc_doc_pagar_plla
            select count(*)
              into ln_count
              from calc_doc_pagar_plla c
             where c.cod_relacion       = rc_maestro_plla.cod_relacion
               and c.tipo_doc           = ls_doc_afp
               and c.nro_doc            = ls_nro_doc;

            if ln_count = 0 then
                --registralo en documentos de pago de planilla
                Insert Into calc_doc_pagar_plla(
                       cod_origen,tipo_trabajador ,fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado)
                Values(
                       asi_origen,asi_tipo_trab,adi_fec_proceso,rc_maestro_plla.cod_relacion,ls_doc_afp,ls_nro_doc,'1');
             end if;


        end if;
    End Loop ;

End Loop ;

-- Actualizo el contador
update num_doc_tipo
   set ultimo_numero = ln_nro
where tipo_doc = ls_doc_afp;


end USP_RH_ACT_DOC_PAGO_AFP;
/
