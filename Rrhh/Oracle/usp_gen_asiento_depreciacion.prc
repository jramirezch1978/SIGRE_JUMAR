create or replace procedure usp_gen_asiento_depreciacion(
       ani_mes    in number,
       ani_year   in number
) is

ln_nro_asiento          cntbl_libro_mes.nro_asiento%TYPE;
ls_nro_asiento          asiento.idasiento%TYPE;
ln_count                NUMBER;
ln_libro_depreciacion   cntbl_libro.nro_libro%TYPE;                -- Esto lo saco de parametros
ln_soles                monedas.id_monedas%TYPE;
ln_plan_contable        plan_contable.idplan_contable%TYPE;
ln_tipo_cambio          asiento.tipo_cambio%TYPE;
ln_item                 NUMBER;
ln_importe_sol          asiento_det.importe_sol%TYPE;
ln_importe_dol          asiento_det.importe_dol%TYPE;
ls_glosa                asiento_det.det_glosa%TYPE;
ln_sucursal_piura       sucursal.idsucursal%TYPE;
ld_fecha_cntbl          date;

-- Cursor con los activos válidos de la empresa
cursor c_activos is
  select a.*,
         (select nvl(sum(d.monto),0)
            from depreciacion d
           where d.idactivo = a.idactivo
             and trim(to_char(d.ano))||trim(to_char(d.mes, '00')) < trim(to_char(ani_year))||trim(to_char(ani_mes, '00'))) as total_depreciado,
         round((a.valor_mon_nac * a.tasa / 100) / 12,2) as valor_depreciacion
     from activos a
  where a.estado = '1'
    and a.matriz is not null
    and a.monto_residual > (select nvl(sum(d.monto),0)
                             from depreciacion d
                            where d.idactivo = a.idactivo
                              and trim(to_char(d.ano))||trim(to_char(d.mes, '00')) < trim(to_char(ani_year))||trim(to_char(ani_mes, '00')))
ORDER BY a.idactivo;

-- cursor para la matriz contable
CURSOR c_matriz(as_matriz  matriz_cntbl_finan.matriz%TYPE) IS
  SELECT m.idcuenta, m.flag_debhab, m.glosa_texto,
         c.flag_ctabco, c.flag_cencos, c.flag_doc_ref, c.flag_proveedor
    FROM matriz_cntbl_finan_det m,
         cuenta                 c
   WHERE m.idcuenta = c.idcuenta
     AND m.matriz = as_matriz
  ORDER BY m.item;  
    
