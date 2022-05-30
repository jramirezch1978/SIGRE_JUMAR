create global temporary table tt_lp_datos_pers
(
 cod_trabajador         char(8),
 apel_paterno           varchar2(30),
 apel_materno           varchar2(30),
 nombre1                varchar2(30),
 nombre2                varchar2(30),
 fec_nacim              date,
 edad                   number(3,1),
 direc_lug_nac          varchar2(100), --Lugar de Nacim
 pais_lug_nac           varchar2(30), --Nomb Pais de Nacim
 dpto_lug_naC           varchar2(30), --Nomb Dpto de Nacim 
 prov_lug_nac           varchar2(30), --Nomb Prov de Nacim
 distr_lug_nac          varchar2(30), --NOmb Distr de Nacim
 direc_actual           varchar2(100), --Lugar del Domic
 pais_actual            varchar2(30), --Nomb Pais de Domic 
 dpto_actual            varchar2(30), --Nomb Dpto de Domic 
 prov_actual            varchar2(30), --Nomb Prov de Domic
 distr_actual           varchar2(30), --Nomb Distr de Domic
 nacionalidad           varchar2(30), --Nacion del Trabaj
 telefono1              char(8),
 telefono2              char(8),
 flg_sexo               char(1),
 flg_est_civil          char(1),
 ruc                    char(11),
 nro_brevete            char(15),
 nro_ipss               char(15),     --Numero de la Pension
 desc_afp               varchar2(30), --Nombre AFP
 nro_afp_trabaj         char(12),     --Numero AFP del Trabaj
 dni                    char(8),
 lib_militar            char(12)  
 ) ;
  
