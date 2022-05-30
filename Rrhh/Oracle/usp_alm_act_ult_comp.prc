create or replace procedure usp_alm_act_ult_comp(
       asi_nada             in  string,
       aso_mensaje          out string,
       aio_ok               out integer
) is

  /*
     Procedimiento que Actualiza el precio de ultima compra a los
     articulos, en Dolares
  */

  -- Cursor con todos los movimientos de articulos que tienen OC
  cursor c_Articulos_oc is
    select aa.cod_Art
    from articulo  aa,
         articulo_mov_proy amp,
         orden_compra      oc
    where aa.cod_art = amp.cod_art
      and amp.nro_doc = oc.nro_oc
      and amp.tipo_doc = (select doc_oc from logparam where reckey = '1')
      and amp.flag_estado <> '0'
      and oc.flag_estado <> '0';

  -- Cursor con todos los articulos x almacen que tienen Compra Directa, sin OC
  cursor c_Articulos_cdir is
    select cod_art
      from articulo_mov am,
           vale_mov     vm
     where vm.cod_origen = am.cod_origen
       and vm.nro_vale   = am.nro_vale
       and vm.tipo_mov   = (select oper_ing_cdir from logparam where reckey = '1')
       and vm.flag_estado <> '0'
       and am.flag_estado <> '0'
       and am.precio_unit <> 0
    minus
    select aa.cod_Art
    from articulo_almacen  aa,
         articulo_mov_proy amp,
         orden_compra      oc
    where aa.cod_art = amp.cod_art
      and amp.almacen = aa.almacen
      and amp.nro_doc = oc.nro_oc
      and amp.tipo_doc = (select doc_oc from logparam where reckey = '1')
      and amp.flag_estado <> '0'
      and oc.flag_estado <> '0';

  ln_costo_ult_comp           articulo.costo_ult_compra%TYPE;
  ls_cod_moneda               moneda.cod_moneda%TYPE;
  ld_fec_ult_comp             date;
  ln_tipo_cambio              logparam.ult_tipo_cam%TYPE;
  ln_count                    number;
  ls_soles                    logparam.cod_soles%TYPE;
  ls_doc_oc                   logparam.doc_oc%TYPE;
  ls_oper_ing_cdir            logparam.oper_ing_cdir%TYPE;
  ls_nro_oc                   orden_Compra.Nro_Oc%TYPE;
  ls_org_oc                   origen.cod_origen%TYPE;

