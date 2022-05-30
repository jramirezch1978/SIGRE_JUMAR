create or replace procedure usp_alm_act_ult_comp_mm(
       asi_nada             in  string,
       aso_mensaje          out string,
       aio_ok               out integer
) is

  /*
     Procedimiento que Actualiza el precio de ultima compra a los
     articulos, en Dolares
  */

  -- Cursor con todos los movimientos de articulos que tienen OC
CURSOR c_articulos_oc(as_tipo_mov in articulo_mov_tipo.tipo_mov%type, 
                      as_doc_oc   in doc_tipo.tipo_doc%type) is
SELECT distinct oc.cod_origen, oc.nro_oc, oc.fec_registro, a.cod_art, 
           (amp.precio_unit - NVL(amp.decuento,0)) as precio_unit, oc.cod_moneda
  FROM articulo a, articulo_mov_proy amp, orden_compra oc, almacen al, 
       ( select a.cod_art, max( oc.fec_registro ) fec_registro 
          from articulo a, articulo_mov_proy amp, orden_compra oc
         where (a.cod_art=amp.cod_art) and 
               (amp.cod_origen=oc.cod_origen and amp.nro_doc=oc.nro_oc and amp.flag_estado<>'0' and oc.flag_estado<>'0') and 
               (amp.tipo_mov=as_tipo_mov and amp.tipo_doc=as_doc_oc) and 
               (amp.precio_unit - NVL(amp.decuento,0)) > 0 
                group by a.cod_art
       ) mmh
where (a.cod_art=amp.cod_art) and 
      (amp.cod_origen=oc.cod_origen and amp.nro_doc=oc.nro_oc) and 
      (mmh.cod_art = a.cod_art and oc.fec_registro = mmh.fec_registro ) and
      (amp.tipo_mov=as_tipo_mov and amp.tipo_doc=as_doc_oc and amp.flag_estado<>'0' and oc.flag_estado<>'0') and 
      (amp.precio_unit - amp.decuento) > 0 and 
      (amp.almacen = al.almacen and al.flag_estado='1') ;--and 
      --amp.almacen in ('MTCN01', 'MTSP01', 'MTPS01', 'MTLM01', 'MTCN90');

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
  ls_oper_oc                  articulo_mov_tipo.tipo_mov%type ;
  ln_ult_tipo_cambio          logparam.ult_tipo_cam%TYPE;
BEGIN 

SELECT cod_soles, doc_oc, l.oper_ing_oc,  l.ult_tipo_cam
  INTO ls_soles, ls_doc_oc, ls_oper_oc, 
  ln_ult_tipo_cambio
  FROM logparam l
 WHERE reckey = '1';

     FOR lc_reg in c_articulos_oc(ls_oper_oc, ls_doc_oc) loop
         -- Obtengo los datos necesarios de ls Orden de compra

         IF lc_reg.cod_moneda = ls_soles then
             select count(*) 
               into ln_count 
               from calendario c
               where trunc(c.fecha) = trunc(lc_reg.fec_registro);
               
             IF ln_count > 0 THEN 
                 select NVL(c.cmp_dol_prom,0) 
                   into ln_tipo_cambio
                   from calendario c
                   where trunc(c.fecha) = trunc(lc_reg.fec_registro);
             ELSE
                 ln_tipo_cambio := ln_ult_tipo_cambio ;
             END IF ;
             
             IF NVL(ln_tipo_cambio,0)<=0 THEN 
                ln_tipo_cambio := 3 ;
             END IF ;
             
             ln_costo_ult_comp := NVL(round(lc_reg.precio_unit / ln_tipo_cambio,4), 0.01) ; 
         ELSE
             ln_costo_ult_comp := NVL(lc_reg.precio_unit, 0.01) ;
         END IF ;
         
         -- Actualizando datos        
         IF ln_costo_ult_comp > 0 THEN
             update articulo a
                set a.costo_ult_compra = round(NVL(ln_costo_ult_comp,0.01),4),
                    a.fec_ult_compra   = lc_reg.fec_registro,
                    a.nro_ultima_oc       = lc_reg.nro_oc,
                    a.cod_origen    = lc_reg.cod_origen,
                    a.flag_replicacion = '1'
              where a.cod_art = lc_reg.cod_art ;
         END IF ;

      END LOOP ;
      commit ;

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

 /*        -- Inserto en tabla temporal para saber como va avanzando el procedimiento
         insert into tt_edg1(cod_art)
         values(lc_reg2.cod_art);
*/
         commit;

     end loop;

end usp_alm_act_ult_comp_mm;
/
