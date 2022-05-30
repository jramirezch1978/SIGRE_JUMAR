CREATE OR REPLACE PROCEDURE usp_alm_act_valor_x_art(
       asi_cod_art          in  articulo.cod_art%TYPE,
       aso_mensaje          out string,
       aio_ok               out integer
) is

-- Precios Promedios
ln_saldo                 articulo.sldo_total%TYPE;
ln_tipo_cambio           logparam.ult_tipo_cam%TYPE;
ano_costo_prom_sol       articulo.costo_prom_sol%TYPE;
ano_costo_prom_dol       articulo.costo_prom_dol%TYPE;
ln_precio_unit           articulo_mov.precio_unit%TYPE;
ln_nro_mov               articulo_mov.nro_mov%TYPE;
ls_cod_origen            articulo_mov.cod_origen%TYPE;
ln_Cant_proc             articulo_mov.cant_procesada%TYPE;
ls_oper_ing_oc           logparam.oper_ing_oc%TYPE;

--  Lectura del movimiento de ingresos y salidas
CURSOR c_movimiento is
  SELECT vm.tipo_mov,
         vm.almacen,
         NVL(am.cant_procesada,0) as cant_procesada,
         NVL(am.precio_unit,0) as precio_unit,
         NVL(am.decuento,0) as descuento,
         NVL(am.impuesto,0) as impuesto,
         am.cod_moneda,
         NVL(amt.flag_ajuste_valorizacion, '0') as flag_ajuste_valorizacion,
         amt.factor_sldo_total,
         am.cod_origen,
         am.nro_mov,
         vm.fec_registro
    FROM vale_mov          vm,
         articulo_mov      am,
         almacen           a,
         articulo_mov_tipo amt
   WHERE vm.cod_origen = am.cod_origen
     and vm.nro_vale   = am.nro_vale
     and vm.almacen    = a.almacen
     and vm.flag_estado <> '0'
     and vm.tipo_mov    = amt.tipo_mov
     and am.cod_art     = asi_cod_art
     AND am.flag_estado <> '0'
     and amt.factor_sldo_total <> 0
     and am.cod_moneda = (select cod_soles from logparam where reckey = '1')
  ORDER BY vm.fec_registro, vm.nro_vale ;

BEGIN

-- Parametros de Logistica
SELECT ult_tipo_cam, oper_ing_oc
  INTO ln_tipo_cambio, ls_oper_ing_oc
FROM logparam
WHERE reckey='1' ;

ln_saldo            := 0;
ano_costo_prom_sol  := 0;
ano_costo_prom_sol  := 0;
ln_cant_proc        := 0;

FOR lc_reg IN c_movimiento LOOP
    ls_cod_origen := lc_reg.cod_origen;
    ln_nro_mov    := lc_reg.nro_mov;
    ln_Cant_proc  := lc_reg.cant_procesada;

    IF lc_reg.factor_sldo_total = 1 and lc_reg.flag_ajuste_valorizacion = '0' THEN
       -- Ingresos
       if ln_saldo + lc_reg.cant_procesada <> 0 then
          /*if lc_reg.precio_unit <> 0 then
             ln_precio_unit := lc_reg.precio_unit;
          else
             ln_precio_unit := ano_costo_prom_sol;
          end if;*/
          
          ln_precio_unit := lc_reg.precio_unit;
          
          if ln_saldo + lc_reg.cant_procesada <> 0 then
             ano_costo_prom_sol := round((abs(ln_saldo) * ano_costo_prom_sol + ln_precio_unit * lc_reg.cant_procesada) /
                                (abs(ln_saldo) + lc_reg.cant_procesada),6);
          end if;

       end if;

       ln_saldo:= ln_saldo + lc_reg.cant_procesada;

    ELSIF lc_reg.flag_ajuste_valorizacion = '1' THEN
       if ln_saldo <> 0 then
           ano_costo_prom_sol := Round((ano_costo_prom_sol*abs(ln_saldo)
                              + NVL(lc_reg.precio_unit,0) * lc_reg.factor_sldo_total)/abs(ln_Saldo),6);
       end if;
    ELSIF lc_reg.factor_sldo_total = -1 and lc_reg.flag_ajuste_valorizacion = '0' then
       -- Salidas
       ln_saldo := ln_saldo - lc_reg.cant_procesada;

    END IF ;
END LOOP ;

if ln_tipo_cambio <> 0 then
   ano_costo_prom_dol := ROUND(ano_costo_prom_sol / ln_tipo_cambio,6);
else
   ano_costo_prom_dol := 0;
end if;

update articulo a
   set a.costo_prom_sol = round(ano_costo_prom_sol,6),
       a.costo_prom_dol = round(ano_costo_prom_dol,6),
       a.flag_replicacion = '1'
where cod_art = asi_cod_art;

insert into tt_edg1(cod_art)
values (asi_cod_art);

COMMIT ;

EXCEPTION
  WHEN OTHERS THEN
      aso_mensaje := 'ORACLE: NO SE HA CALCULAR EL PRECIO PROMEDIO '
                  || chr(13) || 'SQLCODE: ' || to_char(SQLCODE)
                  || chr(13) || 'SQLERRM: ' || SQLERRM
                  || chr(13) || 'Cod_Articulo: ' || asi_Cod_Art
                  || chr(13) || 'Nro_mov     : ' || to_char(ln_nro_mov)
                  || chr(13) || 'Cod Origen  : ' || ls_cod_origen
                  || chr(13) || 'Precio Promedio : ' || to_char(ano_costo_prom_sol)
                  || chr(13) || 'ln_Saldo        : ' || to_char(ln_saldo)
                  || chr(13) || 'ln_precio       : ' || to_char(ln_precio_unit)
                  || chr(13) || 'CAnt Proce      : ' || to_char(ln_Cant_proc);
      aio_ok := 0;
      RAISE_APPLICATION_ERROR(-20000, aso_mensaje);
      rollback;

END usp_alm_act_valor_x_art;
/
