CREATE OR REPLACE PROCEDURE usp_rh_asiento_prov_vac (
  as_origen in origen.cod_origen%type,
  as_usuario in usuario.cod_usr%type,
  as_tipo    in maestro.flag_estado%type,
  ad_fec_proceso in date,
  ad_fec_desde in date,
  ad_fec_hasta in date ) is

-- as_tipo => P = Produccion, V = Veda

ln_libro_prov        cntbl_libro.nro_libro%type ;
ln_ano               cntbl_asiento.ano%type ;
ln_count             Number;
ln_mes               cntbl_asiento.mes%type ;
lc_proceso           cntbl_pre_asiento.tipo_proceso%type ;
ld_fec_inicio        date ;
ln_tipo_cambio       calendario.cmp_dol_emp%type ;
ls_cnta_debe         cntbl_cnta.cnta_ctbl%type ;
ls_cnta_haber        cntbl_cnta.cnta_ctbl%type ;
ls_cnta_aux          cntbl_cnta.cnta_ctbl%type ;
ls_soles             moneda.cod_moneda%type ;
ln_provisional       cntbl_libro.num_provisional%type ;
lb_ok                boolean ;
ls_cod_ctabco        banco_cnta.cod_ctabco%type ;
ls_tipo_doc          doc_tipo.tipo_doc%type ;
ls_nro_doc           cntbl_pre_asiento_det.nro_docref1%type ;
ls_nro_doc2          cntbl_pre_asiento_det.nro_docref1%type ;
ln_total_soldeb      cntbl_pre_asiento.tot_soldeb%type ;
ln_total_solhab      cntbl_pre_asiento.tot_soldeb%type ;
ln_total_doldeb      cntbl_pre_asiento.tot_soldeb%type ;
ln_total_dolhab      cntbl_pre_asiento.tot_soldeb%type ;

--  Personal activo para generacion de asientos de vacaciones
CURSOR c_maestro(an_ano in cntbl_asiento.ano%type, an_mes in cntbl_asiento.mes%type) is
  SELECT m.cod_trabajador, m.tipo_trabajador, m.cencos, m.centro_benef, (r.importe)/2 as importe
    FROM maestro m, prov_vac_bonif r
   WHERE m.cod_trabajador = r.cod_trabajador
     AND to_char(r.Fec_Proceso,'mmyyyy') =  trim(to_char(an_mes,'00')||to_char(an_ano))
     AND m.cod_origen = as_origen
  ORDER BY m.cod_trabajador ;
--rc_mae c_maestro%rowtype ;

/*--  Lectura para generar asientos de la distribucion contable
CURSOR c_distribucion is
  select d.cod_trabajador, d.cencos, d.cod_labor, d.nro_horas
  from distribucion_cntble d
  where d.cod_trabajador = ls_codigo and
        to_date(to_char(d.fec_movimiento,'DD/MM/YYYY'),'DD/MM/YYYY') between
        to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')
  order by d.cod_trabajador, d.cencos, d.cod_labor ;
rc_dis c_distribucion%rowtype ;*/

BEGIN

--  ********************************************************************
--  ***   GENERA ASIENTOS CONTABLES POR PROVIONES DE GRATIFICACION   ***
--  ********************************************************************
SELECT t.libro_prov_vacac
  INTO ln_libro_prov
  FROM tipo_trabajador t
 WHERE t.tipo_trabajador = (SELECT r.tipo_trab_empleado FROM rrhhparam r WHERE r.reckey='1') ;
-- ln_libro_prov := 29 ; -- Colocarlo en parametro mm.

ln_ano := TO_NUMBER(TO_CHAR(ad_fec_proceso,'yyyy')) ;
ln_mes := TO_NUMBER(TO_CHAR(ad_fec_proceso,'mm')) ;
lc_proceso := 'RV' ;  -- Colocarlo en parametro mm.
ld_fec_inicio := to_date('01'||'/'||to_char(ad_fec_proceso,'MM')||'/'||
                 to_char(ad_fec_proceso,'YYYY'),'DD/MM/YYYY') ;
--  Borrar pre asiento tipo gratificacion en caso exista
usp_cnt_borra_preasient_tipo( as_origen, ln_libro_prov, lc_proceso, ld_fec_inicio, ad_fec_proceso ) ;


-- Calculando el tipo de cambio
ln_tipo_cambio := USF_CMP_TIPO_CAMBIO(ad_fec_proceso) ;

-- Calculando moneda soles
SELECT l.cod_soles
  INTO ls_soles
  FROM logparam l
 WHERE l.reckey='1' ;

--  Determina numero provisional
SELECT l.num_provisional
  INTO ln_provisional
  FROM cntbl_libro l
 WHERE l.nro_libro = ln_libro_prov ;

IF NVL(ln_provisional,0) = 0 THEN
  UPDATE cntbl_libro c
     SET c.num_provisional = 1
   WHERE c.nro_libro = ln_provisional ;

  ln_provisional := 1 ;
ELSE
  ln_provisional := ln_provisional + 1 ;
END IF ;

ln_provisional := ln_provisional + 1 ;

