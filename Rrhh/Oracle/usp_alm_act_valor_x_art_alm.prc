CREATE OR REPLACE PROCEDURE usp_alm_act_valor_x_art_alm(
       asi_cod_art          in  articulo.cod_art%TYPE,
       adi_fecha            in  date,
       aso_mensaje          out string,
       aio_ok               out integer
) is

-- Hay un Procedimiento similar que se llama usp_alm_valor_x_art_alm, tener cuidado

-- Precios Promedios
ln_saldo                 articulo.sldo_total%TYPE;
ln_tipo_cambio           logparam.ult_tipo_cam%TYPE;
ls_almacen               almacen.almacen%TYPE;
ln_costo_prom_sol        articulo.costo_prom_sol%TYPE;
ln_costo_prom_dol        articulo.costo_prom_dol%TYPE;
ln_precio_unit           articulo_mov.precio_unit%TYPE;
ln_nro_mov               articulo_mov.nro_mov%TYPE;
ls_cod_origen            articulo_mov.cod_origen%TYPE;
ln_Cant_proc             articulo_mov.cant_procesada%TYPE;
ls_tipo_mov              articulo_mov_tipo.tipo_mov%TYPE;
ls_flag_cntrl            presupuesto_partida.flag_ctrl%TYPE;
ln_count                 number;

ls_oper_ing_oc           logparam.oper_ing_oc%TYPE;
ls_oper_ing_cdir         logparam.oper_ing_cdir%TYPE;

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
         NVL(amt.factor_sldo_total,0) as factor_sldo_total,
         NVL(amt.flag_solicita_precio, '0') as flag_solicita_precio,
         am.cod_origen,
         am.nro_mov,
         vm.fec_registro,
         am.cencos,
         am.cnta_prsp,
         to_number(to_char(vm.fec_registro, 'yyyy')) as ano,
         NVL(amt.factor_presup, 0) as factor_presup
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
     and vm.almacen     = ls_almacen
     AND am.flag_estado <> '0'
     and amt.factor_sldo_total <> 0
     and am.cod_moneda = (select cod_soles from logparam where reckey = '1')
  ORDER BY vm.fec_registro, vm.tipo_mov ;

 Cursor c_almacenes is
 select distinct vm.almacen
   from articulo_mov am,
        vale_mov     vm
  where am.nro_vale   = vm.nro_vale
    and am.cod_origen = vm.cod_origen
    and am.flag_estado <> '0'
    and vm.flag_estado <> '0'
    and am.cod_art = asi_cod_art;

BEGIN

-- Parametros de Logistica
SELECT ult_tipo_cam, oper_ing_oc
  INTO ln_tipo_cambio, ls_oper_ing_oc
FROM logparam
WHERE reckey='1' ;

