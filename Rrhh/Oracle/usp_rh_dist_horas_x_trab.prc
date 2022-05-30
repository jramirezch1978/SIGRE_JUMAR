create or replace procedure usp_rh_dist_horas_x_trab(
       ani_year        in number,
       ani_mes         in number,
       asi_usuario     in usuario.cod_usr%type                 ,
       asi_origen      in origen.cod_origen%type               ,
       asi_tipo_trab   in tipo_trabajador.tipo_trabajador%type 
) is

lc_doc_ot              doc_tipo.tipo_doc%type ;
ls_cencos              centros_costo.cencos%TYPE;
ln_nro_horas           distribucion_cntble.nro_horas%TYPE;
ls_centro_benef        centro_beneficio.centro_benef%TYPE;
ln_count               number;

Cursor c_maestro is
  select m.cencos ,m.cod_trabajador ,tt.flag_tabla_origen
    from maestro         m ,
         tipo_trabajador tt
   where m.tipo_trabajador = tt.tipo_trabajador 
     and m.cod_origen      = asi_origen          
     and m.tipo_trabajador like asi_tipo_trab    
     and m.flag_estado     = '1'                
     and m.flag_cal_plnlla = '1'
  order by m.cod_trabajador       ;

cursor c_fechas is
  select rh.fec_proceso, rh.fec_inicio, rh.fec_final
    from rrhh_param_org rh
   where rh.origen  = asi_origen
     and rh.tipo_trabajador = asi_tipo_trab
     and to_number(to_char(rh.fec_proceso, 'yyyy')) = ani_year
     and (to_number(to_char(rh.fec_proceso, 'mm'))   = ani_mes or ani_mes = -1);  


--  Lectura de horas del personal de parte idario
cursor c_parte_diario (asi_cod_trabajador maestro.cod_trabajador%type, 
                       adi_Fecha1         date,
                       adi_fecha2         date ) is
  select a.cod_trabajador ,
         d.cencos         ,
         trunc(d.hora_inicio) as fec_parte    ,
         d.cod_labor      ,
         a.nro_horas      ,
         ot.centro_benef
   from  pd_ot            po ,
         pd_ot_det        d, 
         pd_ot_asistencia a,
         tt_ope_ot_adm    tto,
         orden_trabajo    ot
  where po.nro_parte     = d.nro_parte      
    and d.nro_parte      = a.no_parte       
    and po.ot_adm        = tto.ot_adm       
    and d.nro_item       = a.nro_item       
    and d.tipo_doc       = lc_doc_ot        
    and d.nro_orden      = ot.nro_orden    
    and a.cod_trabajador = asi_cod_trabajador
    and trunc(d.hora_inicio) between trunc(adi_Fecha1) and trunc(adi_fecha2)
  UNION
  select pd.cod_trabajador ,
         case 
           when op.cencos is null and te.cencos_os is null then
             m.cencos
           when op.cencos is not null then
             op.cencos
           when te.cencos_os is not null then
             te.cencos_os
         end as cencos,  
         p.fec_parte,
         decode(op.cod_labor, null, ta.cod_labor, op.cod_labor) as cod_labor,
         pd.cant_horas_diu + pd.cant_horas_noc as horas,
         case 
           when op.centro_benef is null and te.centro_benef is null then
             m.centro_benef
           when op.centro_benef is not null then
             op.centro_benef
           when te.centro_benef is not null then
             te.centro_benef
         end as centro_benef
    from Tg_Pd_Destajo     p,
         tg_pd_destajo_det pd,
         operaciones       op,
         tg_especies       te,
         maestro           m,
         tg_tarifario      ta
  where p.nro_parte        = pd.nro_parte
    and p.oper_sec         = op.oper_sec    (+)
    and p.cod_especie      = te.especie        
    and p.cod_especie      = ta.cod_especie
    and p.cod_presentacion = ta.cod_presentacion
    and p.cod_tarea        = ta.cod_tarea
    and pd.cod_trabajador  = m.cod_trabajador
    and pd.cod_trabajador  = asi_cod_trabajador
    and ta.flag_destajo    = '0'
    and trunc(p.fec_parte) between trunc(adi_Fecha1) and trunc(adi_fecha2)
  order by fec_parte;

