create or replace procedure usp_rh_utl_rpt_adelantos (
  an_periodo in number, ad_fec_desde in date, ad_fec_hasta in date,
  as_origen in char, as_tipo_trabaj in char ) is

ls_nombres             varchar2(60) ;

--  Lectura del movimiento de adelantos a cuenta de utilidades
cursor c_movimiento is
  select m.cod_origen, o.nombre, m.tipo_trabajador, tt.desc_tipo_tra, m.cod_seccion,
         s.desc_seccion, a.cod_relacion, a.fecha_proceso, a.concep, c.desc_concep,
         a.imp_adelanto, a.imp_reten_jud
  from utl_adlt_ext a, maestro m, concepto c, seccion s, origen o, tipo_trabajador tt
  where a.cod_relacion = m.cod_trabajador and m.cod_origen like as_origen and
        m.tipo_trabajador like as_tipo_trabaj and m.cod_area = s.cod_area and
        m.cod_seccion = s.cod_seccion and m.cod_origen = o.cod_origen and
        m.tipo_trabajador = tt.tipo_trabajador and a.periodo = an_periodo and
        a.concep = c.concep and 
        trunc(a.fecha_proceso) between ad_fec_desde and ad_fec_hasta
  order by m.cod_seccion, a.cod_relacion, a.fecha_proceso ;
  
begin

--  **************************************************************
--  ***   GENERA REPORTE DE ADELANTOS A CUENTA DE UTILIDADES   ***
--  **************************************************************

delete from tt_utl_rpt_adelantos ;

for rc_mov in c_movimiento loop

  ls_nombres := usf_nombre_trabajador(rc_mov.cod_relacion) ;
  
  insert into tt_utl_rpt_adelantos (
    origen, desc_origen, tipo_trabaj, desc_tipo_trabaj, periodo,
    fec_desde, fec_hasta, cod_seccion, desc_desccion, cod_relacion,
    nombres, fec_proceso, concepto, desc_concepto, imp_adelanto,
    imp_retencion, imp_total )
  values (
    rc_mov.cod_origen, rc_mov.nombre, rc_mov.tipo_trabajador, rc_mov.desc_tipo_tra, an_periodo,
    ad_fec_desde, ad_fec_hasta, rc_mov.cod_seccion, rc_mov.desc_seccion, rc_mov.cod_relacion,
    ls_nombres, rc_mov.fecha_proceso, rc_mov.concep, rc_mov.desc_concep, nvl(rc_mov.imp_adelanto,0),
    nvl(rc_mov.imp_reten_jud,0), (nvl(rc_mov.imp_adelanto,0) + nvl(rc_mov.imp_reten_jud,0)) ) ;

end loop ;

end usp_rh_utl_rpt_adelantos ;
/
