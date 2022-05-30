create or replace procedure usp_rh_cal_borra_mov_calculo (
  asi_origen       in origen.cod_origen%TYPE, 
  adi_fec_proceso  in date, 
  asi_tipo_doc     in doc_tipo.tipo_doc%TYPE,
  asi_tipo_trabaj  in tipo_trabajador.tipo_trabajador %TYPE
) is

begin

--  *******************************************************
--  ***   ELIMINA MOVIMIENTO DE LA PLANILLA CALCULADA   ***
--  *******************************************************

delete from gan_desct_variable g
  where g.tipo_doc = asi_tipo_doc 
    and g.cod_trabajador in ( select m.cod_trabajador 
                                from maestro m 
                               where m.tipo_trabajador = asi_tipo_trabaj 
                                 and m.cod_origen      = asi_origen ) ;

delete from calculo c
  where c.cod_trabajador in ( select m.cod_trabajador 
                               from maestro m 
                              where m.tipo_trabajador = asi_tipo_trabaj 
                                and m.cod_origen      = asi_origen ) ;

delete from cnta_crrte_detalle cc
  where cc.fec_dscto = adi_fec_proceso 
    and cc.cod_trabajador in ( select m.cod_trabajador 
                                 from maestro m 
                                where m.tipo_trabajador = asi_tipo_trabaj 
                                  and m.cod_origen      = asi_origen ) 
                                  and cc.flag_estado = '0' ;

delete from diferido d
  where d.fec_proceso = adi_fec_proceso 
    and d.cod_trabajador in ( select m.cod_trabajador 
                                from maestro m 
                               where m.tipo_trabajador = asi_tipo_trabaj 
                                 and m.cod_origen      = asi_origen ) ;

delete from quinta_categoria q
  where q.fec_proceso = adi_fec_proceso 
    and q.cod_trabajador in ( select m.cod_trabajador 
                                from maestro m 
                               where m.tipo_trabajador = asi_tipo_trabaj 
                                 and m.cod_origen      = asi_origen ) ;

commit ;

end usp_rh_cal_borra_mov_calculo ;
/
