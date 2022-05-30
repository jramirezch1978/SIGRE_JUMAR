create or replace procedure usp_rh_destajo_revierte (
   asi_cod_usr in string,
   asi_cod_origen in string,
   adi_ini in date,
   adi_fin in date,
   adi_fec_proceso in date,
   ano_cuenta out number,
   ano_msg out number,
   aso_msg out string
) is

   ls_doc_dstj rrhhparam.doc_dstj%type;
   
   cursor lc_destajo is
   select distinct pdad.nro_parte, pdad.nro_item, pdad.cod_trabajador ,pd.fecha,l.concepto_rrhh
     from pd_ot pd
          inner join pd_ot_det pdd on pd.nro_parte = pdd.nro_parte
          inner join pd_ot_asist_destajo pdad on pdd.nro_parte = pdad.nro_parte and pdd.nro_item = pdad.nro_item
          inner join labor l on pdd.cod_labor = l.cod_labor
    where trunc(pd.fecha) between trunc(adi_ini) and trunc(adi_fin)
      and pdad.flag_procesado        = '1'
      and substr(pd.nro_parte, 1, 2) = asi_cod_origen ;
         
begin

   -- captura el tipo de documento de generación automática
   select rhp.doc_dstj into ls_doc_dstj from rrhhparam rhp  where rhp.reckey = '1';

   -- borra los destajos de los de movimientos variables
--   delete from gan_desct_variable gdv where trunc(gdv.fec_movim) = trunc(adi_fec_proceso) and gdv.tipo_doc = ls_doc_dstj ;

   ano_cuenta := 0;
   
   for rs_dj in lc_destajo loop   
       update pd_ot_asist_destajo poad set poad.flag_procesado = '0' where poad.nro_parte      = rs_dj.nro_parte
                                                                       and poad.nro_item       = rs_dj.nro_item
                                                                       and poad.cod_trabajador = rs_dj.cod_trabajador ;
      
       ano_cuenta := ano_cuenta + 1 ;
      
      --- eliminar de tabla ganancia descuento variable
      --- de acuerdo a fecha
      delete from gan_desct_variable gdv
       where (cod_trabajador = rs_dj.cod_trabajador  ) and
             (fec_movim      = rs_dj.fecha           ) and
             (concep         = rs_dj.concepto_rrhh   ) and
             (gdv.tipo_doc   = ls_doc_dstj           ) ;
      
             
   end loop;
   
   commit;

   exception
        when others then
        ano_msg := 1;
        aso_msg := 'ORACLE: Error en procedimiento usp_rh_destajo_revierte';
   
end usp_rh_destajo_revierte;
/
