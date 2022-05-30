create or replace procedure usp_prc_cd_tranferencia
 (as_cod_postul in postulante.cod_postulante%type ,
  ad_fec_eval   in eval_tecnica_postulantes.fec_evaluacion%type,
  as_cod_area   in area.cod_area%type,
  as_cod_asig   out string )
  is

ls_cod_max maestro.cod_trabajador%type;
ls_cod_asig maestro.cod_trabajador%type;
ln_cod_asig number(8);
ln_cod_max number(8);  
--Datos del Postulates a ser Trasladados  
Cursor c_p is 
select p.apel_paterno, p.apel_materno, p.nombre1, p.nombre2, 
       p.dni, p.lib_militar, p.direccion, p.email, p.cod_cargo,
       p.cod_profesion, p.cod_pais, p.cod_dpto, p.cod_prov,
       p.cod_distr,p.cod_ciudad, p.fec_nacimiento, p.flag_estado_civil,
       p.telefono1, p.telefono2, p.flag_sexo 
from  postulante p
where p.cod_postulante = as_cod_postul;
 
begin

/*select substr(to_char(seq_cod_trabaj.NEXTVAL,'00000000'),2,8) 
into ls_cod_asig
from dual;
*/
--ls_cod_asig := to_char(ln_cod_max + 1 );
/*select u.last_number
into ln_cod_asig
from user_sequences u
where u.sequence_name = 'SEQ_COD_TRABAJ';

--Codigo asignado
as_cod_asig := to_char(ln_cod_asig); 
*/
For rc_p in c_p Loop
 
 Insert Into maestro
   (cod_trabajador         , cod_trab_antguo       , foto_trabaj        ,
    apel_paterno           , apel_materno          , nombre1            ,
    nombre2                , flag_estado_civil     , flag_cal_plnlla    , 
    flag_sindicato         , flag_estado           , fec_ingreso        , 
    fec_nacimiento         , fec_cese              , cod_motiv_cese     ,
    flag_sexo              , direccion             , tel_cod_ciudad     ,
    telefono1              , telefono2             , dni                , 
    lib_militar            , ruc                   , email              , 
    cod_tipo_brev          , nro_brevete           , carnet_trabaj      , 
    nro_ipss               , cod_grado_inst        , cod_profesion      , 
    cod_cargo              , situa_trabaj          , cod_afp            , 
    nro_afp_trabaj         , fec_ini_afil_afp      , fec_fin_afil_afp   ,
    porc_judicial          , bonif_fija_30_25      , flag_quincena      , 
    tipo_trabajador        , nro_cnta_ahorro       , nro_cnta_cts       ,
    cod_moneda             , cod_empresa           , cod_labor          , 
    cencos                 , flag_algun_famil      , cod_usr            , 
    cod_banco              , cod_banco_cts         , cod_tipo_sangre    ,
    cod_categ_sal          , cod_seccion           , cod_area           , 
    cod_pais               , cod_dpto              , cod_prov           ,
    cod_distr              , cod_ciudad            , cod_vivienda       , 
    flag_esposa            , flag_convenio         , flag_juicio        ,
    turno                  )
    /*, flag_marca_reloj    )*/
   
 Values
   (ls_cod_asig            , ''                    , ''                 ,
    rc_p.apel_paterno      , rc_p.apel_materno     , rc_p.nombre1       ,
    rc_p.nombre2           , rc_p.flag_estado_civil, '1'                ,
    ''                     , '1'                   , sysdate            ,
    rc_p.fec_nacimiento    , sysdate               , ''                 ,
    rc_p.flag_sexo         , rc_p.direccion        , ''                 ,
    rc_p.telefono1         , rc_p.telefono2        , rc_p.dni           ,
    rc_p.lib_militar       , ''                    , rc_p.email         ,
    ''                     , ''                    , ''                 ,
    ''                     , ''                    , rc_p.cod_profesion ,
    rc_p.cod_cargo         , ''                    , ''                 ,
    ''                     , sysdate               , sysdate + 1        ,
    0                      , ''                    , ''                 ,
    ''                     , ''                    , ''                 ,
    ''                     , ''                    , ''                 ,
    ''                     , ''                    , ''                 ,
    ''                     , ''                    , ''                 , 
    ''                     , ''                    , ''                 , 
    rc_p.cod_pais          , rc_p.cod_dpto         , rc_p.cod_prov      , 
    rc_p.cod_distr         , rc_p.cod_ciudad       , ''                 ,
    ''                     , ''                    , ''                 ,
    ''                     );
    /*, '0'               );*/
    
End Loop;     
end usp_prc_cd_tranferencia;
/
