create or replace trigger TIA_FIN_CAJA_BANCOS_DET
  after insert on caja_bancos_det
  for each row
declare
  -- local variables here
  lc_flag_tiptran     caja_bancos.flag_tiptran%type  ;
  lc_cod_moneda       moneda.cod_moneda%type         ;
  ln_tasa_cambio      caja_bancos.tasa_cambio%type   ;
  lc_soles            moneda.cod_moneda%type         ;
  lc_dolares          moneda.cod_moneda%type         ;
  ln_saldo_sol        caja_bancos_det.importe%type   ;
  ln_saldo_dol        caja_bancos_det.importe%type   ;
  ln_importe_soles    caja_bancos_det.importe%type   ;
  ln_importe_dolares  caja_bancos_det.importe%type   ;
  ln_monto_sol_dif    caja_bancos_det.importe%type   ;
  ln_mont_pend_dol    caja_bancos_det.importe%type   ;
  ln_mont_pend_sol    caja_bancos_det.importe%type   ;
  ln_monto_total      caja_bancos_det.importe%type   ;
  lc_flag_estado      caja_bancos.flag_estado%type   ;
  ld_fecha_emision    caja_bancos.fecha_emision%type ;
  lc_usr              caja_bancos.cod_usr%type       ;
  lc_flag_estado_og   Char (1)                       ;
  ln_nro_registro     caja_bancos.nro_registro%type  ;
  ln_count            Number ;
  ln_count_cad        Number ;
  lc_origen           origen.cod_origen%type         ;
  lc_flag_debhab_esp  doc_pendientes_cta_cte.flag_debhab%type ;
  ln_factor_esp       doc_pendientes_cta_cte.factor%type      ;
  lc_flag_ctrl_reg    cntas_cobrar.flag_control_reg%type      ;
  lc_origen_cb        origen.cod_origen%type         ;
  ln_ano              caja_bancos.ano%type           ;
  ln_mes              caja_bancos.mes%type           ;
  ln_nro_libro        caja_bancos.nro_libro%type     ;
  ln_nro_asiento      caja_bancos.nro_asiento%type   ;
  ln_cnta_ctbl        cntbl_cnta.cnta_ctbl%type      ;
  lc_flag_caja_bancos cntas_pagar.flag_caja_bancos%type ;
  lc_obs              caja_bancos.obs%type              ;
--Variables por J. Farfán
  ln_f_pago           cntas_pagar.forma_pago%type ; --- Forma de Pago
  lc_nro_sol_cred     cntas_pagar.nro_sol_cred_rrhh%type;
  lc_concep           rrhh_credito_solicitud.concep%type ; --- concepto
  ln_nro_cuotas       rrhh_credito_solicitud.nro_cuotas%type ; ---  nro de cuotas
  ln_tasa_interes     rrhh_credito_solicitud.tasa_interes%type ; ---  tasa de interes
  ln_monto_cuota      rrhh_credito_solicitud.importe%type ; ---  tasa de interes
--  lc_forma_pago       cntas_pagar.forma_pago%type ; --- Forma de Pago

begin

--  Inicio de modificacion realizada por J. Farfán . linea 225 y linea 310 estan los cambios

--
select l.cod_soles,l.cod_dolares into lc_soles,lc_dolares 
  from logparam l where l.reckey ='1' ;

select f_pago_cnta_crte into ln_f_pago from rrhhparam where reckey='1';
--
select cb.flag_tiptran  ,cb.cod_moneda ,cb.tasa_cambio ,
       cb.fecha_emision ,cb.cod_usr    ,cb.origen      ,
       cb.ano           ,cb.mes        ,cb.nro_libro   ,
       cb.nro_asiento   ,cb.obs
  into lc_flag_tiptran  ,lc_cod_moneda ,ln_tasa_cambio ,
       ld_fecha_emision ,lc_usr        ,lc_origen_cb   ,
       ln_ano           ,ln_mes        ,ln_nro_libro   ,
       ln_nro_asiento   ,lc_obs
  from caja_bancos cb
 where (cb.origen       = :new.origen       ) and
       (cb.nro_registro = :new.nro_registro ) ;

