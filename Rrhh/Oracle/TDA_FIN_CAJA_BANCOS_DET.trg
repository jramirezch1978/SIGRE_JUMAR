create or replace trigger TDA_FIN_CAJA_BANCOS_DET
  after delete on caja_bancos_det
  for each row
declare

-- local variables here
lc_flag_tiptran     caja_bancos.flag_tiptran%type ;
ln_tcambio          caja_bancos.tasa_cambio%type  ;
lc_origen           caja_bancos.origen%type       ;
ln_ano              caja_bancos.ano%type          ;
ln_mes              caja_bancos.mes%type          ;
ln_nro_libro        caja_bancos.nro_libro%type    ;
ln_nro_asiento      caja_bancos.nro_asiento%type  ;
ln_monto_total      caja_bancos.imp_total%type    ;
ln_saldo_sol        caja_bancos.imp_total%type    ;
ln_saldo_dol        caja_bancos.imp_total%type    ;
ln_imp_dol_old      caja_bancos.imp_total%type    ;
ln_imp_sol_old      caja_bancos.imp_total%type    ;
ln_saldo_sol_old    caja_bancos.imp_total%type    ;
ln_saldo_dol_old    caja_bancos.imp_total%type    ;
ln_tcambio_old      caja_bancos.tasa_cambio%type  ;
lc_soles            moneda.cod_moneda%type        ;
lc_dolares          moneda.cod_moneda%type        ;
lc_flag_estado      caja_bancos.flag_estado%type  ;
lc_flag_estado_og   caja_bancos.flag_estado%type  ;
ln_count            number                        ;
lc_flag_debhab_esp  doc_pendientes_cta_cte.flag_debhab%type   ;
ln_factor_esp       doc_pendientes_cta_cte.factor%type        ;
lc_flag_ctrl_reg    cntas_cobrar.flag_control_reg%type        ;
lc_flag_caja_bancos cntas_pagar.flag_caja_bancos%type         ;
lc_cnta_ctbl        doc_pendientes_cta_cte.cnta_ctbl%type     ;
lc_cta_ctbl_gan     doc_pendientes_cta_cte.cnta_ctbl%type     ;
lc_cta_ctbl_per     doc_pendientes_cta_cte.cnta_ctbl%type     ;
lc_nro_sol_cred     rrhh_credito_solicitud.nro_solicitud%type ;
ln_existe_cnta_crrte integer                                  ;
lb_control          Boolean ;

--  Inicio de modificacion realizada por JORGE. FARFAN LINEA 486

begin

/*******************************************************
 REPLICACION
********************************************************/
IF ORA_LOGIN_USER = 'REPP5' THEN
   RETURN ;
END IF;

--tabla de parametros
select l.cod_soles, l.cod_dolares 
  into lc_soles,lc_dolares 
  from logparam l 
 where l.reckey = '1';
 
--cabecera de caja bancos
select cb.flag_tiptran ,cb.tasa_cambio, cb.origen       ,cb.ano        ,
       cb.mes          ,cb.nro_libro  , cb.nro_asiento
  into lc_flag_tiptran ,ln_tcambio  ,lc_origen       ,ln_ano      ,
       ln_mes          ,ln_nro_libro ,ln_nro_asiento
  from caja_bancos cb
 where (cb.origen       = :old.origen       ) and  (cb.nro_registro = :old.nro_registro ) ;


 

 
--INICIALIZACION DE VARIABLES
lb_control := FALSE ;

