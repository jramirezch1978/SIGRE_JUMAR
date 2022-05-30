create or replace procedure prueba_cntble_cnta is

Cursor c_cc is
select c.cnta_ctbl, c.desc_cnta, c.abrev_cnta,
       c.niv_cnta, c.fecha_creacion, c.flag_estado,
       c.flag_permite_mov, c.flag_ctabco, c.flag_cencos,
       c.flag_cod_segui, c.flag_labor, c.clase_segui,
       c.tipo_sdocontab, c.tipo_cnta, c.cod_clase,
       c.cod_subclase
from aipsa.cntbl_cnta c;
begin
for cr_cc in c_cc Loop
Insert into work1.cntbl_cnta 
 ( cnta_ctbl          , desc_cnta       , abrev_cnta       , 
   niv_cnta           , fecha_creacion  , flag_estado      ,
   flag_permite_mov   , flag_ctabco     , flag_cencos      ,
   flag_cod_segui     , flag_labor      , flag_doc_ref     ,
   flag_doc_ref2      , clase_segui     , tipo_sdocontab )
Values 
 ( cr_cc.cnta_ctbl        , cr_cc.desc_cnta      , cr_cc.abrev_cnta       ,
   cr_cc.niv_cnta         , cr_cc.fecha_creacion , cr_cc.flag_estado      ,
   cr_cc.flag_permite_mov , cr_cc.flag_ctabco    , cr_cc.flag_cencos      ,
   cr_cc.flag_cod_segui   , cr_cc.flag_labor     , ''                     ,
   ''                     , cr_cc.clase_segui    , cr_cc.tipo_sdocontab );
end loop;  
end prueba_cntble_cnta;
/
