create or replace procedure usp_actualiza_fotos is

--  Lee maestro de trabajadores
Cursor c_maestro is
  Select m.cod_trabajador, m.cod_trab_antguo, m.foto_trabaj
  from maestro m
  where m.cod_trab_antguo <> '     '
  for update ;
           
ls_codigo      char(05) ;
ls_ruta        constant char(15) := 'I:\FOTOS\FOTOS\' ;
ls_extension   constant char(04) := '.JPG';
ls_ubicacion   char(24) ;

begin
      
For rc_maestro in c_maestro Loop
  ls_codigo    := substr(rc_maestro.cod_trab_antguo,1,5) ;
  ls_ubicacion := (ls_ruta||ls_codigo||ls_extension) ;
  Update maestro
    Set foto_trabaj = ls_ubicacion
    where current of c_maestro ;
End Loop ;

end usp_actualiza_fotos;
/
