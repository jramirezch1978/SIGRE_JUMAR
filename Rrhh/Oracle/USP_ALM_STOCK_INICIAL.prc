create or replace procedure USP_ALM_STOCK_INICIAL(
       ani_year in cntbl_asiento.ano%type,
       ani_mes  in cntbl_asiento.mes%type
) is

   -- Declaracion de variables
  ld_fecha_ini                 date ;
  ld_fecha_fin                 date ;
  ls_ano                       char(4) ;
  ln_count                     Number ;
  ls_ing_inicial               articulo_mov_tipo.tipo_mov%type ;
  ln_tipo_cambio               calendario.vta_dol_prom%type ;

CURSOR c_almacen is 
SELECT a.almacen 
  FROM almacen a 
 WHERE flag_tipo_almacen <>'O' 
ORDER BY flag_tipo_almacen, almacen ;

CURSOR c_inv_inicial( as_almacen    IN almacen.almacen%type, 
                      as_tipo_mov   IN articulo_mov_tipo.tipo_mov%type, 
                      as_ano        IN char ) IS 
SELECT vm.almacen, am.cod_art,  
       sum( decode( amt.factor_sldo_total, 1, am.cant_procesada, amt.factor_sldo_total * am.cant_procesada)) 
                    as cantidad, 
       sum( decode( amt.factor_sldo_total, 1, 
            decode( amt.flag_ajuste_valorizacion, '1', 1, am.cant_procesada) * am.precio_unit, 
            amt.factor_sldo_total * decode( amt.flag_ajuste_valorizacion, '1', 1, am.cant_procesada) * 
            am.precio_unit )) 
                    as tot_soles
  FROM vale_mov     vm,
       articulo_mov am, 
       articulo_mov_tipo amt
 WHERE (vm.cod_origen = am.cod_origen
   AND  vm.nro_vale   = am.nro_vale) 
   AND (vm.tipo_mov = amt.tipo_mov) 
   AND vm.almacen    = as_almacen
   AND vm.tipo_mov   = as_tipo_mov 
   AND to_char(vm.fec_registro,'yyyy') = as_ano 
   AND vm.flag_estado <> '0'
   AND am.flag_estado <> '0' 
GROUP BY vm.almacen, am.cod_art ;


CURSOR c_mov_anual_pasado( as_almacen    IN almacen.almacen%type, 
                           as_ano        IN char ) IS 
SELECT vm.almacen, am.cod_art,  
       sum( decode( amt.factor_sldo_total, 1, am.cant_procesada, amt.factor_sldo_total * am.cant_procesada)) 
                    as cantidad, 
       sum( decode( amt.factor_sldo_total, 1, 
            decode( amt.flag_ajuste_valorizacion, '1', 1, am.cant_procesada) * am.precio_unit, 
            amt.factor_sldo_total * decode( amt.flag_ajuste_valorizacion, '1', 1, am.cant_procesada) * 
            am.precio_unit )) 
                    as tot_soles
  FROM vale_mov     vm,
       articulo_mov am, 
       articulo_mov_tipo amt
 WHERE (vm.cod_origen = am.cod_origen
   AND  vm.nro_vale   = am.nro_vale) 
   AND (vm.tipo_mov   = amt.tipo_mov) 
   AND vm.almacen     = as_almacen
   AND to_char(vm.fec_registro,'yyyy') < as_ano 
   AND vm.flag_estado <> '0'
   AND am.flag_estado <> '0' 
GROUP BY vm.almacen, am.cod_art ;


BEGIN

-- Eliminando registros anteriores
DELETE FROM articulo_saldo_mensual asm
 WHERE asm.ano=ani_year
   AND asm.mes= ani_mes ;

If ani_mes<>0 then
   RAISE_APPLICATION_ERROR(-20000, 'Solo puede procesar el mes de apertura 0');
end if ;

SELECT trim(to_char(ani_year)) INTO ls_ano FROM dual ;

-- Fechas año actual (Para que?)
ld_fecha_ini := trunc(to_date( '01/01/'|| to_char(ani_year) ,'dd/mm/yyyy'));
ld_fecha_fin := trunc(to_date( '31/12/'|| to_char(ani_year) ,'dd/mm/yyyy'));

