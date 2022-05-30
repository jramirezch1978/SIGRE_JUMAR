create or replace procedure usp_rh_cal_porcentaje_judicial (
       asi_codtra            in maestro.cod_trabajador%TYPE, 
       adi_fec_proceso       in date, 
       asi_origen            in origen.cod_origen%TYPE,
       ani_tipcam            in number, 
       ani_judicial          in number, 
       ani_judicial_utl      in number,
       asi_codusr            in usuario.cod_usr%TYPE,
       asi_tipo_planilla     in calculo.tipo_planilla%TYPE
) is

lk_judicial           rrhhparam_cconcep.calc_judic%TYPE ;
ls_grp_jud_utl        utlparam.grp_remun_anual%TYPE ;
ls_cnc_dscto_jud      concepto.concep%TYPE ;
ls_cncp_utl           concepto.concep%TYPE ;
ln_count              number;
ln_imp_soles          calculo.imp_soles%TYPE ;
ln_imp_dolar          calculo.imp_dolar%TYPE  ;
ln_ret_jud_fijo_mes   historico_calculo.imp_soles%TYPE;
ln_year               number;
ln_mes                number;
ln_base_imponible     calculo.imp_soles%TYPE;
ln_porc_jud_CTS       maestro.porc_jud_cts%TYPE;
ln_porc_jud_VACA      maestro.porc_jud_vacac%TYPE;
ln_porc_juc_GRATI     maestro.porc_jud_grat%TYPE;

cursor c_judicial is
  select j.concep, j.secuencia, 
         NVL(j.porcentaje,0) as jud_porcentaje, 
         NVL(j.porc_utilidad,0) as jud_porc_util,
         j.importe as jud_importe
    from judicial j
   where j.cod_trabajador = asi_codtra
     and j.flag_estado <> '0';

begin

--  ****************************************************************
--  ***   REALIZA CALCULO DE DESCUENTO JUDICIAL POR TRABAJADOR   ***
--  ****************************************************************
ln_year := to_number(to_char(adi_fec_proceso, 'yyyy'));
ln_mes  := to_number(to_char(adi_fec_proceso, 'mm'));

-- Obtengo el porcentaje
select m.porc_jud_cts, nvl(m.porc_jud_vacac, 0), nvl(m.porc_jud_grat, 0)
  into ln_porc_jud_CTS, ln_porc_jud_VACA, ln_porc_juc_GRATI
  from maestro m
 where m.cod_trabajador = asi_codtra;

-- Elimino el detalle del calculo judicial por alimentistas
delete calculo_judicial cj
 where cj.cod_trabajador = asi_codtra
   and trunc(cj.fec_proceso) = trunc(adi_fec_proceso);

select c.calc_judic 
  into lk_judicial
  from rrhhparam_cconcep c 
 where c.reckey = '1' ;

select p.grp_remun_anual 
  into ls_grp_jud_utl
  from utlparam p 
 where p.reckey = '1' ;

if ls_grp_jud_utl is not null then
  select gc.concepto_gen 
    into ls_cncp_utl 
    from grupo_calculo gc
   where gc.grupo_calculo = ls_grp_jud_utl ;
end if ;

select count(*) 
  into ln_count 
  from grupo_calculo g
 where g.grupo_calculo = lk_judicial ;

