create or replace procedure usp_cencos_sin_equivalencia is

ls_cencos          char(5) ;
ln_registro        number(15) ;
ln_contador        number(15) ;

--  Lectura del archivo maestro
Cursor c_maestro is
  Select m.cod_trabajador, m.cencos
  from maestro m
  where m.cencos <> ' ' ;

--  Lectura del archivo de sobretiempos y turnos
Cursor c_sobretiempo is
  Select st.cod_trabajador, st.cencos
  from sobretiempo_turno st
  where st.cencos <> ' ' ;

--  Lectura del archivo de ganancias y descuentos variables
Cursor c_variables is
  Select dv.cod_trabajador, dv.cencos
  from gan_desct_variable dv
  where dv.cencos <> ' ' ;

--  Lectura del archivo de historico de sobretiempo y turnos
Cursor c_hist_sobret is
  Select hs.cod_trabajador, hs.cencos
  from historico_sobretiempo hs
  where hs.cencos <> ' ' ;

--  Lectura del archivo de historico de variables
Cursor c_hist_variab is
  Select hv.cod_trabajador, hv.cencos
  from historico_variable hv
  where hv.cencos <> ' ' ;

--  Lectura del archivo de historico de calculo
Cursor c_hist_calculo is
  Select hc.cod_trabajador, hc.cencos
  from historico_calculo hc
  where hc.cencos <> ' ' ;

begin

--  Actualiza centros de costos de archivo mestro
For rc_mae in c_maestro Loop
  ls_cencos := substr(rc_mae.cencos,1,5) ;
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from cencos c
    where c.cc_antiguo = ls_cencos ;
  ln_registro := nvl(ln_registro,0) ;
  If ln_registro = 0 then
    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from cencos_sin_equivalencia c
      where c.centro_costo = ls_cencos ;
    ln_contador := nvl(ln_contador,0) ;
    If ln_contador = 0 then
      Insert into cencos_sin_equivalencia
        ( centro_costo )
      Values
        ( ls_cencos ) ;
    End if ;
  End if ;
End Loop ;

--  Actualiza centros de costos de sobretiempos y turnos
For rc_sob in c_sobretiempo Loop
  ls_cencos := substr(rc_sob.cencos,1,5) ;
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from cencos c
    where c.cc_antiguo = ls_cencos ;
  ln_registro := nvl(ln_registro,0) ;
  If ln_registro = 0 then
    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from cencos_sin_equivalencia c
      where c.centro_costo = ls_cencos ;
    ln_contador := nvl(ln_contador,0) ;
    If ln_contador = 0 then
      Insert into cencos_sin_equivalencia
        ( centro_costo )
      Values
        ( ls_cencos ) ;
    End if ;
  End if ;
End Loop ;

--  Actualiza centros de costos de ganacias y descuentos variables
For rc_var in c_variables Loop
  ls_cencos := substr(rc_var.cencos,1,5) ;
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from cencos c
    where c.cc_antiguo = ls_cencos ;
  ln_registro := nvl(ln_registro,0) ;
  If ln_registro = 0 then
    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from cencos_sin_equivalencia c
      where c.centro_costo = ls_cencos ;
    ln_contador := nvl(ln_contador,0) ;
    If ln_contador = 0 then
      Insert into cencos_sin_equivalencia
        ( centro_costo )
      Values
        ( ls_cencos ) ;
    End if ;
  End if ;
End Loop ;

--  Actualiza centros de costos del historico de sobretiempo
For rc_hs in c_hist_sobret Loop
  ls_cencos := substr(rc_hs.cencos,1,5) ;
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from cencos c
    where c.cc_antiguo = ls_cencos ;
  ln_registro := nvl(ln_registro,0) ;
  If ln_registro = 0 then
    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from cencos_sin_equivalencia c
      where c.centro_costo = ls_cencos ;
    ln_contador := nvl(ln_contador,0) ;
    If ln_contador = 0 then
      Insert into cencos_sin_equivalencia
        ( centro_costo )
      Values
        ( ls_cencos ) ;
    End if ;
  End if ;
End Loop ;

--  Actualiza centros de costos del historico de variables
For rc_hv in c_hist_variab Loop
  ls_cencos := substr(rc_hv.cencos,1,5) ;
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from cencos c
    where c.cc_antiguo = ls_cencos ;
  ln_registro := nvl(ln_registro,0) ;
  If ln_registro = 0 then
    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from cencos_sin_equivalencia c
      where c.centro_costo = ls_cencos ;
    ln_contador := nvl(ln_contador,0) ;
    If ln_contador = 0 then
      Insert into cencos_sin_equivalencia
        ( centro_costo )
      Values
        ( ls_cencos ) ;
    End if ;
  End if ;
End Loop ;

--  Actualiza centros de costos del historico de calculo
For rc_hc in c_hist_calculo Loop
  ls_cencos := substr(rc_hc.cencos,1,5) ;
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from cencos c
    where c.cc_antiguo = ls_cencos ;
  ln_registro := nvl(ln_registro,0) ;
  If ln_registro = 0 then
    ln_contador := 0 ;
    Select count(*)
      into ln_contador
      from cencos_sin_equivalencia c
      where c.centro_costo = ls_cencos ;
    ln_contador := nvl(ln_contador,0) ;
    If ln_contador = 0 then
      Insert into cencos_sin_equivalencia
        ( centro_costo )
      Values
        ( ls_cencos ) ;
    End if ;
  End if ;
End Loop ;

end usp_cencos_sin_equivalencia ;
/
