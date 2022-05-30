create or replace procedure usp_rh_cal_otras_aport(
       asi_codtra           in maestro.cod_trabajador%type  ,
       adi_fec_proceso      in date                         ,
       ani_tipcam           in calendario.vta_dol_prom%type ,
       asi_origen           in origen.cod_origen%type       ,
       asi_cnc_tot_ingr     in concepto.concep%TYPE         ,
       asi_tipo_planilla    in calculo.tipo_planilla%TYPE
) is

ln_count         Number                           ;
ln_imp_soles     calculo.imp_soles%TYPE;
ln_imp_dolar     calculo.imp_soles%TYPE;

cursor c_datos is
  select gdf.concep, c.fact_pago
    from gan_desct_fijo gdf,
         concepto       c
   where gdf.concep = c.concep
     and gdf.cod_trabajador = asi_codtra
     and gdf.concep like '3%'
     and gdf.concep not in (select concep
                              from calculo c
                             where c.cod_trabajador = asi_codtra
                               and c.concep like '3%'
                               and c.tipo_planilla = asi_tipo_planilla);

begin

  for lc_reg in c_datos loop
  
      select count(*)
        into ln_count
        from grupo_calculo g
       where g.concepto_gen = lc_reg.concep ;

      if ln_count = 0 then 
         -- Si no existe el concepto en grupo de calculo
         -- entonces asumo el total de ingresos
         select NVL(sum(c.imp_soles), 0)
           into ln_imp_soles
           from calculo c
          where c.cod_trabajador  = asi_codtra
            and c.concep          = asi_cnc_tot_ingr
            and c.tipo_planilla   = asi_tipo_planilla;
      else
         select NVL(sum(c.imp_soles), 0)
           into ln_imp_soles
           from calculo c,
                grupo_calculo_det gcd,
                grupo_calculo     gc
          where gcd.concepto_calc = c.concep
            and gc.grupo_Calculo  = gcd.grupo_calculo
            and c.cod_trabajador  = asi_codtra
            and gc.concepto_gen   = lc_reg.concep
            and c.tipo_planilla   = asi_tipo_planilla;
            
      end if;
      
      if ln_imp_soles > 0 then
         ln_imp_soles := ln_imp_soles * lc_reg.fact_pago ;
         ln_imp_dolar := ln_imp_soles / ani_tipcam ;
         
         UPDATE calculo
             SET imp_soles    = imp_soles + ln_imp_soles,
                 imp_dolar    = imp_dolar + ln_imp_dolar
            WHERE cod_trabajador = asi_codtra
              AND concep         = lc_reg.concep
              and tipo_planilla  = asi_tipo_planilla;
         
         if SQL%NOTFOUND then
           insert into calculo (
                  cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                  dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                  tipo_planilla )
           values (
                  asi_codtra, lc_reg.concep, adi_fec_proceso, 0, 0,
                  0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                  asi_tipo_planilla ) ;
         end if;
      end if ;

  end loop;


end usp_rh_cal_otras_aport ;
/
