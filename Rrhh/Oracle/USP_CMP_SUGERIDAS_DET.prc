create or replace procedure USP_CMP_SUGERIDAS_DET(
       adi_fecha   in date ,
       asi_origen  in origen.cod_origen%TYPE,
       asi_est_amp in char
) is

   /* asi_est_amp es un flag que indica que registros de Articulo_mov_proy
   -- debo tomar y puede tener los siguientes valores:

      1.- Solo tomar los abiertos (1)
      2.- Tomar los abiertos y planeados (1,6)
      3.- Solo tomar los planeados  (6)

   */

   -- Cursor para articulos programados
   CURSOR c_cmp_sug IS
     SELECT amp.COD_ART,
            amp.tipo_mov,
            (NVL(amp.cant_proyect, 0) - NVL(amp.cant_procesada,0)) as cantidad,
            amp.nro_mov,
            amp.fec_proyect,
            amp.tipo_doc,
            amp.nro_doc,
            amp.cencos,
            amp.cnta_prsp,
            amp.oper_sec,
            amp.flag_estado,
            amp.cod_origen
        FROM ARTICULO_MOV_PROY amp,
             ARTICULO a
       WHERE amp.cod_art       = a.cod_art
         and NVL(amp.flag_estado, '0') in ('1', '6')
         and NVL(a.flag_estado, '0')  = '1'
         and NVL(a.flag_inventariable,'0') = '1'
         and TRUNC(amp.fec_proyect) <= TRUNC(adi_fecha)
         and (amp.tipo_mov = (select l.oper_cons_interno from logparam l where reckey = '1') or
              amp.tipo_mov = (select l.oper_ing_oc from logparam l where reckey = '1'))
         AND NVL(amp.cant_procesada,0) < NVL(amp.cant_proyect,0)
     ORDER BY a.cod_art, amp.fec_proyect, amp.tipo_mov;


   -- Cursor para articulos en reposicion
   CURSOR c_rep_stk IS
     SELECT a.COD_ART,
            a.sldo_total,
            a.cnt_compra_rec,
            a.sldo_minimo
       FROM Articulo a
      WHERE NVL(a.flag_estado,'0')         = '1'
        and NVL(a.flag_reposicion,'0')     = '1'
        and NVL(a.flag_inventariable, '0') = '1'
        and NVL(a.sldo_total,0) < NVL(a.sldo_minimo,0)
        and a.cod_art not in (select distinct cod_Art from tt_compras_sugeridas)
     ORDER BY a.cod_art;

   -- define variables
   ls_cod_art          articulo_mov_proy.cod_art%type;
   rc_reg              c_cmp_sug%ROWTYPE;
   rc_stk              c_rep_stk%ROWTYPE;
   ln_saldo            number;
   ln_dispon           number;
   ln_ing              number;
   ln_sal              number;
   ln_saldo_total      articulo.sldo_total%TYPE;
   ls_operacion        tt_compras_sugeridas.operacion%TYPE;
   ln_item             number;
   ln_x_comp           number;
   ln_count            number;
   ln_sldo_total       articulo_almacen.sldo_total%TYPE;
   ln_cnt_compra_rec   articulo.cnt_compra_rec%TYPE;
   ln_sldo_minimo      articulo.sldo_minimo%TYPE;
   li_grabar           integer;

