create or replace procedure usp_asi_marcacion_consolidada (
  ad_fec_proceso   in marcacion_reloj_asistencia.fecha_marcacion%type )
  is

ls_carnet              carnet_trabajador.carnet_trabajador%type ;
ls_turno               turno.turno%type ;
ln_fecha_marcacion     number(4,2) ;
ln_tardanza            marcacion_consolidada_diaria.min_tardanza%type ;
ln_horas_inasist       marcacion_consolidada_diaria.hora_inasistencia%type ;
ln_horas_sobreti       marcacion_consolidada_diaria.hora_sobretiempo%type ;
ln_horas_trabaja       marcacion_consolidada_diaria.hora_trabajada%type ;
ln_nro_marcacion       marcacion_consolidada_diaria.nro_marcaciones%type ;

ls_codtra              maestro.cod_trabajador%type ;
ln_dia_feriado         number(15) ;
ln_dia_descanso        number(15) ;
ls_nombre_dia          char(9) ;
ln_dia_semana          number(2) ;
ln_nro_dia             number(2) ;

ln_nro_ano             semanas.ano%type ;
ln_nro_semana          semanas.semana%type ;
ld_fec_proceso         date ;

ls_turno_reloj         turno.turno%type ;
ls_turno_rotativo      turno.turno%type ;
ld_hora_ini_nor        date ;
ld_hora_fin_nor        date ;
ld_refr_ini_nor        date ;
ld_refr_fin_nor        date ;
ld_hora_ini_sab        date ;
ld_hora_fin_sab        date ;
ld_refr_ini_sab        date ;
ld_refr_fin_sab        date ;
ld_hora_ini_dom        date ;
ld_hora_fin_dom        date ;
ln_marc_dia_nor        number(1) ;
ln_marc_dia_sab        number(1) ;
ln_marc_dia_dom        number(1) ;
ln_tolerancia          number(2) ;
ln_min_tolerancia      number(4,2) ;

ln_hora_ini_nor        number(4,2) ;
ln_hora_fin_nor        number(4,2) ;
ln_refr_ini_nor        number(4,2) ;
ln_refr_fin_nor        number(4,2) ;
ln_hora_ini_sab        number(4,2) ;
ln_hora_fin_sab        number(4,2) ;
ln_refr_ini_sab        number(4,2) ;
ln_refr_fin_sab        number(4,2) ;
ln_hora_ini_dom        number(4,2) ;
ln_hora_fin_dom        number(4,2) ;
ln_diferencia          number(4,2) ;
ln_veces               number(15) ;
ln_contador            number(15) ;
ln_no_faltas           number(15) ;
ln_sw                  number(1) ;
ln_imp_control         number(2,2) ;
ls_importe             varchar2(20) ;
ls_flag_activo         char(1) ;
ln_control_falta       integer ;

--  Cursor del personal que marca asistencia en el reloj
Cursor c_maestro is
  Select m.cod_trabajador, m.carnet_trabaj, m.turno
  from  maestro m, carnet_trabajador ct
  where (m.carnet_trabaj = ct.carnet_trabajador) and
        (ct.flag_estado = '1') and
         m.flag_estado = '1' and       
         m.flag_marca_reloj = '1' and
         m.turno <> ' ' 
  order by m.cod_trabajador ;

