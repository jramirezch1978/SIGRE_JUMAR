create or replace procedure usp_actualiza_cencos_nuevos is

ls_cencos_nuevo    char(10) ;
ln_registro        number(15) ;

Cursor c_cencos is
  Select c.cc_nuevo
  from cencos c
  where c.cc_nuevo <> ' ' ;

begin

For rc_cen in c_cencos Loop
  ls_cencos_nuevo := rc_cen.cc_nuevo ;
  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from centros_costo cc
    where cc.cencos = ls_cencos_nuevo ;
  ln_registro := nvl(ln_registro,0) ;
  If ln_registro = 0 then
    Update cencos
      Set descripcion = '*'
      where cc_nuevo = ls_cencos_nuevo ;
  End if ;
End Loop ;

end usp_actualiza_cencos_nuevos ;
/
