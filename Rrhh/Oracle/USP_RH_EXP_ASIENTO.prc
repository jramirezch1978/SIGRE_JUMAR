create or replace procedure USP_RH_EXP_ASIENTO(
       ani_sucursalId   in sucursal.idsucursal%TYPE,
       ani_mes          in asiento.mes%TYPE,
       ani_year         in asiento.ano%TYPE,
       ani_libro        in asiento.nro_libro%TYPE
) is

ln_nro_asiento     cntbl_libro_mes.nro_asiento%TYPE;
ls_nro_asiento     asiento.idasiento%TYPE;
ln_soles           monedas.id_monedas%TYPE;
ln_plan_contable   plan_contable.idplan_contable%TYPE;
ln_tipo_cambio     asiento.tipo_cambio%TYPE;
ln_item            asiento_det.item%TYPE;
ln_count           number;

-- En un cursor saco todos los pre-asientos que cumplan la condicion 
-- Para ser exportados
cursor c_asientos is
   select pa.*
     from planillas.cntbl_pre_asiento     pa,
          planillas.origen                o
    where pa.origen          = o.cod_origen
      and o.idsucursal       = ani_sucursalId
      and pa.nro_libro       = ani_libro
      and to_number(to_char(pa.fec_cntbl, 'yyyy')) = ani_year
      and to_number(to_char(pa.fec_cntbl, 'mm')) = ani_mes
      and pa.flag_estado = '1'
      and pa.tot_soldeb > 0 and pa.tot_solhab > 0;
 
cursor c_asiento_det(as_origen       planillas.cntbl_pre_asiento.origen%TYPE,
                      an_nro_libro    planillas.cntbl_pre_asiento.nro_libro%TYPE,
                      an_provisional  planillas.cntbl_pre_asiento.nro_provisional%TYPE) is
   select pad.*, c.idcuenta, cc.id_cencos
     from planillas.cntbl_pre_asiento_det     pad,
          cuenta                              c,
          cuenta_plan_contable                cpc,
          centros_costo                       cc
    where pad.origen           = as_origen
      and pad.nro_libro        = an_nro_libro
      and pad.nro_provisional  = an_provisional
      and cpc.idcuenta         = c.idcuenta
      and trim(pad.cnta_ctbl)  = trim(c.cnta_cntbl)
      and pad.cencos           = cc.cencos (+)
      and cpc.idplan_contable  = ln_plan_contable;



begin
  -- Moneda Soles
  SELECT c.conf_valor
    INTO ln_soles
    FROM configuracion c
   WHERE c.conf_nombre = 'SOLES';

  -- Plan contable
  SELECT c.conf_valor
    INTO ln_plan_contable
    FROM configuracion c
   WHERE c.conf_nombre = 'PLAN_CONTABLE';
  
  
  -- Primero elimino los asientos que pertenezcan a ese libro en ese periodo
  delete asiento_det ad
    where ad.idasiento in (select a.idasiento
                             from asiento a
                            where a.nro_libro = ani_libro
                              and a.mes       = ani_mes
                              and a.ano       = ani_year
                              and a.idsucursal = ani_sucursalId);

  delete asiento a
    where a.nro_libro = ani_libro
      and a.mes       = ani_mes
      and a.ano       = ani_year
      and a.idsucursal = ani_sucursalId;
  
  
  -- Del numerador obtengo el siguiente dato
  select count(*)
    into ln_count
    from cntbl_libro_mes cl
   where cl.idsucursal = ani_sucursalId
     and cl.nro_libro  = ani_libro
     and cl.mes        = ani_mes
     and cl.ano        = ani_year;

  if ln_count = 0 then
     insert into cntbl_libro_mes(
            idsucursal, nro_libro, ano, mes, nro_asiento)
     values(
            ani_sucursalId, ani_libro, ani_year, ani_mes, 1);
  end if;
  
  select cl.nro_asiento
    into ln_nro_asiento
    from cntbl_libro_mes cl
   where cl.idsucursal = ani_sucursalId
     and cl.nro_libro  = ani_libro
     and cl.mes        = ani_mes
     and cl.ano        = ani_year
     for update;
   
  -- REcorro el primer cursor para las cabeceras de los asientos
  for lc_reg in c_asientos loop
      -- Obtengo el TIPO CAMBIO
      ln_tipo_cambio := usf_tipo_cambio(lc_reg.fec_cntbl);      


      ls_nro_asiento := trim(to_char(ani_sucursalid, '000')) || trim(to_char(ani_libro, '00')) 
                     || trim(to_char(ani_year, '0000')) || trim(to_char(ani_mes, '00')) 
                     || trim(to_char(ln_nro_asiento, '000000'));
       
      ln_nro_asiento := ln_nro_asiento + 1;
      
      
      -- Ahora inserto la cabecera del asiento
      INSERT INTO asiento(
             idasiento, idsucursal, ano, mes, nro_libro, id_moneda, idplan_contable,
             descripcion, flag_estado, fec_cntbl, tipo_cambio, idtipo_asiento, 
             total_debe_sol, total_haber_sol, total_debe_dol, total_haber_dol, idtip_articulo, idmedio_pago)
      VALUES(
             ls_nro_asiento, ani_sucursalId, ani_year, ani_mes, ani_libro, ln_soles,
             ln_plan_contable, lc_reg.desc_glosa, '1', lc_reg.fec_cntbl, ln_tipo_cambio, 1,
             lc_reg.tot_soldeb, lc_reg.tot_solhab, lc_reg.tot_doldeb, lc_reg.tot_dolhab, 64, 1); 
      
      -- Ahora Inserto el detalle del asiento
      ln_item := 1;
      for lc_reg2 in c_asiento_Det(lc_reg.origen, lc_reg.nro_libro, lc_reg.nro_provisional) loop
        insert into asiento_det(
               idasiento, item, idcuenta, det_glosa, flag_debhab, cencos, 
               importe_sol, importe_dol)
        values(
               ls_nro_asiento, ln_item, lc_reg2.idcuenta, lc_reg2.det_glosa, lc_reg2.flag_debhab, lc_reg2.id_cencos, 
               lc_reg2.imp_movsol, lc_reg2.imp_movdol);
               
        ln_item := ln_item + 1;   
      end loop;
  end loop;

  -- Actualizo el numerador al final
  update cntbl_libro_mes cl
     set cl.nro_asiento = ln_nro_asiento
   where cl.idsucursal = ani_sucursalId
     and cl.nro_libro  = ani_libro
     and cl.mes        = ani_mes
     and cl.ano        = ani_year;
   
   -- HAgo el commit
   commit;
end USP_RH_EXP_ASIENTO;
/
