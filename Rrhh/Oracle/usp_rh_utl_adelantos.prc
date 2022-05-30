CREATE OR REPLACE PROCEDURE usp_rh_utl_adelantos (
  an_periodo in cntbl_asiento.ano%type, 
  ad_fecha_tope in date, 
  as_origen in origen.cod_origen%type,
  as_tipo_trabaj in tipo_trabajador.tipo_trabajador%type, 
  as_del_inf_ext    in char, 
  as_tipo_adelanto  in char, 
  an_monto          in number) is

ln_verifica            integer ;
ld_fec_adelanto        date ;
ls_flag_adelanto       maestro.flag_estado%type ;
ls_concepto            char(4) ;
ln_monto               number(13,2);
ln_judicial            number(13,2);

--  Lectura de personal considerado para pagos a cuenta de utilidades
CURSOR c_maestro is
SELECT hc.cod_trabajador, hc.cod_origen, hc.tipo_trabajador, NVL(m.porc_judicial,0) as porc_judicial, 
       sum(hc.imp_soles) as total_sol
  FROM utlparam u, grupo_calculo gc, grupo_calculo_det gcd, historico_calculo hc, maestro m
 WHERE u.grp_remun_anual = gc.grupo_calculo and
       gc.grupo_calculo  = gcd.grupo_calculo and
       gcd.concepto_calc = hc.concep and
       hc.cod_trabajador = m.cod_trabajador and 
       hc.tipo_trabajador like as_tipo_trabaj and 
       hc.cod_origen like as_origen and 
       trunc(m.fec_ingreso) <= trunc(ad_fecha_tope) and 
       to_number(to_char(hc.fec_calc_plan,'yyyy'))= an_periodo 
GROUP BY hc.cod_trabajador, hc.cod_origen, hc.tipo_trabajador, m.porc_judicial
ORDER BY hc.cod_trabajador ;

BEGIN 

--  ************************************************************************
--  ***   GENERACION DE ADELANTOS A CUENTA DE UTILIDADES DEL EJERCICIO   ***
--  ************************************************************************

--  Verifica que exista montos a otorgar a cuenta de utilidades
ln_verifica := 0 ;

SELECT count(*) 
  INTO ln_verifica 
  FROM utl_adlt_periodo a
 WHERE a.periodo = an_periodo 
   AND nvl(a.flag_estado,'0') = '1' ;

IF ln_verifica=0 THEN
    raise_application_error ( -20000, 'No existe registro autorizado de adelantos. Registre previamente en ventana RH176' ) ;
    Return ;
ELSIF ln_verifica > 1 then
    raise_application_error ( -20001, 'Existe mas de un adelanto a generar. Solo se permite 1 o en todo caso procese al anterior antes de generar el último' ) ;
    Return ;
END IF ;

--  Determina concepto de adelanto a cuenta de utilidades
SELECT p.cncp_adelanto_util 
  INTO ls_concepto 
  FROM utlparam p
 WHERE p.reckey = '1' ;

IF ls_concepto = ' ' THEN
    raise_application_error ( -20002, 'No existe concepto de adelanto de utilidades. Definalo previamente en parametros' ) ;
    Return ;
END IF ;

-- Captura datos de adelantos
SELECT a.fecha_adelanto, a.flag_adelanto 
  INTO ld_fec_adelanto, ls_flag_adelanto
  FROM utl_adlt_periodo a
 WHERE a.periodo = an_periodo 
   AND nvl(a.flag_estado,'0') = '1' ;

-- Elimina adelantos en caso existan
DELETE FROM utl_adlt_ext e
 WHERE e.periodo = an_periodo 
  -- AND e.flag_pers_ext = '0' 
   AND trunc(e.fecha_proceso) = trunc(ld_fec_adelanto) ;


IF as_del_inf_ext='1' THEN
    --  Elimina movimiento generado para nuevo proceso, pero solo a externos
    DELETE FROM utl_adlt_ext e
     WHERE e.periodo = an_periodo 
--       AND e.flag_pers_ext = '1' 
       AND trunc(e.fecha_proceso) = trunc(ld_fec_adelanto) ;
END IF ;

-- Asigna adelantos fijos
FOR c_m IN c_maestro LOOP
    IF ls_flag_adelanto='1' THEN 
       ln_monto := an_monto ;
       ln_judicial := c_m.porc_judicial * ln_monto ;
    ELSE
       ln_monto := (100 - an_monto)/100 * c_m.total_sol ;
       ln_judicial := c_m.porc_judicial * ln_monto ;
    END IF ;
    
    INSERT INTO utl_adlt_ext(periodo, cod_relacion, fecha_proceso, concep, 
                imp_adelanto, imp_reten_jud, flag_replicacion, 
                cod_origen, tipo_trabajador)
    VALUES(an_periodo, c_m.cod_trabajador, ld_fec_adelanto, ls_concepto, 
           ln_monto, ln_judicial,  '1', 
           c_m.cod_origen, c_m.tipo_trabajador) ;
END LOOP ;

--  Actualiza estado de los adelantos otorgados a cuenta

UPDATE utl_adlt_periodo a
   SET a.importe = (SELECT sum(u.imp_adelanto-u.imp_reten_jud) 
                     FROM utl_adlt_ext u 
                    WHERE u.periodo=an_periodo and 
                          TRUNC(u.fecha_proceso)=TRUNC(ld_fec_adelanto)) 
 WHERE a.periodo = an_periodo and 
       trunc(a.fecha_adelanto) = trunc(ld_fec_adelanto) and
       nvl(a.flag_estado,'0') = '1' ;

END usp_rh_utl_adelantos ;
/
