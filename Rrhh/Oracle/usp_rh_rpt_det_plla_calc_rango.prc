create or replace procedure usp_rh_rpt_det_plla_calc_rango (
  asi_origen       in origen.cod_origen%type,
  asi_tipo_trabaj  in tipo_trabajador.tipo_trabajador%type,
  adi_desde        in date,
  adi_hasta        in date
) is

begin

--  ********************************************************
--  ***   REPORTE DEL DETALLE DE LA PLANILLA CALCULADA   ***
--  ********************************************************

delete from tt_det_plla_calculada ;

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
  select  m.tipo_trabajador, m.cod_seccion, s.desc_seccion, m.cod_trabajador,
          m.apel_paterno, apel_materno, nombre1, nombre2, fec_proceso,
          ca.concep, co.desc_breve, (select NVL(sum(gdf.imp_gan_desc),0) from gan_desct_fijo gdf where gdf.cod_trabajador = m.cod_trabajador and gdf.flag_estado = '1' and gdf.concep like '1%'), imp_soles, horas_trabaj,
          horas_pag, dias_trabaj, m.cod_afp, m.cod_cargo, desc_cargo,
          '', m.cencos, desc_cencos, fec_ingreso, fec_nacimiento,
          porc_judicial, m.flag_estado, m.flag_cal_plnlla, dni, carnet_trabaj,
          nro_ipss, m.nro_afp_trabaj, flag_quincena, m.nro_cnta_ahorro, m.nro_cnta_cts,
          turno, m.flag_marca_reloj, flag_sexo, direccion, m.situa_trabaj,
          flag_sindicato, m.cod_origen 
  from maestro       m, 
       seccion       s, 
       cargo         c, 
       centros_costo cc,
       calculo       ca, 
       concepto      co
  where m.cod_area    = s.cod_area 
    and m.cod_seccion = s.cod_seccion 
    and m.cod_cargo   = c.cod_cargo 
    and m.cencos      = cc.cencos(+)
    and ca.cod_trabajador = m.cod_trabajador
    and ca.concep         = co.concep
    and m.cod_origen      = asi_origen 
    and m.tipo_trabajador like asi_tipo_trabaj
    and trunc(ca.fec_proceso) between adi_desde and adi_hasta
  order by m.cod_origen, m.tipo_trabajador, m.cod_seccion, m.apel_paterno,
           m.apel_materno, m.nombre1, m.nombre2 ;

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
  select  m.tipo_trabajador, m.cod_seccion, s.desc_seccion, m.cod_trabajador,
          m.apel_paterno, apel_materno, nombre1, nombre2, ca.fec_calc_plan,
          ca.concep, co.desc_breve, (select NVL(sum(gdf.imp_gan_desc),0) from gan_desct_fijo gdf where gdf.cod_trabajador = m.cod_trabajador and gdf.flag_estado = '1' and gdf.concep like '1%'), imp_soles, horas_trabaj,
          ca.horas_pagad, dias_trabaj, m.cod_afp, m.cod_cargo, desc_cargo,
          '', m.cencos, desc_cencos, fec_ingreso, fec_nacimiento,
          porc_judicial, m.flag_estado, m.flag_cal_plnlla, dni, carnet_trabaj,
          nro_ipss, m.nro_afp_trabaj, flag_quincena, m.nro_cnta_ahorro, m.nro_cnta_cts,
          turno, m.flag_marca_reloj, flag_sexo, direccion, m.situa_trabaj,
          flag_sindicato, m.cod_origen 
  from maestro       m, 
       seccion       s, 
       cargo         c, 
       centros_costo cc,
       historico_calculo ca, 
       concepto      co
  where m.cod_area    = s.cod_area 
    and m.cod_seccion = s.cod_seccion 
    and m.cod_cargo   = c.cod_cargo 
    and m.cencos      = cc.cencos(+)
    and ca.cod_trabajador = m.cod_trabajador
    and ca.concep         = co.concep
    and m.cod_origen      = asi_origen 
    and m.tipo_trabajador like asi_tipo_trabaj
    and trunc(ca.fec_calc_plan) between adi_desde and adi_hasta
  order by m.cod_origen, m.tipo_trabajador, m.cod_seccion, m.apel_paterno,
           m.apel_materno, m.nombre1, m.nombre2 ;          

END usp_rh_rpt_det_plla_calc_rango ;
/
