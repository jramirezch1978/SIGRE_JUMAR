create or replace function USF_RH_RET_5CAEG(
       ani_periodo       in utl_distribucion.periodo%TYPE,
       ani_item          in utl_distribucion.item%TYPE,
       asi_trabajador    in maestro.cod_trabajador%TYPE
) return number is

  ls_grp_quinta_categ      grupo_calculo.grupo_calculo%TYPE ;
  ls_cnc_ret_quinta        concepto.concep%TYPE;
  ln_count                 number;
  ln_ret_categ             number;
  ld_fec_proceso           date;
  ls_cnc_pago              utlparam.cncp_pago_util%TYPE;

begin
  
  select p.cncp_pago_util
    into ls_cnc_pago
    from utlparam p 
   where p.reckey = '1' ;
  
  select u.fecha_pago
    into ld_fec_proceso
    from utl_distribucion u
   where u.periodo = ani_periodo
     and u.item    = ani_item;
  
  select c.quinta_cat_proyecta
    into ls_grp_quinta_categ
    from rrhhparam_cconcep c
    where c.reckey = '1';
      
  select con.concep
    into ls_cnc_ret_quinta
    from concepto con
   where con.concep in ( select g.concepto_gen
                           from grupo_calculo g
                          where g.grupo_calculo = ls_grp_quinta_categ) ;
  
  -- Valido si el proceso de calculo
  select count(*)
    into ln_count
    from calculo c
   where c.cod_trabajador = asi_trabajador
     and c.concep         = ls_cnc_pago
     and trunc(c.fec_proceso) = ld_fec_proceso;
  
  if ln_count = 0 then
     select count(*)
       into ln_count
       from historico_calculo hc
      where hc.cod_trabajador = asi_trabajador
        and hc.concep         = ls_cnc_pago
        and to_char(hc.fec_calc_plan) = ld_fec_proceso;
        
     if ln_count = 0 then
        return 0;
        --RAISE_APPLICATION_ERROR(-20000, 'No existe proceso de calculo para fecha de proceso ' || to_char(ld_fec_proceso, 'dd/mm/yyyy')
        --                                || ', por favor verfiique.');
     end if;
  end if;
  
  -- Obtengo la quinta categoria
  select count(*)
    into ln_count
    from calculo c
   where c.cod_trabajador = asi_trabajador
     and c.concep         = ls_cnc_ret_quinta
     and trunc(c.fec_proceso) = trunc(ld_fec_proceso);
      
  if ln_count = 0 then
     select count(*)
       into ln_count
       from historico_calculo hc
      where hc.cod_trabajador = asi_trabajador
        and hc.concep         = ls_cnc_ret_quinta
        and trunc(hc.fec_calc_plan) = trunc(ld_fec_proceso);
         
     if ln_count = 0 then
        ln_ret_categ := 0;
     else
        select NVL(hc.imp_soles,0)
          into ln_ret_categ
          from historico_calculo hc
         where hc.cod_trabajador = asi_trabajador
           and hc.concep         = ls_cnc_ret_quinta
           and trunc(hc.fec_calc_plan) = trunc(ld_fec_proceso);
     end if;
  else
     select NVL(c.imp_soles,0)
       into ln_ret_categ
       from calculo c
      where c.cod_trabajador = asi_trabajador
        and c.concep         = ls_cnc_ret_quinta
        and trunc(c.fec_proceso) = trunc(ld_fec_proceso);
  end if;

  return(ln_ret_categ);
end USF_RH_RET_5CAEG;
/
