CREATE OR REPLACE PROCEDURE usp_rh_utl_mov_calculo(
  an_periodo      in utl_distribucion.periodo%type, 
  an_item         in utl_distribucion.item%type, 
  as_origen       in origen.cod_origen%type, 
  as_tipo_trabaj  in tipo_trabajador.tipo_trabajador%type, 
  as_flag_externo in utl_distribucion.flag_estado%type 
) is

ln_verifica                        integer ;
-- Variables de parametros
ld_porc_distribucion               utl_distribucion.porc_distribucion%type ;
ld_renta_neta                      utl_distribucion.renta_neta%type ;
ld_porc_dias_laborados             utl_distribucion.porc_dias_laborados%type ;
ld_porc_renumeracion               utl_distribucion.porc_remuneracion%type ;
ls_grupo_pago                      grupo_calculo.grupo_calculo%type ;
ln_dias_tope_ano                   utlparam.dias_tope_ano%type ;

-- Variables del año
ld_ano_ini                         date ;
ld_ano_fin                         date ;
ln_dias_ano                        number(4) ;

-- Variables de configuracion de utilidad
ld_fecha_ini                       utl_distribucion.fecha_ini%type ;
ld_fecha_fin                       utl_distribucion.fecha_fin%type ;
ln_dias_periodo                    number(4) ;

-- Totales por trabajador
ld_fec_ini_trabaj                  date ;
ld_fec_fin_trabaj                  date ;
ln_dias_tot_x_trabaj               number ;
ln_pagos_x_trabaj                  number(13,2) ;
ln_doming_tot_x_trabaj             number(4) ;
ln_feriado_x_trabaj                number(4) ;
ln_dias_inasist_x_trabaj           number(4) ;

--  Lectura del maestro de trabajadores para calculo de utilidades
CURSOR c_personal(ad_fecha_ini in date, ad_fecha_fin in date) is 
SELECT distinct hc.cod_trabajador as cod_trabajador, 
                hc.cod_origen, hc.tipo_trabajador, m.fec_ingreso, m.fec_cese
  FROM historico_calculo hc, 
       maestro           m, 
       grupo_calculo     gc, 
       grupo_calculo_det gcd 
 WHERE hc.cod_trabajador = m.cod_trabajador 
   and hc.cod_origen like as_origen 
   and m.tipo_trabajador like as_tipo_trabaj 
   and TRUNC(hc.fec_calc_plan) between ad_fecha_ini and ad_fecha_fin 
   and gc.grupo_calculo = gcd.grupo_calculo 
   and hc.concep = gcd.concepto_calc 
   and hc.imp_soles > 0 
ORDER BY hc.cod_trabajador ;

--  Lectura del personal extra que no esta en planilla
CURSOR c_personal_extra is
  SELECT e.cod_relacion, e.remun_anual, e.dias_efect_ano, e.cod_origen, e.tipo_trabajador  
    FROM utl_personal_ext e
   WHERE e.periodo = an_periodo 
     AND e.item = an_item 
     AND e.cod_origen like as_origen 
     AND e.tipo_trabajador like as_tipo_trabaj 
ORDER BY e.cod_relacion ;

-- Lectura de personal que recibe utilidades, pero que tenga descuento judicial
CURSOR c_movimiento is
SELECT u.proveedor, m.porc_judicial 
  FROM utl_movim_general u, maestro m 
 WHERE u.proveedor = m.cod_trabajador 
   AND NVL(m.porc_judicial,0) > 0 
   AND u.periodo = an_periodo 
   AND u.item    = an_item ;

BEGIN

--  *******************************************************************
--  ***   CALCULO DE DISTRIBUCION POR PARTICIPACION DE UTILIDADES   ***
--  *******************************************************************

-- Verifica si existe el periodo para calcular utilidades.
SELECT count(*) 
  INTO ln_verifica 
  FROM utl_distribucion d 
 WHERE d.periodo = an_periodo and d.item = an_item and d.flag_estado='1';
 
IF ln_verifica = 0 THEN
   raise_application_error (-20000, 'Registre información para proceso de Utilidades') ;
   return ;
END IF ;

/*IF ln_verifica > 1 THEN
   raise_application_error (-20001, 'Tiene mas de 1 periodo abierto de utilidades en el mismo año') ;
   return ;
END IF ;*/

