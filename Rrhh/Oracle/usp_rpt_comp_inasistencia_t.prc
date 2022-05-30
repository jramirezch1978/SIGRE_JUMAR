create or replace procedure usp_rpt_comp_inasistencia_t
  ( ad_fec_desde        in date,
    ad_fec_hasta        in date,
    as_codigo           in maestro.cod_trabajador%type ) is
  
ls_seccion          maestro.cod_seccion%type ;
ls_cod_area         char(1) ;
ls_desc_seccion     varchar2(40) ;
ls_cencos           maestro.cencos%type ;
ls_desc_cencos      varchar2(40) ;
ls_carnet           carnet_trabajador.carnet_trabajador%type ;
ls_codtra           maestro.cod_trabajador%type ;
ls_tipo_trabajador  maestro.tipo_trabajador%type ;
ls_nombres          varchar2(40) ;
ln_horas_reloj      number(11,2) ;
ld_fecha_digitada   date ;
ls_concepto         concepto.concep%type ;
ls_desc_concepto    varchar2(40) ;
ld_fecha_desde      date ;
ld_fecha_hasta      date ;
ln_dias_digitado    number(11,2) ;
ln_horas_digitado   number(11,2) ;

ln_imp_control      number(2,2) ;
ls_importe          varchar2(20) ;
ln_horas_trabajador  number(11,2) ;

Cursor c_maestro is
  Select m.cod_trabajador, m.carnet_trabaj, m.cod_seccion, m.cod_area, m.cencos
  From maestro m
  Where m.flag_estado = '1' and
        m.flag_marca_reloj = '1' and
        m.cod_trabajador = as_codigo ;
                
Cursor c_consolidado_diario is 
  Select mcd.carnet_trabajador, mcd.fecha_marcacion, mcd.hora_inasistencia
  From marcacion_consolidada_diaria mcd
  Where (to_date(to_char(mcd.fecha_marcacion,'DD/MM/YYYY'),'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')) and
        mcd.carnet_trabajador = ls_carnet and
        mcd.hora_inasistencia > 0 ;
                
Cursor c_incidencias is 
  Select it.cod_trabajador, it.fecha_movim, it.concep,
         it.fecha_inicio, it.fecha_fin, it.nro_horas,
         it.nro_dias
  From incidencia_trabajador it
  Where (to_date(to_char(it.fecha_movim,'DD/MM/YYYY'),'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')) and
        it.cod_trabajador = ls_codtra
  Order by it.cod_trabajador, it.fecha_movim, it.concep ;
  
begin

delete from tt_comp_inasistencia ;

For rc_mae in c_maestro loop

  ls_codtra  := rc_mae.cod_trabajador ;
  ls_carnet  := rc_mae.carnet_trabaj ;
  ls_seccion := rc_mae.cod_seccion ;
  ls_cod_area := rc_mae.cod_area ;
  ls_cencos  := rc_mae.cencos ;
  
  --  Lectura de informacion generada por las marcaciones del reloj
  ln_horas_trabajador := 0 ;
  For rc_con in c_consolidado_diario loop

    ls_carnet      := rc_con.carnet_trabajador ;
    ln_horas_reloj := rc_con.hora_inasistencia ;

    ln_horas_trabajador := ln_horas_trabajador + ln_horas_reloj ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe     := to_char(ln_horas_trabajador,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_horas_trabajador := ((ln_horas_trabajador + 1) - 0.60) ;
    End if ;

  End loop ;

  ls_nombres := usf_nombre_trabajador(ls_codtra) ;
  If ls_seccion  is not null Then
    Select s.desc_seccion
    into ls_desc_seccion
    from seccion s
    where s.cod_area = ls_cod_area and s.cod_seccion = ls_seccion ;
  End if ;
  ls_desc_seccion := nvl(ls_desc_seccion,' ') ;
  If ls_cencos is not null then
    Select cc.desc_cencos
    into ls_desc_cencos
    from centros_costo cc
    where cc.cencos = ls_cencos ;
  End if ;
  ls_desc_cencos := nvl(ls_desc_cencos,' ') ;

  --  Lectura del movimiento digitado
  For rc_inc in c_incidencias loop

    ld_fecha_digitada := rc_inc.fecha_movim ;
    ls_concepto       := rc_inc.concep ;
    ld_fecha_desde    := rc_inc.fecha_inicio ;
    ld_fecha_hasta    := rc_inc.fecha_fin ;
    ln_horas_digitado := rc_inc.nro_horas ;
    ln_dias_digitado  := rc_inc.nro_dias ;
    
    If substr(ls_concepto,1,2) <> '11' and substr(ls_concepto,1,2) <> '12' then

      Select c.desc_breve
        into ls_desc_concepto
        from concepto c
        where c.concep = ls_concepto ;
      ls_desc_concepto := nvl(ls_desc_concepto,' ') ;

      Insert into tt_comp_inasistencia (
        seccion, desc_seccion, cencos,
        desc_cencos, carnet_trabajador, cod_trabajador,
        nombres, horas_reloj, fecha_digitado,
        concepto, desc_concepto, fecha_desde,
        fecha_hasta, dias_digitado, horas_digitado )
      Values (
        ls_seccion, ls_desc_seccion, ls_cencos,
        ls_desc_cencos, ls_carnet, ls_codtra,
        ls_nombres, ln_horas_trabajador, ld_fecha_digitada,
        ls_concepto, ls_desc_concepto, ld_fecha_desde,
        ld_fecha_hasta, ln_dias_digitado, ln_horas_digitado ) ;

    End if ;
         
  End loop ;

End loop ;

End usp_rpt_comp_inasistencia_t ;
/
