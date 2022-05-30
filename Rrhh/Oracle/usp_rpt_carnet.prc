create or replace procedure usp_rpt_carnet
  ( ad_fec_desde in date, ad_fec_hasta in date ) is
  
ls_carnet           carnet_trabajador.carnet_trabajador%type ;
ld_fecha            date ;

ls_codtra           maestro.cod_trabajador%type ;
ls_seccion          maestro.cod_seccion%type ;
ls_cencos           maestro.cencos%type ;
ls_nombres          varchar2(40) ;
ls_carnet_errado    carnet_trabajador.carnet_trabajador%type ;
ls_desc_dia         char(9) ;

ln_registro         number(15) ;

Cursor c_marcacion_reloj is
  Select mra.carnet_trabajador, mra.fecha_marcacion, mra.nro_reloj
  From marcacion_reloj_asistencia mra
  Where mra.fecha_marcacion between ad_fec_desde and ad_fec_hasta ;
                
begin

delete from tt_carnet ;

--  Lectura de marcaciones diarias del reloj
For rc_mar in c_marcacion_reloj loop

  ls_carnet_errado := rc_mar.carnet_trabajador ;
  ld_fecha         := rc_mar.fecha_marcacion ;
  ls_desc_dia      := to_char(ld_fecha,'DAY') ;
    
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from carnet_trabajador ct
    where ct.carnet_trabajador = ls_carnet_errado and
          ct.flag_estado = '0' ;

  If ln_registro > 0 then

    Select ct.cod_trabajador
      into ls_codtra
      from carnet_trabajador ct
      where ct.carnet_trabajador = ls_carnet_errado and
            ct.flag_estado = '0' ;

    Select m.carnet_trabaj, m.cod_seccion, m.cencos
      into ls_carnet, ls_seccion, ls_cencos
      from maestro m
      where m.flag_estado = '1' and
            m.cod_trabajador = ls_codtra ;
            
    ls_nombres := usf_nombre_trabajador(ls_codtra) ;
       
    Insert into tt_carnet (
      cod_trabajador, nombres, seccion,
      cencos, carnet_valido, carnet_no_valido,
      fecha, desc_dia )
    Values (
      ls_codtra, ls_nombres, ls_seccion,
      ls_cencos, ls_carnet, ls_carnet_errado,
      ld_fecha, ls_desc_dia ) ;

  End if ;
  
End Loop ;

End usp_rpt_carnet ;
/