-- Captura datos de utilidades
SELECT u.grp_remun_anual, u.dias_tope_ano 
  INTO ls_grupo_pago, ln_dias_tope_ano 
  FROM utlparam u 
 WHERE u.reckey='1' ;

-- Verfica datos para calcular utilidades
SELECT u.porc_distribucion, u.renta_neta, u.porc_dias_laborados, u.porc_remuneracion, u.fecha_ini, u.fecha_fin, u.dias_periodo
  INTO ld_porc_distribucion, ld_renta_neta, ld_porc_dias_laborados, ld_porc_renumeracion, ld_fecha_ini, ld_fecha_fin, ln_dias_periodo 
  FROM utl_distribucion u 
 WHERE u.periodo=an_periodo AND u.item=an_item ;

-- Calculando dias totales del periodo
ld_ano_ini := to_date('01/01/'||to_char(ld_fecha_ini,'yyyy'),'dd/mm/yyyy') ;
ld_ano_fin := to_date('31/12/'||to_char(ld_fecha_ini,'yyyy'),'dd/mm/yyyy') ;
ln_dias_ano := ld_ano_fin - ld_ano_ini + 1 ;

-- Verifica dias totales del periodo, que no debe exceder a 360 dias
SELECT SUM(u.dias_periodo)
  INTO ln_dias_periodo 
  FROM utl_distribucion u 
 WHERE u.periodo = an_periodo ;

IF ln_dias_periodo > ln_dias_ano THEN
   raise_application_error (-20002, 'Los dias del periodo no pueden exceder al total dias año') ;
   return ;
END IF ;

IF ln_dias_periodo = 0 THEN
   raise_application_error (-20003, 'El periodo a calcular utilidades esta errado') ;
   return ;
END IF ;

-- Eliminando datos de tabla de movimientos para regenerarlos
DELETE FROM utl_movim_general u 
 WHERE u.periodo=an_periodo 
   AND u.item=an_item 
   AND u.cod_origen like as_origen 
   AND u.tipo_trabajador like as_tipo_trabaj;

-- Calcula pagos del todo el personal
FOR c_p IN c_personal(ld_fecha_ini, ld_fecha_fin) LOOP
    -- Verifica si personal debe ser considerado en calculo o no
    SELECT count(*) 
      INTO ln_verifica 
      FROM utl_excl_trabajador u 
     WHERE u.cod_trabajador = c_p.cod_trabajador 
       AND u.periodo        = an_periodo 
       AND item             = an_item ;

    -- Continua el proceso
    IF ln_verifica = 1 THEN
       EXIT ;
    END IF ;
    
    SELECT sum(hc.imp_soles) 
      INTO ln_pagos_x_trabaj  
      FROM historico_calculo hc,
           grupo_calculo_det gcd 
     WHERE hc.cod_trabajador = c_p.cod_trabajador 
       and TRUNC(hc.fec_calc_plan) between trunc(ld_fecha_ini) and trunc(ld_fecha_fin) 
       and hc.concep = gcd.concepto_calc
       and gcd.grupo_calculo = ls_grupo_pago; 
  
    -- Actualizar los dias totales por trabajador
    IF c_p.fec_ingreso <= ld_fecha_ini THEN
       ld_fec_ini_trabaj := ld_fecha_ini ;
    ELSE 
       ld_fec_ini_trabaj := c_p.fec_ingreso ;
    END IF ;
    
    IF NVL(c_p.fec_cese, ld_fecha_fin)>=ld_fecha_fin THEN
       ld_fec_fin_trabaj := ld_fecha_fin ;
    ELSE
       ld_fec_fin_trabaj := c_p.fec_cese ;
    END IF ;
    
