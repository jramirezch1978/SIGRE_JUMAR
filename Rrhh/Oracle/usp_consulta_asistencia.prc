create or replace procedure usp_consulta_asistencia
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
ln_r_min_tardanza         number(11,2) ;
ln_r_hor_inasistencia     number(11,2) ;
ln_r_hor_sobretiempo      number(11,2) ;
ln_r_hor_trabajadas       number(11,2) ;
ln_u_min_tardanza         number(11,2) ;
ln_u_dia_inasistencia     number(11,2) ;
ln_u_hor_inasistencia     number(11,2) ;
ln_u_sob_sem_inglesa      number(11,2) ;
ln_u_sob_normal           number(11,2) ;
ln_u_sob_domingo          number(11,2) ;
ln_u_sob_feriado          number(11,2) ;
ln_u_gua_primera          number(11,2) ;
ln_u_gua_segunda          number(11,2) ;
ln_u_gua_tercera          number(11,2) ;

ls_concepto               concepto.concep%type ;
ln_horas                  number(11,2) ;
ln_dias                   number(11,2) ;

ln_tr_min_tardanza        number(11,2) ;
ln_tr_hor_inasistencia    number(11,2) ;
ln_tr_hor_sobretiempo     number(11,2) ;
ln_tr_hor_trabajadas      number(11,2) ;
ln_total                  number(11,2) ;

ln_imp_control            number(2,2) ;
ls_importe                varchar2(20) ;

--  Cursor de trabajadores del maestro
Cursor c_maestro is 
  Select m.cod_trabajador, m.carnet_trabaj, m.cencos, m.cod_seccion, m.cod_area
  from maestro m
  where m.flag_estado = '1' and
        m.tipo_trabajador = as_tipo_trabajador
  order by m.cod_seccion, m.cencos, m.cod_trabajador ;

--  Cursor de marcaciones consolidadas diarias
Cursor c_marcacion_consolidada is 
  Select mcd.min_tardanza, mcd.hora_inasistencia, mcd.hora_sobretiempo,
         mcd.hora_trabajada
  from marcacion_consolidada_diaria mcd
  where mcd.carnet_trabajador = ls_cod_carnet and
        to_date(to_char(mcd.fecha_marcacion,'DD/MM/YYYY'), 'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'), 'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'), 'DD/MM/YYYY')
  order by mcd.carnet_trabajador, mcd.fecha_marcacion ;

--  Cursor de movimiento digitado por el ususario
Cursor c_incidencia is 
  Select it.concep, it.nro_horas, it.nro_dias
  from incidencia_trabajador it
  where it.cod_trabajador = ls_cod_trabajador and
        to_date(to_char(it.fecha_movim,'DD/MM/YYYY'), 'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'), 'DD/MM/YYYY') and
        to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'), 'DD/MM/YYYY')
  order by it.cod_trabajador, it.fecha_movim, it.concep ;

begin

