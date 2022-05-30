create or replace procedure usp_rh_cal_prom_remun_vacac (
       asi_codtra      in maestro.cod_trabajador%TYPE, 
       asi_codusr      in usuario.cod_usr%TYPE, 
       adi_fec_proceso in date,
       asi_doc_autom   in doc_tipo.tipo_doc%TYPE
) is

lk_concepto_prv       char(3) ;
lk_concepto_vac       char(3) ;

ln_count              number ;
ln_num_mes            integer ;
ls_concepto_prv       char(4) ;
ls_concepto_vac       char(4) ;
ln_dias_vaca          number(4,2) ;
ln_imp_promedio       number(13,2) ;
ln_imp_soles          number(13,2) ;
ln_acu_soles          number(13,2) ;
ld_ran_ini            date ;
ld_ran_fin            date ;

--  Conceptos para promediar pago de remuneracion vacacional
cursor c_detalle is
  select d.concepto_calc 
    from grupo_calculo_det d
   where d.grupo_calculo = lk_concepto_prv ;

begin

--  *******************************************************
--  ***   CALCULA PROMEDIO DE REMUNERACION VACACIONAL   ***
--  *******************************************************

select c.prom_remun_vacac, c.gan_fij_calc_vacac
  into lk_concepto_prv, lk_concepto_vac
  from rrhhparam_cconcep c
  where c.reckey = '1' ;

select count(*) 
  into ln_count
  from grupo_calculo g 
 where g.grupo_calculo = lk_concepto_prv ;

if ln_count > 0 then

   select g.concepto_gen 
     into ls_concepto_prv
     from grupo_calculo g 
    where g.grupo_calculo = lk_concepto_prv ;

   select g.concepto_gen 
     into ls_concepto_vac
     from grupo_calculo g 
    where g.grupo_calculo = lk_concepto_vac ;

   select NVL(sum(i.dias_inasist),0)
     into ln_dias_vaca 
     from inasistencia i
    where i.cod_trabajador = asi_codtra 
      and i.concep         = ls_concepto_vac ;

   if ln_dias_vaca > 0 then

      ln_imp_promedio := 0 ;
      for rc_det in c_detalle loop

          ld_ran_ini := add_months(adi_fec_proceso, - 1) ;
          ln_num_mes := 0 ; 
          ln_acu_soles := 0 ;

          for x in reverse 1 .. 6 loop
              ld_ran_fin   := ld_ran_ini ;
              ld_ran_ini   := add_months( ld_ran_fin, -1 ) + 1 ;
              ln_imp_soles := 0 ;
              select count(*) 
                into ln_count
                from historico_calculo hc
               where hc.concep         = rc_det.concepto_calc 
                 and hc.cod_trabajador = asi_codtra 
                 and trunc(hc.fec_calc_plan) between trunc(ld_ran_ini) and trunc(ld_ran_fin);
                 
              if ln_count > 0 then
                 select NVL(sum(hc.imp_soles),0)
                   into ln_imp_soles 
                   from historico_calculo hc
                  where hc.concep         = rc_det.concepto_calc 
                    and hc.cod_trabajador = asi_codtra 
                    and trunc(hc.fec_calc_plan) between trunc(ld_ran_ini) and trunc(ld_ran_fin) ;
              end if ;
              
              if ln_imp_soles > 0 then
                 ln_num_mes   := ln_num_mes + 1 ;
                 ln_acu_soles := ln_acu_soles + ln_imp_soles ;
              end if ;
              ld_ran_ini := ld_ran_ini - 1 ;
          end loop ;

          if ln_num_mes > 2 then
             ln_imp_promedio := ln_imp_promedio + (ln_acu_soles / 6) ;
          end if ;

      end loop ;

      ln_imp_promedio := ln_imp_promedio / 30 * ln_dias_vaca ;

      if ln_imp_promedio > 0 then
         insert into gan_desct_variable (
                cod_trabajador, fec_movim, concep, imp_var,
                cod_usr, tipo_doc, flag_replicacion )
         values (
                asi_codtra, adi_fec_proceso, ls_concepto_prv, ln_imp_promedio,
                asi_codusr, asi_doc_autom, '1' ) ;
      end if ;

  end if ;

end if ;

end usp_rh_cal_prom_remun_vacac ;
/
