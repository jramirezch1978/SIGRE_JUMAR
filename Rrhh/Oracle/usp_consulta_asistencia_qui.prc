create or replace procedure usp_consulta_asistencia_qui is

ls_cod_area        char(01) ;   ls_desc_area     varchar2(40) ;
ls_cod_seccion     char(03) ;   ls_desc_seccion  varchar2(40) ;
ls_cod_cencos      char(10) ;   ls_desc_cencos   varchar2(40) ;
ls_cod_trabajador  char(08) ;   ls_nombres       varchar2(40) ;
ls_cod_carnet      char(10) ;   ls_importe       varchar2(20) ;
ln_nro_registro    number(10) ; ln_imp_control   number(2,2) ;

ln_r_min_tardanza       number(11,2) ;  ln_r_hor_inasistencia   number(11,2) ;
ln_r_hor_sobretiempo    number(11,2) ;  ln_r_hor_trabajadas     number(11,2) ;
ln_u_min_tardanza       number(11,2) ;  ln_u_dia_inasistencia   number(11,2) ;
ln_u_hor_inasistencia   number(11,2) ;  ln_u_sob_sem_inglesa    number(11,2) ;
ln_u_sob_normal         number(11,2) ;  ln_u_sob_domingo        number(11,2) ;
ln_u_sob_feriado        number(11,2) ;  ln_u_gua_primera        number(11,2) ;
ln_u_gua_segunda        number(11,2) ;  ln_u_gua_tercera        number(11,2) ;

ln_ar_min_tardanza      number(11,2) ;  ln_ar_hor_inasistencia  number(11,2) ;
ln_ar_hor_sobretiempo   number(11,2) ;  ln_ar_hor_trabajadas    number(11,2) ;
ln_au_min_tardanza      number(11,2) ;  ln_au_dia_inasistencia  number(11,2) ;
ln_au_hor_inasistencia  number(11,2) ;  ln_au_sob_sem_inglesa   number(11,2) ;
ln_au_sob_normal        number(11,2) ;  ln_au_sob_domingo       number(11,2) ;
ln_au_sob_feriado       number(11,2) ;  ln_au_gua_primera       number(11,2) ;
ln_au_gua_segunda       number(11,2) ;  ln_au_gua_tercera       number(11,2) ;

ln_sr_min_tardanza      number(11,2) ;  ln_sr_hor_inasistencia  number(11,2) ;
ln_sr_hor_sobretiempo   number(11,2) ;  ln_sr_hor_trabajadas    number(11,2) ;
ln_su_min_tardanza      number(11,2) ;  ln_su_dia_inasistencia  number(11,2) ;
ln_su_hor_inasistencia  number(11,2) ;  ln_su_sob_sem_inglesa   number(11,2) ;
ln_su_sob_normal        number(11,2) ;  ln_su_sob_domingo       number(11,2) ;
ln_su_sob_feriado       number(11,2) ;  ln_su_gua_primera       number(11,2) ;
ln_su_gua_segunda       number(11,2) ;  ln_su_gua_tercera       number(11,2) ;

ln_cr_min_tardanza      number(11,2) ;  ln_cr_hor_inasistencia  number(11,2) ;
ln_cr_hor_sobretiempo   number(11,2) ;  ln_cr_hor_trabajadas    number(11,2) ;
ln_cu_min_tardanza      number(11,2) ;  ln_cu_dia_inasistencia  number(11,2) ;
ln_cu_hor_inasistencia  number(11,2) ;  ln_cu_sob_sem_inglesa   number(11,2) ;
ln_cu_sob_normal        number(11,2) ;  ln_cu_sob_domingo       number(11,2) ;
ln_cu_sob_feriado       number(11,2) ;  ln_cu_gua_primera       number(11,2) ;
ln_cu_gua_segunda       number(11,2) ;  ln_cu_gua_tercera       number(11,2) ;

Cursor c_asistencia is 
  Select c.cod_area, c.desc_area, c.cod_seccion,
         c.desc_seccion, c.cod_cencos, c.desc_cencos,
         c.cod_trabajador, c.nombres, c.cod_carnet,
         c.r_min_tardanza, c.r_hor_inasistencia, c.r_hor_sobretiempo,
         c.r_hor_trabajadas, c.u_min_tardanza, c.u_dia_inasistencia,
         c.u_hor_inasistencia, c.u_sob_sem_inglesa, c.u_sob_normal,
         c.u_sob_domingo, c.u_sob_feriado, c.u_gua_primera,
         c.u_gua_segunda, c.u_gua_tercera
  From tt_consulta_asistencia c
  Order by c.cod_area, c.cod_seccion, c.cod_cencos, c.cod_trabajador ;
  
