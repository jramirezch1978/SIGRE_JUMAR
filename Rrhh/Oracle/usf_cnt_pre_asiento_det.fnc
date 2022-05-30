create or replace function usf_cnt_pre_asiento_det(
  as_origen          in cntbl_pre_asiento_det.origen%type,
  al_nro_libro       in cntbl_pre_asiento_det.nro_libro%type,
  al_nro_provisional in cntbl_pre_asiento_det.nro_provisional%type,
  as_cnta_ctbl       in cntbl_pre_asiento_det.cnta_ctbl%type,
  ad_fec_cntbl       in cntbl_pre_asiento_det.fec_cntbl%type,
  as_det_glosa       in cntbl_pre_asiento_det.det_glosa%type,
  as_flag_gen_aut    in cntbl_pre_asiento_det.flag_gen_aut%type,
  as_flag_debhab     in cntbl_pre_asiento_det.flag_debhab%type,
  as_cencos          in cntbl_pre_asiento_det.cencos%type,
  as_cod_ctabco      in cntbl_pre_asiento_det.cod_ctabco%type,
  as_tipo_docref     in cntbl_pre_asiento_det.tipo_docref%type,
  as_nro_docref1     in cntbl_pre_asiento_det.nro_docref1%type,
  as_nro_docref2     in cntbl_pre_asiento_det.nro_docref2%type,
  as_cod_relacion    in cntbl_pre_asiento_det.cod_relacion%type,
  al_imp_movsol      in cntbl_pre_asiento_det.imp_movsol%type,
  al_imp_movdol      in cntbl_pre_asiento_det.imp_movdol%type,
  al_imp_movaju      in cntbl_pre_asiento_det.imp_movaju%type,
  as_cnta_prsp       in cntbl_pre_asiento_det_aux.cnta_prsp%type,
  as_cencos_destino  in cntbl_pre_asiento_det_aux.cencos%type,
  as_flag_pre_cnta   in cntbl_pre_asiento_det_aux.flag_pre_cnta%type,
  as_centro_benef    IN cntbl_pre_asiento_det.centro_benef%TYPE  
)return boolean is
 
  ln_item            cntbl_pre_asiento_det.item%type;
  ls_flag_mov        cntbl_cnta.flag_permite_mov%type;
  ls_flag_cencos     cntbl_cnta.flag_cencos%type;
  ls_cencos          centros_costo.cencos%type ;
  ls_flag_doc_ref    cntbl_cnta.flag_doc_ref%type;
  ls_flag_doc_ref2   cntbl_cnta.flag_doc_ref%type;
  ls_tipo_doc        doc_tipo.tipo_doc%type ;
  ls_nro_doc         cntbl_asiento_det.nro_docref1%type ;
  ls_nro_doc2        cntbl_asiento_det.nro_docref1%type ;
  ls_flag_codrel     cntbl_cnta.flag_codrel%type;
  ls_codrel          proveedor.proveedor%type ;
  ls_flag_cenbef     cntbl_cnta.flag_centro_benef%TYPE;
  ls_centro_benef    centro_beneficio.centro_benef%type ;
  ls_cod_banco       banco_cnta.cod_ctabco%type ;
  
  Result boolean;

BEGIN

-- Funciona que permite actualizar un registro en CNTBL_PRE_ASIENTO_DET
result := true ;
-- Verificando si datos a grabar son correctos
select flag_permite_mov, flag_cencos, flag_doc_ref, flag_codrel, flag_centro_benef, flag_doc_ref2 
into ls_flag_mov, ls_flag_cencos, ls_flag_doc_ref, ls_flag_codrel, ls_flag_cenbef, ls_flag_doc_ref2
from cntbl_cnta c
where cnta_ctbl = as_cnta_ctbl ;

IF ls_flag_mov='0' then
   RAISE_APPLICATION_ERROR( -20000, 'Cuenta contable ' ||
   as_cnta_ctbl || ' no permite movimiento' ) ;
END IF;

IF ls_flag_cencos='1' THEN
   IF as_cencos is null then
     RAISE_APPLICATION_ERROR( -20001, 'Cuenta contable ' || as_cnta_ctbl || ' necesita centro de costo' ) ;
   END IF ;
   ls_cencos := as_cencos ;
ELSE
   ls_cencos := null ;
END IF;

IF ls_flag_cenbef='1' THEN
   IF as_centro_benef IS NULL then
      RAISE_APPLICATION_ERROR( -20001, 'Cuenta contable ' || as_cnta_ctbl || ' necesita Centro Beneficio' ) ;
   END IF ;
   ls_centro_benef := as_centro_benef ;
ELSE
   ls_centro_benef := null ;
END IF;

