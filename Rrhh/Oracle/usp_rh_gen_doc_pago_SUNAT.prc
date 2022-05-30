create or replace procedure usp_rh_gen_doc_pago_SUNAT(
       asi_origen       in origen.cod_origen%Type       ,
       ani_year         in number                       ,
       ani_mes          in number                       ,
       asi_cod_usr      in usuario.cod_usr%type          
) is

ls_cnc_onp_snp        rrhhparam_cconcep.cnc_snp_onp%TYPE;
ls_cnc_rta_qta        rrhhparam_cconcep.cnc_ret_quinta%TYPE;
ls_cnc_rta_qta2       rrhhparam_cconcep.cnc_ret_quinta%TYPE := '2204';
ls_cnc_ess_vida       rrhhparam_cconcep.cnc_essalud_vida%TYPE;
ls_cnc_essalud        rrhhparam_cconcep.cnc_essalud%TYPE;
ls_prov_SUNAT         rrhhparam_cconcep.prov_sunat%TYPE;

ls_forma_pago         forma_pago.forma_pago%Type            ;
ls_soles              moneda.cod_moneda%Type                ;
ln_tasa_cambio        calendario.cmp_dol_libre%type         ;
ls_cencos_pgo_plla    centros_costo.cencos%Type             ;
ls_cenbef_pago_plla   rrhhparam.centro_benef_plla%TYPE      ;
ls_cnta_prsp_pgo_plla presupuesto_cuenta.cnta_prsp%Type     ;
ls_nro_doc            cntas_pagar.nro_doc%Type              ;
ld_fecha              date;

-- Documentos para tipos de pagos, uno por cada tipo
ls_doc_snp_onp        rrhhparam_cconcep.doc_pago_snp_onp%TYPE;
ls_doc_rta_qta        rrhhparam_cconcep.doc_pago_rta_quinta%TYPE;
ls_doc_vida           rrhhparam_cconcep.doc_pago_es_vida%TYPE;
ls_doc_essalud        rrhhparam_cconcep.doc_pago_essalud%TYPE;
ls_flag_estado        cntas_pagar.flag_estado%TYPE;
ln_item               cntas_pagar_det.item%TYPE;

-- Otras Variables
ln_imp_soles          calculo.imp_soles%type                ;
ln_nro                number                                ;
ls_obs                cntas_pagar.descripcion%type          ;
ln_count              number                                ;

Cursor c_datos(as_concepto  historico_calculo.concep%TYPE) is
  select tt.tipo_trabajador, tt.desc_tipo_tra, 
         sum(hc.imp_soles) as imp_soles,
         sum(hc.imp_dolar) as imp_dolar
    from maestro           m,
         historico_calculo hc,
         tipo_trabajador   tt
   where m.cod_trabajador     = hc.cod_trabajador     
     and m.tipo_trabajador    = tt.tipo_trabajador
     and m.cod_origen         = asi_origen       
     and hc.concep            = as_concepto     
     and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
     and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes
  group by tt.tipo_trabajador, tt.desc_tipo_tra ;

Cursor c_datos2(as_concepto1  historico_calculo.concep%TYPE, as_concepto2  historico_calculo.concep%TYPE) is
  select tt.tipo_trabajador, tt.desc_tipo_tra, 
         sum(hc.imp_soles) as imp_soles,
         sum(hc.imp_dolar) as imp_dolar
    from maestro           m,
         historico_calculo hc,
         tipo_trabajador   tt
   where m.cod_trabajador     = hc.cod_trabajador     
     and m.tipo_trabajador    = tt.tipo_trabajador
     and m.cod_origen         = asi_origen       
     and hc.concep            in (as_concepto1, as_concepto2)
     and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
     and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes
  group by tt.tipo_trabajador, tt.desc_tipo_tra ;

begin
--recupero de parametros grupos deconceptos de afp
select rhc.cnc_snp_onp, rhc.cnc_ret_quinta, rhc.cnc_essalud_vida, rhc.cnc_essalud, rhc.prov_sunat,
       rhc.doc_pago_snp_onp, rhc.doc_pago_rta_quinta, rhc.doc_pago_es_vida, rhc.doc_pago_essalud 
  into ls_cnc_onp_snp, ls_cnc_rta_qta, ls_cnc_ess_vida, ls_cnc_essalud, ls_prov_SUNAT,
       ls_doc_snp_onp, ls_doc_rta_qta, ls_doc_vida, ls_doc_essalud
  from rrhhparam_cconcep rhc
 where rhc.reckey = '1' ;