rc_asistencia c_asistencia%RowType ;

begin

delete from tt_consulta_asistencia_area ;
delete from tt_consulta_asistencia_secc ;
delete from tt_consulta_asistencia_cenc ;

ln_ar_min_tardanza     := 0 ; ln_sr_min_tardanza     := 0 ; 
ln_ar_hor_inasistencia := 0 ; ln_sr_hor_inasistencia := 0 ;
ln_ar_hor_sobretiempo  := 0 ; ln_sr_hor_sobretiempo  := 0 ;
ln_ar_hor_trabajadas   := 0 ; ln_sr_hor_trabajadas   := 0 ;
ln_au_min_tardanza     := 0 ; ln_su_min_tardanza     := 0 ;
ln_au_dia_inasistencia := 0 ; ln_su_dia_inasistencia := 0 ;
ln_au_hor_inasistencia := 0 ; ln_su_hor_inasistencia := 0 ;
ln_au_sob_sem_inglesa  := 0 ; ln_su_sob_sem_inglesa  := 0 ;
ln_au_sob_normal       := 0 ; ln_su_sob_normal       := 0 ;
ln_au_sob_domingo      := 0 ; ln_su_sob_domingo      := 0 ;
ln_au_sob_feriado      := 0 ; ln_su_sob_feriado      := 0 ;
ln_au_gua_primera      := 0 ; ln_su_gua_primera      := 0 ;
ln_au_gua_segunda      := 0 ; ln_su_gua_segunda      := 0 ;
ln_au_gua_tercera      := 0 ; ln_su_gua_tercera      := 0 ;

ln_cr_min_tardanza     := 0 ; ln_cr_hor_inasistencia := 0 ; 
ln_cr_hor_sobretiempo  := 0 ; ln_cr_hor_trabajadas   := 0 ; 
ln_cu_min_tardanza     := 0 ; ln_cu_dia_inasistencia := 0 ; 
ln_cu_hor_inasistencia := 0 ; ln_cu_sob_sem_inglesa  := 0 ; 
ln_cu_sob_normal       := 0 ; ln_cu_sob_domingo      := 0 ; 
ln_cu_sob_feriado      := 0 ; ln_cu_gua_primera      := 0 ; 
ln_cu_gua_segunda      := 0 ; ln_cu_gua_tercera      := 0 ; 

