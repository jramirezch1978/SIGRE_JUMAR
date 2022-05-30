create or replace procedure usp_rh_rpt_det_plla_calc_rango_mm (
  as_origen in origen.cod_origen%type, 
  as_tipo_trabaj in tipo_trabajador.tipo_trabajador%type, 
  ad_fec_proceso_ini in date, 
  ad_fec_proceso_fin in date) is

ln_verifica           integer ;
ln_busca              integer ;
ls_codigo             char(8) ;
ln_imp_fijo           number(13,2) ;

--  Maestro de trabajadores segun origen y tipo de trabajador
cursor c_maestro is
  select m.cod_trabajador, m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2,
         m.flag_cal_plnlla, m.flag_sindicato, m.flag_estado, m.fec_ingreso,
         m.fec_nacimiento, m.flag_sexo, m.direccion, m.dni, m.carnet_trabaj,
         m.nro_ipss, m.cod_cargo, m.situa_trabaj, m.cod_afp, m.nro_afp_trabaj,
         m.porc_judicial, m.flag_quincena, m.tipo_trabajador, m.nro_cnta_ahorro,
         m.nro_cnta_cts, m.cencos, m.cod_categ_sal, m.cod_seccion, m.turno,
         m.flag_marca_reloj, m.cod_origen, s.desc_seccion, c.desc_cargo,
         cc.desc_cencos
  from maestro m, seccion s, cargo c, centros_costo cc
  where m.cod_origen = as_origen and 
        m.tipo_trabajador like as_tipo_trabaj and
        m.cod_area = s.cod_area(+) and 
        m.cod_seccion = s.cod_seccion(+) and
        m.cod_cargo = c.cod_cargo(+) and 
        m.cencos = cc.cencos(+) 
  order by m.cod_origen, m.tipo_trabajador, m.cod_seccion, m.apel_paterno,
           m.apel_materno, m.nombre1, m.nombre2 ;

--  Detalle de la planilla calculada actual
cursor c_calculo is
  select c.concep, c.fec_proceso, c.horas_trabaj, c.horas_pag, c.dias_trabaj,
         c.imp_soles, con.desc_breve
  from calculo c, concepto con
  where (c.cod_trabajador = ls_codigo) and 
        (trunc(c.fec_proceso) between ad_fec_proceso_ini and ad_fec_proceso_fin) and
        (c.concep = con.concep) 
  order by c.cod_trabajador, c.concep ;

cursor c_maestro_hist is
  select distinct(hc.cod_trabajador), m.apel_paterno, m.apel_materno, m.nombre1, m.nombre2,
         m.flag_cal_plnlla, m.flag_sindicato, m.flag_estado, m.fec_ingreso,
         m.fec_nacimiento, m.flag_sexo, m.direccion, m.dni, m.carnet_trabaj,
         m.nro_ipss, m.cod_cargo, m.situa_trabaj, m.cod_afp, m.nro_afp_trabaj,
         m.porc_judicial, m.flag_quincena, hc.tipo_trabajador, m.nro_cnta_ahorro,
         m.nro_cnta_cts, m.cencos, m.cod_categ_sal, m.cod_seccion, m.turno,
         m.flag_marca_reloj, hc.cod_origen, s.desc_seccion, c.desc_cargo,
         cc.desc_cencos
  from historico_calculo hc, maestro m, seccion s, cargo c, centros_costo cc
  where hc.cod_trabajador = m.cod_trabajador and 
        hc.cod_origen = as_origen and 
        hc.tipo_trabajador like as_tipo_trabaj and
        (trunc(hc.fec_calc_plan) between ad_fec_proceso_ini and ad_fec_proceso_fin) and 
        m.cod_area = s.cod_area(+) and 
        m.cod_seccion = s.cod_seccion(+) and
        m.cod_cargo = c.cod_cargo(+) and 
        m.cencos = cc.cencos(+) 
  order by hc.cod_origen, hc.tipo_trabajador, m.cod_seccion, m.apel_paterno,
           m.apel_materno, m.nombre1, m.nombre2 ;


