create or replace procedure usp_rpt_tardanzas
  ( ad_fec_desde        in date,
    ad_fec_hasta        in date,
    as_tipo_trabajador  in maestro.tipo_trabajador%type ) is
  
ls_carnet           carnet_trabajador.carnet_trabajador%type ;
ld_fecha            date ;
ln_minutos          number(11,2) ;
ls_cod_area         char(1) ;

ls_codtra           maestro.cod_trabajador%type ;
ls_seccion          maestro.cod_seccion%type ;
ls_cencos           maestro.cencos%type ;
ls_nombres          varchar2(40) ;
ls_desc_seccion     varchar2(40) ;
ls_desc_cencos      varchar2(40) ;
ls_desc_dia         char(9) ;

ln_imp_control      number(2,2) ;
ls_importe          varchar2(20) ;
ln_min_trabajador   number(11,2) ;
ln_min_cencos       number(11,2) ;
ln_min_seccion      number(11,2) ;
ln_min_general      number(11,2) ;
ln_nro_registro     number(10) ;

Cursor c_consolidado_diario is 
  Select mcd.carnet_trabajador, mcd.fecha_marcacion, mcd.min_tardanza
  From marcacion_consolidada_diaria mcd
  Where (to_date(to_char(mcd.fecha_marcacion,'DD/MM/YYYY'),'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')) and
        mcd.min_tardanza > 0 ;
                
Cursor c_tardanzas is 
  Select t.seccion, t.desc_seccion, t.cencos,
         t.desc_cencos, t.carnet_trabajador, t.cod_trabajador,
         t.nombres, t.fecha, t.desc_dia, t.minutos
  From tt_tardanzas t
  Order by t.seccion, t.cencos, t.cod_trabajador, t.fecha, t.quiebre ;
  
rc_tardanzas c_tardanzas%RowType ;

begin

delete from tt_tardanzas ;

--  Genera archivo temporal de TARDANZAS
For rc_con in c_consolidado_diario loop

  ls_carnet   := rc_con.carnet_trabajador ;
  ld_fecha    := rc_con.fecha_marcacion ;
  ln_minutos  := rc_con.min_tardanza ;
  ls_desc_dia := to_char(ld_fecha,'DAY') ;
    
  Select m.cod_trabajador, m.cod_seccion, m.cod_area, m.cencos
    into ls_codtra, ls_seccion, ls_cod_area, ls_cencos
    from maestro m
    where m.flag_estado = '1' and
          m.flag_marca_reloj = '1' and
          m.carnet_trabaj = ls_carnet and
          m.tipo_trabajador = as_tipo_trabajador ;

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

  Insert into tt_tardanzas (
    seccion, desc_seccion, cencos,
    desc_cencos, carnet_trabajador, cod_trabajador,
    nombres, fecha, desc_dia, minutos, quiebre )
  Values (
    ls_seccion, ls_desc_seccion, ls_cencos,
    ls_desc_cencos, ls_carnet, ls_codtra,
    ls_nombres, ld_fecha, ls_desc_dia, ln_minutos, 0 ) ;

End Loop;

--  Actualiza archivo temporal de TARDANZAS para emitir reporte
ln_min_general    := 0 ;
ln_min_seccion    := 0 ;
ln_min_cencos     := 0 ;
ln_min_trabajador := 0 ;
ln_nro_registro   := 0 ;

