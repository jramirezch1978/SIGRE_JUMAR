create or replace procedure usp_rh_rpt_certificados_quinta (
  ani_year             in number, 
  asi_tipo_trabajador  in tipo_trabajador.tipo_trabajador%TYPE, 
  asi_origen           in origen.cod_origen%TYPE,
  asi_codtra           in maestro.cod_trabajador%TYPE 
) is

ls_empresa_nom           empresa.nombre%TYPE;
ls_empresa_dir           empresa.direccion%TYPE;
ls_ruc                   empresa.ruc%TYPE;
ls_representante         empresa.representante%TYPE;
ls_dni_repre             empresa.identificacion%TYPE;

ls_descripcion           tt_rpt_certificados.descripcion%TYPE ;  
ls_nombres               tt_rpt_certificados.nombres%TYPE;
ln_rem_imprecisa         tt_rpt_certificados.rem_imprecisa%TYPE; 
ln_rem_precisa           tt_rpt_certificados.rem_precisa%TYPE;
ln_rem_grati             tt_rpt_certificados.rem_grati%TYPE;
ln_ingr_externo          tt_rpt_certificados.ingr_externo%TYPE;
ln_retencion_ext         tt_rpt_certificados.ret_externo%TYPE;
ln_imp_total             tt_rpt_certificados.total%TYPE;
ln_base_imponible        tt_rpt_certificados.base_imponible%TYPE;  
ln_ingr_utilidades       tt_rpt_certificados.ingr_utilidades%TYPE := 0;  -- Por ahora no hay utilidades
ln_imp_neto              tt_rpt_certificados.neto%TYPE;
ln_imp_renta             tt_rpt_certificados.IMP_RENTA%TYPE;
ls_dia                   tt_rpt_certificados.dia%TYPE;       
ls_mes                   tt_rpt_certificados.mes%TYPE;
ls_anno                  tt_rpt_certificados.anno%TYPE;       
ln_count                 number;
ln_uit                   uit.importe%TYPE;

-- Renta de Quinta
ls_cnc_rta_qta           rrhhparam_cconcep.cnc_ret_quinta%TYPE;
ls_cnc_rta_qta2          rrhhparam_cconcep.cnc_ret_quinta%TYPE := '2204';
ls_grp_quinta_categ      grupo_calculo.grupo_calculo%TYPE ;
ls_grp_ganan_imprec      grupo_calculo.grupo_calculo%TYPE ;
ls_grp_gratif_jul        grupo_calculo.grupo_calculo%TYPE ;
ls_grp_gratif_dic        grupo_calculo.grupo_calculo%TYPE ;
ls_cnc_grati_jul         concepto.concep%TYPE;
ls_cnc_grati_dic         concepto.concep%TYPE;

-- Fecha
ld_fecha                 date;

--  Cursor para leer trabajadores seleccionados
cursor c_maestro is
  select m.cod_trabajador, m.dni, m.cod_seccion, m.cod_area, tt.tipo_trabajador, m.cod_origen, m.cod_empresa
  from maestro         m, 
       tipo_trabajador tt
  where m.tipo_trabajador  = tt.tipo_trabajador
    and m.flag_estado      = '1' 
    and m.flag_cal_plnlla  = '1' 
    and m.tipo_trabajador  = asi_tipo_trabajador 
    and m.cod_origen       = asi_origen
    and m.cod_trabajador   like asi_codtra
  order by m.cod_seccion, m.cod_trabajador ;

