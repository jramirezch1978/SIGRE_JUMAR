create or replace trigger tiua_new_proveedor
  after insert or update on maestro
  for each row

declare

ls_nombres        char(50) ;

begin

  -- Edgar Morante Miercoles 10Jul2002, replicacion
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

ls_nombres := rtrim(:new.apel_paterno)||' '||rtrim(:new.apel_materno)||' '||
              nvl(rtrim(:new.nombre1),' ')||' '||nvl(rtrim(:new.nombre2),' ') ;

--  Actualiza datos en la tabla proveedores

/*****************************************************
**** REPLICACION
*****************************************************/
Update proveedor p
  set email         = substr(:new.email,1,40) ,
      nom_proveedor = ls_nombres ,
      tipo_doc_ident = '1',
      nro_doc_ident  = :new.dni ,
      flag_replicacion = '0',
      flag_estado   = :new.flag_estado
  where proveedor = :new.cod_trabajador ;
/*****************************************************/

--  Inserta registros en la tabla proveedores
If sql%notfound then
   /*****************************************************
   **** REPLICACION
   *****************************************************/
   insert into proveedor (
        proveedor, flag_estado, nom_proveedor,
        email, tipo_doc_ident, nro_doc_ident , flag_replicacion, apellido_mat, apellido_pat, nombre1, nombre2 )
   Values (
        :new.cod_trabajador, '1', ls_nombres,
        :new.email, '1',:new.dni, '0', :new.apel_materno, :new.apel_materno, :new.nombre1, :new.nombre2 ) ;
   /*****************************************************/
End if ;

End tiua_new_proveedor ;
/
