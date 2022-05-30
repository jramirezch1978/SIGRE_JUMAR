create or replace procedure usp_rh_distribucion_horas (
       adi_fec_desde   in date, 
       adi_fec_hasta   in date, 
       asi_usuario     in usuario.cod_usr%TYPE,
       asi_origen      in origen.cod_origen%TYPE, 
       asi_tipo_trabaj in tipo_trabajador.tipo_trabajador%TYPE 
) is

ls_cencos            centros_costo.cencos%TYPE ;
ln_nro_horas         number;

/*
--  Lectura de horas del personal de campo
cursor c_campo is
  select l.cencos, l.cod_labor, l.hora_inicio, a.cod_trabajador, a.nro_horas
  from pd_ot_det l, pd_ot_asistencia a, maestro m
  where l.nro_item = a.nro_item and l.nro_parte = a.no_parte and
        to_date(to_char(l.hora_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') between
        ad_fec_desde and ad_fec_hasta and a.cod_trabajador = m.cod_trabajador and
        m.cod_origen = as_origen and m.tipo_trabajador = as_tipo_trabaj and
        m.flag_estado = '1' and m.flag_cal_plnlla = '1'
  order by l.hora_inicio ;
*/

--  Lectura de horas del personal de campo
cursor c_campo is
  select d.cod_labor, d.hora_inicio, c.cod_campo, a.cod_trabajador, a.nro_horas,
         m.cencos as cencos_maq, ca.cencos as cencos_camp, 
         m.cencos as cencos_origen
  from pd_ot_det        d, 
       pd_ot_asistencia a, 
       campo_ciclo      c, 
       maquina          mq, 
       campo            ca,
       maestro          m
 where d.nro_parte       = a.no_parte 
   and d.nro_item        = a.nro_item 
   and d.nro_orden       = c.nro_orden 
   and c.cod_campo       = ca.cod_campo 
   and d.cod_maquina     = mq.cod_maquina(+)
   and a.cod_trabajador  = m.cod_trabajador
   and m.cod_origen      = asi_origen
   and m.tipo_trabajador like asi_tipo_trabaj
   and m.flag_estado     = '1'
   and m.flag_cal_plnlla = '1'
   and trunc(d.hora_inicio) between adi_fec_desde and adi_fec_hasta
  order by d.hora_inicio ;

cursor c_campo2 is
  SELECT a.fecha, a.cod_trabajador, 
         a.cod_labor, a.ot_adm,
         (SELECT a1.hrs_normales + a1.hrs_extras_25 + a1.hrs_extras_35 + a1.hrs_extras_100 + a1.hrs_noc_extras_35
            FROM pd_jornal_campo a1
           WHERE a1.fecha = a.fecha
             AND a1.cod_trabajador = a.cod_trabajador
             AND a1.nro_item       = a.nro_item) AS nro_horas,
         (SELECT nvl(SUM(lc.total_ha),0)
            FROM pd_jornal_campo_lote a2,
                 lote_campo           lc
           WHERE lc.nro_lote = a2.nro_lote
             AND a2.fecha = a.fecha
             AND a2.cod_trabajador = a.cod_trabajador
             AND a2.nro_item       = a.nro_item) AS total_has,
         NVL(lc.total_ha,0) AS area_lote, 
         m.cencos as cencos_origen,
         op.cencos as cencos_dst,
         lc.cencos as cencos_lote
  FROM pd_jornal_campo a,
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
    and m.tipo_trabajador like asi_tipo_trabaj
    and trunc(a.fecha) between trunc(adi_fec_desde) and trunc(adi_fec_hasta)
  ORDER BY a.fecha, a.cod_trabajador, a.cod_labor; 
  
begin

--  ***********************************************************************
--  ***   GENERA DISTRIBUCION DE HORAS TRABAJADAS POR CENTRO DE COSTO   ***
--  ***********************************************************************

delete from distribucion_cntble d
  where trunc(d.fec_movimiento) between adi_fec_desde and adi_fec_hasta 
    and d.cod_trabajador in ( select m.cod_trabajador 
                                from maestro m
                               where m.cod_origen = asi_origen 
                                 and m.tipo_trabajador like asi_tipo_trabaj ) ;

for lc_datos in c_campo loop
    
    if lc_datos.cencos_maq is not null then
      ls_cencos := lc_datos.cencos_maq ;
    else
      ls_cencos := lc_datos.cencos_camp ;
    end if ;

    if lc_datos.cencos_origen <> ls_cencos then
    
       update distribucion_cntble
          set nro_horas = nro_horas + nvl(lc_datos.nro_horas,0),
              flag_replicacion = '1'
        where cod_trabajador = lc_datos.cod_trabajador 
          and cencos         = ls_cencos 
          and fec_movimiento = lc_datos.hora_inicio 
          and cod_labor      = lc_datos.cod_labor ;

       if sql%notfound then
          if lc_datos.cod_labor is not null then
             insert into distribucion_cntble (
                    cod_trabajador, cencos, fec_movimiento,
                    cod_labor, cod_usr, nro_horas, flag_replicacion )
             values (
                    lc_datos.cod_trabajador, ls_cencos, lc_datos.hora_inicio,
                    lc_datos.cod_labor, asi_usuario, lc_datos.nro_horas, '1' ) ;
          end if ;
       end if ;

    end if ;
end loop ;

for lc_datos2 in c_campo2 loop
    
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
    
     update distribucion_cntble
        set nro_horas = nro_horas + nvl(ln_nro_horas,0),
            flag_replicacion = '1'
      where cod_trabajador = lc_datos2.cod_trabajador 
        and cencos         = ls_cencos 
        and fec_movimiento = lc_datos2.fecha 
        and cod_labor      = lc_datos2.cod_labor ;

     if sql%notfound then
        if lc_datos2.cod_labor is not null then
           insert into distribucion_cntble (
                  cod_trabajador, cencos, fec_movimiento,
                  cod_labor, cod_usr, nro_horas, flag_replicacion )
           values (
                  lc_datos2.cod_trabajador, ls_cencos, lc_datos2.fecha,
                  lc_datos2.cod_labor, asi_usuario, ln_nro_horas, '1' ) ;
        end if ;
     end if ;

end loop ;

commit;

end usp_rh_distribucion_horas ;
/