Open c_tardanzas ;
Fetch c_tardanzas into rc_tardanzas ;
--  Quiebre por total general
while c_tardanzas%FOUND loop
  ls_seccion := rc_tardanzas.seccion ;
  --  Quiebre por total general y seccion
  while rc_tardanzas.seccion = ls_seccion and
        c_tardanzas%FOUND loop
    ls_cencos := rc_tardanzas.cencos ;
    --  Quiebre por total general, seccion y centro de costo
    while rc_tardanzas.seccion = ls_seccion and
          rc_tardanzas.cencos  = ls_cencos and
          c_tardanzas%FOUND loop
      ls_codtra := rc_tardanzas.cod_trabajador ;
      ls_carnet := rc_tardanzas.carnet_trabajador ;
      --  Quiebre por total general, seccion, centro costo y trabajador
      while rc_tardanzas.seccion = ls_seccion and
            rc_tardanzas.cencos  = ls_cencos and
            rc_tardanzas.cod_trabajador = ls_codtra and
            c_tardanzas%FOUND loop

        ls_seccion      := rc_tardanzas.seccion ;
        ls_desc_seccion := rc_tardanzas.desc_seccion ;
        ls_cencos       := rc_tardanzas.cencos ;
        ls_desc_cencos  := rc_tardanzas.desc_cencos ;
        ls_carnet       := rc_tardanzas.carnet_trabajador ;
        ls_codtra       := rc_tardanzas.cod_trabajador ;
        ls_nombres      := rc_tardanzas.nombres ;
        ln_minutos      := rc_tardanzas.minutos ;
        ld_fecha        := rc_tardanzas.fecha ;
        --  Acumula por trabajador
        ln_min_trabajador := ln_min_trabajador + ln_minutos ;
        ln_imp_control    := 0 ; ls_importe := ' ' ;
        ls_importe        := to_char(ln_min_trabajador,'999,999,999,999.99') ;
        ln_imp_control    := to_number((substr(ls_importe,-3,3)),'.99') ;
        If ln_imp_control >= 0.60 then
          ln_min_trabajador := ((ln_min_trabajador + 1) - 0.60) ;
        End if ;

        Fetch c_tardanzas into rc_tardanzas ;
        ln_nro_registro := ln_nro_registro + 1 ;
        
      end loop ;  --  Quiebre trabajador
      Insert into tt_tardanzas (
        seccion, desc_seccion, cencos,
        desc_cencos, carnet_trabajador, cod_trabajador,
        nombres, fecha, desc_dia, minutos, quiebre )
      Values (
        ls_seccion, ls_desc_seccion, ls_cencos,
        ls_desc_cencos, ls_carnet, ls_codtra,
        ls_nombres,  ld_fecha, '*', ln_min_trabajador, 1 ) ;
        --  Acumula por centro de costo
      ln_min_cencos  := ln_min_cencos + ln_min_trabajador ;
      ln_imp_control := 0 ; ls_importe := ' ' ;
      ls_importe     := to_char(ln_min_cencos,'999,999,999,999.99') ;
      ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
      If ln_imp_control >= 0.60 then
        ln_min_cencos := ((ln_min_cencos + 1) - 0.60) ;
      End if ;
      ln_min_trabajador := 0 ;
    end loop ;  --  Quiebre centro de costo
    Insert into tt_tardanzas (
      seccion, desc_seccion, cencos,
      desc_cencos, carnet_trabajador, cod_trabajador,
      nombres, fecha, desc_dia, minutos, quiebre )
    Values (
      ls_seccion, ls_desc_seccion, ls_cencos,
      ls_desc_cencos, ls_carnet, ls_codtra,
      ls_nombres, ld_fecha, '**', ln_min_cencos, 2 ) ;
    --  Acumula por seccion
    ln_min_seccion := ln_min_seccion + ln_min_cencos ;
    ln_imp_control := 0 ; ls_importe := ' ' ;
    ls_importe     := to_char(ln_min_seccion,'999,999,999,999.99') ;
    ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
    If ln_imp_control >= 0.60 then
      ln_min_seccion := ((ln_min_seccion + 1) - 0.60) ;
    End if ;
    ln_min_cencos := 0 ;
  end loop ;  --  Quiebre seccion
  Insert into tt_tardanzas (
    seccion, desc_seccion, cencos,
    desc_cencos, carnet_trabajador, cod_trabajador,
    nombres, fecha, desc_dia, minutos, quiebre )
  Values (
    ls_seccion, ls_desc_seccion, ls_cencos,
    ls_desc_cencos, ls_carnet, ls_codtra,
    ls_nombres, ld_fecha, '***', ln_min_seccion, 3 ) ;
  --  Acumula por total general
  ln_min_general := ln_min_general + ln_min_seccion ;
  ln_imp_control := 0 ; ls_importe := ' ' ;
  ls_importe     := to_char(ln_min_general,'999,999,999,999.99') ;
  ln_imp_control := to_number((substr(ls_importe,-3,3)),'.99') ;
  If ln_imp_control >= 0.60 then
    ln_min_general := ((ln_min_general + 1) - 0.60) ;
  End if ;
  ln_min_seccion := 0 ;
end loop ;  --  Quiebre total general
Insert into tt_tardanzas (
  seccion, desc_seccion, cencos,
  desc_cencos, carnet_trabajador, cod_trabajador,
  nombres, fecha, desc_dia, minutos, quiebre )
Values (
  ls_seccion, ls_desc_seccion, ls_cencos,
  ls_desc_cencos, ls_carnet, ls_codtra,
  ls_nombres, ld_fecha, 'General', ln_min_general, 4 ) ;
ln_min_general := 0 ;

End usp_rpt_tardanzas ;
/
