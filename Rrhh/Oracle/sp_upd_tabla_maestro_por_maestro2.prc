create or replace procedure sp_upd_tabla_maestro 
is

cursor c_maestro is 
select m.cod_trabajador, m.cod_trab_antguo, m.foto_trabaj
       m.apel_paterno, m.apel_materno, m.nombre1, 
       m.nombre2, m.flag_estado_civil, m.flag_cal_plnlla,
       m.flag_sindicato, m.flag_estado, m.fec_ingreso,
       m.fec_nacimiento, m.fec_cese, m.cod_motiv_cese,
       m.flag_sexo, m.direccion, m.tel_cod_ciudad,
       m.telefono1, m.telefono2, m.dni, 
       m.lib_militar, m.ruc, m.email,
       m.cod_tipo_brev, m.nro_brevete, m.carnet_trabaj,
       m.nro_ipss, m.cod_grado_inst, m.cod_profesion,
       m.cod_cargo, m.situa_trabaj, m.cod_afp,
       m.nro_afp_trabaj, m.fec_ini_afil_afp, m.fec_fin_afil_afp,
       m.porc_judicial, m.bonif_fija_30_25, m.flag_quincena,
       m.tipo_trabajador, m.nro_cnta_ahorro, m.nro_cnta_cts,
       m.cod_moneda, m.cod_empresa, m.cod_labor,
       m.cencos, m.flag_algun_famil, m.cod_usr, 
       m.cod_banco, m.cod_banco_cts, m.cod_tipo_sangre,
       m.cod_categ_sal, m.cod_seccion, m.cod_area,
       m.cod_pais, m.cod_dpto, m.cod_prov,
       m.cod_distr, m.cod_ciudad, m.cod_vivienda,
       m.flag_esposa, m.flag_convenio, m.flag_juicio

from  maestro m

begin
  
  
  
end sp_upd_tabla_maestro;
/