--  Adiciona registro de cabecera del pre asiento
INSERT INTO cntbl_pre_asiento (
  origen, nro_libro, nro_provisional, cod_moneda,
  tasa_cambio, desc_glosa, fec_cntbl, fec_registro,
  tipo_proceso, cod_usr, flag_estado, tot_soldeb,
  tot_solhab, tot_doldeb, tot_dolhab, flag_replicacion )
values (
  as_origen, ln_libro_prov, ln_provisional, ls_soles,
  ln_tipo_cambio, 'PROVISION DE VACACIONES PERIODO '||to_char(ln_ano)||'-'||to_char(ln_mes), ad_fec_proceso, sysdate,
  lc_proceso, as_usuario, '1', 0,
  0, 0, 0, '1' ) ;

-- Actualizando el detalle
FOR c_m IN c_maestro(ln_ano, ln_mes ) LOOP

    -- Buscando la cuenta contable, según centro de costo, asi este en producción o veda
   SELECT DECODE(as_tipo, 'P', c.cnt_ctbl_debe, c.cnt_ctbl_debe_veda), c.cnt_ctbl_haber
     INTO ls_cnta_debe, ls_cnta_haber
     FROM cnt_conf_provis_plla c
    WHERE c.tipo_trabajador = c_m.tipo_trabajador
      AND c.flag_tipo_provision = 'V'
      AND c.cencos = c_m.cencos ;

      select count(*)
      into ln_count
      from matriz_transf_cntbl_cencos t
      where t.cencos = c_m.cencos
        and t.org_cnta_ctbl = ls_cnta_debe;

      ls_cnta_aux := ls_cnta_debe;
      
      if ln_count > 0 then
        select t.dst_cnta_ctbl
          into ls_cnta_debe
          from matriz_transf_cntbl_cencos t
          where t.cencos = c_m.cencos
            and t.org_cnta_ctbl = ls_cnta_aux;
      end if;
   -- Ingresando la cuenta debe
   IF ls_cnta_debe IS NULL THEN
      RAISE_APPLICATION_ERROR(-20000, 'Cuenta contable debe no existe. Coordine con Sistemas') ;
      Return ;
   END IF ;

   lb_ok := usf_cnt_pre_asiento_det(
           as_origen, ln_libro_prov,
           ln_provisional, ls_cnta_debe,
           ad_fec_proceso, 'Provisión de Vacaciones',
           '0', 'D', -->as_flag_gen_aut, as_flag_debhab
           c_m.cencos, ls_cod_ctabco,
           ls_tipo_doc, ls_nro_doc,
           ls_nro_doc2, c_m.cod_trabajador,
           c_m.importe, round(c_m.importe / ln_tipo_cambio,2),
           0, 
           c_m.centro_benef,
           null,
           null ) ;

    -- Ingresando cuenta haber
   IF ls_cnta_haber IS NULL THEN
      RAISE_APPLICATION_ERROR(-20000, 'Cuenta contable haber no existe. Coordine con Sistemas') ;
      Return ;
   END IF ;

   lb_ok := usf_cnt_pre_asiento_det(
           as_origen, ln_libro_prov,
           ln_provisional, ls_cnta_haber,
           ad_fec_proceso, 'Provisión de Vacaciones',
           '0', 'H', -->as_flag_gen_aut, as_flag_debhab
           c_m.cencos, ls_cod_ctabco,
           ls_tipo_doc, ls_nro_doc,
           ls_nro_doc2, c_m.cod_trabajador,
           c_m.importe, round(c_m.importe / ln_tipo_cambio,2),
           0, 
           c_m.centro_benef,
           null,
           null ) ;

END LOOP ;

--  Actualiza nuevo numero provisional
UPDATE cntbl_libro
   SET num_provisional = ln_provisional + 1,
       flag_replicacion = '1'
 WHERE nro_libro = ln_libro_prov ;

--  Actualiza importes del registro de cabebcera
ln_total_soldeb := 0 ; ln_total_solhab := 0 ;
ln_total_doldeb := 0 ; ln_total_dolhab := 0 ;

SELECT sum(decode(d.flag_debhab,'D',d.imp_movsol,0)),
       sum(decode(d.flag_debhab,'H',d.imp_movsol,0)),
       sum(decode(d.flag_debhab,'D',d.imp_movdol,0)),
       sum(decode(d.flag_debhab,'H',d.imp_movdol,0))
  INTO ln_total_soldeb, ln_total_solhab, ln_total_doldeb, ln_total_dolhab
  FROM cntbl_pre_asiento_det d
 WHERE d.origen = as_origen
   AND d.nro_libro = ln_libro_prov
   AND d.nro_provisional = ln_provisional
   AND d.fec_cntbl = ad_fec_proceso ;

UPDATE cntbl_pre_asiento
   SET tot_soldeb = ln_total_soldeb ,
       tot_solhab = ln_total_solhab ,
       tot_doldeb = ln_total_doldeb ,
       tot_dolhab = ln_total_dolhab,
       flag_replicacion = '1'
 WHERE origen = as_origen and nro_libro = ln_libro_prov and
       nro_provisional = ln_provisional and fec_cntbl = ad_fec_proceso ;

END usp_rh_asiento_prov_vac ;
/