/*    IF ld_fec_fin_trabaj < ld_fec_ini_trabaj THEN
       raise_application_error (-20002, 'Dias de inicio y fin errados de ' ||c_p.cod_trabajador) ;
       return ;
    END IF ;*/
    
    -- Calculando los dias totales trabajados (360/ln_dias_ano, factor de conversión)
    ln_dias_tot_x_trabaj := USF_RH_DIAS_TOT_UTIL(c_p.cod_trabajador, c_p.tipo_trabajador, 
                                                 ld_fec_ini_trabaj, ld_fec_fin_trabaj ) ;

    -- Actualizar los domingos (incluye sabados para empleados Lima)
    ln_doming_tot_x_trabaj := USF_RH_CALC_DOMINGOS(ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;
    
    -- Actualizar los feriados
    ln_feriado_x_trabaj := USF_RH_DIAS_FERIADO(c_p.cod_origen, ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;
    
    -- Actualizar las inasistencias (descontar domingos y feriados) 
    ln_dias_inasist_x_trabaj := USF_RH_DIAS_INASIST_UTIL(c_p.cod_trabajador, ld_fec_ini_trabaj, ld_fec_fin_trabaj) ;
                              
    -- Actualiza adelantos por trabajador 
    -- utl_adlt_ext
    
    -- Actualiza datos de utilidades por trabajador 
    UPDATE utl_movim_general u 
       SET u.pagos = NVL(u.pagos,0) + ln_pagos_x_trabaj, 
           u.dias_total = NVL(u.dias_total,0) + ln_dias_tot_x_trabaj, 
           u.dias_domingo = NVL(u.dias_domingo,0) + ln_doming_tot_x_trabaj,
           u.dias_feriado = NVL(u.dias_feriado,0) + ln_feriado_x_trabaj,
           u.dias_inasist = NVL(u.dias_inasist,0) + ln_dias_inasist_x_trabaj
     WHERE u.periodo = an_periodo 
       AND u.item = an_item 
       AND u.proveedor = c_p.cod_trabajador ;
    
    -- Ingresa datos de pagos en caso no exista
    IF SQL%NOTFOUND THEN
       INSERT INTO utl_movim_general(
              periodo, 
              item, 
              proveedor, 
              pagos, 
              dsctos, 
              dias_total, 
              dias_domingo, 
              dias_feriado, 
              dias_inasist, 
              cod_origen, 
              tipo_trabajador, reintegro, adelantos, retencion_judic, utilidad_pago, utilidad_asistencia)
       VALUES(
              an_periodo, 
              an_item, 
              c_p.cod_trabajador, 
              ln_pagos_x_trabaj, 
              0, 
              ln_dias_tot_x_trabaj, 
              ln_doming_tot_x_trabaj, 
              ln_feriado_x_trabaj, 
              ln_dias_inasist_x_trabaj, 
              c_p.cod_origen, 
              c_p.tipo_trabajador, 0, 0, 0, 0, 0) ;
    END IF ;
    
END LOOP ;

IF as_flag_externo = '1' THEN 
    -- Agregar información de externos
    FOR c_e IN c_personal_extra LOOP
            -- Actualiza datos de utilidades por trabajador 
        UPDATE utl_movim_general u 
           SET u.pagos = NVL(u.pagos,0) + c_e.remun_anual, 
               u.dias_total = NVL(u.dias_total,0) + c_e.dias_efect_ano, 
               u.dias_domingo = NVL(u.dias_domingo,0) + 0,
               u.dias_feriado = NVL(u.dias_feriado,0) + 0,
               u.dias_inasist = NVL(u.dias_inasist,0) + 0
         WHERE u.periodo = an_periodo 
           AND u.item = an_item 
           AND u.proveedor = c_e.cod_relacion ;
        
        -- Ingresa datos de pagos en caso no exista
        IF SQL%NOTFOUND THEN
           INSERT INTO utl_movim_general(
                  periodo, 
                  item, 
                  proveedor, 
                  pagos, 
                  dsctos, 
                  dias_total, 
                  dias_domingo, 
                  dias_feriado, 
                  dias_inasist, 
                  cod_origen, 
                  tipo_trabajador, reintegro, adelantos, retencion_judic, utilidad_pago, utilidad_asistencia)
           VALUES(
                  an_periodo, 
                  an_item, 
                  c_e.cod_relacion, 
                  c_e.remun_anual, 
                  0, 
                  c_e.dias_efect_ano, 
                  0, 
                  0, 
                  0, 
                  c_e.cod_origen, 
                  c_e.cod_relacion, 0,0,0,0,0) ;
        END IF ;
        
    END LOOP ;
END IF ;

-- Registra porcentajes de descuentos judiciales
FOR c_m IN c_movimiento LOOP
    UPDATE utl_movim_general u 
       SET u.retencion_judic = c_m.porc_judicial 
     WHERE u.periodo = an_periodo 
       AND u.item    = an_item 
       AND u.proveedor = c_m.proveedor ;
END LOOP ;

END usp_rh_utl_mov_calculo;
/
