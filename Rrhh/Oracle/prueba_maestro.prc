create or replace procedure prueba_maestro is

ls_cencos centros_costo.cencos%type;

cursor c_m is 
select m.cod_trabajador , m.cod_trab_antguo  , m.foto_trabaj     ,
       m.apel_paterno   , m.apel_materno     , m.nombre1         ,
       m.nombre2        , m.flag_estado_civil, m.flag_cal_plnlla ,
       m.flag_sindicato , m.flag_estado      , m.fec_ingreso     ,
       m.fec_nacimiento , m.fec_cese         , m.cod_motiv_cese  ,
       m.flag_sexo      , m.direccion        , m.tel_cod_ciudad  ,
       m.telefono1      , m.telefono2        , m.dni             ,
       m.lib_militar    , m.ruc              , m.email           ,
       m.cod_tipo_brev  , m.nro_brevete      , m.carnet_trabaj   ,
       m.nro_ipss       , m.cod_grado_inst   , m.cod_profesion   , 
       m.cod_cargo      , m.situa_trabaj     , m.cod_afp         ,
       m.nro_afp_trabaj , m.fec_ini_afil_afp , m.fec_fin_afil_afp,
       m.porc_judicial  , m.bonif_fija_30_25 , m.flag_quincena   ,
       m.tipo_trabajador, m.nro_cnta_ahorro  , m.nro_cnta_cts    ,
       m.cod_moneda     , m.cod_empresa      , m.cod_labor       ,
       m.cencos         , m.flag_algun_famil , m.cod_usr         ,
       m.cod_banco      , m.cod_banco_cts    , m.cod_tipo_sangre ,
       m.cod_categ_sal  , m.cod_seccion      , m.cod_area        ,
       m.cod_pais       , m.cod_dpto         , m.cod_prov        ,
       m.cod_distr      , m.cod_ciudad       , m.cod_vivienda    ,
       m.flag_esposa    , m.flag_convenio    , m.flag_juicio     ,
       m.turno          , m.flag_marca_reloj
from   aipsa.maestro m 
where m.cod_trabajador not in (Select w.cod_trabajador
                               From work1.maestro w);
begin
For cr_m in c_m Loop
Insert into work1.maestro 
     (cod_trabajador    , cod_trab_antguo      , foto_trabaj       ,
      apel_paterno      , apel_materno         , nombre1           ,
      nombre2           , flag_estado_civil    , flag_cal_plnlla   ,
      flag_sindicato    , flag_estado          , fec_ingreso       ,
      fec_nacimiento    , fec_cese             , cod_motiv_cese    ,
      flag_sexo         , direccion            , tel_cod_ciudad    ,
      telefono1         , telefono2            , dni               ,
      lib_militar       , ruc                  , email             ,
      cod_tipo_brev     , nro_brevete          , carnet_trabaj     ,
      nro_ipss          , cod_grado_inst       , cod_profesion     ,
      cod_cargo         , situa_trabaj         , cod_afp           , 
      nro_afp_trabaj    , fec_ini_afil_afp     , fec_fin_afil_afp  ,
      porc_judicial     , bonif_fija_30_25     , flag_quincena     ,
      tipo_trabajador   , nro_cnta_ahorro      , nro_cnta_cts      ,
      cod_moneda        , cod_empresa          , cod_labor         ,
      cencos            , flag_algun_famil     , cod_usr           ,
      cod_banco         , cod_banco_cts        , cod_tipo_sangre   ,
      cod_categ_sal     , cod_seccion          , cod_area          ,
      cod_pais          , cod_dpto             , cod_prov          ,
      cod_distr         , cod_ciudad           , cod_vivienda      ,
      turno             , flag_marca_reloj     , flag_esposa       ,
      flag_convenio     , flag_juicio )
values

  (cr_m.cod_trabajador  , cr_m.cod_trab_antguo   , cr_m.foto_trabaj      ,
   cr_m.apel_paterno    , cr_m.apel_materno      , cr_m.nombre1          ,
   cr_m.nombre2         , cr_m.flag_estado_civil , cr_m.flag_cal_plnlla  ,
   cr_m.flag_sindicato  , cr_m.flag_estado       , cr_m.fec_ingreso      ,
   cr_m.fec_nacimiento  , cr_m.fec_cese          , cr_m.cod_motiv_cese   ,
   cr_m.flag_sexo       , cr_m.direccion         , cr_m.tel_cod_ciudad   ,
   cr_m.telefono1       , cr_m.telefono2         , cr_m.dni              ,
   cr_m.lib_militar     , cr_m.ruc               , cr_m.email            ,
   cr_m.cod_tipo_brev   , cr_m.nro_brevete       , cr_m.carnet_trabaj    ,
   cr_m.nro_ipss        , cr_m.cod_grado_inst    , cr_m.cod_profesion    ,
   cr_m.cod_cargo       , cr_m.situa_trabaj      , cr_m.cod_afp          , 
   cr_m.nro_afp_trabaj  , cr_m.fec_ini_afil_afp  , cr_m.fec_fin_afil_afp ,
   cr_m.porc_judicial    , cr_m.bonif_fija_30_25  , cr_m.flag_quincena    ,
   cr_m.tipo_trabajador , cr_m.nro_cnta_ahorro   , cr_m.nro_cnta_cts     ,
   cr_m.cod_moneda      , cr_m.cod_empresa       , cr_m.cod_labor        ,
   cr_m.cencos          , cr_m.flag_algun_famil  , cr_m.cod_usr          ,
   cr_m.cod_banco       , cr_m.cod_banco_cts     , cr_m.cod_tipo_sangre  ,
   cr_m.cod_categ_sal   , cr_m.cod_seccion       , cr_m.cod_area         ,
   cr_m.cod_pais        , cr_m.cod_dpto          , cr_m.cod_prov         ,
   cr_m.cod_distr       , cr_m.cod_ciudad        , cr_m.cod_vivienda     ,
   cr_m.turno           , cr_m.flag_marca_reloj  , cr_m.flag_esposa       ,
   cr_m.flag_convenio   , cr_m.flag_juicio );
End Loop;  
end prueba_maestro;
/