IF ls_flag_doc_ref='1' THEN
   IF (as_tipo_docref is null) or (as_nro_docref1 is null) THEN
      RAISE_APPLICATION_ERROR( -20001, 'Cuenta contable ' || as_cnta_ctbl || ' necesita documento necesita tipo y número de documento' ) ;
   END IF ;
   ls_tipo_doc := as_tipo_docref ;
   ls_nro_doc := as_nro_docref1 ;
ELSE
   ls_tipo_doc := null;
   ls_nro_doc := null;
END IF;

IF ls_flag_codrel='1' THEN
   IF as_cod_relacion is null then
      RAISE_APPLICATION_ERROR( -20001, 'Cuenta contable ' || as_cnta_ctbl || ' necesita codigo de relacion' ) ;      
   END IF ;
   ls_codrel := as_cod_relacion ;
ELSE
   ls_codrel := null ;
END IF;

IF ls_flag_doc_ref='2' THEN
   IF as_nro_docref2 is null THEN
      RAISE_APPLICATION_ERROR( -20001, 'Cuenta contable ' || as_cnta_ctbl || ' necesita documento 2' ) ;
   END IF ;
   ls_nro_doc2 := as_nro_docref2 ;
ELSE
   ls_nro_doc2 := null;
END IF;


-- Consistenciando si va a generar un registro en cntbl_pre_asiento_det_aux
IF as_flag_pre_cnta is null then

   -- Acutalizacion de cntbl_pre_asiento_det segun sea el caso
   IF (ls_flag_cencos='0' and
       ls_flag_doc_ref='0' and
       ls_flag_codrel='0' AND
       ls_flag_cenbef = '0' ) then

       update cntbl_pre_asiento_det
       set fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc, 
           nro_docref2              = ls_nro_doc2, 
           cod_relacion             = ls_codrel, 
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju 
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab ;
   
   -- Caso de centro de costo y centro de beneficio
   ELSIF (ls_flag_cencos='1' and
          ls_flag_doc_ref='0' and
          ls_flag_codrel='0' and
          ls_flag_cenbef = '1') then

       UPDATE cntbl_pre_asiento_det
       set fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc,
           nro_docref2              = ls_nro_doc2,
           cod_relacion             = ls_codrel,
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju,
           centro_benef             = ls_centro_benef
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab and
             cencos = ls_cencos AND
             centro_benef = ls_centro_benef;
             
   -- Caso solo centro beneficio
   ELSIF (ls_flag_cencos='0' and
          ls_flag_doc_ref='0' and
          ls_flag_codrel='0' AND
          ls_flag_cenbef = '1') then

       update cntbl_pre_asiento_det
       set fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc,
           nro_docref2              = ls_nro_doc2,
           cod_relacion             = ls_codrel,
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju,
           centro_benef             = ls_centro_benef
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab and
             centro_benef  = ls_centro_benef;

   -- Caso solo Centro de Costo
   ELSIF (ls_flag_cencos='1' and
          ls_flag_doc_ref='0' and
          ls_flag_codrel='0' AND
          ls_flag_cenbef = '0') then

       update cntbl_pre_asiento_det
       set fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc,
           nro_docref2              = ls_nro_doc2,
           cod_relacion             = ls_codrel,
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju,
           centro_benef             = as_centro_benef
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab and
             cencos  = ls_cencos;

   -- Caso codigo de relacion y tipo de documento
   ELSIF (ls_flag_cencos='0' and
          ls_flag_doc_ref='1' and
          ls_flag_codrel='1' AND 
          ls_flag_cenbef = '0') then

       update cntbl_pre_asiento_det
       set fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc,
           nro_docref2              = ls_nro_doc2,
           cod_relacion             = ls_codrel,
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju     
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab and
             tipo_docref = ls_tipo_doc and
             nro_docref1 = ls_nro_doc and 
             cod_relacion = ls_codrel;
   -- Caso codigo de relacion 
   ELSIF (ls_flag_cencos='0' and
          ls_flag_doc_ref='0' and
          ls_flag_codrel='1' AND 
          ls_flag_cenbef = '0') then

       update cntbl_pre_asiento_det
       set fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc,
           nro_docref2              = ls_nro_doc2,
           cod_relacion             = ls_codrel,
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju     
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab and
             cod_relacion = ls_codrel;
   -- Solo tipo de documento
   ELSIF (ls_flag_cencos='0' and
          ls_flag_doc_ref='1' and
          ls_flag_codrel='0' AND 
          ls_flag_cenbef = '0') then

       update cntbl_pre_asiento_det
       set fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc,
           nro_docref2              = ls_nro_doc2,
           cod_relacion             = ls_codrel,
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju     
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab and
             tipo_docref = ls_tipo_doc and
             nro_docref1 = ls_nro_doc ;
             
   -- Otros casos
   ELSE
       update cntbl_pre_asiento_det
       set origen                   = as_origen,
           nro_libro                = al_nro_libro,
           nro_provisional          = al_nro_provisional,
           cnta_ctbl                = as_cnta_ctbl,
           fec_cntbl                = ad_fec_cntbl,
           det_glosa                = as_det_glosa,
           flag_gen_aut             = as_flag_gen_aut,
           flag_debhab              = as_flag_debhab,
           cencos                   = ls_cencos,
           centro_benef             = ls_centro_benef,           
           cod_ctabco               = ls_cod_banco,
           tipo_docref              = ls_tipo_doc,
           nro_docref1              = ls_nro_doc,
           nro_docref2              = ls_nro_doc2,
           cod_relacion             = ls_codrel,
           imp_movsol               = nvl(imp_movsol,0) + al_imp_movsol,
           imp_movdol               = nvl(imp_movdol,0) + al_imp_movdol,
           imp_movaju               = nvl(imp_movaju,0) + al_imp_movaju
       where origen = as_origen and
             nro_libro = al_nro_libro and
             nro_provisional = al_nro_provisional and
             cnta_ctbl = as_cnta_ctbl and
             flag_debhab = as_flag_debhab and
             cencos = ls_cencos and              
             tipo_docref = ls_tipo_doc and
             nro_docref1 = ls_nro_doc and
             nro_docref2 = ls_nro_doc2 and
             cod_relacion = ls_codrel AND 
             centro_benef = ls_centro_benef;
   END IF;

   IF sql%notfound then
      -- Capturando el item
      select max(item) into ln_item
      from cntbl_pre_asiento_det
      where origen=as_origen and nro_libro=al_nro_libro and
            nro_provisional = al_nro_provisional ;

     ln_item := Nvl(ln_item,0) + 1 ;

      -- Insertando registro
      insert into cntbl_pre_asiento_det
      ( origen, nro_libro, nro_provisional,
      item, cnta_ctbl, fec_cntbl,
      det_glosa, flag_gen_aut, flag_debhab,
      cencos, cod_ctabco, tipo_docref,
      nro_docref1, nro_docref2, cod_relacion,
      imp_movsol, imp_movdol, imp_movaju, centro_benef)
      values
      ( as_origen, al_nro_libro, al_nro_provisional,
        ln_item , as_cnta_ctbl, ad_fec_cntbl,
      as_det_glosa, as_flag_gen_aut, as_flag_debhab,
      ls_cencos, ls_cod_banco, ls_tipo_doc,
      ls_nro_doc, ls_nro_doc2, ls_codrel,
      nvl( al_imp_movsol, 0), nvl( al_imp_movdol, 0), nvl( al_imp_movaju, 0 ), ls_centro_benef) ;
   end if;
