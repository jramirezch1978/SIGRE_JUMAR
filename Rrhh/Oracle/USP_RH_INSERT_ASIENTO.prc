create or replace procedure USP_RH_INSERT_ASIENTO(
       adi_fec_proceso    in date                                   ,
       asi_origen         in origen.cod_origen%type                 ,
       asi_cencos         in centros_costo.cencos%type              ,
       asi_cnta_ctbl      in cntbl_cnta.cnta_ctbl%type              ,
       asi_tipo_doc       in doc_tipo.tipo_doc%type                 ,
       asi_nro_doc        in calculo.nro_doc_cc%type                ,
       asi_cod_relacion   in cntbl_asiento_det.cod_relacion%TYPE   ,
       asi_flag_ctrl_debh in cntbl_asiento_det.flag_debhab%TYPE     ,
       asi_flag_debhab    in cntbl_asiento_det.flag_debhab%TYPE     ,
       ani_nro_libro      in cntbl_libro.nro_libro%type             ,
       asi_glosa_det      in cntbl_pre_asiento_det.det_glosa%TYPE   ,
       ani_item           in out cntbl_pre_asiento_det.item%type    ,
       ani_num_prov       in cntbl_libro.num_provisional%type       ,
       ani_imp_soles      in cntbl_pre_asiento_det.imp_movsol%type  ,
       ani_imp_dolares    in cntbl_pre_asiento_det.imp_movsol%type  ,
       asi_concep         in concepto.concep%type                   ,
       asi_cbenef         in maestro.centro_benef%type              ,
       asi_cod_trabajador in maestro.cod_trabajador%TYPE
) is

ls_grupo_cntbl        centros_costo.grp_cntbl%type ;
ls_cnta_cntbl         cntbl_cnta.cnta_ctbl%type    ;
ls_flag_cencos        cntbl_cnta.flag_cencos%type  ;
ls_flag_doc           cntbl_cnta.flag_doc_ref%type ;
ls_flag_crel          cntbl_cnta.flag_codrel%type  ;
ls_flag_centro_benef  cntbl_cnta.flag_centro_benef%type  ;
ls_cencos             centros_costo.cencos%type    ;
ls_tipo_doc           doc_tipo.tipo_doc%Type       ;
ls_nro_doc            calculo.nro_doc_cc%type      ;
ls_cod_relacion       maestro.cod_trabajador%type  ;
ls_flag_debhab        cntbl_asiento_det.flag_debhab%type ;
ln_count              Number                       ;
ls_centro_benef       maestro.centro_benef%type    ;

