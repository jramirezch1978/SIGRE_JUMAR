create or replace procedure usp_rh_gen_doc_pago_afp(
       asi_ttrab            in maestro.tipo_trabajador%type ,
       asi_origen           in origen.cod_origen%Type       ,
       adi_fec_proceso      in date                         ,
       asi_tipo_planilla    in calculo.tipo_planilla%TYPE   ,
       asi_cod_usr          in usuario.cod_usr%type          
) is

lc_grp_afp_jub        rrhhparam_cconcep.afp_jubilacion%type ;
lc_grp_afp_inv        rrhhparam_cconcep.afp_invalidez%type ;
lc_grp_afp_com        rrhhparam_cconcep.afp_comision%type ;
lc_forma_pago         forma_pago.forma_pago%Type            ;
lc_soles              moneda.cod_moneda%Type                ;
ln_tasa_cambio        calendario.cmp_dol_libre%type         ;
lc_cencos_pgo_plla    centros_costo.cencos%Type             ;
lc_cnta_prsp_pgo_plla presupuesto_cuenta.cnta_prsp%Type     ;
lc_nro_doc            cntas_pagar.nro_doc%Type              ;
lc_doc_afp            doc_tipo.tipo_doc%Type                ;
ln_imp_soles          calculo.imp_soles%type                ;
ln_imp_dolar          calculo.imp_soles%type                ;
ln_nro                number                                ;
lc_obs                cntas_pagar.descripcion%type          ;
ln_count              number                                ;

Cursor c_maestro_plla is
select m.cod_afp,af.cod_relacion,af.desc_afp
  from maestro   m,
       calculo   c,
       admin_afp af
 where m.cod_trabajador     = c.cod_trabajador     
   and m.cod_afp            = af.cod_afp           
   and m.cod_origen         = asi_origen            
   and m.tipo_trabajador    = asi_ttrab             
   and c.tipo_planilla      = asi_tipo_planilla
   and trunc(c.fec_proceso) = Trunc(adi_fec_proceso)
group by m.cod_afp,af.cod_relacion,af.desc_afp ;



Cursor c_pago_afp (as_cod_afp admin_afp.cod_afp%type) is
  select Sum(c.imp_soles) as imp_soles ,Sum(c.imp_dolar) as imp_dolar
    from calculo c,
         maestro m
   where c.cod_trabajador     = m.cod_trabajador     
     and m.cod_origen         = asi_origen            
     and m.tipo_trabajador    = asi_ttrab             
     and c.tipo_planilla      = asi_tipo_planilla
     and m.cod_afp            = as_cod_afp           
     and c.concep in ( (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_jub),
                        (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_inv),
                        (select gc.concepto_gen from grupo_calculo gc where gc.grupo_calculo = lc_grp_afp_com) )
     and trunc(c.fec_proceso) = Trunc(adi_fec_proceso)
  group by m.cod_afp;

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
  into lc_cencos_pgo_plla ,lc_cnta_prsp_pgo_plla,lc_doc_afp
  from rrhhparam rh 
 where rh.reckey = '1' ;

--recupero numero
select count(*)
  into ln_count
  from num_doc_tipo
 where tipo_doc = lc_doc_afp;

  if ln_count = 0 then
     insert into num_doc_tipo(tipo_doc, nro_serie, ultimo_numero)
     values(lc_doc_afp, 1, 1);
  end if;

  select ultimo_numero into ln_nro from num_doc_tipo where tipo_doc = lc_doc_afp for update;

lc_obs := 'PAGO DE AFP DE '||asi_ttrab||'-'||asi_origen||'-'||TO_CHAR(adi_fec_proceso,'dd/mm/yyyy') ;

For rc_maestro_plla in c_maestro_plla Loop
    For rc_pago_afp in c_pago_afp (rc_maestro_plla.cod_afp ) Loop
        ln_imp_soles := rc_pago_afp.imp_soles ;
        ln_imp_dolar := rc_pago_afp.imp_dolar ;

        --CONSTRUIR NUMERO
        lc_nro_doc := asi_origen||lpad(rtrim(ltrim(to_char(ln_nro))),8,'0') ;

        lc_obs := rc_maestro_plla.desc_afp ||' '||asi_ttrab||'-'||asi_origen||'-'||TO_CHAR(adi_fec_proceso,'dd/mm/yyyy') ;

        --inserta registro cabecera
        Insert Into cntas_pagar(
               cod_relacion ,tipo_doc          ,nro_doc     ,flag_estado ,fecha_registro ,fecha_emision    ,
               vencimiento  ,forma_pago        ,cod_moneda  ,tasa_cambio ,cod_usr        ,origen           ,
               descripcion  ,flag_provisionado ,importe_doc ,saldo_sol   ,saldo_dol      ,flag_control_reg )
        Values(
               rc_maestro_plla.cod_relacion ,lc_doc_afp    ,lc_nro_doc   ,'1'            ,adi_fec_proceso ,adi_fec_proceso ,
               adi_fec_proceso              ,lc_forma_pago ,lc_soles     ,ln_tasa_cambio ,asi_cod_usr     ,asi_origen      ,
               lc_obs     ,'D'       ,ln_imp_soles  ,ln_imp_soles ,Round(ln_imp_soles / ln_tasa_cambio,2),'0' ) ;

        --inserta registro detalle
        Insert Into cntas_pagar_det(
               cod_relacion ,tipo_doc ,nro_doc  ,item    ,descripcion  ,cantidad ,importe ,
               cencos       ,cnta_prsp )
        Values(
               rc_maestro_plla.cod_relacion ,lc_doc_afp ,lc_nro_doc,'1',rc_maestro_plla.desc_afp ,1,ln_imp_soles,
               lc_cencos_pgo_plla ,lc_cnta_prsp_pgo_plla ) ;

        --registralo en documentos de pago de planilla
        Insert Into calc_doc_pagar_plla(
               cod_origen,tipo_trabajador ,fec_proceso,cod_relacion ,tipo_doc ,nro_doc,flag_estado, tipo_planilla)
        Values(
               asi_origen,asi_ttrab,adi_fec_proceso,rc_maestro_plla.cod_relacion,lc_doc_afp,lc_nro_doc,'1', asi_tipo_planilla);

        ln_nro := ln_nro + 1 ;



    End Loop ;

       update num_doc_tipo
           set ultimo_numero = ln_nro
         where (tipo_doc = lc_doc_afp) ;

End Loop ;

end usp_rh_gen_doc_pago_afp;
/