for lc_alm in c_almacenes loop
    ln_saldo           := 0;
    ln_costo_prom_sol  := 0;
    ln_costo_prom_sol  := 0;
    ln_cant_proc       := 0;
    ls_almacen         := lc_alm.almacen;

    FOR lc_reg IN c_movimiento LOOP
        ls_cod_origen := lc_reg.cod_origen;
        ln_nro_mov    := lc_reg.nro_mov;
        ln_Cant_proc  := lc_reg.cant_procesada;
        ls_tipo_mov   := lc_reg.tipo_mov;

        IF lc_reg.factor_sldo_total = 1 and lc_reg.flag_ajuste_valorizacion = '0' THEN

           IF lc_reg.tipo_mov <> ls_oper_ing_oc              and
              lc_reg.tipo_mov <> ls_oper_ing_cdir            and
              lc_reg.flag_solicita_precio = '0'              and
              trunc(lc_reg.fec_registro) >= trunc(adi_fecha) and
              lc_reg.precio_unit = 0                         then

              -- Antes de actualizar debo verificar si afecta presupuesto
              -- para desactivar su flag de control y pueda hacerse el cambio sin
              -- problemas
              ls_flag_cntrl := null;
              
              if lc_reg.factor_presup <> 0 and lc_reg.cencos is not null and
                 lc_reg.cnta_prsp is not null then
                 -- Obtengo el flag_ctrl de presupuesto partida
                 select count(*)
                   into ln_count
                   from presupuesto_partida
                  where ano      = lc_reg.ano
                    and cencos    = lc_reg.cencos
                    and cnta_prsp = lc_reg.cnta_prsp;
                 
                 if ln_count > 0 then
                     select NVL(flag_ctrl, '0')
                       into ls_flag_cntrl
                       from presupuesto_partida
                      where ano      = lc_reg.ano
                        and cencos    = lc_reg.cencos
                        and cnta_prsp = lc_reg.cnta_prsp for update;
                 else
                     ls_flag_cntrl := '1';
                     insert into presupuesto_partida(
                            ano, cencos, cnta_prsp, comentario, flag_ctrl, flag_estado )
                     values(
                            lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp, 
                            'PRESUPUESTO PARTIDA GENERADA AUTOMATICAMENTE X AJUSTE DE INVENTARIO',
                            '0', '2');
                 end if;

                 update presupuesto_partida 
                   set flag_ctrl = '0'
                  where ano      = lc_reg.ano
                    and cencos    = lc_reg.cencos
                    and cnta_prsp = lc_reg.cnta_prsp;
                    
              end if;
              
              -- Actualizando registro, si fuera necesario
              UPDATE articulo_mov a
                 SET a.precio_unit = ln_costo_prom_sol
               WHERE a.cod_origen = lc_reg.cod_origen
                 AND a.nro_mov    = lc_reg.nro_mov ;

              -- Despues de actualizar el precio vuelvo a colocar el flag_ctrl 
              -- como era antes
              if lc_reg.factor_presup <> 0 and lc_reg.cencos is not null and
                 lc_reg.cnta_prsp is not null and ls_flag_cntrl is not null then
                 
                 update presupuesto_partida 
                   set flag_ctrl = ls_flag_cntrl
                  where ano      = lc_reg.ano
                    and cencos    = lc_reg.cencos
                    and cnta_prsp = lc_reg.cnta_prsp;
                    
              end if;
                 
              commit;

           END IF ;

           if ln_saldo + lc_reg.cant_procesada <> 0 THEN
           
              ln_precio_unit := lc_reg.precio_unit;
              
              if ln_saldo + lc_reg.cant_procesada <> 0 then
                 ln_costo_prom_sol := round((abs(ln_saldo) * ln_costo_prom_sol
                   + ln_precio_unit * lc_reg.cant_procesada) /(abs(ln_saldo) + lc_reg.cant_procesada),6);
              end if;

           end if;

           ln_saldo:= ln_saldo + lc_reg.cant_procesada;

        ELSIF lc_reg.flag_ajuste_valorizacion = '1' THEN
           if ln_saldo > 0 then
               ln_costo_prom_sol := Round((ln_costo_prom_sol*abs(ln_saldo)
                      + NVL(lc_reg.precio_unit,0) * lc_reg.factor_sldo_total)/abs(ln_Saldo),6);
           end if;
           
        ELSIF lc_reg.factor_sldo_total = -1 and lc_reg.flag_ajuste_valorizacion = '0' then
           -- Salidas
           ln_saldo := ln_saldo - lc_reg.cant_procesada;

           if trunc(lc_reg.fec_registro) >= trunc(adi_fecha) then
              
              -- Antes de actualizar debo verificar si afecta presupuesto
              -- para desactivar su flag de control y pueda hacerse el cambio sin
              -- problemas
              ls_flag_cntrl := null;
              
              if lc_reg.factor_presup <> 0 and lc_reg.cencos is not null and
                 lc_reg.cnta_prsp is not null then
                 -- Obtengo el flag_ctrl de presupuesto partida
                 select count(*)
                   into ln_count
                   from presupuesto_partida
                  where ano      = lc_reg.ano
                    and cencos    = lc_reg.cencos
                    and cnta_prsp = lc_reg.cnta_prsp;
                 
                 if ln_count > 0 then
                     select NVL(flag_ctrl, '0')
                       into ls_flag_cntrl
                       from presupuesto_partida
                      where ano      = lc_reg.ano
                        and cencos    = lc_reg.cencos
                        and cnta_prsp = lc_reg.cnta_prsp for update;
                 else
                     ls_flag_cntrl := '1';
                     insert into presupuesto_partida(
                            ano, cencos, cnta_prsp, comentario, flag_ctrl, flag_estado )
                     values(
                            lc_reg.ano, lc_reg.cencos, lc_reg.cnta_prsp, 
                            'PRESUPUESTO PARTIDA GENERADA AUTOMATICAMENTE X AJUSTE DE INVENTARIO',
                            '0', '2');
                 end if;

                 update presupuesto_partida 
                   set flag_ctrl = '0'
                  where ano      = lc_reg.ano
                    and cencos    = lc_reg.cencos
                    and cnta_prsp = lc_reg.cnta_prsp;
                    
              end if;

              -- Actualizando registro, si fuera necesario
              IF lc_reg.precio_unit <> ln_costo_prom_sol THEN
                 UPDATE articulo_mov a
                    SET a.precio_unit = ln_costo_prom_sol
                  WHERE a.cod_origen  = lc_reg.cod_origen
                    AND a.nro_mov     = lc_reg.nro_mov ;
              END IF;
                 
              -- Despues de actualizar el precio vuelvo a colocar el flag_ctrl 
              -- como era antes
              if lc_reg.factor_presup <> 0 and lc_reg.cencos is not null and
                 lc_reg.cnta_prsp is not null and ls_flag_cntrl is not null then
                 
                 update presupuesto_partida 
                   set flag_ctrl = ls_flag_cntrl
                  where ano      = lc_reg.ano
                    and cencos    = lc_reg.cencos
                    and cnta_prsp = lc_reg.cnta_prsp;
                    
              end if;

              commit;

           END IF ;

        END IF ;
    END LOOP ;

    if ln_tipo_cambio <> 0 then
       ln_costo_prom_dol := ROUND(ln_costo_prom_sol / ln_tipo_cambio,6);
    else
       ln_costo_prom_dol := 0;
    end if;

    update articulo_almacen a
       set a.costo_prom_sol = ln_costo_prom_sol,
           a.costo_prom_dol = ln_costo_prom_dol,
           a.flag_replicacion = '1'
    where cod_art = asi_cod_art
      and almacen = ls_almacen;
end loop;

/*insert into tt_edg1(cod_art)
values (asi_cod_art);

COMMIT ;*/

EXCEPTION
  WHEN OTHERS THEN
      aso_mensaje := 'ORACLE: NO SE HA CALCULAR EL PRECIO PROMEDIO '
                  || chr(13) || 'SQLCODE: ' || to_char(SQLCODE)
                  || chr(13) || 'SQLERRM: ' || SQLERRM
                  || chr(13) || 'Cod_Articulo: ' || asi_Cod_Art
                  || chr(13) || 'Nro_mov     : ' || to_char(ln_nro_mov)
                  || chr(13) || 'Cod Origen  : ' || ls_cod_origen
                  || chr(13) || 'Precio Promedio : ' || to_char(ln_costo_prom_sol)
                  || chr(13) || 'ln_Saldo        : ' || to_char(ln_saldo)
                  || chr(13) || 'ln_precio       : ' || to_char(ln_precio_unit)
                  || chr(13) || 'CAnt Proce      : ' || to_char(ln_Cant_proc);
      aio_ok := 0;
      RAISE_APPLICATION_ERROR(-20000, aso_mensaje);
      rollback;

END usp_alm_act_valor_x_art_alm;
/
