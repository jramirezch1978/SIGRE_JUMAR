select m.porc_judicial, 
       m.centro_benef, cb.desc_centro, 
       m.calif_tipo, 
       decode(m.flag_cat_trab,'1','Trabajador','2','Pensionista','3','Prestador de servicio','4','Personal de terceros') as Categ_trabajador,  
       m.cod_tipo_pension, rhtpr.descripcion, 
       decode(m.flag_reg_laboral,'1','R.Público','2','R.Privado') as regimen_laboral, 
       m.cod_sit_eps, rhser.descripcion, 
       m.cod_tip_trab, rhttr.descripcion, 
       m.cod_eps, rher.descripcion, 
       m.cod_reg_pension, rhrpr.descripcion, 
       m.cod_tipo_contrato, rhtcr.descripcion, 
       m.cod_estado_civil, rhecr.descripcion, 
       m.flag_essalud_vida, 
       m.flag_sctr_salud, 
       m.flag_discapacidad, 
       m.flag_domiciliado, 
       m.cod_via, rhvr.descripcion, 
       m.nombre_via, 
       m.numero_via, 
       m.interior, 
       m.cod_zona, rhzr.descripcion, 
       m.referencia, 
       m.cod_periocidad_rem, rhprr.descripcion, 
       m.flag_tipo_remun_rtps, 
       m.cod_mod_pago_rtps, rhmpr.desc_mod_pago_rtps, 
       m.tipo_doc_ident_rtps, rhtdr.desc_tipo_doc_rtps, 
       m.nro_doc_ident_rtps, 
       m.cod_ocupacion_rtps, ror.desc_ocupacion, 
       m.flag_sctr_pension, 
       m.turno_asist, 
       m.fec_inscrip_reg, 
       m.flag_pensionista, 
       m.flag_sujeto_control_, 
       m.cod_pais_nac, rh_pais.nom_pais, 
       m.cod_dpto_nac, rh_dep.desc_dpto, 
       m.cod_prov_nac, rh_prov.desc_prov, 
       m.cod_dist_nac, rh_dist.desc_distrito, 
       m.flag_jornada_alterna, 
       m.flag_jornada_maxima, 
       m.flag_horario_nocturno, 
       m.flag_otros_quinta_categ, 
       m.flag_afiliado_eps, 
       m.flag_quinta_exonerado, 
       m.flag_tipo_relacion, 
       m.flag_seguro_medico, 
       m.flag_madre_resp_familiar, 
       m.flag_formacion_personal
  from maestro m, 
       centro_beneficio cb, 
       rrhh_tipo_pensiones_rtps rhtpr, 
       rrhh_situacion_eps_rtps rhser, 
       rrhh_tipo_trabajadores_rtps rhttr, 
       rrhh_eps_rtps rher, 
       rrhh_regimen_pensionario_rtps rhrpr, 
       rrhh_tipos_contrato_rtps rhtcr,
       rrhh_estado_civil_rtps rhecr,  
       rrhh_vias_rtps rhvr, 
       rrhh_zonas_rtps rhzr, 
       rrhh_periodo_remun_rtps rhprr, 
       rrhh_modalidad_pago_rtps rhmpr, 
       rrhh_tipo_doc_rtps rhtdr, 
       rrhh_ocupacion_rtps ror, 
       pais rh_pais, 
       departamento_estado rh_dep, 
       provincia_condado rh_prov, 
       distrito rh_dist
where m.centro_benef = cb.centro_benef(+) 
  and m.cod_tipo_pension = rhtpr.cod_tipo_pension (+) 
  and m.cod_sit_eps = rhser.cod_sit_eps (+) 
  and m.cod_tip_trab = rhttr.cod_tip_trab (+) 
  and m.cod_eps = rher.cod_eps (+) 
  and m.cod_reg_pension = rhrpr.cod_reg_pension (+) 
  and m.cod_tipo_contrato = rhtcr.cod_tipo_contrato (+) 
  and m.cod_estado_civil = rhecr.cod_estado_civil (+) 
  and m.cod_via = rhvr.cod_via (+)  
  and m.cod_zona = rhzr.cod_zona (+)  
  and m.cod_periocidad_rem = rhprr.cod_periocidad_rem (+)  
  and m.cod_mod_pago_rtps = rhmpr.cod_mod_pago_rtps (+) 
  and m.tipo_doc_ident_rtps = rhtdr.tipo_doc_rtps (+) 
  and m.cod_ocupacion_rtps = ror.cod_ocupacion_rtps (+)  
  and m.cod_pais_nac = rh_pais.cod_pais (+) 
  and (m.cod_pais_nac = rh_dep.cod_pais(+) and m.cod_dpto_nac = rh_dep.cod_dpto (+)) 
  and (m.cod_pais_nac = rh_prov.cod_pais(+) and m.cod_dpto_nac = rh_prov.cod_dpto(+) and m.cod_prov_nac = rh_prov.cod_prov (+)) 
  and (m.cod_pais_nac = rh_dist.cod_pais(+) and m.cod_dpto_nac = rh_dist.cod_dpto(+) and m.cod_prov_nac = rh_dist.cod_prov(+) and m.cod_dist_nac = rh_dist.cod_distr (+))
 