select forma_pago_contado 
  into ls_forma_pago 
  from genparam 
 where reckey = '1' ;
 
select cod_soles          
  into ls_soles      
  from logparam 
 where reckey = '1' ;

--recuperar tipo de cambio
ld_fecha       := trunc(sysdate);
ln_tasa_cambio := usf_fin_tasa_cambio(ld_fecha) ;
--

--parametros
select rh.cencos_pago_plla ,rh.cnta_prsp_pago_plla, rh.centro_benef_plla
  into ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla, ls_cenbef_pago_plla
  from rrhhparam rh 
 where rh.reckey = '1' ;

/********************************************************************************************
*                     Genero el documento para el pago de SNP-ONP
********************************************************************************************/
select sum(hc.imp_soles)
  into ln_imp_soles
  from maestro           m,
       historico_calculo hc,
       tipo_trabajador   tt
 where m.cod_trabajador     = hc.cod_trabajador     
   and m.tipo_trabajador    = tt.tipo_trabajador
   and m.cod_origen         = asi_origen       
   and hc.concep            = ls_cnc_onp_snp     
   and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
   and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes;

select count(*)
  into ln_count
  from num_doc_tipo
 where tipo_doc = ls_doc_snp_onp;

  if ln_count = 0 then
     insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
     values(ls_doc_snp_onp, 1, 1);
  end if;

  select ultimo_numero 
    into ln_nro 
    from num_doc_tipo 
   where tipo_doc = ls_doc_snp_onp for update;

ls_obs := 'PAGO DE ONP-SNP, PLANILLA PERIODO: '||to_char(ani_mes, '00') || '-' || trim(to_char(ani_year, '0000'))
        ||', Origen: ' || asi_origen ;

-- Primero Verifico si ya existe el numero
select count(*)
  into ln_count
  from calc_doc_pagar_plla c
 where c.cod_relacion = ls_prov_SUNAT
   and c.tipo_doc     = ls_doc_snp_onp
   and c.ano          = ani_year
   and c.mes          = ani_mes;

