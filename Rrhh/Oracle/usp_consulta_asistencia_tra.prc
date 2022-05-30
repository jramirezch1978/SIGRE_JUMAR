create or replace procedure usp_consulta_asistencia_tra
  ( ad_fec_desde        in date,
    ad_fec_hasta        in date,
    as_tipo_trabajador  in maestro.tipo_trabajador%type ) is

ls_cod_area               char(1) ;
ls_desc_area              varchar2(40) ;
ls_cod_seccion            char(3) ;
ls_desc_seccion           varchar2(40) ;
ls_cod_cencos             char(10) ;
ls_desc_cencos            varchar2(40) ;
ls_cod_trabajador         char(8) ;
ls_nombres                varchar2(40) ;
ls_cod_carnet             char(10) ;
ld_fecha_marcacion        date ;
ln_r_min_tardanza         number(11,2) ;
ln_r_hor_inasistencia     number(11,2) ;
ln_r_hor_sobretiempo      number(11,2) ;
ln_r_hor_trabajadas       number(11,2) ;
ld_fecha_digitacion       date ;
ls_concepto               concepto.concep%type ;
ls_desc_concepto          varchar2(40) ;
ld_fecha_desde            date ;
ld_fecha_hasta            date ;
ln_nro_horas              number(11,2) ;
ln_nro_dias               number(11,2) ;

--  Cursor de trabajadores del maestro
Cursor c_maestro is 
  Select m.cod_trabajador, m.carnet_trabaj, m.cencos, m.cod_seccion, m.cod_area
  from maestro m
  where m.flag_estado = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_seccion, m.cencos, m.cod_trabajador ;

--  Cursor de marcaciones consolidadas diarias
Cursor c_marcacion_consolidada is 
  Select mcd.fecha_marcacion, mcd.min_tardanza, mcd.hora_inasistencia,
         mcd.hora_sobretiempo, mcd.hora_trabajada
  from marcacion_consolidada_diaria mcd
  where mcd.carnet_trabajador = ls_cod_carnet and
        to_date(to_char(mcd.fecha_marcacion,'DD/MM/YYYY'), 'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'), 'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'), 'DD/MM/YYYY')
  order by mcd.carnet_trabajador, mcd.fecha_marcacion ;

--  Cursor de movimiento digitado por el ususario
Cursor c_incidencia is 
  Select it.fecha_movim, it.concep, it.fecha_inicio, it.fecha_fin,
         it.nro_horas, it.nro_dias
  from incidencia_trabajador it
  where it.cod_trabajador = ls_cod_trabajador and
        to_date(to_char(it.fecha_movim,'DD/MM/YYYY'), 'DD/MM/YYYY') = to_date(to_char(ld_fecha_marcacion,'DD/MM/YYYY'), 'DD/MM/YYYY')
  order by it.cod_trabajador, it.fecha_movim, it.concep ;

begin

delete from tt_consulta_asistencia_trab ;

