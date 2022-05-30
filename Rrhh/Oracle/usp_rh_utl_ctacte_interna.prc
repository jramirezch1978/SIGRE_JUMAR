CREATE OR REPLACE PROCEDURE usp_rh_utl_ctacte_interna (
  an_periodo      in utl_movim_general.periodo%type, 
  an_item         in utl_movim_general.item%type ) is

ln_adelantos            number ; -- Cuenta corriente interna
ln_verifica             integer ;
ld_fecha_calculo_util   date ; -- Debe ser un campo de utl_distribucion
ln_tipo_cambio          calendario.vta_dol_prom%type ;
ls_cod_soles            moneda.cod_moneda%type ;

--  Lectura del maestro de trabajadores para calculo de utilidades
CURSOR c_movimiento is
  select u.proveedor from utl_movim_general u 
  WHERE u.periodo = an_periodo and 
        u.item    = an_item ;

CURSOR c_ctacte_interna(as_cod_trabajador IN maestro.cod_trabajador%type) IS
SELECT c.tipo_doc, c.nro_doc, c.cod_moneda, m.flag_cal_plnlla, m.flag_estado, 
       CASE WHEN c.mont_cuota <= c.sldo_prestamo THEN c.mont_cuota ELSE c.sldo_prestamo END as cuota 
  FROM cnta_crrte c, maestro m  
 WHERE c.cod_trabajador = m.cod_trabajador 
   AND c.cod_trabajador=as_cod_trabajador  
   AND c.flag_estado='1' 
   AND c.flag_tipo_aplic_parcial='U' ;
        
BEGIN 

  --  *******************************************************************
  --  ***   CALCULO DE DISTRIBUCION POR PARTICIPACION DE UTILIDADES   ***
  --  *******************************************************************
  SELECT count(*) 
    INTO ln_verifica 
    FROM utl_distribucion d
   WHERE d.periodo = an_periodo and d.item = an_item and d.flag_estado = '1' ;
   
  IF ln_verifica = 0 THEN 
    raise_application_error (-20000, 'No existe información para calcular proceso de Utilidades') ;
  END IF ;
  
  -- Lee parametros
  SELECT u.fecha_pago
    INTO ld_fecha_calculo_util
    FROM utl_distribucion u 
   WHERE u.periodo = an_periodo and 
         u.item    = an_item ;
  
  -- Soles
  SELECT l.cod_soles INTO ls_cod_soles FROM logparam l WHERE l.reckey='1' ;
  
  -- Calculando monto a distribuir por remuneracion y/o dias trabajados
  ln_verifica := 0 ;      
  
  SELECT c.vta_dol_prom 
    INTO ln_tipo_cambio 
    FROM calendario c 
   WHERE c.fecha = ld_fecha_calculo_util ;
  
  IF NVL(ln_tipo_cambio,0) = 0 THEN
     raise_application_error (-20000, 'Tipo de cambio errado para fecha ' || to_char(ld_fecha_calculo_util,'dd/mm/yyyy')) ;
  END IF ;
  
  -- Debe eliminar registros, para recalcular cuenta corriente interna a considerar en utilidades - cnta_crrte)
  DELETE from utl_adelanto_interno u 
   WHERE u.periodo = an_periodo 
     AND u.item = an_item ;
  
  commit ;
  
  --  Determina utilidades por trabajador 
  FOR rc_m in c_movimiento LOOP 
      -- Incializa cuenta corriente interna
      ln_adelantos := 0 ;
      
      FOR rc_cta in c_ctacte_interna(rc_m.proveedor) LOOP
          IF rc_cta.cod_moneda = ls_cod_soles THEN
             ln_adelantos := ln_adelantos + rc_cta.cuota  ;
          ELSE
             ln_adelantos := ln_adelantos + rc_cta.cuota / ln_tipo_cambio ;
          END IF ;
          -- Actualiza cuenta corriente interna para calculo de utilidades
          INSERT INTO utl_adelanto_interno(
                 cod_relacion, tipo_doc, nro_doc, periodo, item,
                 cod_moneda, importe, flag_estado_trabaj, flag_calc_plla, flag_estado_registro, 
                 tipo_cambio)
          VALUES(rc_m.proveedor, rc_cta.tipo_doc, rc_cta.nro_doc, an_periodo, an_item, 
                 rc_cta.cod_moneda, rc_cta.cuota, rc_cta.flag_estado, rc_cta.flag_cal_plnlla, '1',
                 ln_tipo_cambio) ;
      
      END LOOP ;
      
  END LOOP ;
  
END usp_rh_utl_ctacte_interna ;
/
