create or replace trigger TUA_RH_CNTA_CRRTE
  after update on cnta_crrte
  for each row
declare
  -- local variables here
  ln_existe  integer;
  ln_tipo_cambio calendario.vnt_dol_libre%type ;
  ld_fecha date ;
  lc_flag_cb     cntas_pagar.flag_caja_bancos%type ;
  lc_flag_cr     cntas_pagar.flag_control_reg%type ;
  lc_flag_estado cntas_pagar.flag_estado%type      ;
  ln_count   number ;
begin
    /***************************************************************************
         Actualiza el saldo de cuentas por cobrar y pagar
   ****************************************************************************/

select count (*) into ln_existe from Cntas_cobrar where tipo_doc = :new.tipo_doc and nro_doc  = :new.nro_doc ;


--buscar cuenta corriente detalle
select count(*) into ln_count from cnta_crrte_detalle ccd
 where (ccd.cod_trabajador = :new.cod_trabajador) and
       (ccd.tipo_doc       = :new.tipo_doc      ) and
       (ccd.nro_doc        = :new.nro_doc       );

if ln_count > 0 then
--busco tipo de cambio

select Max(ccd.fec_dscto) into ld_fecha from cnta_crrte_detalle ccd
 where (ccd.cod_trabajador = :new.cod_trabajador) and
       (ccd.tipo_doc       = :new.tipo_doc      ) and
       (ccd.nro_doc        = :new.nro_doc       );

 ln_tipo_cambio := usf_fin_tasa_cambio(ld_fecha) ;--buscar cuenta corriente detalle

  If  ln_existe = 1 Then

      select cc.flag_caja_bancos,cc.flag_control_reg, cc.flag_estado
        into lc_flag_cb,lc_flag_cr,lc_flag_estado
        from Cntas_cobrar cc
        where ((cc.tipo_doc     = :new.tipo_doc       ) and
               (cc.nro_doc      = :new.nro_doc        )) ;


      if (lc_flag_cb = '1' and lc_flag_cr = '1' ) or (lc_flag_cr = '0' and lc_flag_estado <> '0') then
         update Cntas_cobrar cc
            set   saldo_sol    = :new.sldo_prestamo  , saldo_dol = Round(:new.sldo_prestamo / ln_tipo_cambio,2)
          where ((tipo_doc     = :new.tipo_doc       ) and
                 (nro_doc      = :new.nro_doc        )) ;
      else
         raise_application_error(-20000,'Documento tiene que estar cobrado');
      end if ;

   Else
       --verificar que este pagado
       select count(*)
         into ln_count
         from cntas_pagar cp
        where cp.tipo_doc     = :new.tipo_doc
          -- and cp.cod_relacion = :new.cod_trabajador
          and cp.nro_doc      = :new.nro_doc;

       if ln_count = 0 then
          /*RAISE_APPLICATION_ERROR(-20000, 'Documento no existe en cuentas x pagar'
                                   || chr(13) || 'Tipo Doc: ' || :new.tipo_doc
                                   || chr(13) || 'Nro Doc: ' || :new.nro_doc
                                   || chr(13) || 'C.Relacion :'|| :new.cod_trabajador);

          */
          return;
       end if ;



       select cp.flag_caja_bancos,cp.flag_control_reg,cp.flag_estado
         into lc_flag_cb,lc_flag_cr,lc_flag_estado
         from cntas_pagar cp
        where cp.tipo_doc     = :new.tipo_doc
          -- and cp.cod_relacion = :new.cod_trabajador
          and cp.nro_doc      = :new.nro_doc             ;

       if (lc_flag_cb = '1' and lc_flag_cr = '1' ) or (lc_flag_cr = '0' and lc_flag_estado <> '0') then
          update Cntas_pagar
             set   saldo_sol = :new.sldo_prestamo  ,
                   saldo_dol = Round(:new.sldo_prestamo / ln_tipo_cambio,2)
           where tipo_doc     = :new.tipo_doc
             -- and cod_relacion = :new.cod_trabajador
             and nro_doc      = :new.nro_doc        ;
       else
          raise_application_error(-20000,'Documento tiene que estar pagado'
                                   || chr(13) || 'Tipo Doc: ' || :new.tipo_doc
                                   || chr(13) || 'Nro Doc: ' || :new.nro_doc
                                   || chr(13) || 'C.Relacion :'|| :new.cod_trabajador );

       end if;

    End  If;
end if ;
end TUA_RH_CNTA_CRRTE;
/
