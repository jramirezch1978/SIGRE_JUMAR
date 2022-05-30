create or replace procedure usp_rh_cal_tardanzas (
    asi_codtra              in maestro.cod_trabajador%TYPE ,
    adi_fec_proceso         in date,
    ani_tipcam              in number,
    asi_origen              in origen.cod_origen%TYPE ,
    asi_tip_trab            in tipo_trabajador.tipo_trabajador%type,
    asi_grc_gan_fija        in rrhhparam.grc_gnn_fija%TYPE,
    asi_tipo_planilla       in calculo.tipo_planilla%TYPE
) is

lk_tardanza             grupo_calculo.grupo_calculo%TYPE ;
lk_descuento_tardanza   grupo_calculo.grupo_calculo%TYPE ;

ln_count                number ;
ls_concepto             concepto.concep%TYPE;
ld_fec_desde            date ;
ld_fec_hasta            date ;
ln_valor_minuto         number(9,6) ;
ln_min_tardanza         calculo.imp_soles%TYPE;
ln_ganancias            calculo.imp_soles%TYPE;
ln_imp_soles            calculo.imp_soles%TYPE;
ln_imp_dolar            calculo.imp_dolar%TYPE;

--  Lectura de minutos de inasistencias por trabajador
cursor c_inasistencia is
  select i.dias_inasist
    from inasistencia i
   where i.cod_trabajador = asi_codtra
     and i.concep         = ls_concepto
     and trunc(i.fec_movim) between ld_fec_desde and ld_fec_hasta ;

begin

--  *******************************************************
--  ***   REALIZA CALCULO DE TARDANZAS POR TRABAJADOR   ***
--  *******************************************************
select c.concep_tardanza, c.dscto_tardanza
  into lk_tardanza, lk_descuento_tardanza
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select count(*)
  into ln_count
  from grupo_calculo g
 where g.grupo_calculo = lk_tardanza ;

if ln_count > 0 then

   select g.concepto_gen
     into ls_concepto
     from grupo_calculo g
    where g.grupo_calculo = lk_tardanza ;

   select p.fec_inicio, p.fec_final
     into ld_fec_desde, ld_fec_hasta
     from rrhh_param_org p
    where p.origen          = asi_origen
      and p.tipo_trabajador = asi_tip_trab
      AND trunc(p.fec_proceso) = trunc(adi_fec_proceso)
      and p.tipo_planilla      = asi_tipo_planilla;

   ln_min_tardanza := 0 ;
   for rc_ina in c_inasistencia loop
       ln_min_tardanza := ln_min_tardanza + ( nvl(rc_ina.dias_inasist,0) * 100 ) ;
   end loop ;

   if ln_min_tardanza > 0 then

      select NVL(sum(nvl(gdf.imp_gan_desc,0)),0)
        into ln_ganancias
        from gan_desct_fijo gdf
       where gdf.cod_trabajador = asi_codtra
         and gdf.flag_estado    = '1'
         and substr(gdf.concep,1,2) = asi_grc_gan_fija ;

      ln_valor_minuto := (ln_ganancias / 240) / 60 ;
      ln_imp_soles := round(ln_valor_minuto * ln_min_tardanza, 2) ;
      ln_imp_dolar := ln_imp_soles / ani_tipcam ;

      if ln_imp_soles > 0 then

         select g.concepto_gen
           into ls_concepto
           from grupo_calculo g
          where g.grupo_calculo = lk_descuento_tardanza ;

         update calculo
            set imp_soles        = imp_soles + ln_imp_soles ,
                imp_dolar        = imp_dolar + ln_imp_dolar ,
                flag_replicacion = '1'
          where cod_trabajador = asi_codtra
            and concep         = ls_concepto 
            and tipo_planilla  = asi_tipo_planilla;
         
         IF SQL%NOTFOUND then
            insert into calculo (
                   cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                   dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                   tipo_planilla )
            values (
                   asi_codtra, ls_concepto, adi_fec_proceso, 0, 0,
                   0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                   asi_tipo_planilla ) ;
         end if ;

      end if ;

   end if ;

end if ;

end usp_rh_cal_tardanzas ;
/