--  Cursor de lectura diaria del reloj
Cursor c_reloj is
  Select mra.carnet_trabajador, mra.fecha_marcacion, mra.nro_reloj
  from  marcacion_reloj_asistencia mra
  where mra.carnet_trabajador = ls_carnet and
        to_char(mra.fecha_marcacion,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY')
  order by mra.fecha_marcacion, mra.carnet_trabajador ;

begin

delete from marcacion_consolidada_diaria mcd
  where to_char(mcd.fecha_marcacion,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') ;

--  Borra informacion por 2401 - FALTA SIN PERMISO y 2405 - TARDANZAS
delete from incidencia_trabajador i
  where to_char(i.fecha_movim,'DD/MM/YYYY') = to_char(ad_fec_proceso,'DD/MM/YYYY') and
        i.cod_usr = 'Work' and
        (i.concep = '2401' or i.concep = '2405') ;

ls_nombre_dia := to_char(ad_fec_proceso,'DAY');
ln_nro_dia    := to_char(ad_fec_proceso,'D');

--  Verifica si es dia feriado
ln_dia_feriado := 0 ;
Select count(*)
  into ln_dia_feriado
  from calendario_feriado cf
  where cf.mes = to_number(to_char(ad_fec_proceso,'MM')) and
        cf.dia = to_number(to_char(ad_fec_proceso,'DD')) ;
ln_dia_feriado := nvl(ln_dia_feriado,0) ;

--  Realiza lectura del maestro
For rc_mae in c_maestro Loop

  ls_codtra := rc_mae.cod_trabajador ;
  ls_carnet := rc_mae.carnet_trabaj ;
  ls_turno  := rc_mae.turno ;

  ln_marc_dia_nor := 0 ; ln_marc_dia_sab := 0 ;
  ln_marc_dia_dom := 0 ; ln_tolerancia   := 0 ;
  ln_hora_ini_nor := 0 ; ln_hora_fin_nor := 0 ;
  ln_refr_ini_nor := 0 ; ln_refr_fin_nor := 0 ;
  ln_hora_ini_sab := 0 ; ln_hora_fin_sab := 0 ;
  ln_refr_ini_sab := 0 ; ln_refr_fin_sab := 0 ;
  ln_hora_ini_dom := 0 ; ln_hora_fin_dom := 0 ;
  ls_turno_reloj  := ' ' ;

  --  Proceso para el personal de turno normal
  If substr(ls_turno,1,2) = 'TN' then

    Select t.turno, t.hora_inicio_norm, t.hora_final_norm,
           t.refrig_inicio_norm, t.refrig_final_norm, t.hora_inicio_sab,
           t.hora_final_sab, t.refrig_inicio_sab, t.refrig_final_sab,
           t.hora_inicio_dom, t.hora_final_dom, t.marc_diaria_norm,
           t.marc_diaria_sab, t.marc_diaria_dom, t.tolerancia
      into ls_turno_reloj,  ld_hora_ini_nor, ld_hora_fin_nor,
           ld_refr_ini_nor, ld_refr_fin_nor, ld_hora_ini_sab,
           ld_hora_fin_sab, ld_refr_ini_sab, ld_refr_fin_sab,
           ld_hora_ini_dom, ld_hora_fin_dom, ln_marc_dia_nor,
           ln_marc_dia_sab, ln_marc_dia_dom, ln_tolerancia
      from turno t
      where t.turno = ls_turno ;
    ln_hora_ini_nor := to_number(to_char(ld_hora_ini_nor,'HH24') || '.' || to_char(ld_hora_ini_nor,'MI'),'99.99') ;
    ln_hora_fin_nor := to_number(to_char(ld_hora_fin_nor,'HH24') || '.' || to_char(ld_hora_fin_nor,'MI'),'99.99') ;
    ln_refr_ini_nor := to_number(to_char(ld_refr_ini_nor,'HH24') || '.' || to_char(ld_refr_ini_nor,'MI'),'99.99') ;
    ln_refr_fin_nor := to_number(to_char(ld_refr_fin_nor,'HH24') || '.' || to_char(ld_refr_fin_nor,'MI'),'99.99') ;
    ln_hora_ini_sab := to_number(to_char(ld_hora_ini_sab,'HH24') || '.' || to_char(ld_hora_ini_sab,'MI'),'99.99') ;
    ln_hora_fin_sab := to_number(to_char(ld_hora_fin_sab,'HH24') || '.' || to_char(ld_hora_fin_sab,'MI'),'99.99') ;
    ln_refr_ini_sab := to_number(to_char(ld_refr_ini_sab,'HH24') || '.' || to_char(ld_refr_ini_sab,'MI'),'99.99') ;
    ln_refr_fin_sab := to_number(to_char(ld_refr_fin_sab,'HH24') || '.' || to_char(ld_refr_fin_sab,'MI'),'99.99') ;
    ln_hora_ini_dom := to_number(to_char(ld_hora_ini_dom,'HH24') || '.' || to_char(ld_hora_ini_dom,'MI'),'99.99') ;
    ln_hora_fin_dom := to_number(to_char(ld_hora_fin_dom,'HH24') || '.' || to_char(ld_hora_fin_dom,'MI'),'99.99') ;
    ln_marc_dia_nor := nvl(ln_marc_dia_nor,0) ;
    ln_marc_dia_sab := nvl(ln_marc_dia_sab,0) ;
    ln_marc_dia_dom := nvl(ln_marc_dia_dom,0) ;
    ln_tolerancia   := nvl(ln_tolerancia,0) ;

  End if ;
  
  --  Proceso para el personal de turno rotativo
  If substr(ls_turno,1,2) = 'TR' then

    --  Identifica numero de semana
    ld_fec_proceso := ad_fec_proceso ;
    If ln_nro_dia = 01 then
      Select s.ano, s.semana
        into ln_nro_ano, ln_nro_semana
        from semanas s
        where s.fecha_inicio = ad_fec_proceso ;
    Else
      For x in 1 .. 7 Loop
        ld_fec_proceso := to_date(ld_fec_proceso) - 1 ;
        ln_dia_semana := to_char(ld_fec_proceso,'D');
        If ln_dia_semana = 01 then
          Select s.ano, s.semana
            into ln_nro_ano, ln_nro_semana
            from semanas s
            where s.fecha_inicio = ld_fec_proceso ;
        End if ;
      End loop ;
    End if ;
    ln_nro_ano := nvl(ln_nro_ano,0) ; ln_nro_semana := nvl(ln_nro_semana,0) ;

    ln_dia_descanso := 0 ;
    Select count(*)
      into ln_dia_descanso
      from programacion_turnos p
      where p.carnet_trabajador = ls_carnet and
            p.fecha_descanso = ad_fec_proceso ;
    ln_dia_descanso := nvl(ln_dia_descanso,0) ;

    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from programacion_turnos pt
      where pt.carnet_trabajador = ls_carnet and
            pt.ano = ln_nro_ano and
            pt.semana = ln_nro_semana ;
    ln_contador := nvl(ln_contador,0) ;

    If ln_contador > 0 then
    
      Select pt.turno
        into ls_turno_rotativo
        from programacion_turnos pt
        where pt.carnet_trabajador = ls_carnet and
              pt.ano = ln_nro_ano and
              pt.semana = ln_nro_semana ;
      ls_turno_rotativo := nvl(ls_turno_rotativo,' ') ;

      Select t.turno, t.hora_inicio_norm, t.hora_final_norm,
             t.refrig_inicio_norm, t.refrig_final_norm, t.hora_inicio_sab,
             t.hora_final_sab, t.refrig_inicio_sab, t.refrig_final_sab,
             t.hora_inicio_dom, t.hora_final_dom, t.marc_diaria_norm,
             t.marc_diaria_sab, t.marc_diaria_dom, t.tolerancia
        into ls_turno_reloj,  ld_hora_ini_nor, ld_hora_fin_nor,
             ld_refr_ini_nor, ld_refr_fin_nor, ld_hora_ini_sab,
             ld_hora_fin_sab, ld_refr_ini_sab, ld_refr_fin_sab,
             ld_hora_ini_dom, ld_hora_fin_dom, ln_marc_dia_nor,
             ln_marc_dia_sab, ln_marc_dia_dom, ln_tolerancia
        from turno t
        where t.turno = ls_turno_rotativo ;
      ln_hora_ini_nor := to_number(to_char(ld_hora_ini_nor,'HH24') || '.' || to_char(ld_hora_ini_nor,'MI'),'99.99') ;
      ln_hora_fin_nor := to_number(to_char(ld_hora_fin_nor,'HH24') || '.' || to_char(ld_hora_fin_nor,'MI'),'99.99') ;
      ln_refr_ini_nor := to_number(to_char(ld_refr_ini_nor,'HH24') || '.' || to_char(ld_refr_ini_nor,'MI'),'99.99') ;
      ln_refr_fin_nor := to_number(to_char(ld_refr_fin_nor,'HH24') || '.' || to_char(ld_refr_fin_nor,'MI'),'99.99') ;
      ln_hora_ini_sab := to_number(to_char(ld_hora_ini_sab,'HH24') || '.' || to_char(ld_hora_ini_sab,'MI'),'99.99') ;
      ln_hora_fin_sab := to_number(to_char(ld_hora_fin_sab,'HH24') || '.' || to_char(ld_hora_fin_sab,'MI'),'99.99') ;
      ln_refr_ini_sab := to_number(to_char(ld_refr_ini_sab,'HH24') || '.' || to_char(ld_refr_ini_sab,'MI'),'99.99') ;
      ln_refr_fin_sab := to_number(to_char(ld_refr_fin_sab,'HH24') || '.' || to_char(ld_refr_fin_sab,'MI'),'99.99') ;
      ln_hora_ini_dom := to_number(to_char(ld_hora_ini_dom,'HH24') || '.' || to_char(ld_hora_ini_dom,'MI'),'99.99') ;
      ln_hora_fin_dom := to_number(to_char(ld_hora_fin_dom,'HH24') || '.' || to_char(ld_hora_fin_dom,'MI'),'99.99') ;
      ln_marc_dia_nor := nvl(ln_marc_dia_nor,0) ;
      ln_marc_dia_sab := nvl(ln_marc_dia_sab,0) ;
      ln_marc_dia_dom := nvl(ln_marc_dia_dom,0) ;
      ln_tolerancia   := nvl(ln_tolerancia,0) ;

    End if ;
    
  End if ;
  
  --  Determina numero de marcaciones por cada horario
  ln_nro_marcacion := 0 ; ln_tardanza := 0 ;
  For rc_rel in c_reloj Loop
    ln_nro_marcacion := ln_nro_marcacion + 1 ;
  End loop;
  ln_nro_marcacion := nvl(ln_nro_marcacion,0) ;

  --  Verifica si el trabajador tiene vacaciones, asignacion vacacional,
  --  enfermedad patronal, reembolso ipss, licencia, licencia sindical,
  --  comision de servicios, descanso sustitutorio, subsidio lactancia,
  --  permiso particular, permiso sin goce
  ln_no_faltas := 0 ;
  Select count(*)
    into ln_no_faltas 
    from incidencia_trabajador it
    where (it.cod_trabajador = ls_codtra and
          it.concep = '1413' and  --  Vacaciones
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '1414' and  --  Asignacion Vacacional
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '1415' and  --  Enfermedad Patronal
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '2407' and  --  Reembolso I.P.S.S.
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '2408' and  --  Licencia
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '1422' and  --  Licencia Sindical
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '1423' and  --  Comision de Servicios
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '1424' and  --  Descanso Sustitutorio
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '1421' and  --  Subsidio Lactancia
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '2406' and  --  Permiso Particular
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) or
          (it.cod_trabajador = ls_codtra and
          it.concep = '2402' and  --  Permiso sin Goce
          ad_fec_proceso between it.fecha_inicio and it.fecha_fin) ;
  ln_no_faltas := nvl(ln_no_faltas,0) ;

  ln_min_tolerancia := 0 ;
  ln_min_tolerancia := ln_tolerancia / 100 ;

  --  Procesa informacion para trabajadores de turno NORMAL
  If substr(ls_turno_reloj,1,2) = 'TN' then

    If (ln_nro_dia = 02 or ln_nro_dia = 03 or ln_nro_dia = 04 or
       ln_nro_dia = 05 or ln_nro_dia = 06 ) and
       (ln_nro_marcacion = ln_marc_dia_nor) then
      ln_horas_inasist := 0 ; ln_tardanza      := 0 ; ln_veces := 0 ;
      ln_horas_trabaja := 0 ; ln_horas_sobreti := 0 ; ln_sw    := 0 ;

      For rc_rel in c_reloj Loop
        ln_fecha_marcacion := to_number(to_char(rc_rel.fecha_marcacion,'HH24') || '.' || to_char(rc_rel.fecha_marcacion,'MI'),'99.99') ;
        ln_diferencia := 0 ;
        ln_veces := ln_veces + 1 ;
        If ln_veces = 1 or ln_veces = 3 then
          ln_sw := 0 ;
        End if ;
        --  Primera marcacion
        If ln_veces = 1 then
          If ln_fecha_marcacion <= ln_hora_ini_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_ini_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_ini_nor ;
          End if ;
          If ln_diferencia > 0 then
            If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
              ln_tardanza := ln_tardanza + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + (((ln_refr_ini_nor + 0.60) -1) - ln_fecha_marcacion) ;
            Else
              ln_horas_inasist := ln_horas_inasist + (ln_refr_ini_nor - ln_hora_ini_nor) ;
              ln_sw := 1 ;
            End if ;
          Else
            ln_horas_trabaja := ln_horas_trabaja + (((ln_refr_ini_nor + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        --  Segunda marcacion
        Elsif ln_veces = 2 and ln_sw = 0 then
          If ln_fecha_marcacion <= ln_refr_ini_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_refr_ini_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_refr_ini_nor ;
          End if ;
          If ln_diferencia > 0 then
            ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
            ln_horas_trabaja := ln_horas_trabaja + ln_diferencia ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
            End if ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
            End if ;
          Else
            ln_horas_inasist := ln_horas_inasist + (((ln_refr_ini_nor + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        --  Tercera marcacion
        Elsif ln_veces = 3 then
          If ln_fecha_marcacion <= ln_refr_fin_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_refr_fin_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_refr_fin_nor ;
          End if ;
          If ln_diferencia > 0 then
            If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
              ln_tardanza := ln_tardanza + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_nor + 0.60) -1) - ln_fecha_marcacion) ;
            Else
              ln_horas_inasist := ln_horas_inasist + (ln_hora_fin_nor - ln_refr_fin_nor) ;
              ln_sw := 1 ;
            End if ;
          Else
            ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_nor + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        --  Cuarta marcacion
        Elsif ln_veces = 4 and ln_sw = 0 then
          If ln_fecha_marcacion <= ln_hora_fin_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_fin_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_fin_nor ;
          End if ;
          If ln_diferencia > 0 then
            ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
            ln_horas_trabaja := ln_horas_trabaja + ln_diferencia ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
            End if ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
            End if ;
          Else
            ln_horas_inasist := ln_horas_inasist + (((ln_hora_fin_nor + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        End if ;     
      End loop ;
  
    Elsif (ln_nro_dia = 07) and (ln_nro_marcacion = ln_marc_dia_sab) then
      ln_horas_inasist := 0 ; ln_tardanza      := 0 ; ln_veces := 0 ;
      ln_horas_trabaja := 0 ; ln_horas_sobreti := 0 ; ln_sw    := 0 ;

      For rc_rel in c_reloj Loop
        ln_fecha_marcacion := to_number(to_char(rc_rel.fecha_marcacion,'HH24') || '.' || to_char(rc_rel.fecha_marcacion,'MI'),'99.99') ;
        ln_diferencia := 0 ;
        ln_veces := ln_veces + 1 ;
        If ln_veces = 1 or ln_veces = 3 then
          ln_sw := 0 ;
        End if ;
        --  Primera marcacion para dos marcaciones
        If ln_nro_marcacion = 2 then
          If ln_veces = 1 then
            If ln_fecha_marcacion <= ln_hora_ini_sab then
              ln_diferencia := ln_fecha_marcacion - ((ln_hora_ini_sab + 0.60) -1) ;
            Else
              ln_diferencia := ln_fecha_marcacion - ln_hora_ini_sab ;
            End if ;
            If ln_diferencia > 0 then
              If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
                ln_tardanza := ln_tardanza + ln_diferencia ;
                ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_sab + 0.60) -1) - ln_fecha_marcacion) ;
              Else
                ln_horas_inasist := ln_horas_inasist + (ln_hora_fin_sab - ln_hora_ini_sab) ;
                ln_sw := 1 ;
              End if ;
            Else
              ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_sab + 0.60) -1) - ln_fecha_marcacion) ;
            End if ;
          --  Segunda marcacion para dos marcaciones
          Elsif ln_veces = 2 and ln_sw = 0 then
            If ln_fecha_marcacion <= ln_hora_fin_sab then
              ln_diferencia := ln_fecha_marcacion - ((ln_hora_fin_sab + 0.60) -1) ;
            Else
              ln_diferencia := ln_fecha_marcacion - ln_hora_fin_sab ;
            End if ;
            If ln_diferencia > 0 then
              ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + ln_diferencia ;
              ln_imp_control := 0 ; ls_importe := ' ' ;
              ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
              ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
              If ln_imp_control >= 0.60 then
                ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
              End if ;
              ln_imp_control := 0 ; ls_importe := ' ' ;
              ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
              ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
              If ln_imp_control >= 0.60 then
                ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
              End if ;
            Else
              ln_horas_inasist := ln_horas_inasist + (((ln_hora_fin_sab + 0.60) -1) - ln_fecha_marcacion) ;
            End if ;
          End if ;     
        End if ;     
        If ln_nro_marcacion = 4 then
          --  Primera marcacion para cuatro marcaciones
          If ln_veces = 1 then
            If ln_fecha_marcacion <= ln_hora_ini_sab then
              ln_diferencia := ln_fecha_marcacion - ((ln_hora_ini_sab + 0.60) -1) ;
            Else
              ln_diferencia := ln_fecha_marcacion - ln_hora_ini_sab ;
            End if ;
            If ln_diferencia > 0 then
              If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
                ln_tardanza := ln_tardanza + ln_diferencia ;
                ln_horas_trabaja := ln_horas_trabaja + (((ln_refr_ini_sab + 0.60) -1) - ln_fecha_marcacion) ;
              Else
                ln_horas_inasist := ln_horas_inasist + (ln_refr_ini_sab - ln_hora_ini_sab) ;
                ln_sw := 1 ;
              End if ;
            Else
              ln_horas_trabaja := ln_horas_trabaja + (((ln_refr_ini_sab + 0.60) -1) - ln_fecha_marcacion) ;
            End if ;
          --  Segunda marcacion para cuatro marcaciones
          Elsif ln_veces = 2 and ln_sw = 0 then
            If ln_fecha_marcacion <= ln_refr_ini_sab then
              ln_diferencia := ln_fecha_marcacion - ((ln_refr_ini_sab + 0.60) -1) ;
            Else
              ln_diferencia := ln_fecha_marcacion - ln_refr_ini_sab ;
            End if ;
            If ln_diferencia > 0 then
              ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + ln_diferencia ;
              ln_imp_control := 0 ; ls_importe := ' ' ;
              ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
              ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
              If ln_imp_control >= 0.60 then
                ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
              End if ;
              ln_imp_control := 0 ; ls_importe := ' ' ;
              ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
              ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
              If ln_imp_control >= 0.60 then
                ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
              End if ;
            Else
              ln_horas_inasist := ln_horas_inasist + (((ln_refr_ini_sab + 0.60) -1) - ln_fecha_marcacion) ;
            End if ;
          --  Tercera marcacion para cuatro marcaciones
          Elsif ln_veces = 3 then
            If ln_fecha_marcacion <= ln_refr_fin_sab then
              ln_diferencia := ln_fecha_marcacion - ((ln_refr_fin_sab + 0.60) -1) ;
            Else
              ln_diferencia := ln_fecha_marcacion - ln_refr_fin_sab ;
            End if ;
            If ln_diferencia > 0 then
              If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
                ln_tardanza := ln_tardanza + ln_diferencia ;
                ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_sab + 0.60) -1) - ln_fecha_marcacion) ;
              Else
                ln_horas_inasist := ln_horas_inasist + (ln_hora_fin_sab - ln_refr_fin_sab) ;
                ln_sw := 1 ;
              End if ;
            Else
              ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_sab + 0.60) -1) - ln_fecha_marcacion) ;
            End if ;
          --  Cuarta marcacion para cuatro marcaciones
          Elsif ln_veces = 4 and ln_sw = 0 then
            If ln_fecha_marcacion <= ln_hora_fin_sab then
              ln_diferencia := ln_fecha_marcacion - ((ln_hora_fin_sab + 0.60) -1) ;
            Else
              ln_diferencia := ln_fecha_marcacion - ln_hora_fin_sab ;
            End if ;
            If ln_diferencia > 0 then
              ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + ln_diferencia ;
              ln_imp_control := 0 ; ls_importe := ' ' ;
              ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
              ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
              If ln_imp_control >= 0.60 then
                ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
              End if ;
              ln_imp_control := 0 ; ls_importe := ' ' ;
              ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
              ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
              If ln_imp_control >= 0.60 then
                ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
              End if ;
            Else
              ln_horas_inasist := ln_horas_inasist + (((ln_hora_fin_sab + 0.60) -1) - ln_fecha_marcacion) ;
            End if ;
          End if ;     
        End if ;
      End loop ;

    Elsif (ln_nro_dia = 01) and (ln_nro_marcacion = ln_marc_dia_dom) then
      ln_horas_inasist := 0 ; ln_tardanza      := 0 ; ln_veces := 0 ;
      ln_horas_trabaja := 0 ; ln_horas_sobreti := 0 ; ln_sw    := 0 ;

      For rc_rel in c_reloj Loop
        ln_fecha_marcacion := to_number(to_char(rc_rel.fecha_marcacion,'HH24') || '.' || to_char(rc_rel.fecha_marcacion,'MI'),'99.99') ;
        ln_diferencia := 0 ;
        ln_veces := ln_veces + 1 ;
        If ln_veces = 1 then
          ln_sw := 0 ;
        End if ;
        --  Primera marcacion
        If ln_veces = 1 then
          If ln_fecha_marcacion <= ln_hora_ini_dom then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_ini_dom + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_ini_dom ;
          End if ;
          If ln_diferencia > 0 then
            If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
              ln_tardanza := ln_tardanza + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_dom + 0.60) -1) - ln_fecha_marcacion) ;
            Else
              ln_horas_inasist := ln_horas_inasist + (ln_hora_fin_dom - ln_hora_ini_dom) ;
              ln_sw := 1 ;
            End if ;
          Else
            ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_dom + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        --  Segunda marcacion
        Elsif ln_veces = 2 and ln_sw = 0 then
          If ln_fecha_marcacion <= ln_hora_fin_dom then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_fin_dom + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_fin_dom ;
          End if ;
          If ln_diferencia > 0 then
            ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
            ln_horas_trabaja := ln_horas_trabaja + ln_diferencia ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
            End if ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
            End if ;
          Else
            ln_horas_inasist := ln_horas_inasist + (((ln_hora_fin_dom + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        End if ;     
      End loop ;

    End if ;

  End if;

  --  Procesa informacion para trabajadores de turno ROTATIVO
  If substr(ls_turno_reloj,1,2) = 'TR' then

    If (ls_turno_reloj = 'TR01' or ls_turno_reloj = 'TR02') 
       and ln_nro_marcacion = 2 then
      ln_horas_inasist := 0 ; ln_tardanza      := 0 ; ln_veces := 0 ;
      ln_horas_trabaja := 0 ; ln_horas_sobreti := 0 ; ln_sw    := 0 ;

      For rc_rel in c_reloj Loop
        ln_fecha_marcacion := to_number(to_char(rc_rel.fecha_marcacion,'HH24') || '.' || to_char(rc_rel.fecha_marcacion,'MI'),'99.99') ;
        ln_diferencia := 0 ;
        ln_veces := ln_veces + 1 ;
        If ln_veces = 1 then
          ln_sw := 0 ;
        End if ;
        --  Primera marcacion
        If ln_veces = 1 then
          If ln_fecha_marcacion <= ln_hora_ini_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_ini_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_ini_nor ;
          End if ;
          If ln_diferencia > 0 then
            If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
              ln_tardanza := ln_tardanza + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_nor + 0.60) -1) - ln_fecha_marcacion) ;
            Else
              ln_horas_inasist := ln_horas_inasist + (ln_hora_fin_nor - ln_hora_ini_nor) ;
              ln_sw := 1 ;
            End if ;
          Else
            ln_horas_trabaja := ln_horas_trabaja + (((ln_hora_fin_nor + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        --  Segunda marcacion
        Elsif ln_veces = 2 and ln_sw = 0 then
          If ln_fecha_marcacion <= ln_hora_fin_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_fin_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_fin_nor ;
          End if ;
          If ln_diferencia > 0 then
            ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
            ln_horas_trabaja := ln_horas_trabaja + ln_diferencia ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
            End if ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
            End if ;
          Else
            ln_horas_inasist := ln_horas_inasist + (((ln_hora_fin_nor + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        End if ;     
      End loop ;
  
    Elsif ls_turno_reloj = 'TR03' and ln_nro_marcacion = 2 then
      ln_horas_inasist := 0 ; ln_tardanza      := 0 ; ln_veces := 0 ;
      ln_horas_trabaja := 0 ; ln_horas_sobreti := 0 ; 

      For rc_rel in c_reloj Loop
        ln_fecha_marcacion := to_number(to_char(rc_rel.fecha_marcacion,'HH24') || '.' || to_char(rc_rel.fecha_marcacion,'MI'),'99.99') ;
        ln_diferencia := 0 ;
        ln_veces := ln_veces + 1 ;
        --  Primera marcacion
        If ln_veces = 1 then
          If ln_fecha_marcacion <= ln_hora_fin_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_fin_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_fin_nor ;
          End if ;
          If ln_diferencia > 0 then
            ln_horas_sobreti := ln_horas_sobreti + ln_diferencia ;
            ln_horas_trabaja := ln_horas_trabaja + ln_fecha_marcacion ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_sobreti,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_sobreti := ((ln_horas_sobreti + 1) - 0.60) ;
            End if ;
            ln_imp_control := 0 ; ls_importe := ' ' ;
            ls_importe := to_char(ln_horas_trabaja,'999,999,999,999.99') ;
            ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
            If ln_imp_control >= 0.60 then
              ln_horas_trabaja := ((ln_horas_trabaja + 1) - 0.60) ;
            End if ;
          Else
            ln_horas_inasist := ln_horas_inasist + (((ln_hora_fin_nor + 0.60) -1) - ln_fecha_marcacion) ;
          End if ;
        --  Segunda marcacion
        Elsif ln_veces = 2 then
          If ln_fecha_marcacion <= ln_hora_ini_nor then
            ln_diferencia := ln_fecha_marcacion - ((ln_hora_ini_nor + 0.60) -1) ;
          Else
            ln_diferencia := ln_fecha_marcacion - ln_hora_ini_nor ;
          End if ;
          If ln_diferencia > 0 then
            If ln_diferencia > 0 and ln_diferencia <= ln_min_tolerancia then
              ln_tardanza := ln_tardanza + ln_diferencia ;
              ln_horas_trabaja := ln_horas_trabaja + (23.60 - ln_fecha_marcacion) ;
            Else
              ln_horas_inasist := ln_horas_inasist + 08.00 ;
            End if ;
          Else
            ln_horas_trabaja := ln_horas_trabaja + (23.60 - ln_fecha_marcacion) ;
          End if ;
        End if ;     
      End loop ;
  
    End if ;

  End if;
  
  ln_tardanza      := nvl(ln_tardanza,0) ;
  ln_horas_inasist := nvl(ln_horas_inasist,0) ;
  ln_horas_sobreti := nvl(ln_horas_sobreti,0) ;
  ln_horas_trabaja := nvl(ln_horas_trabaja,0) ;
  
  --  Inserta informacion consolidada diaria por trabajador  
  If ln_nro_marcacion > 0 and ls_turno_reloj <> ' ' then
    Insert into marcacion_consolidada_diaria (
      carnet_trabajador, turno, fecha_marcacion,
      min_tardanza, hora_inasistencia, hora_sobretiempo,
      hora_trabajada, nro_marcaciones )
    Values ( 
      ls_carnet, ls_turno_reloj, ad_fec_proceso,
      ln_tardanza, ln_horas_inasist, ln_horas_sobreti,
      ln_horas_trabaja, ln_nro_marcacion ) ;     
  End if ;  
  
  --  Inserta registro por TARDANZA
  If ln_tardanza > 0 then
    Insert into incidencia_trabajador (
      cod_trabajador, fecha_movim, concep,
      fecha_inicio, fecha_fin, nro_horas,
      nro_dias, flag_conformidad, observacion, cod_usr )
    Values ( 
      ls_codtra, ad_fec_proceso, '2405',
      ad_fec_proceso, ad_fec_proceso, ln_tardanza,
      0, '0', ' ', 'Work' ) ;
  End if ;  
  
  --  Inserta registro por inasistencia ( FALTA SIN PERMISO )
  ln_control_falta := 0 ;
  If ln_no_faltas = 0 then
    If substr(ls_turno,1,2) = 'TN' then
      If ((ln_nro_dia <> 01) and ln_dia_feriado = 0) and
          ln_nro_marcacion = 0 and ln_marc_dia_sab > 0 then
        Insert into incidencia_trabajador (
          cod_trabajador, fecha_movim, concep,
          fecha_inicio, fecha_fin, nro_horas,
          nro_dias, flag_conformidad, observacion, cod_usr )
        Values ( 
          ls_codtra, ad_fec_proceso, '2401',
          ad_fec_proceso, ad_fec_proceso, 0,
          1, '0', ' ', 'Work' ) ;
        ln_control_falta := 1 ;
      End if ;
      If ((ln_nro_dia > 01 and ln_nro_dia < 07) and ln_dia_feriado = 0) and
          ln_nro_marcacion = 0 and ln_control_falta = 0 then
        Insert into incidencia_trabajador (
          cod_trabajador, fecha_movim, concep,
          fecha_inicio, fecha_fin, nro_horas,
          nro_dias, flag_conformidad, observacion, cod_usr )
        Values ( 
          ls_codtra, ad_fec_proceso, '2401',
          ad_fec_proceso, ad_fec_proceso, 0,
          1, '0', ' ', 'Work' ) ;
      End if ;
    End if ;
  
    If substr(ls_turno,1,2) = 'TR' then
      If (ln_dia_descanso = 0 and ln_nro_marcacion = 0) and
         ln_dia_feriado = 0 then
        Insert into incidencia_trabajador (
          cod_trabajador, fecha_movim, concep,
          fecha_inicio, fecha_fin, nro_horas,
          nro_dias, flag_conformidad, observacion, cod_usr )
        Values ( 
          ls_codtra, ad_fec_proceso, '2401',
          ad_fec_proceso, ad_fec_proceso, 0,
          1, '0', ' ', 'Work' ) ;
      End if ;
    End if ;
  End if ;
    
End loop;
    
end usp_asi_marcacion_consolidada ;
/
