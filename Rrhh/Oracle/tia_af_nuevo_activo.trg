CREATE OR REPLACE TRIGGER "PROD3".tia_af_nuevo_activo
  after insert on activo_fijo for each row

declare

begin

-- Replicacion
if (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
  return ;
end if ;

insert into activo_fijo_ocurrencia (
  nro_activo, fecha, tipo_ocurrencia,
  importe, flag_replicacion )
values (
  :new.nro_activo, :new.fecha_adquisicion, :new.flag_tipo_compra,
  :new.valor_orig_sol, '0' ) ;

end tia_af_nuevo_activo ;
/
