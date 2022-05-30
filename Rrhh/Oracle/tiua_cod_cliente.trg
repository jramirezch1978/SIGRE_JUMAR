CREATE OR REPLACE TRIGGER "PROD1".tiua_cod_cliente
  after insert or update on maestro
  for each row







declare

ln_contador       number(15) ;
ls_nombres        varchar2(60) ;

begin

  -- Edgar Morante Miercoles 10Jul2002, replicacion 
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

ls_nombres := rtrim(:new.apel_paterno)||' '||rtrim(:new.apel_materno)||' '||
              nvl(rtrim(:new.nombre1),' ')||' '||nvl(rtrim(:new.nombre2),' ') ;

--  Actualiza datos en la tabla CODIGO_RELACION
update codigo_relacion
 set cod_relacion = :new.cod_trabajador,
     nombre       = ls_nombres,
     flag_tabla   = 'M' ,
     flag_replicacion = '0'
 where cod_relacion = :new.cod_trabajador ;

--  Inserta registros en la tabla proveedores
if sql%notfound then

  insert into codigo_relacion (
    cod_relacion, nombre, flag_tabla, flag_replicacion )
  Values (
    :new.cod_trabajador, ls_nombres, 'M', '0' ) ;
    
end if ;

end tiua_cod_cliente ;
/