--  Detalle de la planilla calcula historica
cursor c_historico is
  select h.concep, h.cod_afp, h.fec_calc_plan, h.horas_trabaj, h.horas_pagad, h.dias_trabaj,
         h.imp_soles, con.desc_breve
  from historico_calculo h, concepto con
  where (h.cod_trabajador = ls_codigo) and 
        (trunc(h.fec_calc_plan) between ad_fec_proceso_ini and ad_fec_proceso_fin) and 
        (h.concep = con.concep)
  order by h.cod_trabajador, h.concep ;

begin

--  ********************************************************
--  ***   REPORTE DEL DETALLE DE LA PLANILLA CALCULADA   ***
--  ********************************************************

delete from tt_det_plla_calculada ;

ln_verifica := 0 ;
select count(*) into ln_verifica from calculo c
  where (trunc(c.fec_proceso) between ad_fec_proceso_ini and ad_fec_proceso_fin)  and 
        (c.cod_origen like as_origen) ;

  
--raise_application_error(-20000,to_char(ln_verifica))  ;
FOR rc_m in c_maestro loop
    
  ls_codigo := rc_m.cod_trabajador ;
  
  IF ln_verifica > 0 THEN
  
    FOR rc_c in c_calculo LOOP 
    
      ln_busca := 0 ; ln_imp_fijo := 0 ;
      select count(*) 
        into ln_busca 
        from gan_desct_fijo f
       where f.cod_trabajador = ls_codigo and f.concep = rc_c.concep ;
      
      if ln_busca > 0 then
        select f.imp_gan_desc 
          into ln_imp_fijo 
         from gan_desct_fijo f
         where f.cod_trabajador = ls_codigo and f.concep = rc_c.concep ;
      end if ;
      
      -- Actualiza en caso ya exista el registro     
      UPDATE tt_det_plla_calculada tt
         SET tt.imp_pagado = NVL(tt.imp_pagado,0) + rc_c.imp_soles, 
             tt.horas_trabaj = NVL(tt.horas_trabaj,0) + rc_c.horas_trabaj, 
             tt.horas_pag = NVL(tt.horas_trabaj,0) + rc_c.horas_pag, 
             tt.dias_trabaj = NVL(tt.dias_trabaj,0) + rc_c.dias_trabaj
       WHERE tt.cod_trabajador = rc_m.cod_trabajador and 
             tt.cod_afp = NVL(rc_m.cod_afp,'') and 
             tt.concepto = rc_c.concep ;
      
      -- Adiciona en caso no exista el registro
      IF SQL%NOTFOUND THEN
          insert into tt_det_plla_calculada (
            tipo_trabajador, cod_seccion, desc_seccion, cod_trabajador,
            apel_paterno, apel_materno, nombre1, nombre2, fec_proceso,
            concepto, desc_concepto, imp_fijo, imp_pagado, horas_trabaj,
            horas_pag, dias_trabaj, cod_afp, cod_cargo, desc_cargo,
            cat_salar, cencos, desc_cencos, fec_ingreso, fec_nacimiento,
            porc_judicial, flag_estado, flag_cal_plla, dni, carnet_trabaj,
            nro_ipss, nro_afp, flag_quincena, cnta_ahorro, cnta_cts,
            turno, marca_reloj, flag_sexo, direccion, situac_trabaj,
            flag_sindicato, cod_origen )
          values (
            rc_m.tipo_trabajador, rc_m.cod_seccion, rc_m.desc_seccion, ls_codigo,
            rc_m.apel_paterno, rc_m.apel_materno, rc_m.nombre1, rc_m.nombre2, rc_c.fec_proceso,
            rc_c.concep, rc_c.desc_breve, ln_imp_fijo, rc_c.imp_soles, rc_c.horas_trabaj,
            rc_c.horas_pag, rc_c.dias_trabaj, NVL(rc_m.cod_afp,''), rc_m.cod_cargo, rc_m.desc_cargo,
            rc_m.cod_categ_sal, rc_m.cencos, rc_m.desc_cencos, rc_m.fec_ingreso, rc_m.fec_nacimiento,
            rc_m.porc_judicial, rc_m.flag_estado, rc_m.flag_cal_plnlla, rc_m.dni, rc_m.carnet_trabaj,
            rc_m.nro_ipss, rc_m.nro_afp_trabaj, rc_m.flag_quincena, rc_m.nro_cnta_ahorro, rc_m.nro_cnta_cts,
            rc_m.turno, rc_m.flag_marca_reloj, rc_m.flag_sexo, rc_m.direccion, rc_m.situa_trabaj,
            rc_m.flag_sindicato, rc_m.cod_origen ) ;
      END IF ;  
    END LOOP ;
    
  END IF ;
