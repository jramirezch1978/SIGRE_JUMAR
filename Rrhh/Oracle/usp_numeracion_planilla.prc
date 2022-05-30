create or replace procedure usp_numeracion_planilla (
  as_nro_desde   in string,
  as_nro_hasta   in string ) is

ln_nro_desde   number(10) ;
ln_nro_hasta   number(10) ;
ls_numeracion  char(10) ;

Begin

delete from tt_numeracion_planilla ;

ln_nro_desde := to_number(as_nro_desde) ;
ln_nro_hasta := to_number(as_nro_hasta) ;
      
For x in ln_nro_desde .. ln_nro_hasta Loop

  ls_numeracion := to_char(x,'999999999') ;
  ls_numeracion := lpad(ltrim(rtrim(ls_numeracion)),10,'0') ;
  Insert into tt_numeracion_planilla
    ( nro_planilla )
  Values
    ( ls_numeracion ) ;
    
End Loop ;

End usp_numeracion_planilla ;
/
