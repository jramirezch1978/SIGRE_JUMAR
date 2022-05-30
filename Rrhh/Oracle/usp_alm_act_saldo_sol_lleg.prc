CREATE OR REPLACE PROCEDURE usp_alm_act_saldo_sol_lleg(
       asi_nada             in string,
       aso_mensaje          out string,
       aio_ok               out integer
) is

-- Precios Promedios
ln_sldo_sol            articulo_almacen.sldo_solicitado%TYPE;
ln_sldo_llegar         articulo_almacen.sldo_por_llegar%TYPE;

--  Lectura del movimiento de ingresos y salidas
CURSOR c_saldos is
    select cod_art, almacen,
           sum((amp.cant_proyect - amp.cant_procesada) * amt.factor_sldo_x_llegar * -1) as saldo_llegar,
           sum((amp.cant_proyect - amp.cant_procesada) * amt.factor_sldo_sol * -1) as saldo_solicitado
    from articulo_mov_proy   amp,
         articulo_mov_tipo   amt
    where amt.tipo_mov = amp.tipo_mov
      and amp.flag_estado = '1'
      and amp.cant_proyect > amp.cant_procesada
      and ( amt.factor_sldo_x_llegar <> 0 or amt.factor_sldo_sol <> 0)
    group by cod_art, almacen;

BEGIN
  update articulo a
    set a.sldo_solicitado = (select sum(sldo_solicitado)
                         from articulo_almacen
                        where cod_art = a.cod_art),
        a.sldo_por_llegar = (select sum(sldo_por_llegar)
                         from articulo_almacen
                        where cod_art = a.cod_art)
  where cod_art in (select distinct cod_art from articulo_almacen);

update articulo_almacen aa
   set aa.sldo_solicitado = 0,
       aa.sldo_por_llegar = 0;


  FOR lc_reg IN c_saldos LOOP
      if lc_reg.saldo_solicitado < 0 then
         ln_sldo_sol := 0;
      else
          ln_sldo_sol := lc_reg.saldo_solicitado;
      end if;

      if lc_reg.saldo_llegar < 0 then
         ln_sldo_llegar := 0;
      else
         ln_sldo_llegar := lc_reg.saldo_llegar;
      end if;

      update articulo_almacen a
         set a.sldo_por_llegar = ln_sldo_llegar,
             a.sldo_solicitado = ln_sldo_sol
       where almacen = lc_reg.almacen
         and cod_art = lc_reg.cod_art;

      IF SQL%NOTFOUND then
         insert into articulo_almacen(
                cod_art, almacen, sldo_por_llegar, sldo_solicitado)
         values(
                lc_reg.cod_art, lc_reg.almacen, ln_sldo_llegar, ln_sldo_sol);
      end if;

 /*     insert into tt_edg1(cod_art)
      values(lc_reg.cod_art);

      commit;*/


  END LOOP ;

  update articulo a
    set a.sldo_solicitado = (select sum(sldo_solicitado)
                         from articulo_almacen
                        where cod_art = a.cod_art),
        a.sldo_por_llegar = (select sum(sldo_por_llegar)
                         from articulo_almacen
                        where cod_art = a.cod_art)
  where cod_art in (select distinct cod_art from articulo_almacen);


  COMMIT ;

END usp_alm_act_saldo_sol_lleg;
/
