create or replace procedure usp_rh_cal_descuentos_fijos (
       asi_codtra          in maestro.cod_trabajador%TYPE, 
       adi_fec_proceso     in date, 
       ani_tipcam          in number,
       asi_origen          in origen.cod_origen%TYPE,
       asi_cnc_total_ingr  in concepto.concep%TYPE,
       asi_tipo_planilla   in calculo.tipo_planilla%TYPE
) is

lk_descuentos_fijos     rrhhparam_cconcep.desct_fijo%TYPE ;

ln_imp_soles            calculo.imp_soles%TYPE ;
ln_imp_dolar            calculo.imp_dolar%TYPE ;
ln_verifica             integer ;
ln_imp_gan_fijas        calculo.imp_soles%TYPE;

--  Cursor de conceptos por descuentos fijos
cursor c_descuentos_fijos is
  select gdf.concep, gdf.imp_gan_desc, gdf.porcentaje
  from gan_desct_fijo gdf
  where gdf.cod_trabajador = asi_codtra 
    and gdf.flag_estado = '1' 
    and gdf.concep in ( select d.concepto_calc 
                          from grupo_calculo_det d
                         where d.grupo_calculo = lk_descuentos_fijos ) ;

begin

  --  ***************************************************************
  --  ***   ADICIONA DESCUENTOS FIJOS POR TRABAJADOR AL CALCULO   ***
  --  ***************************************************************

  select c.desct_fijo 
    into lk_descuentos_fijos
    from rrhhparam_cconcep c 
   where c.reckey = '1' ;

  -- Calculando el importe bruto
    SELECT nvl(sum(c.imp_soles),0)
      into ln_imp_gan_fijas
      FROM calculo c
     WHERE c.COD_TRABAJADOR = asi_codtra
       AND c.concep         = asi_cnc_total_ingr
       and c.tipo_planilla  = asi_tipo_planilla;

  for rc_des in c_descuentos_fijos loop

      ln_verifica := 0 ;
      select count(*) 
        into ln_verifica 
        from gan_desct_fijo gdf
       where gdf.cod_trabajador = asi_codtra 
         and gdf.flag_estado = '1' 
         and gdf.concep in ( select d.concepto_calc 
                               from grupo_calculo_det d
                              where d.grupo_calculo = lk_descuentos_fijos ) ;

      if ln_verifica > 0 then
       
         if rc_des.porcentaje <> 0 then
            ln_imp_soles := ln_imp_gan_fijas * rc_des.porcentaje / 100;
         else
            ln_imp_soles := nvl(rc_des.imp_gan_desc,0) ;
         end if;
       
       ln_imp_dolar := ln_imp_soles / ani_tipcam ;
       
       UPDATE calculo c
          SET imp_soles     = imp_soles + ln_imp_soles,
              imp_dolar     = imp_dolar + ln_imp_dolar
        WHERE cod_trabajador   = asi_codtra
          AND concep           = rc_des.concep
          and c.tipo_planilla  = asi_tipo_planilla;
                  
       if SQL%NOTFOUND then
           insert into calculo (
                  cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                  dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                  tipo_planilla )
           values (
                  asi_codtra, rc_des.concep, adi_fec_proceso, 0, 0,
                  0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                  asi_tipo_planilla ) ;
       end if;
    end if ;

  end loop ;

end usp_rh_cal_descuentos_fijos ;
/
