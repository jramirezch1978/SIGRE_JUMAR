Select m.cod_trabajador,
       upper(m.apel_paterno) as paterno,
       upper(m.apel_materno) as materno,
       upper(m.nombre1) as nombre1,
       upper(NVL(m.nombre2,' ')) as nombre2,
       m.flag_estado_civil,
       decode(NVL(m.flag_estado_civil,'O'), 'C', 'CASADO(A)', 'S', 'SOLTERO(A)', 'V', 'VIUDO(A)', 'D', 'DIVORCIADO(A)', 'OTRO') as estado_civil,
       decode(m.flag_cal_plnlla, '1', 'SI', 'NO') as planilla,
       decode(m.flag_sindicato, '1', 'SI', 'NO') as sindicato,
       m.flag_estado, 
       decode(m.flag_estado, '1', 'ACTIVO', 'INACTIVO') as estado,       
       m.fec_ingreso,
       to_char(m.fec_ingreso, 'dd/mm/yyyy') as ingreso,
       m.fec_nacimiento,
       to_char(m.fec_nacimiento, 'dd/mm/yyyy') as nacimiento,
       m.fec_cese,
       to_char(m.fec_cese, 'dd/mm/yyyy') as cese,
       upper(mc.desc_motiv_cese) as motivo_cese,
       m.flag_sexo,
       decode(m.flag_sexo, 'M', 'MASCULINO', 'FEMENINO') as sexo,
       upper(m.direccion) as direccion_postal,
       m.tel_cod_ciudad as disc_ciu,
       m.telefono1 as tel_princ,
       m.telefono2 as tel_sec,
       m.dni as dni,
       m.lib_militar as lib_milit,
       m.ruc as ruc,
       lower(m.email) as correo_electronico,
       upper(tb.desc_brev) as tipo_brevete,
       upper(m.nro_brevete) as nro_brevete,
       m.carnet_trabaj as carnet,
       m.nro_ipss as seguro_social,
       upper(gi.desc_instruc) as grado_instruccion,
       upper(p.desc_profesion) as profesion,
       upper(c.desc_cargo) as cargo,
       upper(st.desc_sit_trab) as situacion_trabajador,
       m.cod_afp,
       upper(aa.desc_afp) as afp,
       upper(m.nro_afp_trabaj) as nro_afp,
       m.fec_ini_afil_afp,
       to_char(m.fec_ini_afil_afp, 'dd/mm/yyyy') as ini_afp,
       to_char(m.fec_fin_afil_afp, 'dd/mm/yyyy') as fin_afp,
       to_char(m.porc_judicial, '990,00') as judicial,
       decode(m.bonif_fija_30_25, '1', '30%', '2', '25%', 'NO PERCIBE') as bonificacion_fija,
       decode(m.flag_quincena, '1', 'SI', 'NO') as quincena,
       m.tipo_trabajador as cod_tipo_trabajador,
       upper(tt.desc_tipo_tra) as tipo_trabajador,
       m.nro_cnta_ahorro as nro_cnta_ahorro,
       m.nro_cnta_cts as nro_cnta_cts,
       upper(mo.descripcion) as moneda_ahorros,
       upper(e.nombre) as empresa,
       upper(l.desc_labor) as labor,
       m.cencos,
       upper(cc.desc_cencos) as centro_costo,
       m.cod_banco,
       upper(b1.nom_banco) as banco_ahorro,
       m.moneda_cts as MonedaCts,        
       upper(b2.nom_banco) as banco_cts,
       upper(ts.desc_sangre) as tipo_sangre,
       trim(to_char(cs.imp_categ_min)) || ' - ' || trim(to_char(cs.imp_categ_max)) as categoria_salarial,
       m.cod_area,
       upper(a.desc_area) as area,
       m.cod_seccion,
       upper(s.desc_seccion) as seccion,
       upper(ps.nom_pais) as pais,
       upper(de.desc_dpto) as departamento,
       upper(pc.desc_prov) as provincia,
       upper(dt.cod_distr) as distrito,       
       upper(cd.descr_ciudad) as ciudad,
       upper(vd.desc_vivienda) as vivienda,
       upper(tr.descripcion) as turno,
       decode(m.flag_marca_reloj, '1', 'SI', 'NO') as marca_reloj,
       decode(m.flag_convenio, '1', 'SI', 'NO') as convenio,
       decode(m.flag_juicio, '1', 'SI', 'NO') as calcula_sobretirmpo,
       m.cod_origen,
       upper(o.nombre) as origen,        
       m.porc_judicial, 
       m.centro_benef, cb.desc_centro as desc_centro_benef, 
       m.calif_tipo, 
       decode(m.flag_cat_trab,'1','Trabajador','2','Pensionista','3','Prestador de servicio','4','Personal de terceros') as Categ_trabajador,  
       m.cod_tipo_pension, rhtpr.descripcion as desc_tipo_pension, 
       decode(m.flag_reg_laboral,'1','R.Público','2','R.Privado') as regimen_laboral, 
       m.cod_sit_eps, rhser.descripcion as desc_situac_eps, 
       m.cod_tip_trab, rhttr.descripcion as desc_tipo_trabaj, 
       m.cod_eps, rher.descripcion as desc_eps, 
       m.cod_reg_pension, rhrpr.descripcion as desc_reg_pension, 
       m.cod_tipo_contrato, rhtcr.descripcion as desc_tipo_contrato, 
       m.cod_estado_civil, rhecr.descripcion as desc_estado_civil, 
       m.flag_essalud_vida, 
       m.flag_sctr_salud, 
       m.flag_discapacidad, 
       m.flag_domiciliado, 
       m.cod_via, rhvr.descripcion as desc_via, 
       m.nombre_via, 
       m.numero_via, 
       m.interior, 
       m.cod_zona, rhzr.descripcion as desc_zona, 
       m.referencia, 
       m.cod_periocidad_rem, rhprr.descripcion as desc_periodo_renum, 
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
    from maestro m, motivo_cese mc, 
         tipo_brevete tb, grado_instruccion gi, 
         profesion p, cargo c, 
         situacion_trabajador st, admin_afp aa, 
         tipo_trabajador tt, moneda mo, 
         empresa e, labor l, 
         centros_costo cc, banco b1, 
         banco b2, tipo_sangre ts, 
         categoria_salarial cs, area a, 
         seccion s, pais ps, 
         departamento_estado de, provincia_condado pc, 
         ciudad cd, distrito dt, 
         vivienda vd, turno tr, 
         origen o, centro_beneficio cb, 
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
    where m.cod_motiv_cese = mc.cod_motiv_cese (+) and  
          m.cod_tipo_brev = tb.cod_tipo_brev (+) and 
          m.cod_grado_inst = gi.cod_grado_inst (+) and 
          m.cod_profesion = p.cod_profesion (+) and 
          m.cod_cargo = c.cod_cargo (+) and 
          m.situa_trabaj = st.situa_trabaj (+) and 
          m.cod_afp = aa.cod_afp (+) and 
          m.tipo_trabajador = tt.tipo_trabajador (+) and 
          m.cod_moneda = mo.cod_moneda (+) and 
          m.cod_empresa = e.cod_empresa (+) and 
          m.cod_labor = l.cod_labor (+) and 
          m.cencos = cc.cencos (+) and 
          m.cod_banco = b1.cod_banco (+) and 
          m.cod_banco_cts = b2.cod_banco (+) and 
          m.cod_tipo_sangre = ts.cod_tipo_sangre (+) and 
          m.cod_categ_sal = cs.cod_categ_sal (+) and 
          m.cod_area = a.cod_area (+) and 
          (m.cod_area = s.cod_area(+) and m.cod_seccion = s.cod_seccion (+)) and 
          m.cod_pais = ps.cod_pais (+) and 
          (m.cod_pais = de.cod_pais(+) and m.cod_dpto = de.cod_dpto(+)) and 
          (m.cod_pais = pc.cod_pais(+) and m.cod_dpto = pc.cod_dpto(+) and m.cod_prov = pc.cod_prov(+)) and 
          (m.cod_pais = cd.cod_pais(+) and m.cod_dpto = cd.cod_dpto(+) and m.cod_prov = cd.cod_prov(+) and m.cod_ciudad = cd.cod_ciudad(+)) and 
          (m.cod_pais = dt.cod_pais(+) and m.cod_dpto = dt.cod_dpto(+) and m.cod_prov = dt.cod_prov(+) and m.cod_ciudad = dt.cod_distr(+)) and 
          m.cod_vivienda = vd.cod_vivienda(+) and 
          m.turno = tr.turno (+) and 
          m.cod_origen = o.cod_origen (+) and 
          m.centro_benef = cb.centro_benef(+) and 
          m.cod_tipo_pension = rhtpr.cod_tipo_pension (+) and 
          m.cod_sit_eps = rhser.cod_sit_eps (+) and 
          m.cod_tip_trab = rhttr.cod_tip_trab (+) and 
          m.cod_eps = rher.cod_eps (+) and 
          m.cod_reg_pension = rhrpr.cod_reg_pension (+) and 
          m.cod_tipo_contrato = rhtcr.cod_tipo_contrato (+) and 
          m.cod_estado_civil = rhecr.cod_estado_civil (+) and 
          m.cod_via = rhvr.cod_via (+) and 
          m.cod_zona = rhzr.cod_zona (+) and 
          m.cod_periocidad_rem = rhprr.cod_periocidad_rem (+) and 
          m.cod_mod_pago_rtps = rhmpr.cod_mod_pago_rtps (+) and 
          m.tipo_doc_ident_rtps = rhtdr.tipo_doc_rtps (+) and 
          m.cod_ocupacion_rtps = ror.cod_ocupacion_rtps (+) and 
          m.cod_pais_nac = rh_pais.cod_pais (+) and 
          (m.cod_pais_nac = rh_dep.cod_pais(+) and m.cod_dpto_nac = rh_dep.cod_dpto (+)) and 
          (m.cod_pais_nac = rh_prov.cod_pais(+) and m.cod_dpto_nac = rh_prov.cod_dpto(+) and m.cod_prov_nac = rh_prov.cod_prov (+)) and 
          (m.cod_pais_nac = rh_dist.cod_pais(+) and m.cod_dpto_nac = rh_dist.cod_dpto(+) and m.cod_prov_nac = rh_dist.cod_prov(+) and m.cod_dist_nac = rh_dist.cod_distr (+)) 
order by m.cod_trabajador 
