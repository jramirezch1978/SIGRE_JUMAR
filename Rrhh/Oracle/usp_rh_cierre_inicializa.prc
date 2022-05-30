create or replace procedure usp_rh_cierre_inicializa (
  as_origen in char, ad_fec_desde in date, ad_fec_hasta in date,
  ad_fec_proceso in date, as_tipo_trabaj in char ) is

begin

--  *****************************************************************
--  ***   INICIALIZA MOVIMIENTO DE CALCULO PARA NUEVOS PROCESOS   ***
--  *****************************************************************

delete from sobretiempo_turno st
  where (trunc(st.fec_movim) between ad_fec_desde and ad_fec_hasta) and
        st.cod_trabajador in ( select m.cod_trabajador from maestro m
        where m.cod_origen = as_origen and m.tipo_trabajador like as_tipo_trabaj ) ;

delete from gan_desct_variable gdv
  where (trunc(gdv.fec_movim) between ad_fec_desde and ad_fec_proceso) and
        gdv.cod_trabajador in ( select m.cod_trabajador from maestro m
        where m.cod_origen = as_origen and m.tipo_trabajador like as_tipo_trabaj ) ;

delete from inasistencia i
  where (trunc(i.fec_movim) between ad_fec_desde and ad_fec_hasta) and
        i.cod_trabajador in ( select m.cod_trabajador from maestro m
        where m.cod_origen = as_origen and m.tipo_trabajador like as_tipo_trabaj ) ;

commit ;

end usp_rh_cierre_inicializa ;
/
