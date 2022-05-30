create or replace procedure usp_rh_cal_borra_movimiento (
  as_origen in char, ad_fec_proceso in date, as_tipo_doc in char ) is

begin

--  *******************************************************
--  ***   ELIMINA MOVIMIENTO DE LA PLANILLA CALCULADA   ***
--  *******************************************************

delete from gan_desct_variable g
  where g.tipo_doc = as_tipo_doc and g.cod_trabajador in
        ( select m.cod_trabajador from maestro m where
          m.cod_origen = as_origen ) ;

delete from calculo c
  where c.cod_trabajador in
        ( select m.cod_trabajador from maestro m where
          m.cod_origen = as_origen ) ;

delete from cnta_crrte_detalle cc
  where cc.fec_dscto = ad_fec_proceso and cc.cod_trabajador in
        ( select m.cod_trabajador from maestro m where
          m.cod_origen = as_origen ) ;

delete from diferido d
  where d.fec_proceso = ad_fec_proceso and d.cod_trabajador in
        ( select m.cod_trabajador from maestro m where
          m.cod_origen = as_origen ) ;

delete from quinta_categoria q
  where q.fec_proceso = ad_fec_proceso and q.cod_trabajador in
        ( select m.cod_trabajador from maestro m where
          m.cod_origen = as_origen ) ;

commit ;

end usp_rh_cal_borra_movimiento ;
/