begin


  if Substr(asi_cnta_ctbl,1,1) = '9' then --es una cuenta de gasto

     if asi_cencos is null then
        --inserto en tabla de errores inconsistencia de grupo contable de centros de costo
        Insert Into TT_RH_INC_ASIENTOS(
               cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,
               grp_cntbl,obs)
        Values(
               asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,
               asi_flag_debhab ,asi_cnta_ctbl ,ls_grupo_cntbl ,'Centro de costo no puede ser nulo' ) ;
         --
         RAISE_APPLICATION_ERROR(-20000,'La Cuenta Contable ' || asi_cnta_ctbl || ' pide como referencia centro de costo, pero el Centro de Costo del trabajador '
                                         ||asi_cod_relacion||' esta vacío, por favor verifique.'
                                         || chr(13) || 'Concepto: ' || asi_concep);
         return ;
     end if ;

     select count(*)
       into ln_count
       from matriz_transf_cntbl_cencos mt
      where mt.org_cnta_ctbl = asi_cnta_ctbl
        and mt.cencos        = asi_cencos
        and mt.flag_estado   = '1';

     if ln_count = 0 then
        ls_cnta_cntbl := asi_cnta_ctbl ;
     else
        select dst_cnta_ctbl
          into ls_cnta_cntbl
          from matriz_transf_cntbl_cencos mt
         where mt.org_cnta_ctbl = asi_cnta_ctbl
           and mt.cencos        = asi_cencos
           and mt.flag_estado   = '1';

        if ls_cnta_cntbl is null then
           --inserto en tabla de errores inconsistencia de grupo contable de centros de costo
           Insert Into TT_RH_INC_ASIENTOS(
                  cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
           Values(
                  asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,
                  asi_cnta_ctbl ,ls_grupo_cntbl ,'Centro de costo y Cuenta Contable NO TIENE Cuenta Destino, '
                                || 'en la matriz de dstribución, por favor verifique' ) ;

           RAISE_APPLICATION_ERROR(-20000,'Centro de costo y Cuenta Contable NO TIENE Cuenta Destino, '
                                       || 'en la matriz de dstribución, por favor verifique.'
                                       || chr(13) || 'Centro Costo: ' || asi_cencos
                                       || chr(13) || 'Cnta Cntbl: ' || asi_cnta_ctbl);
                                       
           --
           return ;
        end if ;
      end if ;
  else
     ls_cnta_cntbl := asi_cnta_ctbl ;
  end if;

  --verifico si nueva cuenta existe o esta activa
  select count(*)
    into ln_count
    from cntbl_cnta c
   where c.cnta_ctbl = ls_cnta_cntbl
     and c.flag_estado = '1' ;

  if ln_count = 0 then
     --inserto en tabla de errores inconsistencia de cnta cntble inexistente o desactivada
     Insert Into TT_RH_INC_ASIENTOS(
            cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
     Values(
            asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,
            ls_cnta_cntbl ,ls_grupo_cntbl ,'Cuenta Contable no Existe o Esta Desactivada, por favor verifique' ) ;
            
     RAISE_APPLICATION_ERROR(-20000,'La Cuenta Contable '||ls_cnta_cntbl||' es inexistente o inactiva');
    return ;
  end if ;

  --verificar valores de datos requeridos segun cuenta
  select Nvl(c.flag_cencos,'0'),Nvl(c.flag_doc_ref,'0'),Nvl(c.flag_codrel,'0'), Nvl(c.flag_centro_benef,'0')
    into ls_flag_cencos,ls_flag_doc,ls_flag_crel,ls_flag_centro_benef
    from cntbl_cnta c
   where c.cnta_ctbl = ls_cnta_cntbl ;


  if ls_flag_cencos = '1' then --requiere centro de costo
     ls_cencos := asi_cencos ;
  else
     ls_cencos := null ;
  end if ;

  if ls_flag_centro_benef = '1' then --requiere centro de beneficio
     ls_centro_benef := asi_cbenef ;
  else
     ls_centro_benef := null ;
  end if ;

  if ls_flag_doc = '1' then --requiere docuemnto de referencia
     if asi_tipo_doc is null then --tipo de documento no puede ser nulo
        RAISE_APPLICATION_ERROR(-20000,'El Concepto ' || asi_concep || ' tiene la Cuenta Contable ' || ls_cnta_cntbl 
                                     || ' la cual está configurada para que pida Documento de Referencia.'
                                     || chr(13) || 'Cod Trabajador: ' || asi_cod_trabajador
                                     || chr(13) || 'Tipo Doc: ' || ls_tipo_doc
                                     || chr(13) || 'Nro Doc: ' || ls_nro_doc);
        Insert Into TT_RH_INC_ASIENTOS(
               cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
        Values(
               asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,ls_cnta_cntbl ,
               ls_grupo_cntbl ,'Cuenta Contable Requiere tipo de Documento' ) ;
        return ;
     else
        ls_tipo_doc := asi_tipo_doc ;
     end if ;

     if asi_nro_doc is null then --nro de documento no puede ser nulo
        --insertar en tabla temporal problema de documento
        Insert Into TT_RH_INC_ASIENTOS(
               cod_trabajador ,cencos ,concepto ,tipo_doc ,nro_doc ,flag_debhab ,cnta_ctbl,grp_cntbl,obs)
        Values(
               asi_cod_relacion ,asi_cencos ,asi_concep ,asi_tipo_doc ,asi_nro_doc ,asi_flag_debhab ,ls_cnta_cntbl ,
               ls_grupo_cntbl ,'Cuenta Contable Requiere Nro de Documento' ) ;
        return ;
     else
        ls_nro_doc := asi_nro_doc ;
     end if ;
  else --no se coloca tipo ni nro de documento
     ls_tipo_doc := null ;
     ls_nro_doc  := null ;
  end if ;

  if ls_flag_crel = '1' then --requiere codigo de relacion
     ls_cod_relacion := asi_cod_relacion ;
  else
     ls_cod_relacion := null ;
  end if ;



  if asi_flag_ctrl_debh = '0' then
     --invertir valor por valores negativos
     if asi_flag_debhab = 'D' THEN
        ls_flag_debhab := 'H';
     else
        ls_flag_debhab := 'D' ;
     end if ;
  else
     ls_flag_debhab := asi_flag_debhab ;
  end if ;

  --actualiza asiento si ya existe
  Update cntbl_pre_asiento_det c
     set c.imp_movsol = c.imp_movsol + ani_imp_soles,
         c.imp_movdol = c.imp_movdol + ani_imp_dolares
    Where origen                = asi_origen
      and nro_libro             = ani_nro_libro
      and nro_provisional       = ani_num_prov
      and cnta_ctbl             = ls_cnta_cntbl
      and fec_cntbl             = adi_fec_proceso
      and flag_debhab           = ls_flag_debhab
      and Nvl(cencos,' ')       = Nvl(ls_cencos,' ')
      and Nvl(tipo_docref,' ')  = Nvl(ls_tipo_doc,' ')
      and Nvl(nro_docref1,' ')  = Nvl(ls_nro_doc,' ')
      and Nvl(cod_relacion,' ') = Nvl(ls_cod_relacion,' ')
      and Nvl(centro_benef,' ') = Nvl(ls_centro_benef,' ')
      and nvl(det_glosa, ' ')   = nvl(asi_glosa_det, ' ')
      and concep                = asi_concep;



  IF SQL%NOTFOUND THEN
     --CONTADOR DE ITEM
     --incrementa contador del detalle
     -- Se ha aumentado centro de beneficio, MM

     ani_item := ani_item + 1 ;

     Insert Into cntbl_pre_asiento_det   (
            origen      ,nro_libro ,nro_provisional   ,item        ,det_glosa ,flag_debhab ,
            cnta_ctbl   ,fec_cntbl   ,tipo_docref     ,nro_docref1 ,cencos    ,imp_movsol  ,
            imp_movdol  ,cod_relacion, centro_benef   ,concep )
     Values(
            asi_origen     ,ani_nro_libro   ,ani_num_prov   ,ani_item    ,asi_glosa_det ,ls_flag_debhab ,
            ls_cnta_cntbl ,adi_fec_proceso ,ls_tipo_doc     ,ls_nro_doc  ,ls_cencos     ,ani_imp_soles   ,
            ani_imp_dolares,ls_cod_relacion, ls_centro_benef, asi_concep );


  END IF ;


  Update tt_asiento_det tt
     set tt.imp_movsol = tt.imp_movsol + ani_imp_soles,
         tt.imp_movdol = tt.imp_movdol + ani_imp_dolares
   Where tt.cnta_ctbl              = ls_cnta_cntbl
     and tt.cod_trabajador         = asi_cod_relacion
     and tt.flag_debhab            = ls_flag_debhab
     and Nvl(tt.cencos,' ')        = Nvl(ls_cencos,' ')
     and Nvl(tt.tipo_docref,' ')   = Nvl(ls_tipo_doc,' ')
     and Nvl(tt.nro_docref1,' ')   = Nvl(ls_nro_doc,' ')
     and Nvl(tt.cod_relacion, ' ') = Nvl(ls_cod_relacion,' ')
     and Nvl(tt.centro_benef,' ')  = Nvl(ls_centro_benef,' ') ;

  IF SQL%NOTFOUND THEN
      --llena tabla temporal
      Insert into tt_asiento_det(
             cnta_ctbl   ,flag_debhab    ,cencos        ,tipo_docref ,
             nro_docref1 ,cod_relacion   ,imp_movsol    ,imp_movdol  ,
             item        ,cod_trabajador ,cod_trab_audi ,centro_benef )
      Values(
             ls_cnta_cntbl  ,ls_flag_debhab    ,ls_cencos            ,ls_tipo_doc    ,
             ls_nro_doc     ,ls_cod_relacion   ,ani_imp_soles        ,ani_imp_dolares ,
             ani_item       ,asi_cod_trabajador,asi_cod_trabajador   ,ls_centro_benef) ;
  END IF ;


end USP_RH_INSERT_ASIENTO;
/
