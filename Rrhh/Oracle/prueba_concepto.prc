create or replace procedure prueba_concepto is
--Cursor Concepto de AIPSA
Cursor c_c is 
select c.concep              , c.desc_concep         , c.desc_breve       , c.nemotec        , 
       c.flag_estado         , c.cod_formula         , c.fact_pago        , c.cta_haber_obr  ,
       c.cta_debe_obr        , c.cta_haber_emp       , c.cta_debe_emp     , c.imp_tope_min   ,
       c.imp_tope_max        , c.nro_horas           , c.cod_labor        , c.flag_t_snp     ,
       c.flag_t_quinta       , c.flag_t_judicial     , c.flag_t_afp       , c.flag_t_bonif_30,
       c.flag_t_bonif_25     , c.flag_t_gratif       , c.flag_t_cts       , c.flag_t_vacacio ,
       c.flag_t_bonif_vacacio, c.flag_t_pago_quincena, c.flag_t_quinquenio, c.flag_e_essalud ,
       c.flag_e_agrario      , c.flag_e_essalud_vida , c.flag_e_ies       , c.flag_e_senati  ,
       c.flag_e_sctr_ipss    , c.flag_e_sctr_onp     , c.cod_usr
from aipsa.concepto c;

begin
  For cr_c in c_c Loop
  insert into work1.concepto
     ( concep                , desc_concep           , desc_breve          , nemotec           ,
       flag_estado           , cod_formula           , fact_pago           , cta_haber_obr     ,
       cta_debe_obr          , cta_haber_emp         , cta_debe_emp        , cnta_prsp         ,
       imp_tope_min          , imp_tope_max          , nro_horas           , cod_labor         ,
       flag_t_snp            , flag_t_quinta         , flag_t_judicial     , flag_t_afp        ,
       flag_t_bonif_30       , flag_t_bonif_25       , flag_t_gratif       , flag_t_cts        ,
       flag_t_vacacio        , flag_t_bonif_vacacio  , flag_t_pago_quincena, flag_t_quinquenio ,
       flag_e_essalud        , flag_e_agrario        , flag_e_essalud_vida , flag_e_ies        ,
       flag_e_senati         , flag_e_sctr_ipss      , flag_e_sctr_onp     , cod_usr )
  values
     ( cr_c.concep           , cr_c.desc_concep         , cr_c.desc_breve          , cr_c.nemotec           ,  
       cr_c.flag_estado      , cr_c.cod_formula         , cr_c.fact_pago           , cr_c.cta_haber_obr     ,
       cr_c.cta_debe_obr     , cr_c.cta_haber_emp       , cr_c.cta_debe_emp        , ''                     ,
       cr_c.imp_tope_min     , cr_c.imp_tope_max        , cr_c.nro_horas           , cr_c.cod_labor         ,
       cr_c.flag_t_snp       , cr_c.flag_t_quinta       , cr_c.flag_t_judicial     , cr_c.flag_t_afp        ,
       cr_c.flag_t_bonif_30  , cr_c.flag_t_bonif_25     , cr_c.flag_t_gratif       , cr_c.flag_t_cts        ,
       cr_c.flag_t_vacacio   , cr_c.flag_t_bonif_vacacio, cr_c.flag_t_pago_quincena, cr_c.flag_t_quinquenio ,
       cr_c.flag_e_essalud   , cr_c.flag_e_agrario      , cr_c.flag_e_essalud_vida , cr_c.flag_e_ies        ,
       cr_c.flag_e_senati    , cr_c.flag_e_sctr_ipss    , cr_c.flag_e_sctr_onp     , cr_c.cod_usr );
 End loop;      
  
end prueba_concepto;
/
