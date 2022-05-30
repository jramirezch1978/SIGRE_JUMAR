create or replace procedure usp_cal_distribucion_plla
  ( ad_fec_desde in date, ad_fec_hasta in date, as_usuario in char ) is

ls_cencos_origen    char(10) ;
ls_cencos_destino   char(10) ;
ls_cod_labor        char(8) ;
ln_contador         integer ;

--  Lectura de horas del personal de campo
cursor c_campo is
  select d.cod_labor, d.hora_inicio, c.cod_campo, a.cod_trabajador, a.nro_horas
  from pd_ot_det d, pd_ot_asistencia a, campo_ciclo c
  where (to_date(to_char(d.hora_inicio,'DD/MM/YYYY'),'DD/MM/YYYY') between
        to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')) and
        d.nro_parte = a.no_parte and d.nro_item = a.nro_item and
        d.nro_orden = c.nro_orden
  order by d.hora_inicio ;

/*  cambios a futuro para correccion de costos en la planilla
  select d.cod_labor, d.hora_inicio, c.cod_campo, a.cod_trabajador, a.nro_horas,
         m.cencos as cencos_maq, ca.cencos as cencos_camp
  from pd_ot_det d, pd_ot_asistencia a, campo_ciclo c, maquina m, campo ca
  where (to_date(to_char(d.hora_inicio,'DD/MM/YYYY'),'DD/MM/YYYY') between
        to_date('21/01/2004','dd/mm/YYYY') and
        to_date('20/02/2004','DD/MM/YYYY')) and
        d.nro_parte = a.no_parte and d.nro_item = a.nro_item and
        d.nro_orden = c.nro_orden and
        c.cod_campo = ca.cod_campo and
        d.cod_maquina = m.cod_maquina(+)
  order by d.hora_inicio ;
*/

begin

delete from distribucion_cntble dist
  where dist.fec_movimiento between ad_fec_desde and ad_fec_hasta ;

--  **************************************************
--  ***   LECTURA DE HORAS DEL PERSONAL DE CAMPO   ***
--  **************************************************
for rc_cam in c_campo loop

  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from maestro m
    where m.cod_trabajador = rc_cam.cod_trabajador and
          m.flag_estado = '1' and m.flag_cal_plnlla = '1' ;
          
  if ln_contador > 0 then
  
    ls_cod_labor := nvl(rc_cam.cod_labor,' ') ;
    select nvl(m.cencos,' ')
      into ls_cencos_origen
      from maestro m
      where m.cod_trabajador = rc_cam.cod_trabajador and
            m.flag_estado = '1' and m.flag_cal_plnlla = '1' ;
    
    select nvl(c.cencos,' ')
      into ls_cencos_destino
      from campo c
      where c.cod_campo = rc_cam.cod_campo ;
    
    if ls_cencos_origen <> ls_cencos_destino and ls_cencos_destino <> ' ' then

      update distribucion_cntble
        set nro_horas = nro_horas + nvl(rc_cam.nro_horas,0)
        where cod_trabajador = rc_cam.cod_trabajador and
              cencos = ls_cencos_destino and
              fec_movimiento = rc_cam.hora_inicio and
              cod_labor = ls_cod_labor ;
              
      if sql%notfound then
        if ls_cod_labor <> ' ' then
          insert into distribucion_cntble (
            cod_trabajador, cencos, fec_movimiento,
            cod_labor, cod_usr, nro_horas )
          values (
            rc_cam.cod_trabajador, ls_cencos_destino, rc_cam.hora_inicio,
            ls_cod_labor, as_usuario, rc_cam.nro_horas ) ;
        end if ;
      end if ;

    end if ;
    
  end if ;
    
end loop ;

end usp_cal_distribucion_plla ;



/*
create or replace procedure usp_cal_distribucion_plla
  ( ad_fec_desde in date, ad_fec_hasta in date, as_usuario in char ) is

ls_cencos_origen    char(10) ;
ls_cencos_destino   char(10) ;
ls_cod_labor        char(8) ;
ln_contador         integer ;

--  Lectura de horas del personal de campo
cursor c_campo is
  select l.cod_campo, l.cod_labor, l.hora_inicio,
         a.cod_trabajador, a.nro_horas
  from pd_labores l, pd_asistencia a
  where (to_date(to_char(l.hora_inicio,'DD/MM/YYYY'),'DD/MM/YYYY') between
        to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')) and
        l.no_parte = a.no_parte and
        l.nro_item = a.nro_item
  order by l.hora_inicio ;
        

--  Lectura de horas del personal de talleres
cursor c_taller is
  select d.cod_labor, d.hora_inicio, a.cod_trabajador,
         a.nro_horas, o.cencos_slc
  from pd_ot_det d, pd_ot_asistencia a, orden_trabajo o
  where (to_date(to_char(d.hora_inicio,'DD/MM/YYYY'),'DD/MM/YYYY') between
        to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')) and
        d.nro_parte = a.no_parte and
        d.nro_item = a.nro_item and
        d.cod_origen = o.cod_origen and
        d.nro_orden = o.nro_orden
  order by d.hora_inicio ;


begin

delete from distribucion_cntble dist
  where dist.fec_movimiento between ad_fec_desde and ad_fec_hasta ;

--  **************************************************
--  ***   LECTURA DE HORAS DEL PERSONAL DE CAMPO   ***
--  **************************************************
for rc_cam in c_campo loop

  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from maestro m
    where m.cod_trabajador = rc_cam.cod_trabajador and
          m.flag_estado = '1' and m.flag_cal_plnlla = '1' ;
          
  if ln_contador > 0 then
  
    ls_cod_labor := nvl(rc_cam.cod_labor,' ') ;
    select nvl(m.cencos,' ')
      into ls_cencos_origen
      from maestro m
      where m.cod_trabajador = rc_cam.cod_trabajador and
            m.flag_estado = '1' and m.flag_cal_plnlla = '1' ;
    
    select nvl(c.cencos,' ')
      into ls_cencos_destino
      from campo c
      where c.cod_campo = rc_cam.cod_campo ;
    
    if ls_cencos_origen <> ls_cencos_destino and ls_cencos_destino <> ' ' then

      update distribucion_cntble
        set nro_horas = nro_horas + nvl(rc_cam.nro_horas,0)
        where cod_trabajador = rc_cam.cod_trabajador and
              cencos = ls_cencos_destino and
              fec_movimiento = rc_cam.hora_inicio and
              cod_labor = ls_cod_labor ;
              
      if sql%notfound then
        if ls_cod_labor <> ' ' then
          insert into distribucion_cntble (
            cod_trabajador, cencos, fec_movimiento,
            cod_labor, cod_usr, nro_horas )
          values (
            rc_cam.cod_trabajador, ls_cencos_destino, rc_cam.hora_inicio,
            ls_cod_labor, as_usuario, rc_cam.nro_horas ) ;
        end if ;
      end if ;

    end if ;
    
  end if ;
    
end loop ;
         

--  *****************************************************
--  ***   LECTURA DE HORAS DEL PERSONAL DE TALLERES   ***
--  *****************************************************
for rc_tal in c_taller loop

  ln_contador := 0 ;
  select count(*)
    into ln_contador
    from maestro m
    where m.cod_trabajador = rc_tal.cod_trabajador and
          m.flag_estado = '1' and m.flag_cal_plnlla = '1' ;

  if ln_contador > 0 then
  
    ls_cod_labor := nvl(rc_tal.cod_labor,' ') ;
    select nvl(m.cencos,' ')
      into ls_cencos_origen
      from maestro m
      where m.cod_trabajador = rc_tal.cod_trabajador and
            m.flag_estado = '1' and m.flag_cal_plnlla = '1' ;
    
    if ls_cencos_origen <> rc_tal.cencos_slc then

      update distribucion_cntble
        set nro_horas = nro_horas + nvl(rc_tal.nro_horas,0)
        where cod_trabajador = rc_tal.cod_trabajador and
              cencos = rc_tal.cencos_slc and
              fec_movimiento = rc_tal.hora_inicio and
              cod_labor = ls_cod_labor ;
              
      if sql%notfound then
        if ls_cod_labor <> ' ' then
          insert into distribucion_cntble (
            cod_trabajador, cencos, fec_movimiento,
            cod_labor, cod_usr, nro_horas )
          values (
            rc_tal.cod_trabajador, rc_tal.cencos_slc, rc_tal.hora_inicio,
            ls_cod_labor, as_usuario, rc_tal.nro_horas ) ;
        end if ;
      end if ;

    end if ;
    
  end if ;
    
end loop ;


end usp_cal_distribucion_plla ;
*/
/