--Cerrando documentos de control documentario
ln_count := usf_fin_cierra_control_doc(:new.cod_relacion, :new.tipo_doc, :new.nro_doc);       
--

--datos de deuda financiera
--actualizar monto 
--if :new.nro_registro_df is not null then
   --verificar datos de 
--   update deuda_financiera_det dfd
--      set dfd.monto_real   = :new.importe  ,
--          dfd.tipo_doc_ref = :new.tipo_doc ,
--          dfd.nro_doc_ref  = :new.nro_doc  ,
--          dfd.flag_estado  = '2'
--    where (dfd.nro_registro        = :new.nro_registro_df     ) and
--          (dfd.tipo_deuda_concepto = :new.tipo_deuda_concepto ) and
--          (dfd.nro_cuota           = :new.nro_cuota_df        ) ;
--end if ;




IF (lc_flag_tiptran = '2' OR lc_flag_tiptran = '3' OR lc_flag_tiptran = '4') THEN --CARTERA DE PAGOS,CARTERA DE COBROS,APLICACION DE DOCUMENTOS
    --*cuenta corriente*--------
     IF :new.flab_tabor = '1' THEN --CUENTAS COBRAR
        select cc.flag_control_reg, cc.flag_caja_bancos, cc.nro_sol_cred_rrhh
          into lc_flag_ctrl_reg, lc_flag_caja_bancos, lc_nro_sol_cred
          from cntas_cobrar cc 
         where (cc.cod_relacion = :new.cod_relacion ) and
                                  (cc.tipo_doc     = :new.tipo_doc     ) and
                                  (cc.nro_doc      = :new.nro_doc      ) ;
                                     
     ELSIF :new.flab_tabor = '3' THEN --CUENTAS POR PAGAR
     
        select cp.flag_control_reg, cp.flag_caja_bancos, cp.nro_sol_cred_rrhh
          into lc_flag_ctrl_reg, lc_flag_caja_bancos, lc_nro_sol_cred
          from cntas_pagar cp 
         where (cp.cod_relacion = :new.cod_relacion ) and
               (cp.tipo_doc     = :new.tipo_doc     ) and
               (cp.nro_doc      = :new.nro_doc      ) ;

     END IF ;
     
     -- Documentos que aún no han sido pagados (flag_caja_bancos=0)
     IF :new.flag_provisionado = 'D' AND 
        lc_flag_ctrl_reg = '1' AND 
        lc_flag_caja_bancos = '0' AND 
        (:new.flab_tabor = '1' or :new.flab_tabor = '3') THEN --DOCUMENTO TIPO CUENTA CORRIENTE
     
        if    :new.flab_tabor = '1' then--CUENTAS POR COBRAR
           --verifica que documento sea tipo cuenta corriente por cobrar
           select count(*) into ln_count from doc_grupo_relacion dg
            where (dg.grupo    = 'C1'          ) and
                  (dg.tipo_doc = :new.tipo_doc ) ;

           if ln_count = 0 then --documento no esta definido como cuenta corriente
              raise_application_error(-20000,'Documento no esta definido en grupo de cuenta corriente ');
           else
              --busco datos en documentos pendientes
              select dp.flag_debhab, dp.factor into lc_flag_debhab_esp,ln_factor_esp from doc_pendientes_cta_cte dp
               where (dp.cod_relacion = :new.cod_relacion ) and
                     (dp.tipo_doc     = :new.tipo_doc     ) and
                     (dp.nro_doc      = :new.nro_doc      ) ;

              if lc_flag_debhab_esp = 'D' then
                 lc_flag_debhab_esp := 'H' ;
              else --docuementos tiene problemas verifique datos del documento
                 raise_application_error(-20000,'Documento tiene problemas verifique datos Ingresados');
              end if ;

              if ln_factor_esp = '1' then
                 ln_factor_esp := '-1' ;
              else
                 raise_application_error(-20000,'Documento tiene problemas verifique datos Ingresados');
              end if ;
              
              select count(*) into ln_count_cad from cntbl_asiento_det cad
               where (cad.origen       = lc_origen_cb      ) and (cad.ano          = ln_ano            ) and
                     (cad.mes          = ln_mes            ) and (cad.nro_libro    = ln_nro_libro      ) and
                     (cad.nro_asiento  = ln_nro_asiento    ) and (cad.cod_relacion = :new.cod_relacion ) and
                     (cad.tipo_docref1 = :new.tipo_doc     ) and (cad.nro_docref1  = :new.nro_doc      ) ;

              if ln_count_cad > 0 then
                 --BUSCAR CUENTA CONTABLE
                 select cad.cnta_ctbl into ln_cnta_ctbl from cntbl_asiento_det cad
                  where (cad.origen       = lc_origen_cb      ) and (cad.ano          = ln_ano            ) and
                        (cad.mes          = ln_mes            ) and (cad.nro_libro    = ln_nro_libro      ) and
                        (cad.nro_asiento  = ln_nro_asiento    ) and (cad.cod_relacion = :new.cod_relacion ) and
                        (cad.tipo_docref1 = :new.tipo_doc     ) and (cad.nro_docref1  = :new.nro_doc      ) ;
              else
                 raise_application_error(-20000,'Asientos de Documento Tiene problemas ,Verifique!');
              end if ;
              
               --ACTUALIZA CNTAS POR cobrar
              update cntas_cobrar cc set cc.flag_caja_bancos = '1' ,cc.flag_replicacion ='0'
               where (cc.cod_relacion = :new.cod_relacion ) and
                     (cc.tipo_doc     = :new.tipo_doc     ) and
                     (cc.nro_doc      = :new.nro_doc      ) ;

           end if ;

        elsif :new.flab_tabor = '3' then --CUENTAS POR PAGAR
            --verifica que documento sea tipo cuenta corriente por pagar
           select count(*) into ln_count from doc_grupo_relacion dg
            where (dg.grupo    = 'C2'          ) and
                  (dg.tipo_doc = :new.tipo_doc ) ;

           if ln_count = 0 then --documento no esta definido como cuenta corriente
              raise_application_error(-20000,'Documento no esta definido en grupo de cuenta corriente ');
           else
              --busco datos en documentos pendientes
              SELECT dp.flag_debhab, dp.factor 
                INTO lc_flag_debhab_esp, ln_factor_esp 
                FROM doc_pendientes_cta_cte dp
               WHERE (dp.cod_relacion = :new.cod_relacion ) and
                     (dp.tipo_doc     = :new.tipo_doc     ) and
                     (dp.nro_doc      = :new.nro_doc      ) ;

              if lc_flag_debhab_esp = 'H' then
                 lc_flag_debhab_esp := 'D' ;
              else --docuementos tiene problemas verifique datos del documento
                 raise_application_error(-20000,'Documento tiene problemas verifique datos Ingresados '
                                                ||chr(13)||'Cod. Relacion  '||:new.cod_relacion
                                                ||chr(13)||'Tipo documento '||:new.tipo_doc 
                                                ||chr(13)||'Nro. documento '||:new.nro_doc );
              end if ;

              if ln_factor_esp = '-1' then
                 ln_factor_esp := '1' ;
              else
                 raise_application_error(-20000,'Documento tiene problemas verifique datos Ingresados...'
                                                ||chr(13)||'Cod. Relacion  '||:new.cod_relacion 
                                                ||chr(13)||'Tipo documento '||:new.tipo_doc 
                                                ||chr(13)||'Nro. documento '||:new.nro_doc ); 
              end if ;
              
              
              select count(*) into ln_count_cad from cntbl_asiento_det cad
               where (cad.origen       = lc_origen_cb      ) and (cad.ano          = ln_ano            ) and
                     (cad.mes          = ln_mes            ) and (cad.nro_libro    = ln_nro_libro      ) and
                     (cad.nro_asiento  = ln_nro_asiento    ) and (cad.cod_relacion = :new.cod_relacion ) and
                     (cad.tipo_docref1 = :new.tipo_doc     ) and (cad.nro_docref1  = :new.nro_doc      ) ;

              if ln_count_cad > 0 then
                 --BUSCAR CUENTA CONTABLE
                 select cad.cnta_ctbl into ln_cnta_ctbl from cntbl_asiento_det cad
                  where (cad.origen       = lc_origen_cb      ) and (cad.ano          = ln_ano            ) and
                        (cad.mes          = ln_mes            ) and (cad.nro_libro    = ln_nro_libro      ) and
                        (cad.nro_asiento  = ln_nro_asiento    ) and (cad.cod_relacion = :new.cod_relacion ) and
                        (cad.tipo_docref1 = :new.tipo_doc     ) and (cad.nro_docref1  = :new.nro_doc      ) ;
              else
                 raise_application_error(-20000,'Asientos de documento tiene problemas, Verifique!');
              end if ;
              
              --ACTUALIZA CNTAS POR PAGAR
              update cntas_pagar cp set cp.flag_caja_bancos = '1' ,cp.flag_replicacion ='0'
               where (cp.cod_relacion = :new.cod_relacion ) and
                     (cp.tipo_doc     = :new.tipo_doc     ) and
                     (cp.nro_doc      = :new.nro_doc      ) ;


              --CAMBIO PARA RRHH SOLICITUD DE CEDITO
              IF (lc_nro_sol_cred is not null) then
                  select concep, nro_cuotas, tasa_interes into lc_concep, ln_nro_cuotas ,ln_tasa_interes
                    from rrhh_credito_solicitud
                   where (nro_solicitud = lc_nro_sol_cred) ;

                  ln_monto_cuota := Round(:new.importe / ln_nro_cuotas,2) ;

                  --  Inserta cuenta corriente del trabajador
                  insert into cnta_crrte  ( cod_trabajador ,tipo_doc   ,nro_doc       ,fec_prestamo ,concep        ,
                                            flag_estado    ,nro_cuotas ,mont_original ,mont_cuota   ,sldo_prestamo ,
                                            cod_sit_prest  ,cod_moneda ,cod_usr       ,tasa_interes ,forma_pago )
                                  values  ( :new.cod_relacion ,:new.tipo_doc   ,:new.nro_doc ,sysdate         ,lc_concep    ,
                                            '1'               ,ln_nro_cuotas   ,:new.importe,ln_monto_cuota  ,:new.importe ,
                                            'A'               ,:new.cod_moneda ,lc_usr,ln_tasa_interes , ln_f_pago ) ;

                  --ACTUALIZA ESTADO DE SOLICTUD
                  update rrhh_credito_solicitud  set flag_estado = '5'   where (nro_solicitud = lc_nro_sol_cred) ;
             END IF ;      -- FIN NUEVO CAMBIO


           end if ;


        end if;


        --actuliza docuemnto tipo cuenta corriente en doc_pendientes
        update doc_pendientes_cta_cte dp set dp.flag_debhab = lc_flag_debhab_esp,
                                             dp.factor      = ln_factor_esp     ,
                                             dp.cnta_ctbl   = ln_cnta_ctbl      ,
                                             dp.flag_replicacion = '0'
         where (dp.cod_relacion = :new.cod_relacion ) and
               (dp.tipo_doc     = :new.tipo_doc     ) and
               (dp.nro_doc      = :new.nro_doc      ) ;

         RETURN ;

     END IF ;


    --*cuenta corriente*--------, para documento que anteriormente fueron cancelados, o son del tipo directo.



   IF (:new.flag_provisionado = 'R' OR :new.flag_provisionado = 'D' OR :new.flag_provisionado = 'O') THEN --REFERENCIA / DIRECTO / ORDEN DE GIRO ...

       IF :new.flab_tabor = '1' THEN /*Cuentas x Cobrar*/



          select Nvl(importe_doc,0),Nvl(saldo_sol,0),Nvl(saldo_dol,0),flag_caja_bancos
            into ln_monto_total,ln_saldo_sol , ln_saldo_dol ,lc_flag_caja_bancos
            from cntas_cobrar
           where (( origen       = :new.origen_doc   ) AND
                  ( cod_relacion = :new.cod_relacion ) AND
                  ( tipo_doc     = :new.tipo_doc     ) AND
                  ( nro_doc      = :new.nro_doc      ));



          if :new.cod_moneda = lc_soles THEN
             ln_importe_soles   := :new.importe ;
             ln_importe_dolares := Round(:new.importe / ln_tasa_cambio,2) ;

             --encontrar estado del documento
             ln_saldo_sol := ln_saldo_sol - ln_importe_soles ;
             ln_saldo_dol := ln_saldo_dol - ln_importe_dolares ;



             if ln_monto_total = ln_saldo_sol then --activo
                lc_flag_estado := '1';
             elsif ln_saldo_sol = 0 then           --pagado totalmente
                lc_flag_estado := '3';
             elsif ln_saldo_sol > 0 then           --pagado parcialmente
                lc_flag_estado := '2';
             end if ;

          elsif  :new.cod_moneda = lc_dolares THEN

             ln_importe_dolares := :new.importe ;
             ln_importe_soles   := Round(:new.importe * ln_tasa_cambio,2) ;

             --diferencia en cambiode documentos
             select Nvl(sldo_sol,0),Nvl(saldo_dol,0) into ln_mont_pend_sol,ln_mont_pend_dol from doc_pendientes_cta_cte
             where (cod_relacion = :new.cod_relacion ) and
                   (tipo_doc     = :new.tipo_doc     ) and
                   (nro_doc      = :new.nro_doc      ) ;





             ln_monto_sol_dif := Round(ln_mont_pend_dol * ln_tasa_cambio,2) - ln_mont_pend_sol  ;


             --encontrar estado del documento
             ln_saldo_dol := ln_saldo_dol - ln_importe_dolares ;
             ln_saldo_sol := (ln_saldo_sol + ln_monto_sol_dif) - ln_importe_soles ;

             if ln_monto_total = ln_saldo_dol then --activo
                lc_flag_estado := '1';
             elsif ln_saldo_dol = 0 then           --pagado totalmente
                lc_flag_estado := '3';
             elsif ln_saldo_dol > 0 then           --pagado parcialmente
                lc_flag_estado := '2';
             end if ;

          end if ;


          if (lc_flag_estado is null) then

             RAISE_APPLICATION_ERROR( -20000, :new.tipo_doc||' '||:new.nro_doc || ' tiene flag estado nulo, por favor verifique' 
             ||chr(13)||'Saldo soles   ' ||to_char(ln_saldo_sol)
             ||chr(13)||'Saldo dolares ' ||to_char(ln_saldo_dol) );
          end if ;

          --actualizo cntas x cobrar
          /*************************************************************************
           REPLICACION
          *************************************************************************/
           UPDATE cntas_cobrar
              SET flag_estado = lc_flag_estado ,saldo_sol = ln_saldo_sol, saldo_dol = ln_saldo_dol,flag_replicacion = '0'
            WHERE (( origen       = :new.origen_doc   ) AND
                   ( cod_relacion = :new.cod_relacion ) AND
                   ( tipo_doc     = :new.tipo_doc     ) AND
                   ( nro_doc      = :new.nro_doc      ));


           /*Actualizar Doc_Pendientes_cta_cte*/
           if lc_flag_caja_bancos = '1' THEN  --cta cte ha sido cancelada
              --buscar cta ctble de ultima transacion
              select min(cnta_ctbl) into ln_cnta_ctbl from cntbl_asiento_det
               where (cod_relacion = :new.cod_relacion ) and (tipo_docref1 = :new.tipo_doc) and
                     (nro_docref1  = :new.nro_doc      ) ;

              /*REPLICACION*/
              update doc_pendientes_cta_cte
                 set cnta_ctbl = ln_cnta_ctbl,flag_replicacion = '0'
               where (cod_relacion = :new.cod_relacion ) and
                     (tipo_doc     = :new.tipo_doc     ) and
                     (nro_doc      = :new.nro_doc      ) ;

           end if ;



       ELSIF :new.flab_tabor = '6' THEN /*Solicitud de Giro */
          SELECT flag_estado,importe_doc,Nvl(saldo_sol,0),Nvl(saldo_dol,0),nro_reg_caja_banco
            INTO lc_flag_estado_og,ln_monto_total,ln_saldo_sol , ln_saldo_dol,ln_nro_registro
            FROM solicitud_giro
           WHERE ((origen        = :new.origen_doc ) AND
                  (nro_solicitud = :new.nro_doc   )) ;

          IF lc_flag_estado_og = '2' THEN
             /**Actualiza Contador de Solicitudes Pendientes **/
             /*************************************************************************
              REPLICACION
             *************************************************************************/
             UPDATE maestro_param_autoriz
                SET nro_solicitudes_pend = Nvl(nro_solicitudes_pend,0) + 1,flag_replicacion= '0'
              WHERE (cod_relacion = :new.cod_relacion) ;

             lc_flag_estado  := '3' ;
             lc_origen       := :new.origen ;
             ln_nro_registro := :new.nro_registro ;

             /**Actualiza Estado **/
            /*************************************************************************
             REPLICACION
            *************************************************************************/
            UPDATE solicitud_giro sg
               SET sg.nro_reg_caja_banco = ln_nro_registro,
                   sg.origen_caja_banc0  = lc_origen      ,
                   sg.flag_replicacion   = '0'
            WHERE ((origen        = :new.origen_doc ) AND
                   (nro_solicitud = :new.nro_doc   )) ;

          ELSE
             lc_flag_estado  := lc_flag_estado_og ;

          END IF ;

          ln_saldo_sol := abs(ln_saldo_sol) ;
          ln_saldo_dol := abs(ln_saldo_dol) ;

          if :new.cod_moneda = lc_soles THEN
             ln_importe_soles   := :new.importe ;
             ln_importe_dolares := Round(:new.importe / ln_tasa_cambio,2) ;

             --encontrar estado del documento
             ln_saldo_sol := ln_saldo_sol - ln_importe_soles ;
             ln_saldo_dol := ln_saldo_dol - ln_importe_dolares ;

             IF ln_saldo_dol <> 0  THEN
                ln_saldo_dol := ln_saldo_dol * -1 ;
             END IF ;


          elsif  :new.cod_moneda = lc_dolares THEN
             ln_importe_dolares := :new.importe ;
             ln_importe_soles   := Round(:new.importe * ln_tasa_cambio,2) ;

             --diferencia en cambiode documentos
             select Nvl(sldo_sol,0),Nvl(saldo_dol,0) into ln_mont_pend_sol,ln_mont_pend_dol from doc_pendientes_cta_cte
              where (cod_relacion = :new.cod_relacion ) and
                    (tipo_doc     = :new.tipo_doc     ) and
                    (nro_doc      = :new.nro_doc      ) ;

             ln_monto_sol_dif := Round(ln_mont_pend_dol * ln_tasa_cambio,2) - ln_mont_pend_sol  ;


             --encontrar estado del documento
             ln_saldo_dol := ln_saldo_dol - ln_importe_dolares ;
             ln_saldo_sol := (ln_saldo_sol + ln_monto_sol_dif) - ln_importe_soles ;

             IF ln_saldo_dol <> 0  THEN
                ln_saldo_dol := ln_saldo_dol * -1 ;
             END IF ;


          end if ;


          /**Actualiza Estado **/
          /*************************************************************************
           REPLICACION
          *************************************************************************/
          UPDATE solicitud_giro
             SET flag_estado = lc_flag_estado ,saldo_sol   = ln_saldo_sol  ,
                 saldo_dol   = ln_saldo_dol   ,flag_replicacion = '0'
           WHERE ((origen        = :new.origen_doc ) AND
                  (nro_solicitud = :new.nro_doc   )) ;


       ELSIF :new.flab_tabor = '3' THEN --Cuentas por pagar

          select importe_doc,Nvl(saldo_sol,0),Nvl(saldo_dol,0),flag_caja_bancos
            into ln_monto_total,ln_saldo_sol , ln_saldo_dol ,lc_flag_caja_bancos
            from cntas_pagar
           where (( origen       = :new.origen_doc   ) AND
                  ( cod_relacion = :new.cod_relacion ) AND
                  ( tipo_doc     = :new.tipo_doc     ) AND
                  ( nro_doc      = :new.nro_doc      ));



          if :new.cod_moneda = lc_soles THEN
             ln_importe_soles   := :new.importe ;
             ln_importe_dolares := Round(:new.importe / ln_tasa_cambio,2) ;

             --encontrar estado del documento
             ln_saldo_sol := ln_saldo_sol - ln_importe_soles ;
             ln_saldo_dol := ln_saldo_dol - ln_importe_dolares ;

             if ln_monto_total = ln_saldo_sol then --activo
                lc_flag_estado := '1';
             elsif ln_saldo_sol = 0 then           --pagado totalmente
                lc_flag_estado := '3';
             elsif ln_saldo_sol > 0 then           --pagado parcialmente
                lc_flag_estado := '2';
             end if ;

          elsif  :new.cod_moneda = lc_dolares THEN
             ln_importe_dolares := :new.importe ;
             ln_importe_soles   := Round(:new.importe * ln_tasa_cambio,2) ;

             --diferencia en cambiode documentos
             SELECT COUNT(*)
               INTO ln_count
               from doc_pendientes_cta_cte
              where (cod_relacion = :new.cod_relacion ) and
                    (tipo_doc     = :new.tipo_doc     ) and
                    (nro_doc      = :new.nro_doc      ) ;
                    
             IF ln_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20000, 'Documento no esta en Cuenta Corriente'
                                     || chr(13) || 'cod_relacion:' || :new.cod_relacion 
                                     || chr(13) || 'tipo_doc:' || :new.tipo_doc     
                                     || chr(13) || 'nro_doc:' ||:new.nro_doc      );
             END IF;
               
             select Nvl(sldo_sol,0),Nvl(saldo_dol,0) 
               into ln_mont_pend_sol,ln_mont_pend_dol 
               from doc_pendientes_cta_cte
              where (cod_relacion = :new.cod_relacion ) and
                    (tipo_doc     = :new.tipo_doc     ) and
                    (nro_doc      = :new.nro_doc      ) ;

             ln_monto_sol_dif := Round(ln_mont_pend_dol * ln_tasa_cambio,2) - ln_mont_pend_sol  ;


             --encontrar estado del documento
             ln_saldo_dol := ln_saldo_dol - ln_importe_dolares ;
             ln_saldo_sol := (ln_saldo_sol + ln_monto_sol_dif) - ln_importe_soles ;

             if ln_monto_total = ln_saldo_dol then --activo
                lc_flag_estado := '1';
             elsif ln_saldo_dol = 0 then           --pagado totalmente
                lc_flag_estado := '3';
             elsif ln_saldo_dol > 0 then           --pagado parcialmente
                lc_flag_estado := '2';
             end if ;

          end if ;

          /*************************************************************************
           REPLICACION
          *************************************************************************/
          --actualizo cntas x pagar
           UPDATE cntas_pagar
              SET flag_estado = lc_flag_estado ,saldo_sol        = ln_saldo_sol ,
                  saldo_dol   = ln_saldo_dol   ,flag_replicacion = '0'
            WHERE (( origen       = :new.origen_doc   ) AND
                   ( cod_relacion = :new.cod_relacion ) AND
                   ( tipo_doc     = :new.tipo_doc     ) AND
                   ( nro_doc      = :new.nro_doc      ));



           /*Actualizar Doc_Pendientes_cta_cte*/
           if lc_flag_caja_bancos = '1' THEN  --cta cte ha sido cancelada
              --buscar cta ctble de ultima transacion
              select min(cnta_ctbl) into ln_cnta_ctbl from cntbl_asiento_det
               where (cod_relacion = :new.cod_relacion ) and (tipo_docref1 = :new.tipo_doc) and
                     (nro_docref1  = :new.nro_doc      ) ;

              /*REPLICACION*/
              update doc_pendientes_cta_cte
                 set cnta_ctbl = ln_cnta_ctbl, flag_replicacion = '0'
               where (cod_relacion = :new.cod_relacion ) and
                     (tipo_doc     = :new.tipo_doc     ) and
                     (nro_doc      = :new.nro_doc      ) ;

           end if ;




       END IF ;
   ELSIF (:new.flag_provisionado = 'N' AND lc_flag_tiptran = '2' )   THEN