/*  
  FOR rc_h in c_historico LOOP
    
      ln_busca := 0 ; ln_imp_fijo := 0 ;
      select count(*) into ln_busca from gan_desct_fijo f
        where f.cod_trabajador = ls_codigo and f.concep = rc_h.concep ;
      
      -- Calculo las ganancias fijas  
      IF ln_busca > 0 then
        select f.imp_gan_desc 
          into ln_imp_fijo 
          from gan_desct_fijo f
         where f.cod_trabajador = ls_codigo and f.concep = rc_h.concep ;
      END IF;

      -- Actualiza en caso ya exista el registro     
      UPDATE tt_det_plla_calculada tt
         SET tt.imp_pagado = NVL(tt.imp_pagado,0) + rc_h.imp_soles, 
             tt.horas_trabaj = NVL(tt.horas_trabaj,0) + rc_h.horas_trabaj, 
             tt.horas_pag = NVL(tt.horas_trabaj,0) + rc_h.horas_trabaj, 
             tt.dias_trabaj = NVL(tt.dias_trabaj,0) + rc_h.dias_trabaj 
       WHERE tt.cod_trabajador = rc_m.cod_trabajador and 
             tt.cod_afp = rc_h.cod_afp and 
             tt.concepto = rc_h.concep ;
            
      IF SQL%NOTFOUND THEN      
          insert into tt_det_plla_calculada (
            tipo_trabajador, cod_seccion, desc_seccion, cod_trabajador,
            apel_paterno, apel_materno, nombre1, nombre2, fec_proceso,
            concepto, desc_concepto, imp_fijo, imp_pagado, horas_trabaj,
            horas_pag, dias_trabaj, cod_afp, cod_cargo, desc_cargo,
            cat_salar, cencos, desc_cencos, fec_ingreso, fec_nacimiento,
            porc_judicial, flag_estado, flag_cal_plla, dni, carnet_trabaj,
            nro_ipss, nro_afp, flag_quincena, cnta_ahorro, cnta_cts,
            turno, marca_reloj, flag_sexo, direccion, situac_trabaj,
            flag_sindicato, cod_origen )
          values (
            rc_m.tipo_trabajador, rc_m.cod_seccion, rc_m.desc_seccion, ls_codigo,
            rc_m.apel_paterno, rc_m.apel_materno, rc_m.nombre1, rc_m.nombre2, rc_h.fec_calc_plan,
            rc_h.concep, rc_h.desc_breve, ln_imp_fijo, rc_h.imp_soles, rc_h.horas_trabaj,
            rc_h.horas_pagad, rc_h.dias_trabaj, rc_m.cod_afp, rc_m.cod_cargo, rc_m.desc_cargo,
            rc_m.cod_categ_sal, rc_m.cencos, rc_m.desc_cencos, rc_m.fec_ingreso, rc_m.fec_nacimiento,
            rc_m.porc_judicial, rc_m.flag_estado, rc_m.flag_cal_plnlla, rc_m.dni, rc_m.carnet_trabaj,
            rc_m.nro_ipss, rc_m.nro_afp_trabaj, rc_m.flag_quincena, rc_m.nro_cnta_ahorro, rc_m.nro_cnta_cts,
            rc_m.turno, rc_m.flag_marca_reloj, rc_m.flag_sexo, rc_m.direccion, rc_m.situa_trabaj,
            rc_m.flag_sindicato, rc_m.cod_origen ) ;
        END IF ;
    END LOOP ;
*/  
END LOOP ;

