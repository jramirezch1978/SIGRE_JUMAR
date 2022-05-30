create or replace procedure usp_rh_rpt_convenios_cts (
  as_tipo_trabajador in char, as_origen in char,
  ad_fec_desde in date, ad_fec_hasta in date,
  as_convenio_desde in char, as_convenio_hasta in char ) is

ls_cod_empresa          char(8) ;
ls_nom_empresa          varchar2(40) ;
ls_ruc                  char(11) ;
ls_direccion            varchar2(40) ;
ls_distrito             varchar2(40) ;
ls_provincia            varchar2(40) ;
ls_nombres              varchar2(40) ;
ls_nombre_jefe          varchar2(40) ;
ls_dni_jefe             char(8) ;
ls_cod_jefe             char(8) ;
ls_seccion              char(3) ;

--  Adelantos a cuenta de C.T.S. segun fechas y convenios
cursor c_movimiento is
  select a.cod_trabajador, a.fec_proceso, a.imp_a_cuenta, a.nro_convenio,
         m.dni, m.direccion
  from adel_cnta_cts a, maestro m
  where a.cod_trabajador = m.cod_trabajador and m.cod_origen = as_origen and
        m.tipo_trabajador = as_tipo_trabajador and
        (trunc(a.fec_proceso) between ad_fec_desde and ad_fec_hasta) and
        (trim(a.nro_convenio) between trim(as_convenio_desde) and trim(as_convenio_hasta))
  order by a.nro_convenio ;

begin

--  ********************************************************************
--  ***   REPORTE DE EMISION DE CONVENIOS SEGUN FECHAS Y CONVENIOS   ***
--  ********************************************************************

delete from tt_rpt_convenios ;

select p.cod_empresa into ls_cod_empresa from genparam p
  where p.reckey = '1' and p.cod_origen = as_origen ;

select e.nombre, e.ruc, e.dir_calle
  into ls_nom_empresa, ls_ruc, ls_direccion
  from empresa e where e.cod_empresa = ls_cod_empresa ;

select o.dir_distrito, o.dir_provincia
  into ls_distrito, ls_provincia
  from origen o where o.cod_origen = as_origen ;

select s.cod_jefe_seccion into ls_cod_jefe from seccion s
  where s.cod_seccion = '300' ;
ls_nombre_jefe := usf_nombre_trabajador (ls_cod_jefe) ;
select m.dni into ls_dni_jefe from maestro m
  where m.cod_trabajador = ls_cod_jefe ;

for rc_mov in c_movimiento loop

  ls_nombres := usf_nombre_trabajador (rc_mov.cod_trabajador) ;

  insert into tt_rpt_convenios (
    nro_convenio, nom_empresa, ruc, direccion_emp,
    nombre_jefe, dni_jefe, nombres, dni, direccion,
    distrito, provincia, imp_a_cuenta, fec_proceso )
  values (
    rc_mov.nro_convenio, ls_nom_empresa, ls_ruc, ls_direccion,
    ls_nombre_jefe, ls_dni_jefe, ls_nombres, rc_mov.dni, rc_mov.direccion,
    ls_distrito, ls_provincia, rc_mov.imp_a_cuenta, rc_mov.fec_proceso ) ;

end loop ;

end usp_rh_rpt_convenios_cts ;
/