--INDIRECTO...CARTERA DE PAGOS
      /*************************************************************************
           REPLICACION
      *************************************************************************/
      insert into cntas_pagar --se ingresa cancelado totalmente
      (cod_relacion     ,tipo_doc         ,nro_doc      ,
       flag_estado      ,fecha_registro   ,fecha_emision,
       vencimiento      ,cod_moneda       ,tasa_cambio  ,
       cod_usr          ,origen           ,descripcion  ,
       flag_provisionado,importe_doc      ,saldo_sol    ,
       saldo_dol        ,flag_replicacion)
      values
      (:new.cod_relacion     ,:new.tipo_doc  ,:new.nro_doc       ,
       '3'                   ,ld_fecha_emision,ld_fecha_emision   ,
       ld_fecha_emision      ,:new.cod_moneda,ln_tasa_cambio     ,
       lc_usr                ,:new.origen_doc,lc_obs             ,
       :new.flag_provisionado,:new.importe   ,0.00               ,
       0.00                  ,'0');

      --afectacion presupuestal
      /*************************************************************************
           REPLICACION
      *************************************************************************/
      insert into cntas_pagar_det --se ingresa cancelado totalmente
      (cod_relacion ,tipo_doc    ,nro_doc ,
       item         ,descripcion ,cod_art ,
       confin       ,cantidad    ,importe ,
       cencos       ,cnta_prsp   ,flag_replicacion ,
       centro_benef)
      values
      (:new.cod_relacion ,:new.tipo_doc    ,:new.nro_doc  ,
       1                 ,lc_obs           ,null          ,
       null              ,1                ,:new.importe  ,
       :new.cencos       ,:new.cnta_prsp   ,'0'           ,
       :new.centro_benef);

   ELSIF (:new.flag_provisionado = 'N' AND lc_flag_tiptran = '3' )   THEN
