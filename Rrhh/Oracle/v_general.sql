create or replace view V_SALDO_DEVENG as

  select m.cod_trabajador, m.cod_area, m.cod_seccion, m.cencos, 
         a.desc_area, s.desc_seccion, cc.desc_cencos 
  
    from maestro m, area a, seccion s, centros_costo cc
