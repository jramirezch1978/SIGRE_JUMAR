create or replace procedure usp_lp_datos_pers
( as_codtra in maestro.cod_trabajador%type
 ) is
 
--lk_snp constant char(30) := 'Seguro Nac. Pension';
ls_apel_paterno  varchar2(30);
ls_apel_materno  varchar2(30);
ls_nombre1       varchar2(30);
ls_nombre2       varchar2(30);
ls_foto_trabaj   maestro.foto_trabaj%type;
ld_fec_nacim     date        ;
ld_fec_today     date        ;
ls_direccion     varchar2(100);
ls_cod_pais      char(3)      ;
ls_nom_pais      varchar2(30) ;
ls_nacional      varchar2(30) ;
ls_cod_dpto      char(3)     ;
ls_nom_dpto      varchar2(30);
ls_cod_prov      char(3)     ;
ls_nom_prov      varchar2(30);
ls_cod_distr     char(4)     ;
ls_nom_distr     varchar2(30);
ls_telef1        char(8)     ;
ls_telef2        char(8)     ;
ls_flg_sexo      char(1)     ;
ls_flg_pension   char(1)     ;
ls_flg_est_civ   char(1)     ;
ls_ruc           char(11)    ;
ls_nro_brev      char(15)    ;
ls_nro_ipss      char(15)    ;
ls_desc_afp      varchar2(30);
 
ls_nro_afp_trab  char(12)    ;
ls_dni           char(8)     ;
ls_lib_mil       char(12)    ;
ln_edad          number(4,2) ;
ln_dif           number(9,3) ;
 
begin
 
 --Deleteo de la tabla tt_lp_datos_pers
 delete tt_lp_datos_pers tt
 where tt.cod_trabajador = as_codtra;

 --Lectura de los datos del Trabajador 
 select m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2,
        m.foto_trabaj,
        m.fec_nacimiento, m.direccion, m.cod_pais, m.cod_dpto,
        m.cod_prov, m.cod_distr, m.telefono1, m.telefono2,
        m.flag_sexo, m.flag_estado_civil, m.ruc, m.nro_brevete,
        m.nro_ipss, a.desc_afp, m.nro_afp_trabaj, m.dni, 
        m.lib_militar
  into  ls_apel_paterno, ls_apel_materno, ls_nombre1, ls_nombre2,
        ls_foto_trabaj,  
        ld_fec_nacim, ls_direccion, ls_cod_pais, ls_cod_dpto,
        ls_cod_prov, ls_cod_distr, ls_telef1, ls_telef2,
        ls_flg_sexo, ls_flg_est_civ, ls_ruc, ls_nro_brev,
        ls_nro_ipss, ls_desc_afp, ls_nro_afp_trab, ls_dni, 
        ls_lib_mil
 from maestro m, admin_afp a
 where m.cod_trabajador = as_codtra and
       m.cod_afp = a.cod_afp (+);
 
 --Cálculo de la Edad del Trabajador
 select sysdate
 into ld_fec_today
 from Dual;
 
 ln_dif := MONTHS_BETWEEN(ld_fec_today,ld_fec_nacim);
 ln_edad := ln_dif /12;

 --Inserción de los Nombres de la Ubic Geográfica
 --************************************************
 
 --PAIS del DOMICILIO
 select max(p.nom_pais), max(p.nacionalidad)
 into ls_nom_pais, ls_nacional
 from pais p
 where p.cod_pais = ls_cod_pais;
 ls_nom_pais := nvl(ls_nom_pais, ' ');
 ls_nacional := nvl(ls_nacional, ' ');

 --DEPARTAMENTO del DOMICILIO
 select max(d.desc_dpto)
 into ls_nom_dpto
 from departamento_estado d
 where  d.cod_pais = ls_cod_pais and
        d.cod_dpto = ls_cod_dpto;
 ls_nom_dpto := nvl(ls_nom_dpto,' ');

 --PROVINCIA del DOMICILIO
 select max(pc.desc_prov)
 into ls_nom_prov
 from provincia_condado pc
 where pc.cod_pais = ls_Cod_pais and
       pc.cod_dpto = ls_cod_dpto and
       pc.cod_prov = ls_cod_prov;
 ls_nom_prov := nvl(ls_nom_prov, ' ');

 --DISTRITO del DOMICILIO
 select max(d.desc_distrito)
 into ls_nom_distr
 from distrito d
 where  d.cod_pais = ls_Cod_pais and
        d.cod_dpto = ls_cod_dpto and
        d.cod_prov = ls_cod_prov and
        d.cod_distr = ls_cod_distr;
 ls_nom_distr := nvl(ls_nom_distr, ' ');

 --FIN de la Seleccion de Nombres de la Ubic Geograf
 --************************************************
 
 --Ingresamos datos a tt_lp_datos_pers
 INSERT INTO tt_lp_datos_pers
  ( cod_trabajador , apel_paterno  ,  apel_materno   ,
    nombre1        , nombre2       ,  foto_trabaj    ,
    fec_nacim      ,
    edad           , direc_lug_nac ,  pais_lug_nac   ,
    dpto_lug_nac   , prov_lug_nac  ,  distr_lug_nac  ,
    direc_actual   , pais_actual   ,  dpto_actual    ,
    prov_actual    , distr_actual  ,  nacionalidad   ,
    telefono1      , telefono2     ,  flg_sexo       ,
    flg_est_civil  , ruc           ,  nro_brevete    ,
    nro_ipss       , desc_afp      ,  nro_afp_trabaj ,
    dni            , lib_militar )
 values
  ( as_codtra      , ls_apel_paterno , ls_apel_materno ,
    ls_nombre1     , ls_nombre2      , ls_foto_trabaj  ,
    ld_fec_nacim    ,
    ln_edad        , ' '             , ' '             ,
    '  '           , ' '             , ' '             ,
    ls_direccion   , ls_nom_pais     , ls_nom_dpto     ,
    ls_nom_prov    , ls_nom_distr    , ls_nacional     ,
    ls_telef1      , ls_telef2       , ls_flg_sexo     ,
    ls_flg_est_civ , ls_ruc          , ls_nro_brev     ,
    ls_nro_ipss    , ls_desc_afp     , ls_nro_afp_trab , 
    ls_dni         , ls_lib_mil ) ;

end usp_lp_datos_pers;
/