ELSE
   -- Capturando el item
   select max(item) into ln_item
   from cntbl_pre_asiento_det
   where origen=as_origen and nro_libro=al_nro_libro and
         nro_provisional = al_nro_provisional ;

   -- Insertando registro en cntbl_pre_asiento_det
   insert into cntbl_pre_asiento_det
   ( origen, nro_libro, nro_provisional,
     item, cnta_ctbl, fec_cntbl,
     det_glosa, flag_gen_aut, flag_debhab,
     cencos, cod_ctabco, tipo_docref,
     nro_docref1, nro_docref2, cod_relacion,
     imp_movsol, imp_movdol, imp_movaju, centro_benef )
   values
   ( as_origen, al_nro_libro, al_nro_provisional,
     nvl(ln_item,0) + 1, as_cnta_ctbl, ad_fec_cntbl,
     as_det_glosa, as_flag_gen_aut, as_flag_debhab,
     ls_cencos, ls_cod_banco, ls_tipo_doc,
     ls_nro_doc, ls_nro_doc2, ls_codrel,
     nvl( al_imp_movsol, 0), nvl( al_imp_movdol, 0), nvl( al_imp_movaju, 0 ), ls_centro_benef ) ;

   -- Insertando registro en cntbl_pre_asiento_det_aux

   insert into cntbl_pre_asiento_det_aux
   ( origen, nro_libro, nro_provisional,
     item, cnta_prsp, cencos,
     flag_pre_cnta )
   values
   ( as_origen, al_nro_libro, al_nro_provisional,
     nvl(ln_item,0) + 1, as_cnta_prsp, as_cencos_destino,
     as_flag_pre_cnta ) ;

END IF ;

return(Result);

end usf_cnt_pre_asiento_det;
/