--  Lectura del maestro de trabajadores
For rc_mae in c_maestro loop

  ls_cod_trabajador := rc_mae.cod_trabajador ;
  ls_cod_carnet     := rc_mae.carnet_trabaj ;
  ls_cod_cencos     := rc_mae.cencos ;
  ls_cod_seccion    := rc_mae.cod_seccion ;
  ls_cod_carnet     := nvl(ls_cod_carnet,'9999999999') ;
  ls_cod_seccion    := nvl(ls_cod_seccion,'120') ;
  ls_cod_cencos     := nvl(ls_cod_cencos,'8370') ;
  ls_cod_area       := rc_mae.cod_area ;
  ls_nombres        := usf_nombre_trabajador(ls_cod_trabajador) ;
  
  --  Determina descripcion de area, seccion y centro de costo
  If ls_cod_area  is not null Then
    Select a.desc_area
    into ls_desc_area
    from area a
    where a.cod_area = ls_cod_area ;
  End if ;
  ls_desc_area := nvl(ls_desc_area,' ') ;
  If ls_cod_seccion  is not null Then
    Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_area = ls_cod_area and s.cod_seccion = ls_cod_seccion ;
  End if ;
  ls_desc_seccion := nvl(ls_desc_seccion,' ') ;
  If ls_cod_cencos is not null then
    Select cc.desc_cencos
    into ls_desc_cencos
    from centros_costo cc
    where cc.cencos = ls_cod_cencos ;
  End if ;
  ls_desc_cencos := nvl(ls_desc_cencos,' ') ;

  --  Lectura de marcaciones diarias por trabajador
  For rc_con in c_marcacion_consolidada loop
  
    ld_fecha_marcacion    := rc_con.fecha_marcacion ;  
    ln_r_min_tardanza     := rc_con.min_tardanza ;
    ln_r_hor_inasistencia := rc_con.hora_inasistencia ;
    ln_r_hor_sobretiempo  := rc_con.hora_sobretiempo ;
    ln_r_hor_trabajadas   := rc_con.hora_trabajada ;
    ln_r_min_tardanza     := nvl(ln_r_min_tardanza,0) ;
    ln_r_hor_inasistencia := nvl(ln_r_hor_inasistencia,0) ;
    ln_r_hor_sobretiempo  := nvl(ln_r_hor_sobretiempo,0) ;
    ln_r_hor_trabajadas   := nvl(ln_r_hor_trabajadas,0) ;

    Insert into tt_consulta_asistencia_trab (
      cod_area, desc_area, cod_seccion, desc_seccion,
      cod_cencos, desc_cencos, cod_trabajador, nombres,
      cod_carnet, fecha_marcacion, r_min_tardanza, r_hor_inasistencia,
      r_hor_sobretiempo, r_hor_trabajadas, flag )
    Values (
      ls_cod_area, ls_desc_area, ls_cod_seccion, ls_desc_seccion,
      ls_cod_cencos, ls_desc_cencos, ls_cod_trabajador, ls_nombres,
      ls_cod_carnet, ld_fecha_marcacion, ln_r_min_tardanza, ln_r_hor_inasistencia,
      ln_r_hor_sobretiempo, ln_r_hor_trabajadas, 0 ) ;

    --  Lectura del movimiento digitado por el usuario
    For rc_inc in c_incidencia loop
  
      ld_fecha_digitacion := rc_inc.fecha_movim ;
      ls_concepto         := rc_inc.concep ;
      ld_fecha_desde      := rc_inc.fecha_inicio ;
      ld_fecha_hasta      := rc_inc.fecha_fin ;
      ln_nro_horas        := rc_inc.nro_horas ;
      ln_nro_dias         := rc_inc.nro_dias ;
      ln_nro_horas        := nvl(ln_nro_horas,0) ;
      ln_nro_dias         := nvl(ln_nro_dias,0) ;

      Select c.desc_breve
        into ls_desc_concepto
        from concepto c
        where c.concep = ls_concepto ;
      ls_desc_concepto := nvl(ls_desc_concepto,' ') ;
  
      Insert into tt_consulta_asistencia_trab (
        cod_area, desc_area, cod_seccion, desc_seccion,
        cod_cencos, desc_cencos, cod_trabajador, nombres,
        cod_carnet, fecha_digitacion, concepto, desc_concepto,
        fecha_desde, fecha_hasta, nro_horas, nro_dias, flag )
      Values (
        ls_cod_area, ls_desc_area, ls_cod_seccion, ls_desc_seccion,
        ls_cod_cencos, ls_desc_cencos, ls_cod_trabajador, ls_nombres,
        ls_cod_carnet, ld_fecha_digitacion, ls_concepto, ls_desc_concepto,
        ld_fecha_desde, ld_fecha_hasta, ln_nro_horas, ln_nro_dias, 1 ) ;

    End loop ;
    
  End loop ;

End loop ;
                     
End usp_consulta_asistencia_tra ;
/