-- Lectura de Destajo del personal
cursor c_parte_destajo (asi_cod_trabajador maestro.cod_trabajador%type,
                        adi_fecha1         date,
                        adi_fecha2         date) is
  select a.cod_trabajador ,d.cencos,
         trunc(d.hora_inicio) AS FEC_PARTE,
         d.cod_labor,
         a.cant_destajada ,
         ot.centro_benef
   from pd_ot_det           d, 
        pd_ot_asist_destajo a,
        orden_trabajo       ot
  where d.nro_parte      = a.nro_parte      
    and d.nro_item       = a.nro_item       
    and d.tipo_doc       = lc_doc_ot        
    and d.nro_orden      = ot.nro_orden     
    and a.cod_trabajador = asi_cod_trabajador
    and trunc(d.hora_inicio) between trunc(adi_Fecha1) and trunc(adi_fecha2)
  UNION
  select pd.cod_trabajador ,
         case 
           when op.cencos is null and te.cencos_os is null then
             m.cencos
           when op.cencos is not null then
             op.cencos
           when te.cencos_os is not null then
             te.cencos_os
         end as cencos,  
         p.fec_parte,
         decode(op.cod_labor, null, ta.cod_labor, op.cod_labor) as cod_labor,
         sum(case 
               when ta.flag_destajo = '1' then 
                 pd.cant_producida
               else
                 pd.cant_horas_diu + pd.cant_horas_noc * 1.35
             end * p.precio_unit)   as cant_producida,
         case 
           when op.centro_benef is null and te.centro_benef is null then
             m.centro_benef
           when op.centro_benef is not null then
             op.centro_benef
           when te.centro_benef is not null then
             te.centro_benef
         end as centro_benef
    from Tg_Pd_Destajo     p,
         tg_pd_destajo_det pd,
         operaciones       op,
         tg_especies       te,
         maestro           m,
         tg_tarifario      ta
  where p.nro_parte        = pd.nro_parte
    and p.oper_sec         = op.oper_sec    (+)
    and p.cod_especie      = te.especie        
    and p.cod_especie      = ta.cod_especie
    and p.cod_presentacion = ta.cod_presentacion
    and p.cod_tarea        = ta.cod_tarea
    and pd.cod_trabajador  = m.cod_trabajador
    and pd.cod_trabajador  = asi_cod_trabajador
    and trunc(p.fec_parte) between trunc(adi_Fecha1) and trunc(adi_fecha2)
group by pd.cod_trabajador ,
         case 
           when op.cencos is null and te.cencos_os is null then
             m.cencos
           when op.cencos is not null then
             op.cencos
           when te.cencos_os is not null then
             te.cencos_os
         end,  
         p.fec_parte,
         decode(op.cod_labor, null, ta.cod_labor, op.cod_labor),
         case 
           when op.centro_benef is null and te.centro_benef is null then
             m.centro_benef
           when op.centro_benef is not null then
             op.centro_benef
           when te.centro_benef is not null then
             te.centro_benef
         end    

  order by FEC_PARTE ;

-- Lectura de horas de los tripulantes de parte idario
cursor c_parte_pesca (asi_tripulante maestro.cod_trabajador%type,
                      adi_fecha1     date,
                      adi_fecha2     date) is
  select fp.tripulante as cod_trabajador,
         DECODE(fp.cencos, null, tn.cencos, fp.cencos) as cencos,
         trunc(fp.fecha) as hora_inicio,
         (select labor_partic_pesca from fl_param where reckey = '1') as cod_labor,
         fp.participacion_pesca,
         tn.centro_benef
  from fl_participacion_pesca fp,
       tg_naves               tn
  where tn.nave       = fp.nave
    and fp.tripulante = asi_tripulante
    and trunc(fp.fecha) between trunc(adi_Fecha1) and trunc(adi_fecha2)
  order by fp.fecha ;

-- Lectura para la gente de campo
cursor c_parte_campo(adi_fecha1     date,
                     adi_fecha2     date) is
  SELECT a.fecha, a.cod_trabajador, 
         a.cod_labor, a.ot_adm,
         (SELECT a1.hrs_normales + a1.hrs_extras_25 + a1.hrs_extras_35 + a1.hrs_extras_100 + a1.hrs_noc_extras_35
            FROM pd_jornal_campo a1
           WHERE a1.fecha          = a.fecha
             AND a1.cod_trabajador = a.cod_trabajador
             AND a1.nro_item       = a.nro_item) AS nro_horas,
         (SELECT nvl(SUM(lc.total_ha),0)
            FROM pd_jornal_campo_lote a2,
                 lote_campo           lc
           WHERE lc.nro_lote       = a2.nro_lote
             AND a2.fecha          = a.fecha
             AND a2.cod_trabajador = a.cod_trabajador
             AND a2.nro_item       = a.nro_item) AS total_has,
         NVL(lc.total_ha,0) AS area_lote, 
         m.cencos  as cencos_origen,
         op.cencos as cencos_dst,
         lc.cencos as cencos_lote,
         op.centro_benef as centro_benef_op,
         lc.centro_benef as centro_benef_lote,
         m.centro_benef as centro_benef_maestro,
         m.tipo_trabajador,
         m.cod_origen
  FROM pd_jornal_campo      a,
       pd_jornal_campo_lote b,
       ot_administracion    oa,
       maestro              m,
       lote_campo           lc,
       operaciones          op
  WHERE a.fecha          = b.fecha          (+)
    AND a.cod_trabajador = b.cod_trabajador (+)
    AND a.nro_item       = b.nro_item       (+)
    and a.oper_sec       = op.oper_sec      (+)
    AND a.cod_trabajador = m.cod_trabajador 
    and a.ot_adm         = oa.ot_adm
    AND b.nro_lote       = lc.nro_lote      (+)
    and m.cod_origen     = asi_origen
    and m.tipo_trabajador like asi_tipo_trab
    and trunc(a.fecha) between trunc(adi_Fecha1) and trunc(adi_fecha2)
  ORDER BY a.fecha, a.cod_trabajador, a.cod_labor; 