-- Si el contador es cero entonces construyo el nro del documento e incremento el contador
if ln_count = 0 then
   --CONSTRUIR NUMERO
   ls_nro_doc := asi_origen || lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;
   
   -- Incremento el numerador y lo actualizo
   ln_nro := ln_nro + 1 ;

   update num_doc_tipo
      set ultimo_numero = ln_nro
    where (tipo_doc = ls_doc_snp_onp) ;
    
   -- Flag de estado activo por defecto
   ls_flag_estado := '1';

   --inserta registro cabecera
   Insert Into cntas_pagar(
           cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
           vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
           descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
   Values(
           ls_prov_SUNAT , ls_doc_snp_onp   ,ls_nro_doc   ,ls_flag_estado ,ld_fecha      ,ld_fecha         ,
           ld_fecha      , ls_forma_pago    ,ls_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
           ls_obs        ,'D',ln_imp_soles     ,ln_imp_soles ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;
    

else
   -- De lo contrario obtengo el numero creado anteriormente, asi como su flag de estado
   select c.nro_doc, c.flag_estado
     into ls_nro_doc, ls_flag_estado
     from calc_doc_pagar_plla c
    where c.cod_relacion = ls_prov_SUNAT
      and c.tipo_doc     = ls_doc_snp_onp
      and c.ano          = ani_year
      and c.mes          = ani_mes;
   
   -- Actualizo en la cabecera del documento los totales necesarios, solo si el documento est? activo
   if ls_flag_estado = '1' then
      update cntas_pagar cp
         set cp.importe_doc = ln_imp_soles,
             cp.saldo_sol   = ln_imp_soles,
             cp.saldo_dol   = Round(ln_imp_soles / ln_tasa_cambio,2),
             cp.tasa_cambio = ln_tasa_cambio
       where cp.cod_relacion = ls_prov_SUNAT
         and cp.tipo_doc     = ls_doc_snp_onp
         and cp.nro_doc      = ls_nro_doc;
   end if;
end if;

-- Si el documento sigue activo entonces simplemente reconstruyo el detalle, para ello primero lo elimino
if ls_flag_estado = '1' and ln_count > 0 then
   delete cntas_pagar_det cpd
     where cpd.cod_relacion = ls_prov_SUNAT
       and cpd.tipo_doc     = ls_doc_snp_onp
       and cpd.nro_doc      = ls_nro_doc;
end if;

-- Luego ya inserto el detalle asi de simple
if ls_flag_estado = '1' or ln_count = 0 then
   ln_item := 1;
   For lc_reg in c_datos(ls_cnc_onp_snp) Loop
       ln_imp_soles := lc_reg.imp_soles ;

       --inserta registro detalle
       Insert Into cntas_pagar_det(
              cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
              cencos       ,cnta_prsp, centro_benef )
       Values(
              ls_prov_SUNAT ,ls_doc_snp_onp ,ls_nro_doc, ln_item,
              'Pago de SNP-ONP, Tipo Trab: ' || lc_reg.tipo_trabajador || ' - ' || lc_reg.desc_tipo_tra ,
              1,ln_imp_soles, ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla, ls_cenbef_pago_plla ) ;
       
       ln_item := ln_item + 1;
   End Loop ;
end if;

--registralo en documentos de pago de planilla
if ln_count = 0 then
   Insert Into calc_doc_pagar_plla(
         cod_origen, fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado, ano, mes)
   Values(
         asi_origen, ld_fecha,ls_prov_SUNAT,ls_doc_snp_onp,ls_nro_doc,'1', ani_year, ani_mes);
else
   update calc_doc_pagar_plla c
      set c.fec_proceso = ld_fecha
    where c.cod_relacion = ls_prov_SUNAT
      and c.tipo_doc     = ls_doc_snp_onp
      and c.nro_doc      = ls_nro_doc;
end if;        


/********************************************************************************************
*                     Genero el documento para el pago de RTA QUINTA
********************************************************************************************/
select sum(hc.imp_soles)
  into ln_imp_soles
  from maestro           m,
       historico_calculo hc,
       tipo_trabajador   tt
 where m.cod_trabajador     = hc.cod_trabajador     
   and hc.tipo_trabajador   = tt.tipo_trabajador
   and m.cod_origen         = asi_origen       
   and hc.concep            in (ls_cnc_rta_qta, ls_cnc_rta_qta2)
   and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
   and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes;

if ln_imp_soles > 0 then   
    select count(*)
      into ln_count
      from num_doc_tipo
     where tipo_doc = ls_doc_rta_qta;

      if ln_count = 0 then
         insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
         values(ls_doc_rta_qta, 1, 1);
      end if;

      select ultimo_numero 
        into ln_nro 
        from num_doc_tipo 
       where tipo_doc = ls_doc_rta_qta for update;

    ls_obs := 'PAGO DE RENTA QUINTA CATEG, PLANILLA PERIODO: '||to_char(ani_mes, '00') || '-' || trim(to_char(ani_year, '0000'))
            ||', Origen: ' || asi_origen ;

    -- Primero Verifico si ya existe el numero
    select count(*)
      into ln_count
      from calc_doc_pagar_plla c
     where c.cod_relacion = ls_prov_SUNAT
       and c.tipo_doc     = ls_doc_rta_qta
       and c.ano          = ani_year
       and c.mes          = ani_mes;

    -- Si el contador es cero entonces construyo el nro del documento e incremento el contador
    if ln_count = 0 then
       --CONSTRUIR NUMERO
       ls_nro_doc := asi_origen || lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;
       
       -- Incremento el numerador y lo actualizo
       ln_nro := ln_nro + 1 ;

       update num_doc_tipo
          set ultimo_numero = ln_nro
        where (tipo_doc = ls_doc_rta_qta) ;
        
       -- Flag de estado activo por defecto
       ls_flag_estado := '1';

       --inserta registro cabecera
       Insert Into cntas_pagar(
               cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
               vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
               descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
       Values(
               ls_prov_SUNAT , ls_doc_rta_qta   ,ls_nro_doc   ,ls_flag_estado ,ld_fecha      ,ld_fecha         ,
               ld_fecha      , ls_forma_pago    ,ls_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
               ls_obs        ,'D',ln_imp_soles     ,ln_imp_soles ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;
        

    else
       -- De lo contrario obtengo el numero creado anteriormente, asi como su flag de estado
       select c.nro_doc, c.flag_estado
         into ls_nro_doc, ls_flag_estado
         from calc_doc_pagar_plla c
        where c.cod_relacion = ls_prov_SUNAT
          and c.tipo_doc     = ls_doc_rta_qta
          and c.ano          = ani_year
          and c.mes          = ani_mes;

       -- Actualizo en la cabecera del documento los totales necesarios, solo si el documento est? activo
       if ls_flag_estado = '1' then
          update cntas_pagar cp
             set cp.importe_doc = ln_imp_soles,
                 cp.saldo_sol   = ln_imp_soles,
                 cp.saldo_dol   = Round(ln_imp_soles / ln_tasa_cambio,2),
                 cp.tasa_cambio = ln_tasa_cambio
           where cp.cod_relacion = ls_prov_SUNAT
             and cp.tipo_doc     = ls_doc_rta_qta
             and cp.nro_doc      = ls_nro_doc;
       end if;
          
    end if;
    
    -- Si el documento sigue activo entonces simplemente reconstruyo el detalle, para ello primero lo elimino
    if ls_flag_estado = '1' and ln_count > 0 then
       delete cntas_pagar_det cpd
         where cpd.cod_relacion = ls_prov_SUNAT
           and cpd.tipo_doc     = ls_doc_rta_qta
           and cpd.nro_doc      = ls_nro_doc;
    end if;

    -- Luego ya inserto el detalle asi de simple
    if ls_flag_estado = '1' or ln_count = 0 then
       ln_item := 1;
       For lc_reg in c_datos2(ls_cnc_rta_qta, ls_cnc_rta_qta2) Loop
           ln_imp_soles := lc_reg.imp_soles ;

           --inserta registro detalle
           Insert Into cntas_pagar_det(
                  cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
                  cencos       ,cnta_prsp, centro_benef )
           Values(
                  ls_prov_SUNAT ,ls_doc_rta_qta ,ls_nro_doc, ln_item,
                  'Pago de RTA QUINTA, Tipo Trab: ' || lc_reg.tipo_trabajador || ' - ' || lc_reg.desc_tipo_tra ,
                  1,ln_imp_soles, ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla, ls_cenbef_pago_plla ) ;
           
           ln_item := ln_item + 1;
       End Loop ;
    end if;

    --registralo en documentos de pago de planilla
    if ln_count = 0 then
       Insert Into calc_doc_pagar_plla(
             cod_origen, fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado, ano, mes)
       Values(
             asi_origen, ld_fecha,ls_prov_SUNAT,ls_doc_rta_qta,ls_nro_doc,'1', ani_year, ani_mes);
    else
       update calc_doc_pagar_plla c
          set c.fec_proceso = ld_fecha
        where c.cod_relacion = ls_prov_SUNAT
          and c.tipo_doc     = ls_doc_rta_qta
          and c.nro_doc      = ls_nro_doc;
    end if;
end if;

        

/********************************************************************************************
*                     Genero el documento para el pago de ESSALUD VIDA
********************************************************************************************/
select sum(hc.imp_soles)
  into ln_imp_soles
  from maestro           m,
       historico_calculo hc,
       tipo_trabajador   tt
 where m.cod_trabajador     = hc.cod_trabajador     
   and m.tipo_trabajador    = tt.tipo_trabajador
   and m.cod_origen         = asi_origen       
   and hc.concep            = ls_cnc_ess_vida     
   and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
   and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes;
   
if ln_imp_soles > 0 then
    select count(*)
      into ln_count
      from num_doc_tipo
     where tipo_doc = ls_doc_vida;

      if ln_count = 0 then
         insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
         values(ls_doc_vida, 1, 1);
      end if;

      select ultimo_numero 
        into ln_nro 
        from num_doc_tipo 
       where tipo_doc = ls_doc_vida for update;

    ls_obs := 'PAGO DE ESSALUD VIDA, PLANILLA PERIODO: '||to_char(ani_mes, '00') || '-' || trim(to_char(ani_year, '0000'))
            ||', Origen: ' || asi_origen ;

    -- Primero Verifico si ya existe el numero
    select count(*)
      into ln_count
      from calc_doc_pagar_plla c
     where c.cod_relacion = ls_prov_SUNAT
       and c.tipo_doc     = ls_doc_vida
       and c.ano          = ani_year
       and c.mes          = ani_mes;

    -- Si el contador es cero entonces construyo el nro del documento e incremento el contador
    if ln_count = 0 then
       --CONSTRUIR NUMERO
       ls_nro_doc := asi_origen || lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;
       
       -- Incremento el numerador y lo actualizo
       ln_nro := ln_nro + 1 ;

       update num_doc_tipo
          set ultimo_numero = ln_nro
        where (tipo_doc = ls_doc_vida) ;
        
       -- Flag de estado activo por defecto
       ls_flag_estado := '1';

       --inserta registro cabecera
       Insert Into cntas_pagar(
               cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
               vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
               descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
       Values(
               ls_prov_SUNAT , ls_doc_vida   ,ls_nro_doc   ,ls_flag_estado ,ld_fecha      ,ld_fecha         ,
               ld_fecha      , ls_forma_pago    ,ls_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
               ls_obs        ,'D',ln_imp_soles     ,ln_imp_soles ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;
        

    else
       -- De lo contrario obtengo el numero creado anteriormente, asi como su flag de estado
       select c.nro_doc, c.flag_estado
         into ls_nro_doc, ls_flag_estado
         from calc_doc_pagar_plla c
        where c.cod_relacion = ls_prov_SUNAT
          and c.tipo_doc     = ls_doc_vida
          and c.ano          = ani_year
          and c.mes          = ani_mes;

       -- Actualizo en la cabecera del documento los totales necesarios, solo si el documento est? activo
       if ls_flag_estado = '1' then
          update cntas_pagar cp
             set cp.importe_doc = ln_imp_soles,
                 cp.saldo_sol   = ln_imp_soles,
                 cp.saldo_dol   = Round(ln_imp_soles / ln_tasa_cambio,2),
                 cp.tasa_cambio = ln_tasa_cambio
           where cp.cod_relacion = ls_prov_SUNAT
             and cp.tipo_doc     = ls_doc_vida
             and cp.nro_doc      = ls_nro_doc;
       end if;
          
    end if;
    
    -- Si el documento sigue activo entonces simplemente reconstruyo el detalle, para ello primero lo elimino
    if ls_flag_estado = '1' and ln_count > 0 then
       delete cntas_pagar_det cpd
         where cpd.cod_relacion = ls_prov_SUNAT
           and cpd.tipo_doc     = ls_doc_vida
           and cpd.nro_doc      = ls_nro_doc;
    end if;

    -- Luego ya inserto el detalle asi de simple
    if ls_flag_estado = '1' or ln_count = 0 then
       ln_item := 1;
       For lc_reg in c_datos(ls_cnc_ess_vida) Loop
           ln_imp_soles := lc_reg.imp_soles ;

           --inserta registro detalle
           Insert Into cntas_pagar_det(
                  cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
                  cencos       ,cnta_prsp, centro_benef )
           Values(
                  ls_prov_SUNAT ,ls_doc_vida ,ls_nro_doc, ln_item,
                  'Pago de ESSALUD VIDA, Tipo Trab: ' || lc_reg.tipo_trabajador || ' - ' || lc_reg.desc_tipo_tra ,
                  1,ln_imp_soles, ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla, ls_cenbef_pago_plla ) ;
           
           ln_item := ln_item + 1;
       End Loop ;
    end if;

    --registralo en documentos de pago de planilla
    if ln_count = 0 then
       Insert Into calc_doc_pagar_plla(
             cod_origen, fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado, ano, mes)
       Values(
             asi_origen, ld_fecha,ls_prov_SUNAT,ls_doc_vida,ls_nro_doc,'1', ani_year, ani_mes);
    else
       update calc_doc_pagar_plla c
          set c.fec_proceso = ld_fecha
        where c.cod_relacion = ls_prov_SUNAT
          and c.tipo_doc     = ls_doc_vida
          and c.nro_doc      = ls_nro_doc;
    end if; 
end if;




/********************************************************************************************
*                     Genero el documento para el pago de ESSALUD
********************************************************************************************/
select sum(hc.imp_soles)
  into ln_imp_soles
  from maestro           m,
       historico_calculo hc,
       tipo_trabajador   tt
 where m.cod_trabajador     = hc.cod_trabajador     
   and m.tipo_trabajador    = tt.tipo_trabajador
   and m.cod_origen         = asi_origen       
   and hc.concep            = ls_cnc_essalud     
   and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ani_year
   and to_number(to_char(hc.fec_calc_plan, 'mm'))   = ani_mes;
   
select count(*)
  into ln_count
  from num_doc_tipo
 where tipo_doc = ls_doc_essalud;

  if ln_count = 0 then
     insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
     values(ls_doc_essalud, 1, 1);
  end if;

  select ultimo_numero 
    into ln_nro 
    from num_doc_tipo 
   where tipo_doc = ls_doc_essalud for update;

ls_obs := 'PAGO DE ESSALUD, PLANILLA PERIODO: '||to_char(ani_mes, '00') || '-' || trim(to_char(ani_year, '0000'))
        ||', Origen: ' || asi_origen ;

-- Primero Verifico si ya existe el numero
select count(*)
  into ln_count
  from calc_doc_pagar_plla c
 where c.cod_relacion = ls_prov_SUNAT
   and c.tipo_doc     = ls_doc_essalud
   and c.ano          = ani_year
   and c.mes          = ani_mes;

-- Si el contador es cero entonces construyo el nro del documento e incremento el contador
if ln_count = 0 then
   --CONSTRUIR NUMERO
   ls_nro_doc := asi_origen || lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;
   
   -- Incremento el numerador y lo actualizo
   ln_nro := ln_nro + 1 ;

   update num_doc_tipo
      set ultimo_numero = ln_nro
    where (tipo_doc = ls_doc_essalud) ;
    
   -- Flag de estado activo por defecto
   ls_flag_estado := '1';

   --inserta registro cabecera
   Insert Into cntas_pagar(
           cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
           vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
           descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
   Values(
           ls_prov_SUNAT , ls_doc_essalud   ,ls_nro_doc   ,ls_flag_estado ,ld_fecha      ,ld_fecha         ,
           ld_fecha      , ls_forma_pago    ,ls_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
           ls_obs        ,'D',ln_imp_soles     ,ln_imp_soles ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;
    

else
   -- De lo contrario obtengo el numero creado anteriormente, asi como su flag de estado
   select c.nro_doc, c.flag_estado
     into ls_nro_doc, ls_flag_estado
     from calc_doc_pagar_plla c
    where c.cod_relacion = ls_prov_SUNAT
      and c.tipo_doc     = ls_doc_essalud
      and c.ano          = ani_year
      and c.mes          = ani_mes;

   if ls_flag_estado = '1' then
      update cntas_pagar cp
         set cp.importe_doc = ln_imp_soles,
             cp.saldo_sol   = ln_imp_soles,
             cp.saldo_dol   = Round(ln_imp_soles / ln_tasa_cambio,2),
             cp.tasa_cambio = ln_tasa_cambio
       where cp.cod_relacion = ls_prov_SUNAT
         and cp.tipo_doc     = ls_doc_essalud
         and cp.nro_doc      = ls_nro_doc;
   end if;

      
end if;

-- Si el documento sigue activo entonces simplemente reconstruyo el detalle, para ello primero lo elimino
if ls_flag_estado = '1' and ln_count > 0 then
   delete cntas_pagar_det cpd
     where cpd.cod_relacion = ls_prov_SUNAT
       and cpd.tipo_doc     = ls_doc_essalud
       and cpd.nro_doc      = ls_nro_doc;
end if;

-- Luego ya inserto el detalle asi de simple
if ls_flag_estado = '1' or ln_count = 0 then
   ln_item := 1;
   For lc_reg in c_datos(ls_cnc_essalud) Loop
       ln_imp_soles := lc_reg.imp_soles ;

       --inserta registro detalle
       Insert Into cntas_pagar_det(
              cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
              cencos       ,cnta_prsp, centro_benef )
       Values(
              ls_prov_SUNAT ,ls_doc_essalud ,ls_nro_doc, ln_item,
              'Pago de ESSALUD VIDA, Tipo Trab: ' || lc_reg.tipo_trabajador || ' - ' || lc_reg.desc_tipo_tra ,
              1,ln_imp_soles, ls_cencos_pgo_plla ,ls_cnta_prsp_pgo_plla, ls_cenbef_pago_plla ) ;
       
       ln_item := ln_item + 1;
   End Loop ;
end if;

--registralo en documentos de pago de planilla
if ln_count = 0 then
   Insert Into calc_doc_pagar_plla(
         cod_origen, fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado, ano, mes)
   Values(
         asi_origen, ld_fecha,ls_prov_SUNAT,ls_doc_essalud,ls_nro_doc,'1', ani_year, ani_mes);
else
   update calc_doc_pagar_plla c
      set c.fec_proceso = ld_fecha
    where c.cod_relacion = ls_prov_SUNAT
      and c.tipo_doc     = ls_doc_essalud
      and c.nro_doc      = ls_nro_doc;
end if; 


-- Confirmo los cambios realizados
commit;
end usp_rh_gen_doc_pago_SUNAT;
/