begin
   delete tt_compras_sugeridas;
   delete tt_edg1;

   Open c_cmp_sug;
   Fetch c_cmp_sug into rc_reg;
   While c_cmp_sug%found loop
      ls_cod_art := rc_reg.cod_art;
      ln_dispon := 0;
      ln_x_comp := 0;

      -- Busca saldo en almacen
      Select NVL(a.sldo_total,0)
        into ln_dispon
        from articulo a
       where cod_art = ls_cod_art;

      IF ln_dispon > 0 then
           ls_operacion := 'Sldo ini';
           ln_x_comp := ln_dispon * -1;
           insert into tt_compras_sugeridas(
              tipo_mov, cod_art, disponible, operacion, por_comprar)
           values (
               '1', ls_cod_art, ln_dispon ,ls_operacion, ln_x_comp);
      END IF;

      ln_saldo := ln_dispon;
      ln_item := 1;

      -- Recorro el cursor en busca de todos los articulos proyectados
      While rc_reg.cod_art = ls_cod_art and c_cmp_sug%found loop
          ln_ing := 0;
          ln_sal := 0;
          li_grabar := 0;

          if Substr(rc_reg.tipo_mov,1,1) = 'I' then
             -- Si son ingresos
             ln_ing := rc_reg.cantidad;
             ls_operacion := rc_reg.tipo_doc || ': ' || rc_reg.nro_doc;
             ln_item := ln_item + 1;
             li_grabar := 1;
          else
             -- Valido las salidas de acuerdo al flag e estado y al valor
             -- que tenga la variable asi_est_amp
             if (asi_est_amp = '1' and rc_reg.flag_estado = '1')         or
                (asi_est_amp = '2' and rc_reg.flag_estado in ('1', '6')) or
                (asi_est_amp = '3' and rc_reg.flag_estado = '6')         then

                -- Si son Salidas
                ln_item := ln_item + 1;
                ln_sal  := rc_reg.cantidad;
                li_grabar := 1;
                if rc_reg.tipo_doc is not null then
                   ls_operacion := rc_reg.tipo_doc || ' - ' || rc_reg.nro_doc;
                else
                   IF rc_reg.oper_sec is not null then
                      ls_operacion := 'OPERSEC: ' || rc_reg.oper_sec;
                   else
                      ls_operacion := 'MOV.PROY.:' || TO_CHAR(rc_reg.nro_mov);
                   end if;
                end if;
             end if;
          end if;

          if li_grabar = 1 then
              ln_x_comp := ln_x_comp - ln_ing + ln_sal;

              -- Graba datos
              insert into tt_compras_sugeridas(
                     tipo_mov, cod_art, fecha, ingresos, salidas,
                     operacion, cencos, por_comprar, nro_mov_proy,
                     origen_mov_proy, oper_sec, tipo_doc,
                     nro_doc, flag_estado)
              values(
                     to_char(ln_item), ls_cod_art, rc_reg.fec_proyect, ln_ing, ln_sal,
                     ls_operacion, rc_reg.cencos, ln_x_comp, rc_reg.nro_mov,
                     rc_reg.cod_origen ,rc_reg.oper_sec, rc_reg.tipo_doc,
                     rc_reg.nro_doc, rc_reg.flag_estado);
          end if;

          Fetch c_cmp_sug into rc_reg;

      end loop;

      -- Verifica si es de reposicion
      SELECT count(*)
        into ln_count
        FROM Articulo a
       WHERE NVL(a.flag_estado, '0')        = '1'
         and NVL(a.flag_reposicion, '0')    = '1'
         and NVL(a.flag_inventariable, '0') = '1'
         and NVL(a.sldo_total,0) < NVL(a.sldo_minimo,0)
         and a.cod_art = ls_cod_art;

      if ln_count > 0 then
         ln_item := ln_item + 1;

         SELECT NVL(a.cnt_compra_rec,0), NVL(a.sldo_minimo,0), NVL(a.sldo_total,0)
           into ln_cnt_compra_rec, ln_sldo_minimo, ln_saldo_total
           FROM Articulo a
           WHERE NVL(a.flag_estado,'0') = '1'
             and NVL(a.flag_reposicion,'0') = '1'
             and NVL(a.flag_inventariable, '0') = '1'
             and NVL(a.sldo_total,0) <= NVL(a.sldo_minimo,0)
             and a.cod_art = ls_cod_Art;

          IF ln_cnt_compra_rec = 0 then -- cuando la recompra es cero
             ln_saldo := ln_sldo_minimo - ln_sldo_total;
             ln_sal   := ln_sldo_minimo;
          else
              ln_saldo := ABS(ln_sldo_total - ln_cnt_compra_rec);
              ln_sal   := ln_cnt_compra_rec;
          end if;

         if ln_sal > 0 then
            ln_x_comp := ln_x_comp + ln_sal;
            insert into tt_compras_sugeridas(
                    tipo_mov, cod_art, fecha, stock, por_comprar, operacion)
            values(
                    to_char(ln_item), ls_cod_art, adi_fecha, ln_sal, ln_x_comp, 'Rep. Stk');
         end if;
      end if;

      -- Si no hay que comprar, eliminar movimiento
      -- Lo grabo en una tabla temporal para eliminarlo despues
      if ln_x_comp <= 0 then
         insert into tt_edg1(cod_art)
         values (ls_cod_art);
      end if;

   end loop;
   close c_cmp_sug;

   -- Genera los de reposicion de stocks
   -- Genera los de reposicion de stocks
   for rc_stk in c_rep_stk loop
       ls_cod_art        := rc_stk.cod_art;
       ln_sldo_minimo    := rc_stk.sldo_minimo;
       ln_cnt_compra_rec := rc_stk.cnt_compra_rec;
       ln_sldo_total     := rc_stk.sldo_total;

       ln_item := 1;

       -- Si tiene Saldo inicial
       IF ln_sldo_total > 0 then
         ls_operacion := 'Sldo ini';
         ln_x_comp    := ln_sldo_total * -1;

         insert into tt_compras_sugeridas(
                nro_item, cod_art, disponible, operacion, por_comprar, flag_estado,
                comp_sugerida)
         values (
                ln_item, ls_cod_art, ln_sldo_total ,ls_operacion, ln_x_comp, '1', 0  );

         ln_item := ln_item + 1;
      END IF;

       IF ln_cnt_compra_rec = 0 then -- cuando la recompra es cero
          ln_sal   := ln_sldo_minimo;
       else
          ln_sal   := ln_cnt_compra_rec;
       end if;

       ln_x_comp := ln_sal;

       if ln_sal > 0 then
           insert into tt_compras_sugeridas(
                  nro_item, cod_art,   fecha,     stock,  por_comprar, operacion,
                  flag_estado)
           values (
                  ln_item, ls_cod_art, adi_fecha, ln_sal, ln_x_comp, 'Rep. Stk', '1') ;
       end if;

   end loop;

   -- Ahora elimino todo aquellos articulos que no deben comprarse todavia
   delete tt_compras_sugeridas
   where cod_art in (select cod_art from tt_edg1);

   delete tt_edg1;

   commit;
end USP_CMP_SUGERIDAS_DET;
/
