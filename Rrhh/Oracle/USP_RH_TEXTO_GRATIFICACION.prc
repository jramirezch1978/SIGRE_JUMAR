CREATE OR REPLACE PROCEDURE USP_RH_TEXTO_GRATIFICACION
       (as_origen in origen.cod_origen%type, 
        as_tipo_trabajador in tipo_trabajador.tipo_trabajador%type, 
        as_tipo_archivo in char, 
        as_banco in banco.cod_banco%type, 
        as_periodo in char, 
        ad_fecha_abono in date) is

ln_total_adelanto  number ;
ls_adelanto        varchar2(20) ;
ln_count           number ;

BEGIN

-- as_tipo_archivo: G-Gratificacion
-- as_banco : 001
-- as_periodo : yyyymm

-- Inicializa el archivo
delete from tt_rh_exp_mm ;

SELECT SUM(g.imp_adelanto)
  INTO ln_total_adelanto 
  FROM gratificacion g, maestro m
 WHERE g.cod_trabajador = m.cod_trabajador and 
       m.cod_origen     = as_origen and 
       m.tipo_trabajador= as_tipo_trabajador and 
       g.periodo = as_periodo and 
       m.nro_cnta_ahorro is not null and 
       m.cod_banco = as_banco ;

SELECT count(*) 
  INTO ln_count 
  FROM gratificacion g, maestro m
 WHERE g.cod_trabajador = m.cod_trabajador and 
       m.cod_origen     = as_origen and 
       m.tipo_trabajador= as_tipo_trabajador and 
       g.periodo = as_periodo and 
       m.nro_cnta_ahorro is not null and 
       m.cod_banco = as_banco ;

ls_adelanto := TRIM(LTRIM(RTRIM(TO_CHAR( 100 * ln_total_adelanto, '000000000000000')))) ;

IF as_tipo_archivo = 'G' THEN 
  -- Ingresa el primer registro
  INSERT INTO tt_rh_exp_mm(exp_row) 
  VALUES ('#1HC19300532055092      S/'
          ||ls_adelanto||to_char(ad_fecha_abono,'ddmmyyyy')
          ||'PAGO HABERES        325008294106300'
          ||LTRIM(RTRIM(TO_CHAR(ln_count,'000000')))
          ||'1               1') ;
  
  -- Actualiza el detalle del artchivo
  INSERT INTO tt_rh_exp_mm
  SELECT ' 2A'||SUBSTR(m.nro_cnta_ahorro,1,3)||SUBSTR(m.nro_cnta_ahorro,5,8)||SUBSTR(m.nro_cnta_ahorro,14,1)||
         SUBSTR(m.nro_cnta_ahorro,16,2)||'      '|| 
         SUBSTR(TRIM(LTRIM(RTRIM(m.apel_paterno))||' '||LTRIM(RTRIM(m.apel_materno))||' '||LTRIM(RTRIM(m.nombre1))||' '||LTRIM(RTRIM(nvl(m.nombre2,''))))||'                              ',1,40)||
         substr(m.cod_moneda,1,2)|| 
         TRIM(LTRIM(RTRIM(TO_CHAR(100*g.imp_adelanto,'000000000000000'))))|| 
         ' PAGO TELECREDITO                       '|| 
         '0DNI'||m.dni||'    1'
    FROM gratificacion g, maestro m
   WHERE g.cod_trabajador = m.cod_trabajador and 
         m.cod_origen     = as_origen and 
         m.tipo_trabajador= as_tipo_trabajador and 
         g.periodo = as_periodo and 
         m.nro_cnta_ahorro is not null and 
         m.cod_banco = as_banco ;
END IF ;
commit ;

END USP_RH_TEXTO_GRATIFICACION;
/
