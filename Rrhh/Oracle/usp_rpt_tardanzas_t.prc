create or replace procedure usp_rpt_tardanzas_t
  ( ad_fec_desde        in date,
    ad_fec_hasta        in date,
    as_cod_trabajador   in maestro.cod_trabajador%type ) is
  
ls_carnet           carnet_trabajador.carnet_trabajador%type ;
ld_fecha            date ;
ln_minutos          number(11,2) ;

ls_codtra           maestro.cod_trabajador%type ;
ls_seccion          maestro.cod_seccion%type ;
ls_cencos           maestro.cencos%type ;
ls_nombres          varchar2(40) ;
ls_desc_seccion     varchar2(40) ;
ls_desc_cencos      varchar2(40) ;
ls_desc_dia         char(9) ;
ls_cod_area         char(1) ;

ln_imp_control      number(2,2) ;
ls_importe          varchar2(20) ;
ln_min_trabajador   number(11,2) ;

Cursor c_consolidado_diario is 
  Select mcd.carnet_trabajador, mcd.fecha_marcacion, mcd.min_tardanza
  From marcacion_consolidada_diaria mcd
  Where (to_date(to_char(mcd.fecha_marcacion,'DD/MM/YYYY'),'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY')) and
        mcd.min_tardanza > 0 and
        mcd.carnet_trabajador = ls_carnet ;
                
Cursor c_tardanzas is 
  Select t.seccion, t.desc_seccion, t.cencos,
         t.desc_cencos, t.carnet_trabajador, t.cod_trabajador,
         t.nombres, t.fecha, t.desc_dia, t.minutos
  From tt_tardanzas t
  Order by t.seccion, t.cencos, t.cod_trabajador, t.fecha, t.quiebre ;
  
begin

delete from tt_tardanzas ;

Select m.cod_trabajador, m.carnet_trabaj, m.cod_seccion, m.cod_area, m.cencos
  into ls_codtra, ls_carnet, ls_seccion, ls_cod_area, ls_cencos
  from maestro m
  where m.flag_estado = '1' and
        m.flag_marca_reloj = '1' and
        m.cod_trabajador = as_cod_trabajador ;

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

--  Genera archivo temporal de TARDANZAS
For rc_con in c_consolidado_diario loop

  ls_carnet   := rc_con.carnet_trabajador ;
  ld_fecha    := rc_con.fecha_marcacion ;
  ln_minutos  := rc_con.min_tardanza ;
  ls_desc_dia := to_char(ld_fecha,'DAY') ;

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
ln_min_trabajador := 0 ;
For rc_tar in c_tardanzas loop

  ls_seccion      := rc_tar.seccion ;
  ls_desc_seccion := rc_tar.desc_seccion ;
  ls_cencos       := rc_tar.cencos ;
  ls_desc_cencos  := rc_tar.desc_cencos ;
  ls_carnet       := rc_tar.carnet_trabajador ;
  ls_codtra       := rc_tar.cod_trabajador ;
  ls_nombres      := rc_tar.nombres ;
  ln_minutos      := rc_tar.minutos ;
  ld_fecha        := rc_tar.fecha ;
  --  Acumula por trabajador
  ln_min_trabajador := ln_min_trabajador + ln_minutos ;
  ln_imp_control    := 0 ; ls_importe := ' ' ;
  ls_importe        := to_char(ln_min_trabajador,'999,999,999,999.99') ;
  ln_imp_control    := to_number((substr(ls_importe,-3,3)),'.99') ;
  If ln_imp_control >= 0.60 then
    ln_min_trabajador := ((ln_min_trabajador + 1) - 0.60) ;
  End if ;

end loop ;  --  Quiebre trabajador

Insert into tt_tardanzas (
  seccion, desc_seccion, cencos,
  desc_cencos, carnet_trabajador, cod_trabajador,
  nombres, fecha, desc_dia, minutos, quiebre )
Values (
  ls_seccion, ls_desc_seccion, ls_cencos,
  ls_desc_cencos, ls_carnet, ls_codtra,
  ls_nombres,  ld_fecha, '*', ln_min_trabajador, 1 ) ;
  ln_min_trabajador := 0 ;

End usp_rpt_tardanzas_t ;
/