delete from tt_consulta_asistencia ;

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
  ln_tr_min_tardanza     := 0 ; ln_tr_hor_inasistencia := 0 ;   
  ln_tr_hor_sobretiempo  := 0 ; ln_tr_hor_trabajadas   := 0 ;   
  
  For rc_con in c_marcacion_consolidada loop
  
    ln_r_min_tardanza     := rc_con.min_tardanza ;
    ln_r_hor_inasistencia := rc_con.hora_inasistencia ;
    ln_r_hor_sobretiempo  := rc_con.hora_sobretiempo ;
    ln_r_hor_trabajadas   := rc_con.hora_trabajada ;
    ln_r_min_tardanza     := nvl(ln_r_min_tardanza,0) ;
    ln_r_hor_inasistencia := nvl(ln_r_hor_inasistencia,0) ;
    ln_r_hor_sobretiempo  := nvl(ln_r_hor_sobretiempo,0) ;
    ln_r_hor_trabajadas   := nvl(ln_r_hor_trabajadas,0) ;

    --  Acumula minutos por tardanzas
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ln_tr_min_tardanza := ln_tr_min_tardanza + ln_r_min_tardanza ;
    ls_importe := to_char(ln_tr_min_tardanza,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_tr_min_tardanza := ((ln_tr_min_tardanza + 1) - 0.60) ;
    End if ;
    --  Acumula horas de inasistencias
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ln_tr_hor_inasistencia := ln_tr_hor_inasistencia + ln_r_hor_inasistencia ;
    ls_importe := to_char(ln_tr_hor_inasistencia,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_tr_hor_inasistencia := ((ln_tr_hor_inasistencia + 1) - 0.60) ;
    End if ;
    --  Acumula horas por sobretiempos
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ln_tr_hor_sobretiempo := ln_tr_hor_sobretiempo + ln_r_hor_sobretiempo ;
    ls_importe := to_char(ln_tr_hor_sobretiempo,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_tr_hor_sobretiempo := ((ln_tr_hor_sobretiempo + 1) - 0.60) ;
    End if ;
    --  Acumula horas trabajadas
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ln_tr_hor_trabajadas := ln_tr_hor_trabajadas + ln_r_hor_trabajadas ;
    ls_importe := to_char(ln_tr_hor_trabajadas,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_tr_hor_trabajadas := ((ln_tr_hor_trabajadas + 1) - 0.60) ;
    End if ;
    
  End loop ;
     
  --  Lectura del movimiento digitado por el usuario
  ln_u_dia_inasistencia := 0 ; ln_u_hor_inasistencia := 0 ;
  ln_u_sob_sem_inglesa  := 0 ; ln_u_sob_normal       := 0 ;
  ln_u_sob_domingo      := 0 ; ln_u_sob_feriado      := 0 ;
  ln_u_gua_primera      := 0 ; ln_u_gua_segunda      := 0 ;
  ln_u_gua_tercera      := 0 ; ln_u_min_tardanza     := 0 ;
  
  For rc_inc in c_incidencia loop
  
    ls_concepto := rc_inc.concep ;
    ln_horas    := rc_inc.nro_horas ;
    ln_dias     := rc_inc.nro_dias ;
    ln_horas    := nvl(ln_horas,0) ;
    ln_dias     := nvl(ln_dias,0) ;

    --  Acumula minutos por tardanzas
    If ls_concepto = '2405' then
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ln_u_min_tardanza := ln_u_min_tardanza + ln_horas ;
      ls_importe := to_char(ln_u_min_tardanza,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_u_min_tardanza := ((ln_u_min_tardanza + 1) - 0.60) ;
      End if ;
    End if ;
    --  Acumula dias y horas de inasistencias
    If substr(ls_concepto,1,2) = '24' or ls_concepto = '1401' or
      ls_concepto = '1413' or ls_concepto = '1414' or
      ls_concepto = '1415' or (ls_concepto >= '1421' and ls_concepto <= '1449') and
      ls_concepto <> '2405' then

      If ln_dias > 0 then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_dia_inasistencia := ln_u_dia_inasistencia + ln_dias ;
        ls_importe := to_char(ln_u_dia_inasistencia,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_dia_inasistencia := ((ln_u_dia_inasistencia + 1) - 0.60) ;
        End if ;
      End if ;
      If ln_horas > 0 then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_hor_inasistencia := ln_u_hor_inasistencia + ln_horas ;
        ls_importe := to_char(ln_u_hor_inasistencia,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_hor_inasistencia := ((ln_u_hor_inasistencia + 1) - 0.60) ;
        End if ;
      End if ;

    End if ;
    --  Acumula horas de sobretiempos
    If substr(ls_concepto,1,2) = '11' then

      If  ls_concepto = '1101' then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_sob_sem_inglesa := ln_u_sob_sem_inglesa + ln_horas ;
        ls_importe := to_char(ln_u_sob_sem_inglesa,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_sob_sem_inglesa := ((ln_u_sob_sem_inglesa + 1) - 0.60) ;
        End if ;
      Elsif ls_concepto = '1102' then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_sob_normal := ln_u_sob_normal + ln_horas ;
        ls_importe := to_char(ln_u_sob_normal,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_sob_normal := ((ln_u_sob_normal + 1) - 0.60) ;
        End if ;
      Elsif ls_concepto = '1103' then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_sob_domingo := ln_u_sob_domingo + ln_horas ;
        ls_importe := to_char(ln_u_sob_domingo,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_sob_domingo := ((ln_u_sob_domingo + 1) - 0.60) ;
        End if ;
      Elsif ls_concepto = '1104' then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_sob_feriado := ln_u_sob_feriado + ln_horas ;
        ls_importe := to_char(ln_u_sob_feriado,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_sob_feriado := ((ln_u_sob_feriado + 1) - 0.60) ;
        End if ;
      End if ;
      
    End if ;
    --  Acumula horas de guardias ( primera, segunda o tercera )
    If substr(ls_concepto,1,2) = '12' then

      If  ls_concepto = '1201' then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_gua_primera := ln_u_gua_primera + ln_horas ;
        ls_importe := to_char(ln_u_gua_primera,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_gua_primera := ((ln_u_gua_primera + 1) - 0.60) ;
        End if ;
      Elsif ls_concepto = '1202' then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_gua_segunda := ln_u_gua_segunda + ln_horas ;
        ls_importe := to_char(ln_u_gua_segunda,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_gua_segunda := ((ln_u_gua_segunda + 1) - 0.60) ;
        End if ;
      Elsif ls_concepto = '1203' then
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ln_u_gua_tercera := ln_u_gua_tercera + ln_horas ;
        ls_importe := to_char(ln_u_gua_tercera,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_u_gua_tercera := ((ln_u_gua_tercera + 1) - 0.60) ;
        End if ;
      End if ;
      
    End if ;
  
  End loop ;
  
  ln_total := 0 ;
  ln_total := ln_tr_min_tardanza + ln_tr_hor_inasistencia + ln_tr_hor_sobretiempo +
              ln_tr_hor_trabajadas + ln_u_min_tardanza + ln_u_dia_inasistencia +
              ln_u_hor_inasistencia + ln_u_sob_sem_inglesa + ln_u_sob_normal +
              ln_u_sob_domingo + ln_u_sob_feriado + ln_u_gua_primera +
              ln_u_gua_segunda + ln_u_gua_tercera ;
     
  --  Graba registro para realizar consulta
  If ln_total <> 0 then
    Insert into tt_consulta_asistencia (
      cod_area, desc_area, cod_seccion, desc_seccion,
      cod_cencos, desc_cencos, cod_trabajador, nombres,
      cod_carnet, r_min_tardanza, r_hor_inasistencia, r_hor_sobretiempo,
      r_hor_trabajadas, u_min_tardanza, u_dia_inasistencia, u_hor_inasistencia,
      u_sob_sem_inglesa, u_sob_normal, u_sob_domingo, u_sob_feriado,
      u_gua_primera, u_gua_segunda, u_gua_tercera )
    Values (
      ls_cod_area, ls_desc_area, ls_cod_seccion, ls_desc_seccion,
      ls_cod_cencos, ls_desc_cencos, ls_cod_trabajador, ls_nombres,
      ls_cod_carnet, ln_tr_min_tardanza, ln_tr_hor_inasistencia, ln_tr_hor_sobretiempo,
      ln_tr_hor_trabajadas, ln_u_min_tardanza, ln_u_dia_inasistencia, ln_u_hor_inasistencia,
      ln_u_sob_sem_inglesa, ln_u_sob_normal, ln_u_sob_domingo, ln_u_sob_feriado,
      ln_u_gua_primera, ln_u_gua_segunda, ln_u_gua_tercera ) ;
  End if ;

End loop ;
                     
End usp_consulta_asistencia ;
/