begin
  -- Elimino el detalle de los asientos generados por depreciacion
  delete asiento_det ad
   where ad.idasiento in (select d.idasiento
                            from depreciacion d
                           where d.ano = ani_year
                             and d.mes = ani_mes);
  -- Anulo las cabeceras de dichos asientos
  update asiento a
     set a.flag_estado = '0',
         a.total_debe_sol = 0,
         a.total_haber_sol = 0,
         a.total_debe_dol = 0,
         a.total_haber_dol = 0
   where a.idasiento in (select d.idasiento
                            from depreciacion d
                           where d.ano = ani_year
                             and d.mes = ani_mes);
  
  -- Elimino los registros de depreciacion  
  delete depreciacion d
   where d.ano = ani_year
     and d.mes = ani_mes;
  
  -- Obtengo el numero del libro para depreciacion
  SELECT COUNT(*)
    INTO ln_count
    FROM configuracion c
   WHERE c.conf_nombre = 'LIBRO_DEPRECIACION';
  
  IF ln_count = 0 THEN
     INSERT INTO configuracion(conf_nombre, conf_valor, conf_tipodato, conf_descripcion)
     VALUES('LIBRO_DEPRECIACION', '', 'INTEGER', 'NRO DE LIBRO PARA DEPRECIACION');
     COMMIT;
     RAISE_APPLICATION_ERROR(-20000, 'No ha indicado el valor para LIBRO_DEPRECIACION, por favor verifique');
  END IF;
  
  SELECT c.conf_valor
    INTO ln_libro_depreciacion
    FROM configuracion c
   WHERE c.conf_nombre = 'LIBRO_DEPRECIACION';

  -- Por defecto todos los activos son de Piura
  SELECT COUNT(*)
    INTO ln_count
    FROM configuracion c
   WHERE c.conf_nombre = 'SUCURSAL_PIURA';
  
  IF ln_count = 0 THEN
     INSERT INTO configuracion(conf_nombre, conf_valor, conf_tipodato, conf_descripcion)
     VALUES('SUCURSAL_PIURA', '', 'INTEGER', 'SUCURSAL PARA PIURA');
     COMMIT;
     RAISE_APPLICATION_ERROR(-20000, 'No ha indicado el valor para SUCURSAL_PIURA, por favor verifique');
  END IF;
  
  SELECT c.conf_valor
    INTO ln_sucursal_piura
    FROM configuracion c
   WHERE c.conf_nombre = 'SUCURSAL_PIURA';     
  
  -- La moneda soles
  SELECT c.conf_valor
    INTO ln_soles
    FROM configuracion c
   WHERE c.conf_nombre = 'SOLES';
   
  -- Plan contable
  SELECT c.conf_valor
    INTO ln_plan_contable
    FROM configuracion c
   WHERE c.conf_nombre = 'PLAN_CONTABLE';
  
  -- Luego verifico si existe el contador en la tabla contadores
  SELECT COUNT(*)
    INTO ln_count
    FROM cntbl_libro_mes clm
   WHERE clm.idsucursal = ln_sucursal_piura
     AND clm.nro_libro  = ln_libro_depreciacion
     AND clm.ano        = ani_year
     AND clm.mes        = ani_mes;
                    
  IF ln_count = 0 THEN
     INSERT INTO cntbl_libro_mes(idsucursal, nro_libro, ano, mes, nro_asiento)
     VALUES(ln_sucursal_piura, ln_libro_depreciacion, ani_year, ani_mes, 1);
  END IF;
                    
  SELECT clm.nro_asiento
    INTO ln_nro_asiento
    FROM cntbl_libro_mes clm
   WHERE clm.idsucursal = ln_sucursal_piura
     AND clm.nro_libro  = ln_libro_depreciacion
     AND clm.ano        = ani_year
     AND clm.mes        = ani_mes FOR UPDATE;
  
  -- Pongo como fecha contable el ultimo dia del mes
  ld_fecha_cntbl :=  last_day(to_date('01/' || trim(to_char(ani_mes, '00')) || '/' || to_char(ani_year), 'dd/mm/yyyy'));
  
  for lc_reg in c_activos loop
      -- Genero un idasiento
      ls_nro_asiento := TRIM(to_char(ln_sucursal_piura, '000')) || TRIM(to_char(ln_libro_depreciacion, '00')) || 
                        TRIM(to_char(ani_year, '0000')) || TRIM(to_char(ani_mes, '00')) || 
                        trim(to_char(ln_nro_asiento, '000000'));

     -- Obtengo el TIPO CAMBIO
     ln_tipo_cambio := usf_tipo_cambio(ld_fecha_cntbl);

     -- Genero la cabecera del asiento
     ls_glosa := 'DEPRECIACION DEL ACTIVO ' || lc_reg.descripcion 
              || ', IDACTIVO: ' || to_char(lc_reg.idactivo) || ', MONTO ACTUAL: ' 
              || to_char(lc_reg.valor_mon_nac - lc_reg.total_depreciado, '999,990.00') ;
            
      INSERT INTO asiento(
             idasiento, idbanco, idsucursal, ano, mes, nro_libro, id_moneda, idplan_contable, 
             descripcion, flag_estado, fec_cntbl, tipo_cambio)
      VALUES(
             ls_nro_asiento, null, ln_sucursal_piura, ani_year, ani_mes, ln_libro_depreciacion, ln_soles, 
             ln_plan_contable, ls_glosa, '1', ld_fecha_cntbl, ln_tipo_cambio);
                      
     -- Genero el detalle del asiento
     DELETE asiento_det ad
      WHERE ad.idasiento = ls_nro_asiento;
            
     ln_item := 1;
     if lc_reg.monto_residual - lc_reg.total_depreciado > lc_reg.valor_depreciacion then
        ln_importe_sol := lc_reg.valor_depreciacion;
     else
        ln_importe_sol := lc_reg.monto_residual - lc_reg.total_depreciado;
     end if;
     
     if ln_importe_sol < 0 then
        RAISE_APPLICATION_ERROR(-20000, 'ERROR EL IMPORTE ESTA EN NEGATIVO');
     end if;
     
     ln_importe_dol := ln_importe_sol / ln_tipo_cambio;
            
     FOR lc_matriz IN c_matriz(lc_reg.matriz) LOOP
                
         INSERT INTO asiento_det(
                idasiento, item, idcuenta, det_glosa, flag_debhab, cod_ctabco, 
                importe_sol, importe_dol, nro_docref)
         VALUES(
                ls_nro_asiento, ln_item, lc_matriz.idcuenta, ls_glosa, lc_matriz.flag_debhab, null,
                ln_importe_sol, ln_importe_dol, null);
         ln_item := ln_item + 1;
     END LOOP;
            
     -- Actualizo los totales del debe y el haber en soles y dolares en la tabla asiento
     UPDATE asiento a
        SET a.total_debe_sol  = (SELECT NVL(SUM(ad.importe_sol),0) FROM asiento_det ad WHERE ad.idasiento = ls_nro_asiento AND ad.flag_debhab = 'D'),
            a.total_haber_sol = (SELECT NVL(SUM(ad.importe_sol),0) FROM asiento_det ad WHERE ad.idasiento = ls_nro_asiento AND ad.flag_debhab = 'H'),
            a.total_debe_dol  = (SELECT NVL(SUM(ad.importe_dol),0) FROM asiento_det ad WHERE ad.idasiento = ls_nro_asiento AND ad.flag_debhab = 'D'),
            a.total_haber_dol = (SELECT NVL(SUM(ad.importe_dol),0) FROM asiento_det ad WHERE ad.idasiento = ls_nro_asiento AND ad.flag_debhab = 'H')
      WHERE a.idasiento = ls_nro_asiento;
      
      -- Actualizo el contador en la tabla numeradora
      ln_nro_asiento := ln_nro_asiento + 1;

      -- registro en la tabla depreciaciones  
      insert into depreciacion(
             idactivo, ano, mes, idasiento, monto, fec_registro)
      values(
             lc_reg.idactivo, ani_year, ani_mes, ls_nro_asiento, ln_importe_sol, sysdate);
  end loop;
  
  -- Actualizo el numerador
  UPDATE cntbl_libro_mes clm
     SET clm.nro_asiento = ln_nro_asiento
   WHERE clm.idsucursal = ln_sucursal_piura
     AND clm.nro_libro  = ln_libro_depreciacion
     AND clm.ano        = ani_year
     AND clm.mes        = ani_mes;
  
  commit;
end usp_gen_asiento_depreciacion;
/
