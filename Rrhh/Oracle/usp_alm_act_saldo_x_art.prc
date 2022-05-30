CREATE OR REPLACE PROCEDURE usp_alm_act_saldo_x_art(
       asi_cod_art          in  articulo.cod_art%TYPE,
       aso_mensaje          out string,
       aio_ok               out integer
) is

-- Precios Promedios
ln_saldo                 articulo_almacen.sldo_total%TYPE;
ln_saldo_und2            articulo_almacen.sldo_total_und2%TYPE;
ln_sldo_total            articulo.sldo_total%TYPE;
ln_sldo_total_und2       articulo.sldo_total%TYPE;
ls_almacen               almacen.almacen%TYPE;
ls_actualizado           char(1);

--  Lectura del movimiento de ingresos y salidas
CURSOR c_saldos is
  SELECT am.cod_art, vm.almacen,
         SUM(NVL(am.cant_procesada,0) * amt.factor_sldo_total) as Saldo_total,
         SUM(NVL(am.cant_proc_und2,0) * amt.factor_sldo_total) as saldo_total_und2
    FROM vale_mov          vm,
         articulo_mov      am,
         articulo_mov_tipo amt
   WHERE vm.cod_origen = am.cod_origen
     and vm.nro_vale   = am.nro_vale
     and vm.tipo_mov    = amt.tipo_mov
     and vm.flag_estado <> '0'
     AND am.flag_estado <> '0'
     and amt.factor_sldo_total <> 0
     and NVL(amt.flag_ajuste_valorizacion,'0') = '0'
     and am.cod_art = asi_cod_art
group by am.cod_art, vm.almacen;

BEGIN

  ln_sldo_total := 0;
  ln_sldo_total_und2 := 0;

  update articulo
    set sldo_Total     = (select sum(sldo_total) from articulo_almacen where cod_art = asi_cod_art),
        sldo_total_und2 = (select sum(sldo_total_und2) from articulo_almacen where cod_art = asi_cod_art),
        flag_replicacion = '0'
  where cod_art = asi_cod_art;

  commit;

  FOR lc_reg IN c_saldos LOOP
      if lc_reg.saldo_total < 0 then
         ln_saldo := 0;
      else
         ln_saldo := lc_reg.saldo_total;
      end if;
      if lc_reg.saldo_total_und2 < 0 then
         ln_saldo_und2 := 0;
      else
         ln_saldo_und2 := lc_reg.saldo_total_und2;
      end if;

      ln_sldo_total      := ln_sldo_total + ln_saldo;
      ln_sldo_total_und2 := ln_sldo_total_und2 + ln_saldo_und2;

      update articulo_almacen a
         set a.sldo_total      = ln_saldo,
             a.sldo_total_und2 = ln_saldo_und2
       where almacen = lc_reg.almacen
         and cod_art = lc_reg.cod_art;

      IF SQL%NOTFOUND then
         insert into articulo_almacen(
                cod_art, almacen, sldo_total, sldo_total_und2)
         values(
                lc_reg.cod_art, lc_reg.almacen, ln_saldo, ln_saldo_und2);
      end if;

      commit;

  END LOOP ;

  if ln_sldo_total is null then ln_sldo_total := 0; end if;

  if ln_sldo_total_und2 is null then ln_sldo_total_und2 := 0; end if;

  update articulo
    set sldo_Total = ln_sldo_total,
        sldo_total_und2 = ln_sldo_total_und2
  where cod_art = asi_cod_art;

  insert into tt_edg1(cod_art)
  values(asi_cod_art);

  COMMIT ;

EXCEPTION
  WHEN OTHERS THEN
      aso_mensaje := 'ORACLE: NO SE HA PODIDO REGENERAR EL SALDO X ARTICULO '
                  || chr(13) || 'SQLCODE: ' || to_char(SQLCODE)
                  || chr(13) || 'SQLERRM: ' || SQLERRM;
      aio_ok := 0;
      rollback;

END usp_alm_act_saldo_x_art;
/
