create or replace procedure usp_alm_act_saldo_pres_dev is

  ls_saldo        articulo_almacen.sldo_consignacion%TYPE;

  cursor c_mov_dev is
       select cod_art, almacen, 
              sum(NVL(adp.cant_salida,0) - NVL(adp.cant_ingreso,0)) as saldo
        from art_devol_prestamo adp,
             articulo_mov_tipo  amt
        where amt.tipo_mov = adp.tipo_mov
          and amt.factor_sldo_dev = 1
          and adp.flag_estado = '1'   
          and NVL(adp.cant_salida,0) > NVL(adp.cant_ingreso,0)
        group by cod_art, almacen;

  cursor c_mov_pres is
       select cod_art, almacen, 
              sum(NVL(adp.cant_salida,0) - NVL(adp.cant_ingreso,0)) as saldo
        from art_devol_prestamo adp,
             articulo_mov_tipo  amt
        where amt.tipo_mov = adp.tipo_mov
          and amt.factor_sldo_pres = 1
          and adp.flag_estado = '1'   
          and NVL(adp.cant_salida,0) > NVL(adp.cant_ingreso,0)
        group by cod_art, almacen;        
begin
   delete tt_edg1;
   commit;
   
   -- Actualizo Prestamos
   update art_devol_prestamo a
      set a.cant_ingreso = (select NVL(sum(adp.cant_ingreso),0)
                                    from art_devol_prestamo     adp,
                                         art_devol_prest_enlace b
                                   where b.nro_mov_ing = adp.nro_mov
                                     and adp.flag_estado = '1'  -- Solo los activos
                                     and b.nro_mov_sal = a.nro_mov)
    where a.tipo_mov in (select tipo_mov 
                          from articulo_mov_tipo amt 
                         where amt.factor_sldo_pres = 1) -- Solo las Salidas
      and a.flag_estado = '1';

   commit;
   
   -- Actualizo devoluciones
   update art_devol_prestamo a
      set a.cant_ingreso = (select NVL(sum(adp.cant_ingreso),0)
                                    from art_devol_prestamo     adp,
                                         art_devol_prest_enlace b
                                   where b.nro_mov_ing = adp.nro_mov
                                     and adp.flag_estado = '1'  -- Solo los activos
                                     and b.nro_mov_sal = a.nro_mov)
    where a.tipo_mov in (select tipo_mov 
                          from articulo_mov_tipo amt 
                         where amt.factor_sldo_dev = 1) -- Solo los salidas
      and a.flag_estado = '1';

   commit;
   
   -- Actualizo saldos de devoluciones en Almacen
   for lc_reg in c_mov_dev loop
       update articulo_almacen aa
          set aa.sldo_devuelto = lc_reg.saldo
        where aa.cod_art = lc_reg.cod_art
          and aa.almacen = lc_reg.almacen;
       
       if SQL%NOTFOUND then
          insert into articulo_almacen(
                 cod_art, almacen, sldo_devuelto)
          values(
                 lc_reg.cod_art, lc_reg.almacen, lc_reg.saldo);
       end if;
       
  /*     insert into tt_edg1(cod_art)
       values(lc_reg.cod_art);
       
       commit;   */
   end loop;
   
   -- Actualizo saldos de prestamos en Almacen
   for lc_reg in c_mov_pres loop
       update articulo_almacen aa
          set aa.sldo_prestamo = lc_reg.saldo
        where aa.cod_art = lc_reg.cod_art
          and aa.almacen = lc_reg.almacen;
       
       if SQL%NOTFOUND then
          insert into articulo_almacen(
                 cod_art, almacen, sldo_prestamo)
          values(
                 lc_reg.cod_art, lc_reg.almacen, lc_reg.saldo);
       end if;
       
/*       insert into tt_edg1(cod_art)
       values(lc_reg.cod_art);
       
       commit;   */
   end loop;
   
   update articulo a
      set a.sldo_devuelto = 0,
          a.sldo_prestamo = 0;
   
   commit;
   
   update articulo a
      set a.sldo_devuelto = (select sum(sldo_devuelto) 
                               from articulo_almacen 
                              where cod_art = a.cod_art),
          a.sldo_prestamo = (select sum(sldo_prestamo) 
                               from articulo_almacen 
                              where cod_art = a.cod_art)
    where a.cod_art in (select distinct cod_art 
                          from art_devol_prestamo
                         where flag_estado = '1');
   commit;
end usp_alm_act_saldo_pres_dev;
/
