create or replace procedure usp_rpt_marc_det_irregular
  ( ad_fec_desde        in date,
    ad_fec_hasta        in date ) is
  
ls_seccion                char(3) ;
ls_desc_seccion           varchar2(40) ;
ls_cencos                 char(10) ;
ls_desc_cencos            varchar2(40) ;
ls_carnet_trabajador      char(10) ;
ls_cod_trabajador         char(8) ;
ls_nombres                varchar2(40) ;
ls_desc_dia               char(9) ;
ln_nro_dia                number(2) ;
ln_marcacion_horario      number(2) ;
ln_marcacion_usuario      number(2) ;
ls_cod_area               char(1) ;

ls_carnet                 carnet_trabajador.carnet_trabajador%type ;
ls_turno_marcacion        marcacion_consolidada_diaria.turno%type ;
ld_fecha_marcacion        marcacion_consolidada_diaria.fecha_marcacion%type ;
ld_fecha_reloj            marcacion_reloj_asistencia.fecha_marcacion%type ;

ln_graba                  number(2) ;
ln_marcacion_nor          turno.marc_diaria_norm%type ;
ln_marcacion_sab          turno.marc_diaria_sab%type ;
ln_marcacion_dom          turno.marc_diaria_dom%type ;

ln_contador               number(15) ;

Cursor c_consolidado_diario is 
  Select mcd.carnet_trabajador, mcd.fecha_marcacion, mcd.turno,
         mcd.nro_marcaciones
  From marcacion_consolidada_diaria mcd
--  Where mcd.carnet_trabajador = '15678603' and
  Where to_date(to_char(mcd.fecha_marcacion,'DD/MM/YYYY'),'DD/MM/YYYY') between to_date(to_char(ad_fec_desde,'DD/MM/YYYY'),'DD/MM/YYYY') and to_date(to_char(ad_fec_hasta,'DD/MM/YYYY'),'DD/MM/YYYY') ;
                
Cursor c_marcacion_reloj is 
  Select mra.fecha_marcacion
  From marcacion_reloj_asistencia mra
  Where mra.carnet_trabajador = ls_carnet and
        to_char(mra.fecha_marcacion,'DD/MM/YYYY') =
        to_char(ld_fecha_marcacion,'DD/MM/YYYY') ;
                
begin

delete from tt_marcacion_irregular ;

--  Genera archivo temporal de MARCACIONES IRREGULARES
For rc_con in c_consolidado_diario loop

  ls_carnet            := rc_con.carnet_trabajador ;
  ld_fecha_marcacion   := rc_con.fecha_marcacion ;
  ls_turno_marcacion   := rc_con.turno ;
  ln_marcacion_usuario := rc_con.nro_marcaciones ;
  ln_marcacion_usuario := nvl(ln_marcacion_usuario,0) ;
  ls_desc_dia          := to_char(ld_fecha_marcacion,'DAY') ;
  ln_nro_dia           := to_char(ld_fecha_marcacion,'D') ;
    
  Select t.marc_diaria_norm, t.marc_diaria_sab, t.marc_diaria_dom
    into ln_marcacion_nor, ln_marcacion_sab, ln_marcacion_dom
    from turno t
    where t.turno = ls_turno_marcacion ;

  --  Determina numero de marcaciones irregulares
  ln_marcacion_horario := 0 ;
  If (ln_nro_dia <> 07 and ln_nro_dia <> 01) then
    ln_marcacion_horario := ln_marcacion_nor ;
  Elsif ln_nro_dia = 07 then
    ln_marcacion_horario := ln_marcacion_sab ;
  Elsif ln_nro_dia = 01 then
    ln_marcacion_horario := ln_marcacion_dom ;
  End if ;
  ln_marcacion_horario := nvl(ln_marcacion_horario,0) ;

  ln_graba := 0 ;
  ln_graba := ln_marcacion_horario - ln_marcacion_usuario ;

  ln_contador := 0 ;
  Select count(*)
    into ln_contador
    from maestro m
    where m.flag_estado = '1' and
          m.carnet_trabaj = ls_carnet and
          m.flag_marca_reloj = '1' ;
  ln_contador := nvl(ln_contador,0) ;

  If ln_contador > 0 then
  If ln_graba <> 0 then

    Select m.cod_trabajador, m.cod_seccion, m.cod_area, m.cencos
      into ls_cod_trabajador, ls_seccion, ls_cod_area, ls_cencos
      from maestro m
      where m.flag_estado = '1' and
            m.carnet_trabaj = ls_carnet and
            m.flag_marca_reloj = '1' ;

    ls_nombres := usf_nombre_trabajador(ls_cod_trabajador) ;
       
    If ls_seccion  is not null Then
      Select s.desc_seccion
      into ls_desc_seccion
      from seccion s
      where s.cod_area = ls_cod_area and s.cod_seccion = ls_seccion ;
    End if ;
    ls_desc_seccion := nvl(ls_desc_seccion,' ') ;

    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from centros_costo cc
      where cc.cencos = ls_cencos ;
    ln_contador := nvl(ln_contador,0) ;
    
    If ln_contador > 0 then
      Select cc.desc_cencos
      into ls_desc_cencos
      from centros_costo cc
      where cc.cencos = ls_cencos ;
    End if ;
    ls_desc_cencos := nvl(ls_desc_cencos,' ') ;

    For rc_mar in c_marcacion_reloj loop
      ld_fecha_reloj := rc_mar.fecha_marcacion ;
      --  Inserta registros con marcaciones irregulares
      Insert into tt_marcacion_irregular (
        seccion, desc_seccion, cencos,
        desc_cencos, carnet_trabajador, cod_trabajador,
        nombres, fecha, desc_dia, turno,
        marcacion_horario, marcacion_usuario )
      Values (
        ls_seccion, ls_desc_seccion, ls_cencos,
        ls_desc_cencos, ls_carnet, ls_cod_trabajador,
        ls_nombres, ld_fecha_reloj, ls_desc_dia, ls_turno_marcacion,
        ln_marcacion_horario, ln_marcacion_usuario ) ;
    End loop ;

  End if ;
  End if ;

End Loop;

End usp_rpt_marc_det_irregular ;
/