SELECT NVL(c.vta_dol_prom,0) INTO ln_tipo_cambio FROM calendario c WHERE TRUNC(c.fecha) = ld_fecha_ini ;

IF ln_tipo_cambio<=0 THEN
   RAISE_APPLICATION_ERROR(-20000, 'Tipo de cambio errado para '||to_char(ld_fecha_fin,'dd/mm/yyyy'));
END IF ;

/* Captura tipo de inventario inicial */
SELECT oper_inv_inicial
  INTO ls_ing_inicial
  FROM logparam
 WHERE reckey='1';

FOR c_a IN c_almacen loop
    SELECT count(*)
      INTO ln_count
      FROM vale_mov vm,
           almacen  a
     WHERE vm.almacen = a.almacen 
       AND vm.tipo_mov = ls_ing_inicial 
       AND vm.almacen = c_a.almacen 
       AND vm.flag_estado <> '0' 
       AND TO_CHAR(vm.fec_registro,'yyyy') = ls_ano ;
       
    IF ln_count>0 THEN
    -- Si tiene movimiento de apertura 
       FOR c_ini IN c_inv_inicial(c_a.almacen, ls_ing_inicial, ls_ano) LOOP
          -- Si stock es positivo          
          IF c_ini.cantidad > 0 THEN
            INSERT INTO articulo_saldo_mensual(
                   ano, mes, cod_art, sldo_total, 
                   compras_totales, consumos_totales, precio_prom_sol, 
                   precio_prom_dol, almacen, total_mes_ingr,                    
                   total_mes_egr, valor_saldo_total, valor_cons_total, 
                   valor_comp_total, valor_mes_ingr, valor_mes_egr, 
                   ingresos_prod_term, ventas_prod_term, valor_ingresos_pt, 
                   valor_venta_pt)
            VALUES (
                   ani_year, ani_mes, c_ini.cod_art, c_ini.cantidad, 
                   0, 0, (c_ini.tot_soles/c_ini.cantidad), 
                   (c_ini.tot_soles/c_ini.cantidad/ln_tipo_cambio), c_a.almacen, 0, 
                   0, c_ini.tot_soles, 0, 
                   0, 0, 0, 
                   0, 0, 0, 
                   0 ) ;
          ELSIF c_ini.cantidad < 0 THEN
            RAISE_APPLICATION_ERROR(-20000, 'Cantidad negativa en '||c_ini.almacen||', articulo '||c_ini.cod_art) ;
          END IF ;
       END LOOP ;
    
    ELSE
    -- Captura apertura de movimiento pasado
       FOR c_mov IN c_mov_anual_pasado(c_a.almacen, ls_ano) LOOP 
           IF c_mov.cantidad > 0 THEN 
              INSERT INTO articulo_saldo_mensual(
                     ano, mes, cod_art, sldo_total, 
                     compras_totales, consumos_totales, precio_prom_sol, 
                     precio_prom_dol, almacen, total_mes_ingr,                    
                     total_mes_egr, valor_saldo_total, valor_cons_total, 
                     valor_comp_total, valor_mes_ingr, valor_mes_egr, 
                     ingresos_prod_term, ventas_prod_term, valor_ingresos_pt, 
                     valor_venta_pt)
              VALUES (
                     ani_year, ani_mes, c_mov.cod_art, c_mov.cantidad, 
                     0, 0, (c_mov.tot_soles/c_mov.cantidad), 
                     (c_mov.tot_soles/c_mov.cantidad/ln_tipo_cambio), c_a.almacen, 0, 
                     0, c_mov.tot_soles, 0, 
                     0, 0, 0, 
                     0, 0, 0, 
                     0 ) ;
          ELSIF c_mov.cantidad < 0 THEN
              RAISE_APPLICATION_ERROR(-20000, 'Cantidad negativa en '||c_mov.almacen||', articulo '||c_mov.cod_art) ;
           END IF ; 
       END LOOP ;
       
    END IF ;

END LOOP ;

--commit ;

END USP_ALM_STOCK_INICIAL;
/
