create or replace procedure usp_rh_utl_rpt_det_utilidades (
  an_periodo in number ) is
  
ln_verifica            integer ;
ls_origen              char(2) ;
ls_desc_origen         varchar2(50) ;
ls_tipo_trabaj         char(3) ;
ls_desc_tipo_trabaj    varchar2(30) ;
ls_seccion             char(3) ;
ls_desc_seccion        varchar2(30) ;

--  Lectura del calculo de utilidades del ejercicio
cursor c_movimiento is
  select u.cod_relacion, u.remun_anual, u.imp_utl_remun_anual, u.dias_efectivos,
         u.imp_ult_dias_efect, u.adelantos, u.reten_jud, p.nom_proveedor
  from utl_ext_hist u, proveedor p
  where u.periodo = an_periodo and u.cod_relacion = p.proveedor
  order by u.cod_relacion ;
  
begin

--  *******************************************************
--  ***   GENERA REPORTE AL DETALLE DE LAS UTILIDADES   ***
--  *******************************************************

delete from tt_utl_rpt_det_utilidades ;

for rc_mov in c_movimiento loop

  ls_origen      := 'SC' ;  ls_desc_origen      := 'SIN ORIGEN' ;
  ls_tipo_trabaj := 'OTR' ; ls_desc_tipo_trabaj := 'OTROS' ;
  ls_seccion     := 'SS' ;  ls_desc_seccion     := 'SIN SECCION' ;
  ln_verifica    := 0 ;
  select count(*) into ln_verifica from maestro m
    where m.cod_trabajador = rc_mov.cod_relacion ;
  if ln_verifica > 0 then
    select m.cod_origen, o.nombre, m.tipo_trabajador, tt.desc_tipo_tra, m.cod_seccion,
           s.desc_seccion
      into ls_origen, ls_desc_origen, ls_tipo_trabaj, ls_desc_tipo_trabaj, ls_seccion,
           ls_desc_seccion
      from maestro m, origen o, tipo_trabajador tt, seccion s
      where m.cod_trabajador = rc_mov.cod_relacion and m.cod_origen = o.cod_origen and
            m.tipo_trabajador = tt.tipo_trabajador and m.cod_area = s.cod_area and
            m.cod_seccion = s.cod_seccion ;
  end if ;
  
  insert into tt_utl_rpt_det_utilidades (
    origen, desc_origen, tipo_trabaj, desc_tipo_trabaj, periodo,
    cod_seccion, desc_desccion, cod_relacion, nombres,
    remuner_anual, imp_remuner_anual, dias_anual,
    imp_dias_anual, imp_utilidades,
    adelantos, reten_judicial,
    imp_utl_netas )
  values (
    ls_origen, ls_desc_origen, ls_tipo_trabaj, ls_desc_tipo_trabaj, an_periodo,
    ls_seccion, ls_desc_seccion, rc_mov.cod_relacion, rc_mov.nom_proveedor,
    nvl(rc_mov.remun_anual,0), nvl(rc_mov.imp_utl_remun_anual,0), nvl(rc_mov.dias_efectivos,0),
    nvl(rc_mov.imp_ult_dias_efect,0), (nvl(rc_mov.imp_utl_remun_anual,0) + nvl(rc_mov.imp_ult_dias_efect,0)),
    nvl(rc_mov.adelantos,0), nvl(rc_mov.reten_jud,0),
    (nvl(rc_mov.imp_utl_remun_anual,0) + nvl(rc_mov.imp_ult_dias_efect,0) - nvl(rc_mov.adelantos,0) -
    nvl(rc_mov.reten_jud,0)) ) ;

end loop ;

end usp_rh_utl_rpt_det_utilidades ;
/
