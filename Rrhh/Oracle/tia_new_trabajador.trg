CREATE OR REPLACE TRIGGER "PROD3".tia_new_trabajador
  after insert  on maestro
  for each row



declare

ld_fecha          date ;

begin

  -- Edgar Morante Miercoles 10Jul2002, replicacion
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;


ld_fecha := sysdate ;

--  Inserta registros en la tabla cargo real del trabajador

  insert into rh_cargo_real_trabajador (
    cod_trabajador, cod_area, cod_cargo,
    fecha, flag_estado, flag_replicacion )
  Values (
    :new.cod_trabajador, :new.cod_area,:new.cod_cargo,
    ld_fecha, '1', '0' ) ;

End tia_new_trabajador ;
/
