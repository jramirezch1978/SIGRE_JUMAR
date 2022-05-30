create or replace procedure usp_adiciona_gratificacion
  ( ad_fec_proceso     in date ) is

lk_gra_jubilado    constant char(04) := '1412' ;
lk_adelanto        constant char(04) := '2309' ;
ls_cod_trabajador  gratificacion.cod_trabajador%type ;
ld_fec_proceso     date ;
ls_mes             char(2) ;
ls_concepto        concepto.concep%type ;
ln_imp_bruto       number(13,2) ;
ln_imp_adelanto    number(13,2) ;
ls_cod_seccion     maestro.cod_seccion%type ;
ln_nro_registro    number(15) ;

--  Cursor de gratificaciones
Cursor c_gratificacion is
  Select g.cod_trabajador, g.fec_proceso, g.imp_bruto,
         g.imp_adelanto
  from gratificacion g ;

begin

delete from gan_desct_variable gdv    
  where gdv.fec_movim = ad_fec_proceso and
        gdv.concep = '1410' or
        gdv.concep = '1411' or
        gdv.concep = '1412' or
        gdv.concep = '2309' ;

For rc_gra in c_gratificacion Loop

  ls_cod_trabajador := rc_gra.cod_trabajador ;
  ld_fec_proceso    := rc_gra.fec_proceso ;
  ln_imp_bruto      := rc_gra.imp_bruto ;
  ln_imp_adelanto   := rc_gra.imp_adelanto ;
  ls_cod_seccion    := '340' ;
  
  ls_mes := to_char(ld_fec_proceso,'MM') ;
  If ls_mes = '07' then
    ls_concepto := '1410' ;
  Elsif ls_mes = '12' then
    ls_concepto := '1411' ;
  End if ;
  
  ln_nro_registro := 0 ;
  Select count(*)
    into ln_nro_registro
    from maestro m
    where m.cod_trabajador = ls_cod_trabajador ;
  ln_nro_registro := nvl(ln_nro_registro,0) ;

  If ln_nro_registro > 0 then
    Select m.cod_seccion
      into ls_cod_seccion
      from maestro m
      where m.cod_trabajador = ls_cod_trabajador ;
  End if ;

  If ln_imp_bruto > 0 then
    If ls_cod_seccion = '950' then
      Insert Into gan_desct_variable
        (cod_trabajador, fec_movim, nro_doc, concep,
         imp_var, tipo_doc)
      Values 
        (ls_cod_trabajador, ld_fec_proceso, ' ', lk_gra_jubilado,
         ln_imp_bruto, 'auto');
    Else 
      Insert Into gan_desct_variable
        (cod_trabajador, fec_movim, nro_doc, concep,
         imp_var, tipo_doc)
      Values 
        (ls_cod_trabajador, ld_fec_proceso, ' ', ls_concepto,
         ln_imp_bruto, 'auto');
    End if ;
  End if ;
    
  If ln_imp_adelanto > 0 then
    Insert Into gan_desct_variable
      (cod_trabajador, fec_movim, nro_doc, concep,
       imp_var, tipo_doc)
    Values 
      (ls_cod_trabajador, ld_fec_proceso, ' ', lk_adelanto,
       ln_imp_adelanto, 'auto');
  End if ;
    
End loop;

End usp_adiciona_gratificacion ;
/