begin

  --  **********************************************************************
  --  ***   REPORTE DE CERTIFICADOS DE RETENCIONES DE QUINTA CATEGORIA   ***
  --  **********************************************************************
  
  ld_fecha := to_date('31/12/' || trim(to_char(ani_year, '0000')), 'dd/mm/yyyy');
  
  -- Busco el UIT de acuerdo a la fecha
  SELECT COUNT(*)
    INTO ln_count
  FROM uit t
  WHERE trunc(fec_ini_vigen) <= trunc(ld_fecha);

  IF ln_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20000, '"NO HA ESPECIFICADO LA UIT PARA EL AÑO ' || to_char(ld_fecha, 'YYYY'));
  END IF;

  SELECT importe
    INTO ln_uit
  FROM (SELECT t.importe
          FROM UIT T
        WHERE TRUNC(FEC_INI_VIGEN) <= TRUNC(ld_fecha)
        ORDER BY t.ano DESC, t.fec_ini_vigen DESC)
  WHERE ROWNUM = 1;

  delete from tt_rpt_certificados ;

  select count(*)
    into ln_count 
  from uit u
  where trunc(u.fec_ini_vigen) <= trunc(ld_fecha);

  if ln_count = 0 then
     RAISE_APPLICATION_ERROR(-20000, 'No hay registro valido de UIT anterior a la fecha ' || to_char(ld_fecha, 'dd/mm/yyyy'));
  end if;
  
  -- PAraemtros para el concepto de renta de quinta
  select rhc.cnc_ret_quinta 
    into ls_cnc_rta_qta
  from rrhhparam_cconcep rhc
  where rhc.reckey = '1' ;
 
   -- Obtengo los parámetros necesarios para trabajar
  select c.quinta_cat_proyecta, c.quinta_cat_imprecisa, c.grati_medio_ano, c.grati_fin_ano
    into ls_grp_quinta_categ, ls_grp_ganan_imprec, ls_grp_gratif_jul, ls_grp_gratif_dic
  from rrhhparam_cconcep c
  where c.reckey = '1' ;
  
  -- Obtengo los conceptos de Grati de Julio y Diciembre
  select gc.concepto_gen
    into ls_cnc_grati_jul
  from grupo_calculo gc
  where gc.grupo_calculo = ls_grp_gratif_jul;

  select gc.concepto_gen
    into ls_cnc_grati_dic
  from grupo_calculo gc
  where gc.grupo_calculo = ls_grp_gratif_dic;

  ls_dia  := to_char(ld_fecha,'DD') ;
  if to_char(ld_fecha,'MM') = '01' then
    ls_mes := 'ENERO' ;
  elsif to_char(ld_fecha,'MM') = '02' then
    ls_mes := 'FEBRERO' ;
  elsif to_char(ld_fecha,'MM') = '03' then
    ls_mes := 'MARZO' ;
  elsif to_char(ld_fecha,'MM') = '04' then
    ls_mes := 'ABRIL' ;
  elsif to_char(ld_fecha,'MM') = '05' then
    ls_mes := 'MAYO' ;
  elsif to_char(ld_fecha,'MM') = '06' then
    ls_mes := 'JUNIO' ;
  elsif to_char(ld_fecha,'MM') = '07' then
    ls_mes := 'JULIO' ;
  elsif to_char(ld_fecha,'MM') = '08' then
    ls_mes := 'AGOSTO' ;
  elsif to_char(ld_fecha,'MM') = '09' then
    ls_mes := 'SETIEMBRE' ;
  elsif to_char(ld_fecha,'MM') = '10' then
    ls_mes := 'OCTUBRE' ;
  elsif to_char(ld_fecha,'MM') = '11' then
    ls_mes := 'NOVIEMBRE' ;
  elsif to_char(ld_fecha,'MM') = '12' then
    ls_mes := 'DICIEMBRE' ;
  end if ;
  ls_anno := to_char(ld_fecha,'YYYY') ;

  -- Recorro el cursor de los trabajadores para sacar los datos
  for rc_mae in c_maestro loop

   ls_nombres := usf_rh_nombre_trabajador(rc_mae.cod_trabajador) ;
    
   select e.nombre, e.Direccion, e.ruc, e.representante, e.identificacion
     into ls_empresa_nom, ls_empresa_dir, ls_ruc, ls_representante, ls_dni_repre
   from empresa e 
   where e.cod_empresa = rc_mae.cod_empresa ;

   select nvl(s.desc_seccion,' ') 
     into ls_descripcion 
   from seccion s
   where s.cod_area    = rc_mae.cod_area 
     and s.cod_seccion = rc_mae.cod_seccion ;
    
    -- Sumo toda la retención obtenida
   select NVL(sum(h.imp_soles),0) 
     into ln_imp_renta 
   from historico_calculo h
   where h.concep in (ls_cnc_rta_qta, ls_cnc_rta_qta2) 
     and h.cod_trabajador = rc_mae.cod_trabajador 
     and to_char(h.fec_calc_plan,'YYYY') = to_char(ld_fecha,'YYYY') ;
    
    -- Gratificacion de Julio y Diciembre
   select NVL(sum(h.imp_soles),0) 
     into ln_rem_grati 
   from historico_calculo h
   where h.concep in (ls_cnc_grati_dic, ls_cnc_grati_jul) 
     and h.cod_trabajador = rc_mae.cod_trabajador 
     and to_char(h.fec_calc_plan,'YYYY') = to_char(ld_fecha,'YYYY') ;

    -- Remuneracion Precisa
   select NVL(sum(h.imp_soles),0) 
     into ln_rem_precisa 
   from historico_calculo h
   where h.concep in ( select d.concepto_calc
              from grupo_calculo_det d
              where d.grupo_calculo = ls_grp_quinta_categ )
     and h.cod_trabajador = rc_mae.cod_trabajador 
     and to_char(h.fec_calc_plan,'YYYY') = to_char(ld_fecha,'YYYY') ;
       
     -- Remuneracion Variable
   select NVL(sum(h.imp_soles),0) 
     into ln_rem_imprecisa 
   from historico_calculo h
   where h.concep in ( select d.concepto_calc
              from grupo_calculo_det d
              where d.grupo_calculo = ls_grp_ganan_imprec )
     and h.cod_trabajador = rc_mae.cod_trabajador 
     and to_char(h.fec_calc_plan,'YYYY') = to_char(ld_fecha,'YYYY') 
     and h.concep not in (ls_cnc_grati_jul, ls_cnc_grati_dic);

     -- remuneracion Externa
   select NVL(SUM(q.rem_externa),0)
     into ln_ingr_externo
   from quinta_categoria q
   where q.cod_trabajador = rc_mae.cod_trabajador
     and to_char(q.fec_proceso,'yyyy') = to_char(ld_fecha,'yyyy')
     and q.flag_automatico = '0';

     -- Retención Externa
   select NVL(SUM(q.rem_retencion),0)
     into ln_retencion_ext
   from quinta_categoria q
   where q.cod_trabajador = rc_mae.cod_trabajador
     and to_char(q.fec_proceso,'yyyy') = to_char(ld_fecha,'yyyy')
     and q.flag_automatico = '0';

     -- calculo la base imponible
    ln_base_imponible := ln_uit * 7;
    
     -- Calculo los totales
    ln_imp_total := ln_rem_precisa + ln_rem_imprecisa + ln_rem_grati + ln_ingr_externo ;
    ln_imp_neto  := ln_imp_total - ( ln_base_imponible + ln_retencion_ext ) ;

    insert into tt_rpt_certificados (
      empresa_nom, empresa_dir, ruc, seccion, descripcion, codigo, nombres, dni, 
      rem_precisa, rem_imprecisa, rem_grati, ingr_externo, ret_externo, base_imponible, 
      imp_renta, total, neto, dia, mes, anno, tipo_trabajador, cod_origen, 
      representante, dni_representante, ingr_utilidades )
    values (
      ls_empresa_nom, ls_empresa_dir, ls_ruc, rc_mae.cod_seccion, ls_descripcion, 
      rc_mae.cod_trabajador, ls_nombres, rc_mae.dni, ln_rem_precisa, ln_rem_imprecisa, 
      ln_rem_grati, ln_ingr_externo, ln_retencion_ext, ln_base_imponible, ln_imp_renta, 
      ln_imp_total, ln_imp_neto, ls_dia, ls_mes, ls_anno, rc_mae.tipo_trabajador, 
      rc_mae.cod_origen, ls_representante, ls_dni_repre, ln_ingr_utilidades ) ;

  end loop ;
  
  commit;
end usp_rh_rpt_certificados_quinta ;
/
