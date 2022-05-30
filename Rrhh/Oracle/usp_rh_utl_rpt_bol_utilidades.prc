CREATE OR REPLACE PROCEDURE usp_rh_utl_rpt_bol_utilidades (
  ani_periodo                in utl_distribucion.periodo%type, 
  ani_item                   in utl_distribucion.item%type, 
  asi_origen                 in origen.cod_origen%type, 
  asi_tipo_trabajador        in tipo_trabajador.tipo_trabajador%type,
  adi_fec_proceso           in date
) is

ln_ano_entrega           utl_distribucion.periodo%type ;
ls_ruc                   proveedor.ruc%type ;
ls_direccion             tt_utl_rpt_bol_utilidades.direccion%type ;
ls_concepto              concepto.concep%type ;
ln_renta_neta            number(13,2) ;
ln_porc_distribucion     number(5,2) ;
ln_porc_dias_laborados   number(5,2) ;
ln_remuner_ano           number(13,2) ;
ln_dias_ano              number(13,2) ;
ln_total_utilidades      number(13,2) ;
ln_neto_cobrado          number(13,2) ;
ld_fecha_pago            date ;
ls_soles                 moneda.cod_moneda%type ;
ls_grp_quinta_categ      grupo_calculo.grupo_calculo%TYPE ;
ls_cnc_ret_quinta        concepto.concep%TYPE;
ln_count                 number;
ln_ret_categ             number;

--  Lectura del calculo de utilidades del ejercicio
CURSOR c_movimiento is
SELECT m.COD_TRABAJADOR, 
       m.NOM_TRABAJADOR,
       ud.renta_neta, 
       ud.porc_distribucion, 
       ud.porc_dias_laborados, 
       ud.porc_remuneracion, 
       ud.fecha_ini, ud.fecha_fin, ud.fecha_pago, 
       ud.tot_dias_ejer, 
       ue.dias_efectivos, 
       ud.tot_remun_ejer, 
       ue.remun_anual,
       ue.imp_utl_remun_anual, 
       ue.adelantos, 
       ue.reten_jud, 
       ue.imp_ult_dias_efect, 
       m.COD_ORIGEN 
  FROM utl_distribucion ud, 
       utl_ext_hist     ue, 
       vw_pr_trabajador m
 WHERE ud.periodo        = ue.periodo 
   and ud.item           = ue.item
   and ue.cod_relacion   = m.cod_trabajador 
   and ud.periodo        = ani_periodo 
   and ud.item           = ani_item 
   and m.cod_origen      like asi_origen 
   and m.tipo_trabajador like asi_tipo_trabajador ;

BEGIN 

--  *******************************************************************
--  ***   GENERA REPORTE DEL CALCULO DE LAS UTLIDADES POR PERSONA   ***
--  *******************************************************************

delete from tt_utl_rpt_bol_utilidades ;

ln_ano_entrega := to_number(to_char(adi_fec_proceso, 'yyyy')) ;

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

-- Verifica si hay adelantos de utilidades
SELECT p.cncp_adelanto_util 
  INTO ls_concepto 
  FROM utlparam p
 WHERE p.reckey = '1' ;

SELECT e.ruc, substr(trim(e.dir_calle)||' - '||trim(e.dir_distrito),1,45)
  INTO ls_ruc, ls_direccion
  FROM empresa e 
 WHERE e.cod_empresa = (SELECT p.cod_empresa FROM genparam p WHERE p.reckey = '1') ;

SELECT d.renta_neta, d.porc_distribucion, d.porc_dias_laborados, d.tot_remun_ejer, d.tot_dias_ejer, d.fecha_pago
  INTO ln_renta_neta, ln_porc_distribucion, ln_porc_dias_laborados, ln_remuner_ano, ln_dias_ano, ld_fecha_pago 
  FROM utl_distribucion d
 WHERE d.periodo = ani_periodo 
   AND d.item    = ani_item ;

SELECT l.cod_soles INTO ls_soles FROM logparam l WHERE l.reckey='1' ;

--  Lectura del movimiento seleccionado
FOR lc_reg IN c_movimiento LOOP
    
    -- Obtengo la quinta categoria
    select count(*)
      into ln_count
      from calculo c
     where c.cod_trabajador = lc_reg.cod_trabajador
       and c.concep         = ls_cnc_ret_quinta
       and trunc(c.fec_proceso) = trunc(adi_fec_proceso);
    
    if ln_count = 0 then
       select count(*)
         into ln_count
         from historico_calculo hc
        where hc.cod_trabajador = lc_reg.cod_trabajador
          and hc.concep         = ls_cnc_ret_quinta
          and trunc(hc.fec_calc_plan) = trunc(adi_fec_proceso);
       
       if ln_count = 0 then
          ln_ret_categ := 0;
       else
          select NVL(hc.imp_soles,0)
            into ln_ret_categ
            from historico_calculo hc
           where hc.cod_trabajador = lc_reg.cod_trabajador
             and hc.concep         = ls_cnc_ret_quinta
             and trunc(hc.fec_calc_plan) = trunc(adi_fec_proceso);
       end if;
    else
       select NVL(c.imp_soles,0)
         into ln_ret_categ
         from calculo c
        where c.cod_trabajador = lc_reg.cod_trabajador
          and c.concep         = ls_cnc_ret_quinta
          and trunc(c.fec_proceso) = trunc(adi_fec_proceso);
    end if;
      
  ln_total_utilidades := nvl(lc_reg.imp_utl_remun_anual,0) + nvl(lc_reg.imp_ult_dias_efect,0) ;

  ln_neto_cobrado := nvl(ln_total_utilidades,0) - ( nvl(lc_reg.adelantos,0) +
                     nvl(lc_reg.reten_jud,0) + ln_ret_categ ) ;

  INSERT INTO tt_utl_rpt_bol_utilidades (
         direccion, ruc, periodo, cod_relacion, nombres,
         renta_neta, porc_distribucion, monto_distribuir,
         dias_ano, dias_ano_trabaj, remuner_ano, remuner_ano_trabaj,
         imp_util_dias, imp_utl_remuner, total_utilidades,
         adelantos, otros_adelantos, reten_judicial, reten_5categ, 
         neto_cobrado, ano_entrega, fecha_pago )
  VALUES (
         ls_direccion, ls_ruc, ani_periodo, lc_reg.cod_trabajador, lc_reg.nom_trabajador,
         lc_reg.renta_neta, lc_reg.porc_distribucion, lc_reg.renta_neta*lc_reg.porc_distribucion/100,
         lc_reg.tot_dias_ejer, lc_reg.dias_efectivos, lc_reg.tot_remun_ejer, lc_reg.remun_anual, 
         lc_reg.imp_ult_dias_efect, lc_reg.imp_utl_remun_anual, ln_total_utilidades,
         NVL(lc_reg.adelantos,0),0, NVL(lc_reg.reten_jud,0), NVL(ln_ret_categ,0), 
         ln_neto_cobrado, ln_ano_entrega, ld_fecha_pago ) ;
    
END LOOP ;

END usp_rh_utl_rpt_bol_utilidades ;
/
