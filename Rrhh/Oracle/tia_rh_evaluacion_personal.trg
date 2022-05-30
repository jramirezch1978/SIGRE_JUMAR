CREATE OR REPLACE TRIGGER "PROD3".tia_rh_evaluacion_personal
  after insert on rh_evaluacion_personal
  for each row



declare
  -- local variables here
  cursor c_rh_cargo_compet_comport is
  select cod_competencia, cod_comport
  from rh_cargo_compet_comport
  where cod_area = :new.cod_area and
        cod_cargo = :new.cod_cargo ;

begin

  -- Edgar Morante Miercoles 10Jul2002, replicacion
  If (dbms_reputil.from_remote=true or dbms_snapshot.i_am_a_refresh=true) then
     return;
  end if;

FOR r_cm IN c_rh_cargo_compet_comport LOOP

    -- Ingresa a rh_evaluacion_personal_det
    insert into rh_evaluacion_personal_det
    ( fecha_evaluacion , cod_trabajador , cod_competencia, cod_comport, puntaje, flag_replicacion )
    values
    (:new.fecha_evaluacion, :new.cod_trabajador, r_cm.cod_competencia, r_cm.cod_comport, 0, '0' ) ;
end loop ;

end tia_rh_evaluacion_personal;
/