--INDIRECTO...CARTERA DE COBROS
      /*************************************************************************
           REPLICACION
      *************************************************************************/
      Insert Into cntas_cobrar  --se ingresa cancelado totalmente
      (tipo_doc          ,nro_doc       ,cod_relacion    ,
       flag_estado       ,fecha_registro,fecha_documento ,
       fecha_vencimiento ,cod_moneda    ,tasa_cambio     ,
       cod_usr           ,origen        ,observacion     ,
       flag_provisionado ,importe_doc   ,saldo_sol       ,
       saldo_dol         ,flag_replicacion)
      Values
      (:new.tipo_doc         ,:new.nro_doc     ,:new.cod_relacion  ,
       '3'                   ,ld_fecha_emision ,ld_fecha_emision   ,
       ld_fecha_emision      ,:new.cod_moneda  ,ln_tasa_cambio     ,
       lc_usr                ,:new.origen_doc  ,substr(lc_obs,1,40),
       :new.flag_provisionado,:new.importe     ,0.00               ,
       0.00                  ,'0');

      -- detalle
      /*************************************************************************
           REPLICACION
      *************************************************************************/

      Insert Into cntas_cobrar_det
      (tipo_doc    ,nro_doc  ,item ,
       descripcion ,cantidad ,precio_unitario,
       flag_replicacion,centro_benef )
      Values
      (:new.tipo_doc     ,:new.nro_doc , 1           ,
       lc_obs            ,1            ,:new.importe ,
       '0'               ,:new.centro_benef);

   END IF;
END IF ;

end TIA_FIN_CAJA_BANCOS_DET;
/