begin

     delete tt_edg1;
     commit;

     select cod_soles, doc_oc, oper_ing_cdir
       into ls_soles, ls_doc_oc, ls_oper_ing_cdir
       from logparam
      where reckey = '1';

     for lc_reg in c_articulos_oc loop
         -- Obtengo los datos necesarios de ls Orden de compra

         select precio, fec_registro, cod_moneda, nro_doc, cod_origen
           into ln_costo_ult_comp, ld_fec_ult_comp, ls_cod_moneda, ls_nro_oc, ls_org_oc
           from (select (amp.precio_unit - NVL(amp.decuento,0)) as precio,
                         oc.fec_registro, amp.cod_moneda, amp.nro_doc, amp.cod_origen
                   from articulo_mov_proy amp,
                        orden_compra      oc
                  where oc.nro_oc        = amp.nro_doc
                    and oc.cod_origen   = amp.cod_origen
                    and amp.tipo_doc     = ls_doc_oc
                    and amp.cod_art      = lc_reg.cod_art
                    and amp.flag_estado  <> '0'
                    and oc.flag_estado   <> '0'
               order by oc.fec_registro desc)
         where rownum = 1;

         if ls_cod_moneda = ls_soles then
            select count(*)
              into ln_count
              from calendario c
             where trunc(c.fecha) = trunc(ld_fec_ult_comp);

            if ln_count > 0 then
               select c.cmp_dol_prom
                 into ln_tipo_cambio
                 from calendario c
                 where trunc(c.fecha) = trunc(ld_fec_ult_comp);

            else
               select l.ult_tipo_cam
                 into ln_tipo_cambio
                 from logparam l
                where reckey = '1';
            end if;

            if ln_tipo_cambio = 0 or ln_tipo_cambio is null then
               RAISE_APPLICATION_ERROR(-20000, 'El ultimo tipo de cambio no puede ser cero ni nulo');
            end if;

            ln_costo_ult_comp := round(ln_costo_ult_comp / ln_tipo_cambio,4);

         end if;

         update articulo a
            set a.costo_ult_compra = ln_costo_ult_comp,
                a.fec_ult_compra   = ld_fec_ult_comp,
                a.nro_ultima_oc    = ls_nro_oc,
                a.cod_origen       = ls_org_oc,
                a.flag_replicacion = '1'
          where a.cod_art = lc_reg.cod_art;

         commit;

 /*        -- Inserto en tabla temporal para saber como va avanzando el procedimiento
         insert into tt_edg1(cod_art)
         values(lc_reg.cod_art);*/

         commit;

     end loop;

     -- Borro nuevamente la tabla temporal para comenzar con el segundo procedimiento
     delete tt_edg1;
     commit;

     -- Ahora procedo a barrer todos aquellos articulos que tienen Ingreso Directo
     -- Sin Orden de Compra
     for lc_reg2 in c_articulos_cdir loop
         -- En caso que no tenga OC, entonces lo obtengo a partir del ultimo
         -- movimiento de Almacen que tenga compra Directa

         select count(*)
            into ln_count
            from articulo_mov am,
                 vale_mov     vm
           where vm.cod_origen  = am.cod_origen
             and vm.nro_vale    = am.nro_vale
             and am.cod_art     = lc_reg2.cod_art
             and vm.tipo_mov    = ls_oper_ing_cdir
             and am.flag_estado <> '0'
             and vm.flag_estado <> '0'
             and am.precio_unit <> 0;

         if ln_count > 0 then
            select precio, fec_registro, cod_moneda
               into ln_costo_ult_comp, ld_fec_ult_comp, ls_cod_moneda
               from (select (NVL(am.precio_unit,0) - NVL(am.precio_unit,0) * NVL(am.decuento,0)/100) as precio,
                            vm.fec_registro, am.cod_moneda
                       from articulo_mov am,
                            vale_mov     vm
                      where vm.cod_origen  = am.cod_origen
                        and vm.nro_vale    = am.nro_vale
                        and am.cod_art     = lc_reg2.cod_art
                        and vm.tipo_mov    = ls_oper_ing_cdir
                        and am.flag_estado <> '0'
                        and vm.flag_estado <> '0'
                        and am.precio_unit <> 0
                   order by vm.fec_registro desc)
            where rownum = 1;

            if ls_cod_moneda = ls_soles then
               select count(*)
                 into ln_count
                 from calendario c
                where trunc(c.fecha) = trunc(ld_fec_ult_comp);

               if ln_count > 0 then
                  select c.cmp_dol_prom
                    into ln_tipo_cambio
                    from calendario c
                   where trunc(c.fecha) = trunc(ld_fec_ult_comp);
               else
                  select l.ult_tipo_cam
                    into ln_tipo_cambio
                    from logparam l
                   where reckey = '1';
               end if;

               if ln_tipo_cambio = 0 or ln_tipo_cambio is null then
                  RAISE_APPLICATION_ERROR(-20000, 'El ultimo tipo de cambio no puede ser cero ni nulo');
               end if;

               ln_costo_ult_comp := round(ln_costo_ult_comp / ln_tipo_cambio,4);
               ls_nro_oc         := null;
               ls_org_oc         := null;
            end if;
         else
            -- En caso contario no tiene ultimo precio de compra
            ln_costo_ult_comp := 0;
            ld_fec_ult_comp   := null;
            ls_nro_oc         := null;
            ls_org_oc         := null;
         end if;

         update articulo a
            set a.costo_ult_compra = ln_costo_ult_comp,
                a.fec_ult_compra   = ld_fec_ult_comp,
                a.nro_ultima_oc    = ls_nro_oc,
                a.cod_origen       = ls_org_oc,
                a.flag_replicacion = '1'
          where a.cod_art = lc_reg2.cod_art;

         commit;

/*         -- Inserto en tabla temporal para saber como va avanzando el procedimiento
         insert into tt_edg1(cod_art)
         values(lc_reg2.cod_art);
*/
         commit;

     end loop;

end usp_alm_act_ult_comp;
/
