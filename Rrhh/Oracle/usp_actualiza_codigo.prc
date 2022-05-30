create or replace procedure usp_actualiza_codigo is

ls_codigo      char(08) ;
ls_nombres     varchar2(60) ;
ls_flag        char(1) ;
ln_registro    number(15) ;

--  Lee maestro de trabajadores
Cursor c_maestro is
  Select m.cod_trabajador, m.apel_paterno, m.apel_materno,
         m.nombre1, m.nombre2
  from maestro m
  where m.flag_estado = '1' ;

begin

delete from codigo_relacion ;
      
For rc_mae in c_maestro Loop

  ls_flag    := 'M' ;
  ls_codigo  := rc_mae.cod_trabajador ;
  ls_nombres := rtrim(rc_mae.apel_paterno)||' '||rtrim(rc_mae.apel_materno)||' '||
                nvl(rtrim(rc_mae.nombre1),' ')||' '||nvl(rtrim(rc_mae.nombre2),' ') ;

  ln_registro := 0 ;
  Select count(*)
    into ln_registro
    from codigo_relacion cr
    where cr.cod_relacion = ls_codigo ;
  ln_registro := nvl(ln_registro,0) ;
    
  If ln_registro > 0 then
    Update codigo_relacion
      Set cod_relacion = ls_codigo ,
          nombre       = ls_nombres ,
          flag_tabla   = ls_flag
      where cod_relacion = ls_codigo ;
  Else    
    Insert into codigo_relacion (
      cod_relacion, nombre, flag_tabla )
    Values (
      ls_codigo, ls_nombres, ls_flag ) ;
  End if ;
  
End Loop ;

end usp_actualiza_codigo ;


/*
create or replace procedure usp_actualiza_codigo is

cursor c_banda is
  select b.codigo, b.tipo, b.contra, b.banda
  from banda b, maestro m
  where b.codigo = m.cod_trabajador
  order by b.codigo ;

begin

for rc_ban in c_banda loop

  update maestro m
    set m.contra = rc_ban.contra ,
        m.banda  = rc_ban.banda ,
        m.condes = rc_ban.tipo
    where m.cod_trabajador = rc_ban.codigo ;
    
end loop ;      

end usp_actualiza_codigo ;
*/
/
