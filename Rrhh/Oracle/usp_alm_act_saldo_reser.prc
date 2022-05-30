CREATE OR REPLACE PROCEDURE usp_alm_act_saldo_reser(
       asi_nada             in STRING
) is

-- Precios Promedios
ln_sldo_reserv            articulo_almacen.sldo_reservado%TYPE;
ls_doc_ot                 logparam.doc_ot%TYPE;
ls_doc_oc                 logparam.doc_oc%TYPE;
ls_oper_cons_int          logparam.oper_cons_interno%TYPE;
ln_count                  NUMBER;
ln_sldo_libre             NUMBER;

-- Cursor con algunos AMPS que tiene errores
CURSOR c_errores IS
SELECT amp1.cod_origen, amp1.nro_mov,
       amp1.tipo_doc,
       amp1.nro_doc,
       amp1.cod_art,
       amp1.almacen,
       amp1.cant_proyect,
       amp1.cant_procesada,
       amp1.cant_reservado,
       usf_cmp_cant_cmp_amp_ot(amp1.cod_origen, amp1.nro_mov ) AS cant_comprada
FROM articulo_mov_proy amp1
WHERE tipo_doc = ls_doc_ot
  AND flag_estado = '1'
  AND amp1.tipo_mov = ls_oper_cons_int
  AND amp1.cant_reservado > 0
  AND cod_art || almacen IN (select amp.cod_art || amp.almacen
                              from articulo_mov_proy   amp,
                                   articulo            a
                              where amp.cod_art = a.cod_art
                                AND amp.cant_proyect > amp.cant_procesada
                                and amp.tipo_mov = ls_oper_cons_int
                                AND amp.tipo_doc = ls_doc_ot
                                and NVL(a.flag_inventariable, '0') = '1'
                                and a.flag_estado                  = '1'
                                AND amp.flag_estado                = '1'
                                AND amp.cant_reservado             > 0
                              group by amp.cod_art, amp.almacen
                            HAVING SUM(amp.cant_reservado) > (SELECT sldo_total 
                                                                FROM articulo_almacen
                                                               WHERE cod_art = amp.cod_art
                                                                 AND almacen = amp.almacen))
   ORDER BY amp1.fec_proyect;
   
-- Cursor con datos de reservacion                                                                 
CURSOR c_saldos is
    select amp.cod_art, amp.almacen,
           SUM(amp.cant_reservado) AS saldo_reservado
      from articulo_mov_proy   amp,
           articulo            a
      where amp.cod_art = a.cod_art
        AND amp.cant_proyect > amp.cant_procesada
        and amp.tipo_mov = ls_oper_cons_int
        AND amp.tipo_doc = ls_doc_ot
        and NVL(a.flag_inventariable, '0') = '1'
        and a.flag_estado                  = '1'
        AND amp.flag_estado                = '1'
        AND amp.cant_reservado             > 0
      group by amp.cod_art, amp.almacen;

BEGIN
  
  LOCK TABLE articulo_mov_proy IN EXCLUSIVE MODE;
  LOCK TABLE articulo_almacen IN EXCLUSIVE MODE;
  
  SELECT doc_ot, oper_cons_interno, doc_oc
    INTO ls_doc_ot, ls_oper_cons_int, ls_doc_oc
    FROM logparam
   WHERE reckey = '1';
  
  update articulo a
    set a.sldo_reservado = (select sum(sldo_reservado)
                             from articulo_almacen
                            where cod_art = a.cod_art)
  where cod_art in (select distinct cod_art from articulo_almacen);

  update articulo_almacen
     set sldo_reservado = 0;
  
  -- Primero los errores para corregirlos
  FOR lc_reg IN c_errores LOOP
      SELECT COUNT(*)
        INTO ln_count
        FROM articulo_almacen
       WHERE cod_art = lc_reg.cod_art
         AND almacen = lc_reg.almacen;
      
      IF ln_count = 0 THEN
         ln_sldo_libre := 0;
      ELSE
         SELECT sldo_total - sldo_reservado
           INTO ln_sldo_libre
           FROM articulo_almacen
          WHERE cod_art = lc_reg.cod_art
            AND almacen = lc_reg.almacen; 
      END IF;
      
      IF ln_sldo_libre >= lc_reg.cant_reservado THEN
         UPDATE articulo_almacen
            SET sldo_reservado = sldo_reservado + lc_reg.cant_reservado
          WHERE cod_art = lc_reg.cod_art
            AND almacen = lc_reg.almacen;
      ELSE
         UPDATE articulo_mov_proy amp
            SET amp.Org_Amp_Ref = NULL,
                amp.nro_amp_ref = NULL
          WHERE amp.Org_Amp_Ref = lc_reg.cod_origen
            AND amp.nro_amp_ref = lc_reg.nro_mov;
            
         UPDATE articulo_mov_proy
            SET cant_reservado = ln_sldo_libre
          WHERE cod_origen = lc_reg.cod_origen
            AND nro_mov    = lc_reg.nro_mov;

         UPDATE articulo_almacen
            SET sldo_reservado = sldo_reservado + lc_reg.cant_reservado
          WHERE cod_art = lc_reg.cod_art
            AND almacen = lc_reg.almacen;
            
      END IF;
        
  END LOOP;
  
  FOR lc_reg IN c_saldos LOOP
      if lc_reg.saldo_reservado < 0 then
         ln_sldo_reserv := 0;
      else
          ln_sldo_reserv := lc_reg.saldo_reservado;
      end if;

      update articulo_almacen a
         set a.sldo_reservado = ln_sldo_reserv
       where almacen = lc_reg.almacen
         and cod_art = lc_reg.cod_art;

      IF SQL%NOTFOUND then
         insert into articulo_almacen(
                cod_art, almacen, sldo_reservado)
         values(
                lc_reg.cod_art, lc_reg.almacen, ln_sldo_reserv);
      end if;

      insert into tt_edg1(cod_art)
      values(lc_reg.cod_art);

      commit;


  END LOOP ;

  update articulo a
    set a.sldo_reservado = (select sum(sldo_reservado)
                             from articulo_almacen
                            where cod_art = a.cod_art)
  where cod_art in (select distinct cod_art from articulo_almacen);


  COMMIT ;

END usp_alm_act_saldo_reser;
/