begin

  --  ***********************************************************************
  --  ***   GENERA DISTRIBUCION DE HORAS TRABAJADAS POR CENTRO DE COSTO   ***
  --  ***********************************************************************

  select l.doc_ot 
    into lc_doc_ot 
    from logparam l 
   where l.reckey = '1' ;
  
  for lc_fechas in c_fechas loop

      --eliminar informacion de distribucion_contable
      delete from distribucion_cntble d
       where trunc(d.fec_movimiento) between trunc(lc_fechas.fec_inicio) and trunc(lc_fechas.fec_final)
         and d.cod_trabajador in ( select m.cod_trabajador 
                                     from maestro m 
                                    where m.cod_origen      =    asi_origen    
                                      and m.tipo_trabajador like asi_tipo_trab 
                                      and m.flag_estado     = '1'             
                                      and m.flag_cal_plnlla = '1'             );

      For rc_maestro in c_maestro Loop
          if rc_maestro.flag_tabla_origen = 'A' THEN --PARTE DIARIO DE ASISTENCIA
             For rc_parte in c_parte_diario (rc_maestro.cod_trabajador, lc_fechas.fec_inicio, lc_fechas.fec_final) Loop --lee de parte diario de asistencia
                 update distribucion_cntble
                    set nro_horas = nro_horas + nvl(rc_parte.nro_horas,0)
                  where cod_trabajador        = rc_parte.cod_trabajador                
                    and cencos                = rc_parte.cencos                        
                    and trunc(fec_movimiento) = trunc(rc_parte.fec_parte) 
                    and cod_labor             = rc_parte.cod_labor                    
                    and centro_benef          = rc_parte.centro_benef                  ;

                 if sql%notfound then --si regisro no existe
                    --inserta distribucion contable
                    Insert Into distribucion_cntble(
                           cod_trabajador ,cencos ,fec_movimiento ,cod_labor ,cod_usr ,nro_horas ,fec_calculo ,centro_benef, 
                           tipo_trabajador, cod_origen )
                    Values(
                           rc_parte.cod_trabajador,
                           rc_parte.cencos ,
                           rc_parte.fec_parte,
                           rc_parte.cod_labor ,
                           asi_usuario ,
                           rc_parte.nro_horas ,
                           lc_fechas.fec_proceso , 
                           rc_parte.centro_benef,
                           asi_tipo_trab,
                           asi_origen ) ;
                 end if ;
                 commit;

             End Loop ;
          elsif rc_maestro.flag_tabla_origen = 'D' THEN --PARTE DIARIO DE DESTAJO
             For rc_parte_dest in c_parte_destajo (rc_maestro.cod_trabajador, lc_fechas.fec_inicio, lc_fechas.fec_final) Loop --lee de parte diario de asistencia
                 select count(*)
                   into ln_count
                   from distribucion_cntble
                  where trim(cod_trabajador)  = trim(rc_parte_dest.cod_trabajador)
                    and trim(cencos)          = trim(rc_parte_dest.cencos)
                    and trunc(fec_movimiento) = trunc(rc_parte_dest.fec_parte)
                    and trim(cod_labor)       = trim(rc_parte_dest.cod_labor)
                    and trim(centro_benef)    = trim(rc_parte_dest.centro_benef);
                    
                 if ln_count > 0 then
                    update distribucion_cntble
                       set nro_horas = nro_horas + nvl(rc_parte_dest.cant_destajada,0)
                     where trim(cod_trabajador)  = trim(rc_parte_dest.cod_trabajador)
                       and trim(cencos)          = trim(rc_parte_dest.cencos)
                       and trunc(fec_movimiento) = trunc(rc_parte_dest.fec_parte)
                       and trim(cod_labor)       = trim(rc_parte_dest.cod_labor)
                       and trim(centro_benef)    = trim(rc_parte_dest.centro_benef);
                 else
                    --inserta distribucion contable
                    Insert Into distribucion_cntble(
                           cod_trabajador ,cencos ,fec_movimiento ,cod_labor ,cod_usr ,nro_horas ,fec_calculo ,centro_benef, 
                           tipo_trabajador, cod_origen )
                    Values(
                           rc_maestro.cod_trabajador,
                           rc_parte_dest.cencos ,
                           rc_parte_dest.fec_parte,
                           rc_parte_dest.cod_labor ,
                           asi_usuario ,
                           rc_parte_dest.cant_destajada ,
                           lc_fechas.fec_proceso , 
                           rc_parte_dest.centro_benef,
                           asi_tipo_trab,
                           asi_origen ) ;
                 end if ;

             End Loop ;

          elsif rc_maestro.flag_tabla_origen = 'F' THEN --PARTE DIARIO DE FLOTA

             For rc_parte_pesca in c_parte_pesca (rc_maestro.cod_trabajador, lc_fechas.fec_inicio, lc_fechas.fec_final) Loop --lee de parte diario de asistencia
                 update distribucion_cntble
                    set nro_horas = nro_horas + nvl(rc_parte_pesca.participacion_pesca,0)
                  where cod_trabajador        = rc_parte_pesca.cod_trabajador                
                    and cencos                = rc_parte_pesca.cencos                       
                    and trunc(fec_movimiento) = trunc(rc_parte_pesca.hora_inicio)
                    and cod_labor             = rc_parte_pesca.cod_labor                     
                    and centro_benef          = rc_parte_pesca.centro_benef     ;

                 if sql%notfound then --si regisro no existe
                    --inserta distribucion contable
                    Insert Into distribucion_cntble(
                           cod_trabajador ,cencos ,fec_movimiento ,cod_labor ,cod_usr ,nro_horas ,fec_calculo ,centro_benef, 
                           tipo_trabajador, cod_origen )
                    Values(
                           rc_parte_pesca.cod_trabajador,
                           rc_parte_pesca.cencos ,
                           rc_parte_pesca.hora_inicio,
                           rc_parte_pesca.cod_labor ,
                           asi_usuario ,
                           rc_parte_pesca.participacion_pesca ,
                           lc_fechas.fec_proceso , 
                           rc_parte_pesca.centro_benef,
                           asi_tipo_trab,
                           asi_origen ) ;
                 end if ;

             End Loop ;

          end if ;

      End Loop ;

      for lc_datos2 in c_parte_campo(lc_fechas.fec_inicio, lc_fechas.fec_final) loop
          
          if lc_datos2.cencos_lote is not null then
             ls_cencos := lc_datos2.cencos_lote;
          elsif lc_datos2.cencos_dst is not null then
             ls_cencos := lc_datos2.cencos_dst ;
          else
             ls_cencos := lc_datos2.cencos_origen ;
          end if ;
          
          if lc_datos2.total_has <> 0 then
             ln_nro_horas := lc_datos2.nro_horas / lc_datos2.total_has * lc_datos2.area_lote;
          else
             ln_nro_horas := lc_datos2.nro_horas;
          end if;
          
          if lc_datos2.centro_benef_lote is not null then
             ls_centro_benef := lc_datos2.centro_benef_lote;
          elsif lc_datos2.centro_benef_op is not null then
             ls_centro_benef := lc_datos2.centro_benef_op;
          else
             ls_centro_benef := lc_datos2.centro_benef_maestro;
          end if;
          
           update distribucion_cntble
              set nro_horas = nro_horas + nvl(ln_nro_horas,0),
                  flag_replicacion = '1'
            where cod_trabajador = lc_datos2.cod_trabajador 
              and cencos         = ls_cencos 
              and centro_benef   = ls_centro_benef
              and fec_movimiento = lc_datos2.fecha 
              and cod_labor      = lc_datos2.cod_labor ;

           if sql%notfound then
              if lc_datos2.cod_labor is not null then
                 insert into distribucion_cntble (
                        cod_trabajador, cencos, fec_movimiento, fec_calculo, 
                        cod_labor, cod_usr, nro_horas, flag_replicacion, centro_benef, tipo_trabajador, cod_origen )
                 values (
                        lc_datos2.cod_trabajador, ls_cencos, lc_datos2.fecha, lc_fechas.fec_proceso,
                        lc_datos2.cod_labor, asi_usuario, ln_nro_horas, '1', ls_centro_benef, lc_datos2.tipo_trabajador, lc_datos2.cod_origen ) ;
              end if ;
           end if ;

      end loop ;

  end loop;
  
  commit;


end usp_rh_dist_horas_x_trab  ;
/