FOR rc_mh in c_maestro_hist  loop
    
  ls_codigo := rc_mh.cod_trabajador ;
  
  FOR rc_h in c_historico LOOP
    
      ln_busca := 0 ; ln_imp_fijo := 0 ;
      select count(*) into ln_busca from gan_desct_fijo f
        where f.cod_trabajador = ls_codigo and f.concep = rc_h.concep ;
      
      -- Calculo las ganancias fijas  
      IF ln_busca > 0 then
        select f.imp_gan_desc 
          into ln_imp_fijo 
          from gan_desct_fijo f
         where f.cod_trabajador = ls_codigo and f.concep = rc_h.concep ;
      END IF;

      -- Actualiza en caso ya exista el registro     
      UPDATE tt_det_plla_calculada tt
         SET tt.imp_pagado = NVL(tt.imp_pagado,0) + rc_h.imp_soles, 
             tt.horas_trabaj = NVL(tt.horas_trabaj,0) + rc_h.horas_trabaj, 
             tt.horas_pag = NVL(tt.horas_trabaj,0) + rc_h.horas_trabaj, 
             tt.dias_trabaj = NVL(tt.dias_trabaj,0) + rc_h.dias_trabaj 
       WHERE tt.cod_trabajador = rc_mh.cod_trabajador and 
             tt.cod_afp = NVL(rc_h.cod_afp,'') and 
             tt.concepto = rc_h.concep ;
            
      IF SQL%NOTFOUND THEN      
          insert into tt_det_plla_calculada (
            tipo_trabajador, cod_seccion, desc_seccion, cod_trabajador,
            apel_paterno, apel_materno, nombre1, nombre2, fec_proceso,
            concepto, desc_concepto, imp_fijo, imp_pagado, horas_trabaj,
            horas_pag, dias_trabaj, cod_afp, cod_cargo, desc_cargo,
            cat_salar, cencos, desc_cencos, fec_ingreso, fec_nacimiento,
            porc_judicial, flag_estado, flag_cal_plla, dni, carnet_trabaj,
            nro_ipss, nro_afp, flag_quincena, cnta_ahorro, cnta_cts,
            turno, marca_reloj, flag_sexo, direccion, situac_trabaj,
            flag_sindicato, cod_origen )
          values (
            rc_mh.tipo_trabajador, rc_mh.cod_seccion, rc_mh.desc_seccion, ls_codigo,
            rc_mh.apel_paterno, rc_mh.apel_materno, rc_mh.nombre1, rc_mh.nombre2, rc_h.fec_calc_plan,
            rc_h.concep, rc_h.desc_breve, ln_imp_fijo, rc_h.imp_soles, rc_h.horas_trabaj,
            rc_h.horas_pagad, rc_h.dias_trabaj, NVL(rc_mh.cod_afp,''), rc_mh.cod_cargo, rc_mh.desc_cargo,
            rc_mh.cod_categ_sal, rc_mh.cencos, rc_mh.desc_cencos, rc_mh.fec_ingreso, rc_mh.fec_nacimiento,
            rc_mh.porc_judicial, rc_mh.flag_estado, rc_mh.flag_cal_plnlla, rc_mh.dni, rc_mh.carnet_trabaj,
            rc_mh.nro_ipss, rc_mh.nro_afp_trabaj, rc_mh.flag_quincena, rc_mh.nro_cnta_ahorro, rc_mh.nro_cnta_cts,
            rc_mh.turno, rc_mh.flag_marca_reloj, rc_mh.flag_sexo, rc_mh.direccion, rc_mh.situa_trabaj,
            rc_mh.flag_sindicato, rc_mh.cod_origen ) ;
        END IF ;
    END LOOP ;
  
END LOOP ;

END usp_rh_rpt_det_plla_calc_rango_mm ;
/