if ln_count > 0 then
   
   select g.concepto_gen 
     into ls_cnc_dscto_jud 
     from grupo_calculo g
    where g.grupo_calculo = lk_judicial ;

   select count(*) 
     into ln_count 
     from calculo c
    where c.cod_trabajador = asi_codtra 
      and c.tipo_planilla  = asi_tipo_planilla
      and c.concep in ( select d.concepto_calc
                          from grupo_calculo_det d 
                         where d.grupo_calculo = lk_judicial ) ;

   if ln_count > 0 then
      select sum(nvl(c.imp_soles * DECODE(substr(c.concep, 1,1), '1', 1, -1),0)) 
        into ln_base_imponible 
        from calculo c
       where c.cod_trabajador = asi_codtra 
         and c.tipo_planilla  = asi_tipo_planilla
         and c.concep in ( select d.concepto_calc
                             from grupo_calculo_det d 
                            where d.grupo_calculo = lk_judicial ) ;

      select count(*)
        into ln_count
        from judicial j
       where j.cod_trabajador = asi_codtra;
      
      if ln_count > 0 then
         for lc_reg in c_judicial loop
             if lc_reg.jud_porcentaje <> 0 then
                ln_imp_soles := ln_base_imponible * lc_reg.jud_porcentaje/100;
                ln_imp_dolar := ln_imp_soles / ani_tipcam ;
                
                update calculo c
                   set c.imp_soles = c.imp_soles + ln_imp_soles ,
                       c.imp_dolar = c.imp_dolar + ln_imp_dolar
                 where c.cod_trabajador = asi_codtra 
                   and c.concep         = lc_reg.concep 
                   and c.fec_proceso    = adi_fec_proceso 
                   and c.tipo_planilla  = asi_tipo_planilla;

                if SQL%NOTFOUND then
                   insert into calculo (
                          cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                          dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                          tipo_planilla )
                    values (
                          asi_codtra, lc_reg.concep, adi_fec_proceso, 0, 0,
                          0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                          asi_tipo_planilla ) ;
                end if;
                
                update calculo_judicial cj
                   set cj.imp_soles = NVL(cj.imp_soles, 0) + ln_imp_soles,
                       cj.imp_dolar = NVL(cj.imp_dolar, 0) + ln_imp_dolar
                 where cj.cod_trabajador = asi_codtra
                   and cj.concep         = lc_reg.concep
                   and cj.secuencia      = lc_reg.secuencia
                   and trunc(cj.fec_proceso) = trunc(adi_fec_proceso);
                
                if SQL%NOTFOUND then
                   insert into calculo_judicial(
                          cod_trabajador, concep, secuencia, fec_proceso, imp_dolar, cod_usr, imp_soles)
                   values(
                          asi_codtra, lc_reg.concep, lc_reg.secuencia, adi_fec_proceso, ln_imp_dolar, asi_codusr, ln_imp_soles);
                end if;
             end if;
             
             
             -- La retencion judicial fija es siempre mensual
             if lc_reg.jud_importe <> 0 then
                -- Primero obtengo lo que se haya retenido en el mes
                select nvl(sum(hc.imp_soles), 0)
                  into ln_ret_jud_fijo_mes
                  from historico_calculo hc
                 where hc.cod_trabajador = asi_codtra  
                   and hc.concep         = lc_reg.concep
                   and to_number(to_char(hc.fec_calc_plan, 'yyyy')) = ln_year
                   and to_number(to_char(hc.fec_calc_plan, 'mm')) = ln_mes;
                
                -- Solo si queda un saldo por retener, entonces lo retengo
                if lc_reg.jud_importe > ln_ret_jud_fijo_mes then
                   
                   if lc_reg.jud_importe - ln_ret_jud_fijo_mes >= ln_base_imponible then
                      ln_imp_soles := ln_base_imponible;
                   else
                      ln_imp_soles := lc_reg.jud_importe - ln_ret_jud_fijo_mes;
                   end if;
                   
                   if ln_imp_soles > 0 then
                      ln_imp_soles := lc_reg.jud_importe ;
                      ln_imp_dolar := ln_imp_soles / ani_tipcam ;
                      
                      update calculo c
                         set c.imp_soles = c.imp_soles + ln_imp_soles ,
                             c.imp_dolar = c.imp_dolar + ln_imp_dolar
                       where c.cod_trabajador = asi_codtra 
                         and c.concep         = lc_reg.concep 
                         and c.fec_proceso    = adi_fec_proceso 
                         and c.tipo_planilla  = asi_tipo_planilla;

                      if SQL%NOTFOUND then
                         insert into calculo (
                                 cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                                 dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                                 tipo_planilla )
                          values (
                                 asi_codtra, lc_reg.concep , adi_fec_proceso, 0, 0,
                                 0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                                 asi_tipo_planilla ) ;
                      end if;
                        
                      update calculo_judicial cj
                         set cj.imp_soles = NVL(cj.imp_soles, 0) + ln_imp_soles,
                             cj.imp_dolar = NVL(cj.imp_dolar, 0) + ln_imp_dolar
                       where cj.cod_trabajador = asi_codtra
                         and cj.concep         = lc_reg.concep
                         and cj.secuencia      = lc_reg.secuencia
                         and trunc(cj.fec_proceso) = trunc(adi_fec_proceso);
                        
                      if SQL%NOTFOUND then
                          insert into calculo_judicial(
                                 cod_trabajador, concep, secuencia, fec_proceso, imp_dolar, cod_usr, imp_soles, cod_origen)
                          values(
                                 asi_codtra, lc_reg.concep, lc_reg.secuencia, adi_fec_proceso, ln_imp_dolar, asi_codusr, ln_imp_soles, asi_origen);
                      end if;
                   end if;
                     
                   end if;

             end if;
             
             -- Si tiene porcentaje de retencion judicial de utilidad, se calcula
             if lc_reg.jud_porc_util > 0 then
                 select nvl(sum(c.imp_soles),0)
                   into ln_imp_soles 
                   from calculo c
                  where c.cod_trabajador = asi_codtra 
                    and c.concep         = ls_cncp_utl 
                    and c.tipo_planilla  = asi_tipo_planilla;
                 
                 if ln_imp_soles > 0 then
                    ln_imp_soles := ln_imp_soles * lc_reg.jud_porc_util /100 ;
                    ln_imp_dolar := ln_imp_soles / ani_tipcam ;
                    
                    update calculo c
                       set c.imp_soles = c.imp_soles + ln_imp_soles ,
                           c.imp_dolar = c.imp_dolar + ln_imp_dolar
                     where c.cod_trabajador = asi_codtra 
                       and c.concep         = lc_reg.concep 
                       and c.fec_proceso    = adi_fec_proceso 
                       and c.tipo_planilla  = asi_tipo_planilla;
                     
                    if SQL%NOTFOUND then
                       insert into calculo (
                               cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                               dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                               tipo_planilla )
                        values (
                               asi_codtra, lc_reg.concep, adi_fec_proceso, 0, 0,
                               0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                               asi_tipo_planilla ) ;
                    end if;
                    
                    update calculo_judicial cj
                       set cj.imp_soles = NVL(cj.imp_soles, 0) + ln_imp_soles,
                           cj.imp_dolar = NVL(cj.imp_dolar, 0) + ln_imp_dolar
                     where cj.cod_trabajador = asi_codtra
                       and cj.concep         = lc_reg.concep
                       and cj.secuencia      = lc_reg.secuencia
                       and trunc(cj.fec_proceso) = trunc(adi_fec_proceso);
                    
                    if SQL%NOTFOUND then
                       insert into calculo_judicial(
                              cod_trabajador, concep, secuencia, fec_proceso, imp_dolar, cod_usr, imp_soles)
                       values(
                              asi_codtra, lc_reg.concep, lc_reg.secuencia, adi_fec_proceso, ln_imp_dolar, asi_codusr, ln_imp_soles);
                    end if;
                 end if ;
             end if ;

             
         end loop;
      else
        -- Este DEscuento no se aplica en CTS Tripulantes
        if nvl(ani_judicial,0) <> 0 and asi_tipo_planilla not in ('C', 'V', 'G') then
           ln_imp_soles := ln_base_imponible * ani_judicial/100;
           ln_imp_dolar := ln_imp_soles / ani_tipcam ;
           update calculo c
              set c.imp_soles = c.imp_soles + ln_imp_soles ,
                  c.imp_dolar = c.imp_dolar + ln_imp_dolar
            where c.cod_trabajador = asi_codtra 
              and c.concep         = ls_cnc_dscto_jud 
              and c.fec_proceso    = adi_fec_proceso 
              and c.tipo_planilla  = asi_tipo_planilla;   

           if SQL%NOTFOUND then
              insert into calculo (
                     cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                     dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                     tipo_planilla )
               values (
                     asi_codtra, ls_cnc_dscto_jud, adi_fec_proceso, 0, 0,
                     0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                     asi_tipo_planilla ) ;
           end if;
        end if;

        --  Realiza descuentos de retencion judicial de utilidades
        if nvl(ani_judicial_utl,0) <> 0 and asi_tipo_planilla not in ('C', 'V', 'G') then
           select nvl(sum(c.imp_soles),0) 
                into ln_imp_soles 
                from calculo c
               where c.cod_trabajador = asi_codtra 
                 and c.concep         = ls_cncp_utl 
                 and c.tipo_planilla  = asi_tipo_planilla;
           
           if ln_imp_soles > 0 then
              
              ln_imp_soles := ln_imp_soles * ( ani_judicial_utl/100 ) ;
              ln_imp_dolar := ln_imp_soles / ani_tipcam ;
              
              update calculo c
                 set c.imp_soles = c.imp_soles + ln_imp_soles ,
                     c.imp_dolar = c.imp_dolar + ln_imp_dolar
               where c.cod_trabajador = asi_codtra 
                 and c.concep         = ls_cnc_dscto_jud 
                 and c.fec_proceso    = adi_fec_proceso 
                 and c.tipo_planilla  = asi_tipo_planilla;
               
              if SQL%NOTFOUND then
                 insert into calculo (
                         cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                         dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                         tipo_planilla )
                  values (
                         asi_codtra, ls_cnc_dscto_jud, adi_fec_proceso, 0, 0,
                         0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                         asi_tipo_planilla ) ;
              end if;
           end if ;
        end if ;

        -- Este Descuento si se aplica en CTS Tripulantes
        if nvl(ln_porc_jud_CTS,0) <> 0 and asi_tipo_planilla in ('C') then
           ln_imp_soles := ln_base_imponible * ln_porc_jud_CTS/100;
           ln_imp_dolar := ln_imp_soles / ani_tipcam ;
           update calculo c
              set c.imp_soles = c.imp_soles + ln_imp_soles ,
                  c.imp_dolar = c.imp_dolar + ln_imp_dolar
            where c.cod_trabajador = asi_codtra 
              and c.concep         = ls_cnc_dscto_jud 
              and c.fec_proceso    = adi_fec_proceso 
              and c.tipo_planilla  = asi_tipo_planilla;   

           if SQL%NOTFOUND then
              insert into calculo (
                     cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                     dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                     tipo_planilla )
               values (
                     asi_codtra, ls_cnc_dscto_jud, adi_fec_proceso, 0, 0,
                     0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                     asi_tipo_planilla ) ;
           end if;
        end if;
        
        -- Este Descuento si se aplica en Vacaciones Tripulantes
        if nvl(ln_porc_jud_VACA,0) <> 0 and asi_tipo_planilla in ('V') then
           ln_imp_soles := ln_base_imponible * ln_porc_jud_VACA/100;
           ln_imp_dolar := ln_imp_soles / ani_tipcam ;
           update calculo c
              set c.imp_soles = c.imp_soles + ln_imp_soles ,
                  c.imp_dolar = c.imp_dolar + ln_imp_dolar
            where c.cod_trabajador = asi_codtra 
              and c.concep         = ls_cnc_dscto_jud 
              and c.fec_proceso    = adi_fec_proceso 
              and c.tipo_planilla  = asi_tipo_planilla;   

           if SQL%NOTFOUND then
              insert into calculo (
                     cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                     dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                     tipo_planilla )
               values (
                     asi_codtra, ls_cnc_dscto_jud, adi_fec_proceso, 0, 0,
                     0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                     asi_tipo_planilla ) ;
           end if;
        end if;
        
        -- Este Descuento si se aplica en GRATIFICACIONES Tripulantes
        if nvl(ln_porc_jud_VACA,0) <> 0 and asi_tipo_planilla in ('G') then
           ln_imp_soles := ln_base_imponible * ln_porc_juc_GRATI/100;
           ln_imp_dolar := ln_imp_soles / ani_tipcam ;
           update calculo c
              set c.imp_soles = c.imp_soles + ln_imp_soles ,
                  c.imp_dolar = c.imp_dolar + ln_imp_dolar
            where c.cod_trabajador = asi_codtra 
              and c.concep         = ls_cnc_dscto_jud 
              and c.fec_proceso    = adi_fec_proceso 
              and c.tipo_planilla  = asi_tipo_planilla;   

           if SQL%NOTFOUND then
              insert into calculo (
                     cod_trabajador, concep,  fec_proceso, horas_trabaj, horas_pag,
                     dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, 
                     tipo_planilla )
               values (
                     asi_codtra, ls_cnc_dscto_jud, adi_fec_proceso, 0, 0,
                     0, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1,
                     asi_tipo_planilla ) ;
           end if;
        end if;
        
      end if;
      
      
      
   end if ;

end if ;

end usp_rh_cal_porcentaje_judicial ;
/