IF  (lc_flag_tiptran = '2' OR lc_flag_tiptran = '3' OR lc_flag_tiptran = '4') THEN
    --CARTERA DE PAGOS , CARTERA DE COBROS ,APLICACION DE DOCUEMNTOS

    if :old.flab_tabor = '1' then --cuentas por cobrar
       select cc.flag_estado, cc.flag_caja_bancos, cc.flag_control_reg, cc.nro_sol_cred_rrhh
         into lc_flag_estado, lc_flag_caja_bancos, lc_flag_ctrl_reg, lc_nro_sol_cred
         from cntas_cobrar cc
        where (cc.cod_relacion = :old.cod_relacion ) and
              (cc.tipo_doc     = :old.tipo_doc     ) and
              (cc.nro_doc      = :old.nro_doc      ) ;

       /*verificaicon de asignación en grupo de doc tipo cta cte*/
       select count(*) into ln_count from doc_grupo_relacion dg where (dg.grupo    = 'C1'          ) and
                                                                      (dg.tipo_doc = :old.tipo_doc ) ;

    elsif :old.flab_tabor = '3' then --cuentas por pagar
        select cp.flag_estado,cp.flag_caja_bancos,cp.flag_control_reg,cp.nro_sol_cred_rrhh
          into lc_flag_estado,lc_flag_caja_bancos,lc_flag_ctrl_reg,lc_nro_sol_cred
          from cntas_pagar cp
         where (cp.cod_relacion = :old.cod_relacion ) and
               (cp.tipo_doc     = :old.tipo_doc     ) and
               (cp.nro_doc      = :old.nro_doc      ) ;

        /*verificaicon de asignación en grupo de doc tipo cta cte*/
        select count(*) 
          into ln_count 
          from doc_grupo_relacion dg 
         where (trim(dg.grupo)  = 'C2') and (dg.tipo_doc =:old.tipo_doc );

    end if ;


    if lc_flag_ctrl_reg = '1' and lc_flag_caja_bancos = '1' then --documento por cobrar verifico si es cuenta corriente
       if ln_count = 0 then
          raise_application_error(-20000,'Verifique Documento '||:old.tipo_doc||' no esta Considerado en Grupo de Cta Cte') ;
       end if ;
   


       if lc_flag_tiptran = '2' or lc_flag_tiptran = '4' then --cartera de pagos y aplicacion de documentos
          if :old.factor = -1  and :old.flab_tabor = '1' then --primer cobro de cntas cobrar
             --datos de cta cte
             USP_FIN_DATOS_PEND_CTA_CTE(:old.cod_relacion,:old.tipo_doc,:old.nro_doc,lc_flag_debhab_esp,ln_factor_esp);
             
             if lc_flag_debhab_esp = 'H' then
               lc_flag_debhab_esp := 'D' ;
             else
               --verifique flag_debhab de documento
               raise_application_error(-20000,'Verifque Flag Deb_Haber del documento ...'||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
             end if ;

             if ln_factor_esp = '-1' then
                ln_factor_esp := '1' ;
             else
                --verifique factor del documento
                raise_application_error(-20000,'Verifque Flag Deb_Haber del documento .... '||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
             end if ;

             --enciende control de cta cte
             lb_control := TRUE ;

          elsif :old.factor = 1  and :old.flab_tabor = '3' then --primer pago de cntas pagar
             --datos de cta cte   
             USP_FIN_DATOS_PEND_CTA_CTE(:old.cod_relacion,:old.tipo_doc,:old.nro_doc,lc_flag_debhab_esp,ln_factor_esp);   
             
             if lc_flag_debhab_esp = 'D' then
                lc_flag_debhab_esp := 'H' ;
             else
               --verifique flag_debhab de documento
               raise_application_error(-20000,'Verifque Flag Deb_Haber del documento .'||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
             end if ;
             
              
             
             if ln_factor_esp = 1 then
                ln_factor_esp := -1 ;
             else
                --verifique factor del documento
                raise_application_error(-20000,'Verifque Factor del documento '||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
             end if ;
             
             
                   
               
             --enciende control de cta cte
             lb_control := TRUE ;
             
          end if ;
          
        elsif lc_flag_tiptran = '3' then --cartera de cobros
        
           if :old.factor = 1  and :old.flab_tabor = '1' then --primer cobro de cntas cobrar
             --datos de cta cte   
             USP_FIN_DATOS_PEND_CTA_CTE(:old.cod_relacion, :old.tipo_doc, :old.nro_doc, lc_flag_debhab_esp, ln_factor_esp);   
             
              if lc_flag_debhab_esp = 'H' then
                 lc_flag_debhab_esp := 'D' ;
              else
                 --verifique flag_debhab de documento
                 raise_application_error(-20000,'Verifque Flag Deb_Haber del documento '||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
              end if ;
              
              
             if ln_factor_esp = '-1' then
                ln_factor_esp := '1' ;
             else
                --verifique factor del documento
                raise_application_error(-20000,'Verifque Flag Deb_Haber del documento '||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
             end if ;
             
             --enciende control de cta cte
             lb_control := TRUE ;
             
             
          elsif :old.factor = -1  and :old.flab_tabor = '3' then --primer pago de cntas pagar
          
             --datos de cta cte   
             USP_FIN_DATOS_PEND_CTA_CTE(:old.cod_relacion, :old.tipo_doc, :old.nro_doc, lc_flag_debhab_esp, ln_factor_esp);   
          
             if lc_flag_debhab_esp = 'D' then
                lc_flag_debhab_esp := 'H' ;
             else
               --verifique flag_debhab de documento
               raise_application_error(-20000,'Verifque Flag Deb_Haber del documento '||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
             end if ;
             
             
             if ln_factor_esp = '1' then
                ln_factor_esp := '-1' ;
             else
                --verifique factor del documento
                raise_application_error(-20000,'Verifque Flag Deb_Haber del documento '||:old.cod_relacion ||' '||:old.tipo_doc||' '||:old.nro_doc);
             end if ;

             --enciende control de cta cte
             lb_control := TRUE ;

          end if ;
        end if ;
        
        -- No permite 
        IF lb_control = TRUE THEN
           if lc_flag_estado <> '1' then
              raise_application_error(-20000, 'Verifique Documento: '||
                                      chr(13)||'Codigo de relación: '||:old.cod_relacion||
                                      chr(13)||'Tipo documento: '||:old.tipo_doc||
                                      chr(13)||'Nro documento: '||:old.nro_doc ||', ya ha sido aplicado') ;            
           end if ;
        
           if :old.flab_tabor = '3' then --ACTUALIZA CUENTAS POR PAGAR
              If (lc_nro_sol_cred is not null) OR trim(lc_nro_sol_cred) <> '' then
                 select count(*) into ln_existe_cnta_crrte from cnta_crrte_detalle
                  where ((cod_trabajador = :old.cod_relacion ) and (tipo_doc = :old.tipo_doc) and
                         (nro_doc        = :old.nro_doc      ));

                 If ln_existe_cnta_crrte > 0 then
                    Raise_application_error(-20001, ' No se Puede eliminar el  Registro '||:old.nro_registro||'  porque ya se realizo el descuento al Trabajador');
                 else
                    delete from cnta_crrte
                     where ((cod_trabajador = :old.cod_relacion ) and (tipo_doc = :old.tipo_doc) and
                            (nro_doc        = :old.nro_doc      ));

                    update rrhh_credito_solicitud set flag_estado = '4'
                     where (nro_solicitud = lc_nro_sol_cred);
                 End If;
              End If;

              ----------------
              update cntas_pagar cp 
                 set cp.flag_caja_bancos = '0' ,cp.flag_replicacion ='1'
               where (cp.cod_relacion = :old.cod_relacion ) and
                     (cp.tipo_doc     = :old.tipo_doc     ) and
                     (cp.nro_doc      = :old.nro_doc      ) ;
           elsif :old.flab_tabor = '1' then
              update cntas_cobrar cc 
                 set cc.flag_caja_bancos = '0' ,cc.flag_replicacion ='1'
               where (cc.cod_relacion = :old.cod_relacion ) and
                     (cc.tipo_doc     = :old.tipo_doc     ) and
                     (cc.nro_doc      = :old.nro_doc      ) ;

           end if ;

           update doc_pendientes_cta_cte dp 
              set dp.flag_debhab = lc_flag_debhab_esp ,
                  dp.factor      = ln_factor_esp      ,
                  dp.cnta_ctbl   = null               ,
                  dp.flag_replicacion = '1'
            where (dp.cod_relacion = :old.cod_relacion ) and
                  (dp.tipo_doc     = :old.tipo_doc     ) and
                  (dp.nro_doc      = :old.nro_doc      ) ;


           RETURN ;

        END IF ;

    end if ;




    lc_flag_estado := null ;






    IF (:old.flag_provisionado = 'R' OR :old.flag_provisionado = 'D' OR :old.flag_provisionado= 'O') THEN --REFERENCIA / DIRECTO...



        if :old.flab_tabor = '1' then  /*Cuentas x Cobrar*/
           select NVL(importe_doc,0),Nvl(saldo_sol,0),Nvl(saldo_dol,0),flag_caja_bancos
             into ln_monto_total,ln_saldo_sol,ln_saldo_dol,lc_flag_caja_bancos
             from cntas_cobrar
            where (( origen       = :old.origen_doc   ) AND
                   ( cod_relacion = :old.cod_relacion ) AND
                   ( tipo_doc     = :old.tipo_doc     ) AND
                   ( nro_doc      = :old.nro_doc      ));

           ln_imp_dol_old := ln_saldo_dol ;
           ln_imp_sol_old := ln_saldo_sol ;

           --hallar t.cambio old
           select tasa_cambio into ln_tcambio_old from tt_fin_tasa_cambio_cb
            where (origen       = :old.origen      ) and
                  (nro_registro = :old.nro_registro ) ;


             if :old.cod_moneda = lc_soles then
                ln_saldo_sol := (ln_saldo_sol + Nvl(:old.importe,0)) ;
                ln_saldo_dol := (ln_saldo_dol  + Round(Nvl(:old.importe,0) /ln_tcambio_old,2))  ;

                if ln_saldo_sol = 0 then --cobrado totalmente
                   lc_flag_estado := '3' ;
                elsif ln_monto_total = ln_saldo_sol then --generado
                   lc_flag_estado := '1';
                elsif ln_saldo_sol > 0 then    --cobrado parcialmente
                   lc_flag_estado := '2';
                else
                   RAISE_APPLICATION_ERROR( -20000,:old.nro_doc||' '||:old.tipo_doc)  ;
                end if ;

             elsif :old.cod_moneda = lc_dolares then
                --monto anterior a transación x diferencia en cambio
                usp_fin_monto_asiento_x_doc(lc_origen,ln_ano,ln_mes,ln_nro_libro,ln_nro_asiento,:old.cod_relacion,:old.tipo_doc,:old.nro_doc,ln_saldo_sol_old,ln_saldo_dol_old);

                ln_saldo_sol_old := Nvl(ln_saldo_sol_old,0) + Nvl(ln_imp_sol_old,0) ;
                ln_saldo_dol_old := Nvl(ln_saldo_dol_old,0) + Nvl(ln_imp_dol_old,0) ;

                ln_saldo_sol_old := Round(ln_saldo_dol_old * ln_tcambio_old,2) -ln_saldo_sol_old ;

                ---termina diferencia en cambio
                ln_saldo_dol := ((ln_saldo_dol + Nvl(:old.importe,0)) )  ;
                ln_saldo_sol := (ln_saldo_sol  + (Round(Nvl(:old.importe,0) * ln_tcambio_old,2) - ln_saldo_sol_old) ) ;

                if ln_saldo_dol = 0 then --pagado totalmente
                   lc_flag_estado := '3' ;
                elsif ln_monto_total = ln_saldo_dol then --generado
                   lc_flag_estado := '1';
                elsif ln_saldo_dol > 0 then    --pagado parcialmente
                   lc_flag_estado := '2';
                end if ;

             end if ;

             /**/
             /**************************************************************************
              REPLICACION (replicar informacion)
             ***************************************************************************/



             UPDATE cntas_cobrar
                SET flag_estado = lc_flag_estado , saldo_sol = ln_saldo_sol,saldo_dol =ln_saldo_dol,flag_replicacion = '1'
              WHERE (( origen       = :old.origen_doc   ) AND
                     ( cod_relacion = :old.cod_relacion ) AND
                     ( tipo_doc     = :old.tipo_doc     ) AND
                     ( nro_doc      = :old.nro_doc      ));


           /*Actualizar Doc_Pendientes_cta_cte*/
           if lc_flag_caja_bancos = '1' THEN  --cta cte ha sido cancelada
              --buscar cta ctble de ultima transacion
              select min(cnta_ctbl) into lc_cnta_ctbl from cntbl_asiento_det
               where (cod_relacion = :old.cod_relacion ) and (tipo_docref1 = :old.tipo_doc) and
                     (nro_docref1  = :old.nro_doc      ) ;

              /*REPLICACION*/
              update doc_pendientes_cta_cte
                 set cnta_ctbl = lc_cnta_ctbl,flag_replicacion = '1'
               where (cod_relacion = :old.cod_relacion ) and
                     (tipo_doc     = :old.tipo_doc     ) and
                     (nro_doc       = :old.nro_doc     ) ;

           end if ;


        elsif :old.flab_tabor = '6' then  /*Solicitud de Giro*/


           select importe_doc,Nvl(saldo_sol,0),Nvl(saldo_dol,0),flag_estado
             into ln_monto_total,ln_saldo_sol,ln_saldo_dol,lc_flag_estado_og
             from solicitud_giro
            where (( origen        = :old.origen_doc ) AND
                   ( nro_solicitud = :old.nro_doc    ));



           --contador de og..
           if lc_flag_estado_og = '3' then --pagada
              lc_flag_estado := '2' ;--aprobada

              /**Actualiza Contador de Solicitudes Pendientes **/
             /**************************************************************************
              REPLICACION (replicar informacion)
             ***************************************************************************/


              UPDATE maestro_param_autoriz
                 SET nro_solicitudes_pend = Nvl(nro_solicitudes_pend,0) - 1,flag_replicacion= '1'
               WHERE (cod_relacion = :old.cod_relacion) ;

              --

             /**Actualiza Estado **/
             /**************************************************************************
              REPLICACION (replicar informacion)
             ***************************************************************************/
             UPDATE solicitud_giro sg
                SET sg.nro_reg_caja_banco = null,
                    sg.origen_caja_banc0  = null,
                    sg.flag_replicacion   = '1'
             WHERE ((origen        = :old.origen_doc ) AND
                    (nro_solicitud = :old.nro_doc   )) ;

           else
              lc_flag_estado := lc_flag_estado_og ;--mantener estado
           end if ;


           ln_imp_dol_old := ln_saldo_dol ;
           ln_imp_sol_old := ln_saldo_sol ;


           --hallar t.cambio old
           select tasa_cambio into ln_tcambio_old from tt_fin_tasa_cambio_cb
            where (origen       = :old.origen       ) and
                  (nro_registro = :old.nro_registro ) ;


          ln_saldo_sol := abs(ln_saldo_sol) ;
          ln_saldo_dol := abs(ln_saldo_dol) ;



           if :old.cod_moneda = lc_soles then
              ln_saldo_sol := (ln_saldo_sol + Nvl(:old.importe,0)) ;
              ln_saldo_dol := (ln_saldo_dol + Round(Nvl(:old.importe,0) / ln_tcambio_old,2));

           elsif :old.cod_moneda = lc_dolares then
              --monto anterior a transación x diferencia en cambio
              usp_fin_monto_asiento_x_doc(lc_origen,ln_ano,ln_mes,ln_nro_libro,ln_nro_asiento,:old.cod_relacion,:old.tipo_doc,:old.nro_doc,ln_saldo_sol_old,ln_saldo_dol_old);

              ln_saldo_sol_old := Nvl(ln_saldo_sol_old,0) + Nvl(ln_imp_sol_old,0) ;
              ln_saldo_dol_old := Nvl(ln_saldo_dol_old,0) + Nvl(ln_imp_dol_old,0) ;

              ln_saldo_sol_old := Round(ln_saldo_dol_old * ln_tcambio_old,2)-ln_saldo_sol_old ;
              ---termina diferencia en cambio
              ln_saldo_dol := ((ln_saldo_dol + Nvl(:old.importe,0)) )  ;
              ln_saldo_sol := (ln_saldo_sol  + (Round(Nvl(:old.importe,0) * ln_tcambio_old,2)- ln_saldo_sol_old) ) ;

           end if ;

           --revertir devolucion
           if lc_flag_estado = '5' then
              --parametros
              select cnta_ctbl_liq_HABER ,cnta_ctbl_liq_debe
                into lc_cta_ctbl_gan,lc_cta_ctbl_per
                from finparam where reckey = '1' ;
              --
              select count(*) into ln_count from solicitud_giro_liq_det where nro_solicitud= :old.nro_doc ;




              if ln_count = 0 then
                 ln_saldo_dol := ln_saldo_dol * -1 ;
                 ln_saldo_sol := ln_saldo_sol * -1 ;
              else--revertir devoluciones o excedencia
                 --
                 select Count(*) into ln_count from cntbl_asiento_det cad
                   where (TRIM(cad.cod_relacion) = TRIM(:old.cod_relacion) ) and
                         (TRIM(cad.tipo_docref1) = TRIM(:old.tipo_doc)     ) and
                         (TRIM(cad.nro_docref1)  = TRIM(:old.nro_doc)      ) and
                         (TRIM(cad.cnta_ctbl)    = TRIM(lc_cta_ctbl_gan)   ) and
                         (cad.origen||trim(to_char(cad.ano))||trim(to_char(cad.mes))||trim(to_char(cad.nro_libro))||trim(to_char(cad.nro_asiento)))= (select sg.cnt_origen||trim(to_char(sg.ano))||trim(to_char(sg.mes))||trim(to_char(sg.nro_libro))||trim(to_char(sg.nro_asiento))
                                                                                                                                                        from solicitud_giro sg
                                                                                                                                                       where sg.nro_solicitud = :old.nro_doc  ) ;

--

                 IF ln_count > 0 THEN
                    ln_saldo_dol := ABS(ln_saldo_dol) * 1 ;
                    ln_saldo_sol := ABS(ln_saldo_sol) * 1 ;
                 ELSE
                    select Count(*) into ln_count from cntbl_asiento_det cad
                     where (cad.cod_relacion = :old.cod_relacion ) and
                           (cad.tipo_docref1 = :old.tipo_doc     ) and
                           (cad.nro_docref1  = :old.nro_doc      ) and
                           (cad.cnta_ctbl    = lc_cta_ctbl_per   ) and
                           (cad.origen||trim(to_char(cad.ano))||trim(to_char(cad.mes))||trim(to_char(cad.nro_libro))||trim(to_char(cad.nro_asiento)))= (select sg.cnt_origen||trim(to_char(sg.ano))||trim(to_char(sg.mes))||trim(to_char(sg.nro_libro))||trim(to_char(sg.nro_asiento))
                                                                                                                                                          from solicitud_giro sg
                                                                                                                                                         where sg.nro_solicitud = :old.nro_doc  ) ;


                    IF ln_count > 0 THEN
                       ln_saldo_dol := ABS(ln_saldo_dol) * -1 ;
                       ln_saldo_sol := ABS(ln_saldo_sol) * -1 ;
                    END IF ;
                 END IF;

--                 RAISE_APPLICATION_ERROR(-20000,to_char(ln_count)||' '||TO_CHAR(ln_saldo_dol));

              end if;

           end if ;
           /**/
           /**************************************************************************
              REPLICACION (replicar informacion)
            ***************************************************************************/
           UPDATE solicitud_giro
              SET saldo_sol = ln_saldo_sol,saldo_dol = ln_saldo_dol,flag_estado=lc_flag_estado,
                  flag_replicacion = '1'
            WHERE ((origen        = :old.origen_doc ) AND
                   (nro_solicitud = :old.nro_doc    )) ;

        elsif :old.flab_tabor = '3' then  /*Cuentas x Pagar*/



           select cp.importe_doc,Nvl(cp.saldo_sol,0),Nvl(cp.saldo_dol,0),cp.flag_caja_bancos
             into ln_monto_total,ln_saldo_sol,ln_saldo_dol,lc_flag_caja_bancos
             from cntas_pagar cp,doc_tipo dt
            where  ( cp.tipo_doc     = dt.tipo_doc       ) AND
                  (( cp.origen       = :old.origen_doc   ) AND
                   ( cp.cod_relacion = :old.cod_relacion ) AND
                   ( cp.tipo_doc     = :old.tipo_doc     ) AND
                   ( cp.nro_doc      = :old.nro_doc      ));

           ln_imp_dol_old := ln_saldo_dol ;
           ln_imp_sol_old := ln_saldo_sol ;


           --hallar t.cambio old
           select tasa_cambio into ln_tcambio_old from tt_fin_tasa_cambio_cb
            where (origen       = :old.origen       ) and
                  (nro_registro = :old.nro_registro ) ;



           if :old.cod_moneda = lc_soles then
              ln_saldo_sol := (ln_saldo_sol + Nvl(:old.importe,0)) ;
              ln_saldo_dol := (ln_saldo_dol  + Round(Nvl(:old.importe,0) / ln_tcambio_old,2)
)
;

              if ln_saldo_sol = 0 then --pagado totalmente
                 lc_flag_estado := '3' ;
              elsif ln_monto_total = ln_saldo_sol then --generado
                 lc_flag_estado := '1';
              elsif ln_saldo_sol > 0 then    --pagado parcialmente
                 lc_flag_estado := '2';
              end if ;

           elsif :old.cod_moneda = lc_dolares then
              --monto anterior a transación x diferencia en cambio
              usp_fin_monto_asiento_x_doc(lc_origen, ln_ano, ln_mes, ln_nro_libro,
                                          ln_nro_asiento, :old.cod_relacion, :old.tipo_doc,
                                          :old.nro_doc, ln_saldo_sol_old, ln_saldo_dol_old);

              ln_saldo_sol_old := Nvl(ln_saldo_sol_old,0) + Nvl(ln_imp_sol_old,0) ;
              ln_saldo_dol_old := Nvl(ln_saldo_dol_old,0) + Nvl(ln_imp_dol_old,0) ;

              ln_saldo_sol_old := Round(ln_saldo_dol_old * ln_tcambio_old,2) - ln_saldo_sol_old ;
              ---termina diferencia en cambio
              ln_saldo_dol := ((ln_saldo_dol + Nvl(:old.importe,0)) )  ;
              ln_saldo_sol := (ln_saldo_sol  + (Round(Nvl(:old.importe,0) * ln_tcambio_old,2 ) - ln_saldo_sol_old) ) ;

              if ln_saldo_dol = 0 then --pagado totalmente
                 lc_flag_estado := '3' ;
              elsif ln_monto_total = ln_saldo_dol then --generado
                 lc_flag_estado := '1';
              elsif ln_saldo_dol > 0 then    --pagado parcialmente
                 lc_flag_estado := '2';
              end if ;

           end if ;
           /**/
           /***************************************************************************
              REPLICACION (replicar informacion)
            ***************************************************************************/
           UPDATE cntas_pagar
              SET flag_estado = lc_flag_estado , saldo_sol = ln_saldo_sol,saldo_dol = ln_saldo_dol,
                  flag_replicacion = '1'
            WHERE (( origen       = :old.origen_doc   ) AND
                   ( cod_relacion = :old.cod_relacion ) AND
                   ( tipo_doc     = :old.tipo_doc     ) AND
                   ( nro_doc      = :old.nro_doc      ));

           /*Actualizar Doc_Pendientes_cta_cte*/
           if lc_flag_caja_bancos = '1' THEN  --cta cte ha sido cancelada
              --buscar cta ctble de ultima transacion
              select min(cnta_ctbl) into lc_cnta_ctbl from cntbl_asiento_det
               where (cod_relacion = :old.cod_relacion ) and (tipo_docref1 = :old.tipo_doc) and
                     (nro_docref1  = :old.nro_doc      ) ;

              /*REPLICACION*/
              update doc_pendientes_cta_cte
                 set cnta_ctbl = lc_cnta_ctbl,flag_replicacion = '1'
               where (cod_relacion = :old.cod_relacion ) and
                     (tipo_doc     = :old.tipo_doc     ) and
                     (nro_doc       = :old.nro_doc     ) ;

           end if ;

        END IF ;

     ELSIF (:old.flag_provisionado = 'N' AND lc_flag_tiptran = '2') THEN   --INDIRECTO/CARTERA DE PAGOS
        --ELIMINAR DE CNTAS PAGAR DETALLE
        delete from cntas_pagar_det where ((cod_relacion = :old.cod_relacion ) and
                                           (tipo_doc     = :old.tipo_doc     ) and
                                           (nro_doc      = :old.nro_doc      )) ;

        --ELIMINAR DE CNTAS PAGAR CABECERA
        delete from cntas_pagar where ((cod_relacion = :old.cod_relacion ) and
                                       (tipo_doc     = :old.tipo_doc     ) and
                                       (nro_doc      = :old.nro_doc      )) ;

     ELSIF (:old.flag_provisionado = 'N' AND lc_flag_tiptran = '3') THEN   --INDIRECTO/CARTERA DE COBROS
        --ELIMINAR DE CNTAS COBRAR DETALLE
        delete from cntas_cobrar_det where ((tipo_doc     = :old.tipo_doc     ) and
                                            (nro_doc      = :old.nro_doc      )) ;

        --ELIMINAR DE CNTAS COBRAR CABECERA
        delete from cntas_cobrar where ((cod_relacion = :old.cod_relacion ) and
                                        (tipo_doc     = :old.tipo_doc     ) and
                                        (nro_doc      = :old.nro_doc      )) ;

    END IF ;

END IF ;


end TDA_FIN_CAJA_BANCOS_DET;
/
