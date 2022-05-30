create or replace trigger TUB_RRHH_PERMISO_VACAC
  before update on rrhh_permiso_vacac  
  for each row
declare
  -- local variables here
  ln_count number;
begin
  if :old.flag_estado = '1' and :new.flag_estado = '2' then
     -- Lo esta enviando a la planilla
     update rrhh_vacaciones_trabaj t
        set t.dias_gozados  = t.dias_gozados + trunc(:new.fecha_fin) - trunc(:new.fecha_inicio) + 1
      where t.cod_trabajador = :new.cod_trabajador
        and t.periodo_inicio = :new.periodo_inicio
        and t.concep         = :new.concep;
     
     if SQL%NOTFOUND then
        insert into rrhh_vacaciones_trabaj(
               cod_trabajador, periodo_inicio, periodo_fin, dias_totales, dias_gozados, 
               flag_estado, concep, cod_usr, item_laboral)
        values(
               :new.cod_trabajador, :new.periodo_inicio, :new.periodo_fin, :new.dias_totales, trunc(:new.fecha_fin) - trunc(:new.fecha_inicio) + 1,
               '1', :new.concep, :new.usr_aprob, 1);
     end if;
     
     -- Ahora el detalle
     update inasistencia i
        set i.cod_trabajador = :new.cod_trabajador,
            i.concep         = :new.concep,
            i.fec_desde      = :new.fecha_inicio,
            i.fec_hasta      = :new.fecha_fin,
            i.fec_movim      = :new.fec_movimiento,
            i.dias_inasist   = trunc(:new.fecha_fin) - trunc(:new.fecha_inicio) + 1,
            i.cod_usr        = :new.usr_aprob,
            i.periodo_inicio = :new.periodo_inicio,
            i.cod_suspension_lab = 23,
            i.mes_periodo        = to_number(to_char(:new.fec_movimiento, 'mm'))
      where i.nro_permiso        = :new.nro_permiso;

     if SQL%NOTFOUND then
        select count(*)
          into ln_count
          from inasistencia i
         where i.COD_TRABAJADOR = :new.cod_trabajador
           and i.CONCEP         = :new.concep
           and i.FEC_DESDE      = :new.fecha_inicio;
        
        if ln_count > 0 then
           RAISE_APPLICATION_ERROR(-20000, 'Ya existe un concepto de vacaciones para el trabajador en la misma fecha de inicio, por favor verifique'
                                       || chr(13) || 'Cod Trabajador: ' || :new.cod_trabajador
                                       || chr(13) || 'Concepto: ' || :new.concep
                                       || chr(13) || 'Fecha Desde: ' || to_char(:new.fecha_inicio, 'dd/mm/yyyy'));
        end if;
        
        insert into inasistencia(
               cod_trabajador,concep, fec_desde, fec_hasta, fec_movim, dias_inasist, 
               cod_usr, periodo_inicio, cod_suspension_lab, item_laboral, flag_vacac_adelantadas, nro_permiso )
        values(
               :new.cod_trabajador, :new.concep, :new.fecha_inicio, :new.fecha_fin, :new.fec_movimiento, trunc(:new.fecha_fin) - trunc(:new.fecha_inicio) + 1,
               :new.usr_aprob, :new.periodo_inicio, 23, 1, '0', :new.nro_permiso);
     end if;
  end if;
  
  if :old.flag_estado = '2' and :new.flag_estado = '1' then
    
     delete inasistencia i
     where i.nro_permiso = :new.nro_permiso;
  end if;
end TUB_RRHH_PERMISO_VACAC;
/
