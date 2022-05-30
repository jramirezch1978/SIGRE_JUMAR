CREATE OR REPLACE TRIGGER "PROD3".TUA_PROVEEDOR
  after update on proveedor
  for each row






declare
  -- local variables here
begin
  -- Edgar Morante Miercoles 10Jul2002, replicacion
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

  UPDATE Codigo_relacion set nombre = :new.nom_proveedor ,
                             flag_replicacion = '0'
    Where cod_relacion = :new.proveedor  ;
end TUA_PROVEEDOR;
/