Open c_asistencia ;
Fetch c_asistencia into rc_asistencia ;
--  Lectura hasta que sea fin de archivo
while c_asistencia%FOUND loop
      ls_cod_area := rc_asistencia.cod_area ;
  --  Quiebre por area
  while rc_asistencia.cod_area = ls_cod_area and
        c_asistencia%FOUND loop
        ls_cod_seccion := rc_asistencia.cod_seccion ;
    --  Quiebre por area y seccion    
    while rc_asistencia.cod_area = ls_cod_area and
          rc_asistencia.cod_seccion = ls_cod_seccion and
          c_asistencia%FOUND loop
          ls_cod_cencos := rc_asistencia.cod_cencos ;
      --  Quiebre por area, seccion y centro de costo
      while rc_asistencia.cod_area = ls_cod_area and
            rc_asistencia.cod_seccion = ls_cod_seccion and
            rc_asistencia.cod_cencos  = ls_cod_cencos and
            c_asistencia%FOUND loop

        ls_cod_area           := rc_asistencia.cod_area ;  
        ls_desc_area          := rc_asistencia.desc_area ;
        ls_cod_seccion        := rc_asistencia.cod_seccion ;
        ls_desc_seccion       := rc_asistencia.desc_seccion ;
        ls_cod_cencos         := rc_asistencia.cod_cencos ;
        ls_desc_cencos        := rc_asistencia.desc_cencos ;
        ls_cod_trabajador     := rc_asistencia.cod_trabajador ;
        ls_nombres            := rc_asistencia.nombres ;
        ls_cod_carnet         := rc_asistencia.cod_carnet ;
        ln_r_min_tardanza     := rc_asistencia.r_min_tardanza ;
        ln_r_hor_inasistencia := rc_asistencia.r_hor_inasistencia ;
        ln_r_hor_sobretiempo  := rc_asistencia.r_hor_sobretiempo ;
        ln_r_hor_trabajadas   := rc_asistencia.r_hor_trabajadas ;
        ln_u_min_tardanza     := rc_asistencia.u_min_tardanza ;
        ln_u_dia_inasistencia := rc_asistencia.u_dia_inasistencia ;
        ln_u_hor_inasistencia := rc_asistencia.u_hor_inasistencia ;
        ln_u_sob_sem_inglesa  := rc_asistencia.u_sob_sem_inglesa ;
        ln_u_sob_normal       := rc_asistencia.u_sob_normal ;
        ln_u_sob_domingo      := rc_asistencia.u_sob_domingo ;
        ln_u_sob_feriado      := rc_asistencia.u_sob_feriado ;
        ln_u_gua_primera      := rc_asistencia.u_gua_primera ;
        ln_u_gua_segunda      := rc_asistencia.u_gua_segunda ;
        ln_u_gua_tercera      := rc_asistencia.u_gua_tercera ;

        --  Acumula para centros de costos
        ln_cr_min_tardanza := ln_cr_min_tardanza + ln_r_min_tardanza ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cr_min_tardanza,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cr_min_tardanza := ((ln_cr_min_tardanza + 1) - 0.60) ;
        End if ;

        ln_cr_hor_inasistencia := ln_cr_hor_inasistencia + ln_r_hor_inasistencia ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cr_hor_inasistencia,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cr_hor_inasistencia := ((ln_cr_hor_inasistencia + 1) - 0.60) ;
        End if ;

        ln_cr_hor_sobretiempo := ln_cr_hor_sobretiempo + ln_r_hor_sobretiempo ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cr_hor_sobretiempo,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cr_hor_sobretiempo := ((ln_cr_hor_sobretiempo + 1) - 0.60) ;
        End if ;

        ln_cr_hor_trabajadas := ln_cr_hor_trabajadas + ln_r_hor_trabajadas ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cr_hor_trabajadas,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cr_hor_trabajadas := ((ln_cr_hor_trabajadas + 1) - 0.60) ;
        End if ;

        ln_cu_min_tardanza := ln_cu_min_tardanza + ln_u_min_tardanza ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_min_tardanza,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_min_tardanza := ((ln_cu_min_tardanza + 1) - 0.60) ;
        End if ;

        ln_cu_dia_inasistencia := ln_cu_dia_inasistencia + ln_u_dia_inasistencia ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_dia_inasistencia,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_dia_inasistencia := ((ln_cu_dia_inasistencia + 1) - 0.60) ;
        End if ;

        ln_cu_hor_inasistencia := ln_cu_hor_inasistencia + ln_u_hor_inasistencia ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_hor_inasistencia,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_hor_inasistencia := ((ln_cu_hor_inasistencia + 1) - 0.60) ;
        End if ;

        ln_cu_sob_sem_inglesa := ln_cu_sob_sem_inglesa + ln_u_sob_sem_inglesa ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_sob_sem_inglesa,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_sob_sem_inglesa := ((ln_cu_sob_sem_inglesa + 1) - 0.60) ;
        End if ;

        ln_cu_sob_normal := ln_cu_sob_normal + ln_u_sob_normal ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_sob_normal,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_sob_normal := ((ln_cu_sob_normal + 1) - 0.60) ;
        End if ;

        ln_cu_sob_domingo := ln_cu_sob_domingo + ln_u_sob_domingo ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_sob_domingo,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_sob_domingo := ((ln_cu_sob_domingo + 1) - 0.60) ;
        End if ;

        ln_cu_sob_feriado := ln_cu_sob_feriado + ln_u_sob_feriado ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_sob_feriado,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_sob_feriado := ((ln_cu_sob_feriado + 1) - 0.60) ;
        End if ;

        ln_cu_gua_primera := ln_cu_gua_primera + ln_u_gua_primera ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_gua_primera,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_gua_primera := ((ln_cu_gua_primera + 1) - 0.60) ;
        End if ;

        ln_cu_gua_segunda := ln_cu_gua_segunda + ln_u_gua_segunda ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_gua_segunda,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_gua_segunda := ((ln_cu_gua_segunda + 1) - 0.60) ;
        End if ;

        ln_cu_gua_tercera := ln_cu_gua_tercera + ln_u_gua_tercera ;
        ln_imp_control := 0 ; ls_importe := ' ' ;
        ls_importe := to_char(ln_cu_gua_tercera,'999,999,999,999.99') ;
        ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_cu_gua_tercera := ((ln_cu_gua_tercera + 1) - 0.60) ;
        End if ;

        Fetch c_asistencia into rc_asistencia ;
        ln_nro_registro := ln_nro_registro + 1 ;
        
      end loop ;  --  Quiebre centro de costo

      Insert into tt_consulta_asistencia_cenc (
        cod_area, desc_area, cod_seccion, desc_seccion,
        cod_cencos, desc_cencos, cod_trabajador, nombres,
        cod_carnet, r_min_tardanza, r_hor_inasistencia, r_hor_sobretiempo,
        r_hor_trabajadas, u_min_tardanza, u_dia_inasistencia, u_hor_inasistencia,
        u_sob_sem_inglesa, u_sob_normal, u_sob_domingo, u_sob_feriado,
        u_gua_primera, u_gua_segunda, u_gua_tercera )
      Values (
        ls_cod_area, ls_desc_area, ls_cod_seccion, ls_desc_seccion,
        ls_cod_cencos, ls_desc_cencos, ls_cod_trabajador, ls_nombres,
        ls_cod_carnet, ln_cr_min_tardanza, ln_cr_hor_inasistencia, ln_cr_hor_sobretiempo,
        ln_cr_hor_trabajadas, ln_cu_min_tardanza, ln_cu_dia_inasistencia, ln_cu_hor_inasistencia,
        ln_cu_sob_sem_inglesa, ln_cu_sob_normal, ln_cu_sob_domingo, ln_cu_sob_feriado,
        ln_cu_gua_primera, ln_cu_gua_segunda, ln_cu_gua_tercera ) ;

      --  Acumula para secciones
      ln_sr_min_tardanza := ln_sr_min_tardanza + ln_cr_min_tardanza ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_sr_min_tardanza,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_sr_min_tardanza := ((ln_sr_min_tardanza + 1) - 0.60) ;
      End if ;

      ln_sr_hor_inasistencia := ln_sr_hor_inasistencia + ln_cr_hor_inasistencia ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_sr_hor_inasistencia,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_sr_hor_inasistencia := ((ln_sr_hor_inasistencia + 1) - 0.60) ;
      End if ;

      ln_sr_hor_sobretiempo := ln_sr_hor_sobretiempo + ln_cr_hor_sobretiempo ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_sr_hor_sobretiempo,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_sr_hor_sobretiempo := ((ln_sr_hor_sobretiempo + 1) - 0.60) ;
      End if ;

      ln_sr_hor_trabajadas := ln_sr_hor_trabajadas + ln_cr_hor_trabajadas ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_sr_hor_trabajadas,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_sr_hor_trabajadas := ((ln_sr_hor_trabajadas + 1) - 0.60) ;
      End if ;

      ln_su_min_tardanza := ln_su_min_tardanza + ln_cu_min_tardanza ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_min_tardanza,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_min_tardanza := ((ln_su_min_tardanza + 1) - 0.60) ;
      End if ;

      ln_su_dia_inasistencia := ln_su_dia_inasistencia + ln_cu_dia_inasistencia ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_dia_inasistencia,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_dia_inasistencia := ((ln_su_dia_inasistencia + 1) - 0.60) ;
      End if ;

      ln_su_hor_inasistencia := ln_su_hor_inasistencia + ln_cu_hor_inasistencia ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_hor_inasistencia,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_hor_inasistencia := ((ln_su_hor_inasistencia + 1) - 0.60) ;
      End if ;

      ln_su_sob_sem_inglesa := ln_su_sob_sem_inglesa + ln_cu_sob_sem_inglesa ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_sob_sem_inglesa,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_sob_sem_inglesa := ((ln_su_sob_sem_inglesa + 1) - 0.60) ;
      End if ;

      ln_su_sob_normal := ln_su_sob_normal + ln_cu_sob_normal ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_sob_normal,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_sob_normal := ((ln_su_sob_normal + 1) - 0.60) ;
      End if ;

      ln_su_sob_domingo := ln_su_sob_domingo + ln_cu_sob_domingo ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_sob_domingo,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_sob_domingo := ((ln_su_sob_domingo + 1) - 0.60) ;
      End if ;

      ln_su_sob_feriado := ln_su_sob_feriado + ln_cu_sob_feriado ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_sob_feriado,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_sob_feriado := ((ln_su_sob_feriado + 1) - 0.60) ;
      End if ;

      ln_su_gua_primera := ln_su_gua_primera + ln_cu_gua_primera ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_gua_primera,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_gua_primera := ((ln_su_gua_primera + 1) - 0.60) ;
      End if ;

      ln_su_gua_segunda := ln_su_gua_segunda + ln_cu_gua_segunda ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_gua_segunda,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_gua_segunda := ((ln_su_gua_segunda + 1) - 0.60) ;
      End if ;

      ln_su_gua_tercera := ln_su_gua_tercera + ln_cu_gua_tercera ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe := to_char(ln_su_gua_tercera,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_su_gua_tercera := ((ln_su_gua_tercera + 1) - 0.60) ;
      End if ;
        
      ln_cr_min_tardanza     := 0 ; ln_cr_hor_inasistencia := 0 ; 
      ln_cr_hor_sobretiempo  := 0 ; ln_cr_hor_trabajadas   := 0 ; 
      ln_cu_min_tardanza     := 0 ; ln_cu_dia_inasistencia := 0 ; 
      ln_cu_hor_inasistencia := 0 ; ln_cu_sob_sem_inglesa  := 0 ; 
      ln_cu_sob_normal       := 0 ; ln_cu_sob_domingo      := 0 ; 
      ln_cu_sob_feriado      := 0 ; ln_cu_gua_primera      := 0 ; 
      ln_cu_gua_segunda      := 0 ; ln_cu_gua_tercera      := 0 ; 

    end loop ;  --  Quiebre seccion

    Insert into tt_consulta_asistencia_secc (
      cod_area, desc_area, cod_seccion, desc_seccion,
      cod_cencos, desc_cencos, cod_trabajador, nombres,
      cod_carnet, r_min_tardanza, r_hor_inasistencia, r_hor_sobretiempo,
      r_hor_trabajadas, u_min_tardanza, u_dia_inasistencia, u_hor_inasistencia,
      u_sob_sem_inglesa, u_sob_normal, u_sob_domingo, u_sob_feriado,
      u_gua_primera, u_gua_segunda, u_gua_tercera )
    Values (
      ls_cod_area, ls_desc_area, ls_cod_seccion, ls_desc_seccion,
      ls_cod_cencos, ls_desc_cencos, ls_cod_trabajador, ls_nombres,
      ls_cod_carnet, ln_sr_min_tardanza, ln_sr_hor_inasistencia, ln_sr_hor_sobretiempo,
      ln_sr_hor_trabajadas, ln_su_min_tardanza, ln_su_dia_inasistencia, ln_su_hor_inasistencia,
      ln_su_sob_sem_inglesa, ln_su_sob_normal, ln_su_sob_domingo, ln_su_sob_feriado,
      ln_su_gua_primera, ln_su_gua_segunda, ln_su_gua_tercera ) ;

    --  Acumula por areas
    ln_ar_min_tardanza := ln_ar_min_tardanza + ln_sr_min_tardanza ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_ar_min_tardanza,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_ar_min_tardanza := ((ln_ar_min_tardanza + 1) - 0.60) ;
    End if ;

    ln_ar_hor_inasistencia := ln_ar_hor_inasistencia + ln_sr_hor_inasistencia ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_ar_hor_inasistencia,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_ar_hor_inasistencia := ((ln_ar_hor_inasistencia + 1) - 0.60) ;
    End if ;

    ln_ar_hor_sobretiempo := ln_ar_hor_sobretiempo + ln_sr_hor_sobretiempo ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_ar_hor_sobretiempo,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_ar_hor_sobretiempo := ((ln_ar_hor_sobretiempo + 1) - 0.60) ;
    End if ;

    ln_ar_hor_trabajadas := ln_ar_hor_trabajadas + ln_sr_hor_trabajadas ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_ar_hor_trabajadas,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_ar_hor_trabajadas := ((ln_ar_hor_trabajadas + 1) - 0.60) ;
    End if ;

    ln_au_min_tardanza := ln_au_min_tardanza + ln_su_min_tardanza ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_min_tardanza,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_min_tardanza := ((ln_au_min_tardanza + 1) - 0.60) ;
    End if ;

    ln_au_dia_inasistencia := ln_au_dia_inasistencia + ln_su_dia_inasistencia ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_dia_inasistencia,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_dia_inasistencia := ((ln_au_dia_inasistencia + 1) - 0.60) ;
    End if ;

    ln_au_hor_inasistencia := ln_au_hor_inasistencia + ln_su_hor_inasistencia ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_hor_inasistencia,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_hor_inasistencia := ((ln_au_hor_inasistencia + 1) - 0.60) ;
    End if ;

    ln_au_sob_sem_inglesa := ln_au_sob_sem_inglesa + ln_su_sob_sem_inglesa ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_sob_sem_inglesa,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_sob_sem_inglesa := ((ln_au_sob_sem_inglesa + 1) - 0.60) ;
    End if ;

    ln_au_sob_normal := ln_au_sob_normal + ln_su_sob_normal ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_sob_normal,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_sob_normal := ((ln_au_sob_normal + 1) - 0.60) ;
    End if ;

    ln_au_sob_domingo := ln_au_sob_domingo + ln_su_sob_domingo ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_sob_domingo,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_sob_domingo := ((ln_au_sob_domingo + 1) - 0.60) ;
    End if ;

    ln_au_sob_feriado := ln_au_sob_feriado + ln_su_sob_feriado ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_sob_feriado,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_sob_feriado := ((ln_au_sob_feriado + 1) - 0.60) ;
    End if ;

    ln_au_gua_primera := ln_au_gua_primera + ln_su_gua_primera ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_gua_primera,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_gua_primera := ((ln_au_gua_primera + 1) - 0.60) ;
    End if ;

    ln_au_gua_segunda := ln_au_gua_segunda + ln_su_gua_segunda ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_gua_segunda,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_gua_segunda := ((ln_au_gua_segunda + 1) - 0.60) ;
    End if ;

    ln_au_gua_tercera := ln_au_gua_tercera + ln_su_gua_tercera ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe := to_char(ln_au_gua_tercera,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_au_gua_tercera := ((ln_au_gua_tercera + 1) - 0.60) ;
    End if ;
        
    ln_sr_min_tardanza     := 0 ; ln_sr_hor_inasistencia := 0 ; 
    ln_sr_hor_sobretiempo  := 0 ; ln_sr_hor_trabajadas   := 0 ; 
    ln_su_min_tardanza     := 0 ; ln_su_dia_inasistencia := 0 ; 
    ln_su_hor_inasistencia := 0 ; ln_su_sob_sem_inglesa  := 0 ; 
    ln_su_sob_normal       := 0 ; ln_su_sob_domingo      := 0 ; 
    ln_su_sob_feriado      := 0 ; ln_su_gua_primera      := 0 ; 
    ln_su_gua_segunda      := 0 ; ln_su_gua_tercera      := 0 ; 

  end loop ;  -- Quiebre area
  
  Insert into tt_consulta_asistencia_area (
    cod_area, desc_area, cod_seccion, desc_seccion,
    cod_cencos, desc_cencos, cod_trabajador, nombres,
    cod_carnet, r_min_tardanza, r_hor_inasistencia, r_hor_sobretiempo,
    r_hor_trabajadas, u_min_tardanza, u_dia_inasistencia, u_hor_inasistencia,
    u_sob_sem_inglesa, u_sob_normal, u_sob_domingo, u_sob_feriado,
    u_gua_primera, u_gua_segunda, u_gua_tercera )
  Values (
    ls_cod_area, ls_desc_area, ls_cod_seccion, ls_desc_seccion,
    ls_cod_cencos, ls_desc_cencos, ls_cod_trabajador, ls_nombres,
    ls_cod_carnet, ln_ar_min_tardanza, ln_ar_hor_inasistencia, ln_ar_hor_sobretiempo,
    ln_ar_hor_trabajadas, ln_au_min_tardanza, ln_au_dia_inasistencia, ln_au_hor_inasistencia,
    ln_au_sob_sem_inglesa, ln_au_sob_normal, ln_au_sob_domingo, ln_au_sob_feriado,
    ln_au_gua_primera, ln_au_gua_segunda, ln_au_gua_tercera ) ;

  ln_ar_min_tardanza     := 0 ; ln_ar_hor_inasistencia := 0 ; 
  ln_ar_hor_sobretiempo  := 0 ; ln_ar_hor_trabajadas   := 0 ; 
  ln_au_min_tardanza     := 0 ; ln_au_dia_inasistencia := 0 ; 
  ln_au_hor_inasistencia := 0 ; ln_au_sob_sem_inglesa  := 0 ; 
  ln_au_sob_normal       := 0 ; ln_au_sob_domingo      := 0 ; 
  ln_au_sob_feriado      := 0 ; ln_au_gua_primera      := 0 ; 
  ln_au_gua_segunda      := 0 ; ln_au_gua_tercera      := 0 ; 
  
end loop ;  --  Fin de lectura

End usp_consulta_asistencia_qui ;
/
