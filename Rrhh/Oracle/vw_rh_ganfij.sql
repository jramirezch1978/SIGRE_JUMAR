create or replace view vw_rh_ganfij as
select gdf.cod_trabajador, 
          gdf.concep, 
          gdf.flag_trabaj, 
          gdf.flag_estado, 
          nvl(m.bonif_fija_30_25,'0') as flag_bonif_fija_30_25, 
          nvl(m.situa_trabaj,' ') as situa_trabaj, 
          decode(nvl(m.situa_trabaj,' '), 'E', 'ESTABLE', 'S', 'ESTABLE', 'C', 'CONTRATADO', 'OTROS') as estado_contrato, 
          gdf.imp_gan_desc
      from gan_desct_fijo gdf
      inner join maestro m on gdf.cod_trabajador = m.cod_trabajador
      where gdf.concep in (select c.concep from concepto c where c.flag_estado = '1' and substr(c.concep,1,2) = (select p.grc_gnn_fija from rrhhparam p where p.reckey = '1') and c.concep not in (select g.concepto_gen from grupo_calculo g where g.grupo_calculo in ('030', '031'))) 
         and gdf.flag_estado = '1'
         and m.flag_estado = '1'
         and gdf.imp_gan_desc <> 0
         and m.situa_trabaj in ('S','E','C')

union all

   select gdf.cod_trabajador, 
          (select min(gc.concepto_gen) from grupo_calculo gc where gc.grupo_calculo = '031'),
          gdf.flag_trabaj, 
          gdf.flag_estado, 
          nvl(m.bonif_fija_30_25,'0') as flag_bonif_fija_30_25, 
          nvl(m.situa_trabaj,' ') as situa_trabaj, 
          decode(nvl(m.situa_trabaj,' '), 'E', 'ESTABLE', 'S', 'ESTABLE', 'C', 'CONTRATADO', 'OTROS') as estado_contrato, 
          round((decode(nvl(m.bonif_fija_30_25,'0'), '1', 0.30, 0) * decode(m.situa_trabaj, 'E', gdf.imp_gan_desc, 'S', gdf.imp_gan_desc, 'C', gdf.imp_gan_desc, 0)),2) as imp_acumula_30
      from gan_desct_fijo gdf
      inner join maestro m on gdf.cod_trabajador = m.cod_trabajador
      where gdf.concep in (select c.concep from concepto c where c.flag_estado = '1' and substr(c.concep,1,2) = (select p.grc_gnn_fija from rrhhparam p where p.reckey = '1') and c.concep not in (select g.concepto_gen from grupo_calculo g where g.grupo_calculo in ('030', '031'))) 
         and gdf.flag_estado = '1'
         and m.flag_estado = '1'
         and round((decode(nvl(m.bonif_fija_30_25,'0'), '1', 0.30, 0) * decode(m.situa_trabaj, 'E', gdf.imp_gan_desc, 'S', gdf.imp_gan_desc, 'C', gdf.imp_gan_desc, 0)),2) <> 0
         and m.situa_trabaj in ('S','E','C')

union all


   select gdf.cod_trabajador, 
          (select min(gc.concepto_gen) from grupo_calculo gc where gc.grupo_calculo = '030'),
          gdf.flag_trabaj, 
          gdf.flag_estado, 
          nvl(m.bonif_fija_30_25,'0') as flag_bonif_fija_30_25, 
          nvl(m.situa_trabaj,' ') as situa_trabaj, 
          decode(nvl(m.situa_trabaj,' '), 'E', 'ESTABLE', 'S', 'ESTABLE', 'C', 'CONTRATADO', 'OTROS') as estado_contrato, 
          round((decode(nvl(m.bonif_fija_30_25,'0'), '2', 0.25, 0) * decode(m.situa_trabaj, 'E', gdf.imp_gan_desc, 'S', gdf.imp_gan_desc, 'C', gdf.imp_gan_desc, 0)),2) as imp_acumula_25
      from gan_desct_fijo gdf
      inner join maestro m on gdf.cod_trabajador = m.cod_trabajador
      where gdf.concep in (select c.concep from concepto c where c.flag_estado = '1' and substr(c.concep,1,2) = (select p.grc_gnn_fija from rrhhparam p where p.reckey = '1') and c.concep not in (select g.concepto_gen from grupo_calculo g where g.grupo_calculo in ('030', '031'))) 
         and gdf.flag_estado = '1'
         and m.flag_estado = '1'
         and round((decode(nvl(m.bonif_fija_30_25,'0'), '2', 0.25, 0) * decode(m.situa_trabaj, 'E', gdf.imp_gan_desc, 'S', gdf.imp_gan_desc, 'C', gdf.imp_gan_desc, 0)),2) <> 0
         and m.situa_trabaj in ('S','E','C')

