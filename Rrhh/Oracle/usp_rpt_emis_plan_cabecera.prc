create or replace procedure usp_rpt_emis_plan_cabecera
 ( as_codtra in maestro.cod_trabajador%type
  ) is

--Concep Imp basico     
lk_conc_basico constant char(4):='1001';

ls_nombre varchar2(100); 
ls_desc_cargo cargo.desc_cargo%type;
ld_fec_ing  date;
ls_nro_ipss  maestro.nro_ipss%type;
ls_desc_afp admin_afp.desc_afp%type;
ls_nro_afp maestro.nro_afp_trabaj%type;
ls_dni  maestro.dni%type;
ld_fec_cese date;
ln_basico number(13,2);
ln_periodo number(4);
ld_fec_sal_vac date;
ld_fec_ret_vac date; 


begin
 
 --Datos del Trabajador  
 Select c.desc_cargo  , m.fec_ingreso   , m.nro_ipss, 
        aa.desc_afp   , m.nro_afp_trabaj, m.dni     ,
        m.fec_cese 
  into  ls_desc_cargo , ld_fec_ing , ls_nro_ipss,
        ls_desc_afp   , ls_nro_afp , ls_dni     ,
        ld_fec_cese 
  from  maestro m, cargo c, admin_afp aa
 Where  m.cod_trabajador = as_codtra and 
        m.cod_cargo = c.cod_cargo (+) and 
        m.cod_afp = aa.cod_afp (+);
 ls_nombre := usf_nombre_trabajador(as_codtra);

 --Importe Basico del Trabajador
 select sum(gdf.imp_gan_desc)
  into ln_basico 
  from gan_desct_fijo gdf
 where gdf.cod_trabajador = as_codtra and 
       gdf.concep = lk_conc_basico; 
 ln_basico:= nvl(ln_basico,0);   

 --Seleccisn del Maximo Periodo
 Select max(pv.periodo)
  into ln_periodo
  from program_vacacion pv 
 where pv.cod_trabajador = as_codtra;
 
 IF ln_periodo > 0 then 
  --Seleccion de la Fechas de Vacaciones 
  select pv.fec_salida_vaca, pv.fec_retor_vaca
   into ld_fec_sal_vac, ld_fec_ret_vac
   from program_vacacion pv 
  where pv.cod_trabajador = as_codtra and 
        pv.periodo = ln_periodo;
 End If;
  
 --Insert de la Tabla Temporal
 INSERT INTO tt_rpt_emis_plan
  ( cod_trabajador , nombre         , desc_cargo     , fec_ingreso   ,
    nro_ipss       , desc_afp       , nro_afp        , dni           ,
    fec_cese       , basico         , salida_vac     , retorno_vac   ,
    rem_basica     , asig_merito    , tran_recate    , in_ley        ,
    in_dl          , cta_categ      , rem_gerencia   , sem_inglesa   ,
    sobret         , dom_trabaj     , sob_dom        , fer_trabaj    ,
    sob_tur_vac    , asig_guardia   , subsidio_ley   , sub_cta_ipss  ,
    resp_direct    , asig_espe      , rein_inasis    , perm_remun    ,
    otras_gan      , bonif_quinq    , afp_10         , afp_3         ,
    rac_trabaj     , rem_deveng     , gratif_dev     , vacaciones    ,
    vac_deveng     , asig_vacac      , gratif_jubil   , int_legales   ,
    gratificacion  , v_per          , v_dev          , a_vac         ,
    bonif_30       , rac_azucar     , pens_jubilac   , bonif_25_jubi ,
    increm_10      , prestamo       , campo43        , campo44       ,
    campo45        , campo46        , campo47        , campo48       ,
    campo49        , campo50        , campo51        , tot_ingreso   ,
    snp            , aporte_afp     , invalid_afp    , comision_afp  ,
    judicial       , qta_categ      , adel_gratif    , adel_con_mes  ,
    otros_desc     , perm_partic    , tardanzas      , comp_almace   ,
    serv_telef     , sindicato      , jud_deveng     , prestamos     ,
    adel_liquid    , fact_hospit    , terr_vivie     , ute_fonavi    ,
    redondeo_ant   , tot_desc       , tot_neto       , redondeo      ,
    campo77        , tot_pagado     , ipss           , ies           ,
    senati         , sctr_ipss      , sctr_onp       , campo84       ,
    campo85        , campo86        , campo87        , campo88       ,
    campo89        , campo90        , tot_patronal   , dias_trabaj   ,
    horas_trabaj   , horas_extras   , campo95        , campo96       ,
    campo97        , campo98        , campo99        , campo100      ,
    campo101       , campo102       , campo103       , campo104      , 
    obr_pag_destaj , obr_reint_sobr , obr_dobl_guard , obr_rac_cocida,
    obr_trab_espec , obr_rein_tarea , obr_riesgo     , obr_toxico    ,
    obr_turnos     , obr_campo42 ) 
 values 
  ( as_codtra      , ls_nombre      , ls_desc_cargo  , ld_fec_ing    , 
    ls_nro_ipss    , ls_desc_afp    , ls_nro_afp     , ls_dni        , 
    ld_fec_cese    , ln_basico      , ld_fec_sal_vac , ld_fec_ret_vac, 
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             , 
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             , 
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0              , 0              , 0             ,
    0              , 0 );
  
end usp_rpt_emis_plan_cabecera;
/
