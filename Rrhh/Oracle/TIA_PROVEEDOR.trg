CREATE OR REPLACE TRIGGER "PROD3".TIA_PROVEEDOR
  after insert on proveedor
  for each row






declare
  -- local variables here
begin
  -- Edgar Morante Miercoles 10Jul2002, replicacion
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

  INSERT INTO CODIGO_RELACION(COD_RELACION, NOMBRE, FLAG_TABLA, FLAG_REPLICACION )
      VALUES(:new.proveedor, :new.nom_proveedor, 'P', '0' );
end TIA_PROVEEDOR;
/
