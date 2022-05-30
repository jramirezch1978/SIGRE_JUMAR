create or replace procedure usp_rh_cal_borra_mov_calculo (
  asi_origen         in origen.cod_origen%TYPE,
  adi_fec_proceso    in date,
  asi_tipo_trabaj    in tipo_trabajador.tipo_trabajador %TYPE,
  asi_tipo_planilla  in calculo.tipo_planilla%TYPE
) is

ls_doc_autom    rrhhparam.doc_reg_automatico%TYPE;

begin

SELECT doc_reg_automatico
  INTO ls_doc_autom
  FROM rrhhparam
 WHERE reckey = '1';

--  *******************************************************
--  ***   ELIMINA MOVIMIENTO DE LA PLANILLA CALCULADA   ***
--  *******************************************************

delete from gan_desct_variable g
  where g.tipo_doc = ls_doc_autom
    and g.cod_trabajador in ( select m.cod_trabajador
                                from maestro m
                               where m.tipo_trabajador = asi_tipo_trabaj
                                 and m.cod_origen      = asi_origen ) ;

delete from calculo c
  where c.cod_trabajador in ( select m.cod_trabajador
                               from maestro m
                              where m.tipo_trabajador = asi_tipo_trabaj
                                and m.cod_origen      = asi_origen ) 
   and c.tipo_planilla = asi_tipo_planilla;

delete from cnta_crrte_detalle cc
  where cc.fec_dscto = adi_fec_proceso
    and cc.cod_trabajador in ( select m.cod_trabajador
                                 from maestro m
                                where m.tipo_trabajador = asi_tipo_trabaj
                                  and m.cod_origen      = asi_origen ) ;

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
                                 and m.cod_origen      = asi_origen ) 
    and q.tipo_planilla  = asi_tipo_planilla;

commit ;

end usp_rh_cal_borra_mov_calculo ;
/
