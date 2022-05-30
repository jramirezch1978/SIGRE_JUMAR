create or replace procedure usp_rh_cal_fijo_tripulante (
    asi_codtra        in maestro.cod_trabajador%TYPE,
    adi_fec_proceso   in date,
    asi_origen        in origen.cod_origen%TYPE,
    ani_tipcam        in number,
    asi_tipo_planilla in calculo.tipo_planilla%TYPE
) is

ln_imp_soles          calculo.imp_soles%TYPE ;
ln_imp_dolar          calculo.imp_dolar%TYPE ;
ln_horas_trabaj       calculo.horas_trabaj%TYPE;

--Conceptos para la asistencia de los jornaleros
ln_dias               number;

begin

  --  *********************************************************
  --  ***   CALCULA LAS BONIFICACIONES DE LOS TRIPULANTES   ***
  --  *********************************************************

  -- Obtengo la cantidad de días
  select nvl(sum(f.nro_dias), 0)
    into ln_dias
    from fl_dias_motorista f
   where f.cod_motorista = asi_codtra
     and f.anio          = to_number(to_char(adi_fec_proceso, 'yyyy'))
     and f.mes           = to_number(to_char(adi_fec_proceso, 'mm'));
  
  -- Si no hay días no calculo nada
  if ln_dias = 0 then return; end if;
  
  -- Calculo el importe total
  select nvl(sum(gdf.imp_gan_desc),0)
    into ln_imp_soles
    from gan_desct_fijo gdf
   where gdf.cod_trabajador = asi_codtra
     and gdf.concep         = usp_sigre_rrhh.is_cnc_bonif_tri;
  
  -- Si el importe es cero entonces no hay nada mas que hacer
  if ln_imp_soles = 0 then
     return;
  end if;
  
  -- Calculo el proporcional
  ln_imp_soles := ln_imp_soles / 30 * ln_dias;

  -- Calculo en dolares
  ln_imp_dolar := ln_imp_soles / ani_tipcam ;
        
  UPDATE calculo
     SET horas_trabaj = ln_horas_trabaj,
         horas_pag    = ln_horas_trabaj,
         imp_soles    = imp_soles + ln_imp_soles,
         imp_dolar    = imp_dolar + ln_imp_dolar,
         DIAS_TRABAJ  = ln_dias
    WHERE cod_trabajador = asi_codtra
      AND concep         = usp_sigre_rrhh.is_cnc_bonif_tri
      and tipo_planilla  = asi_tipo_planilla;
        
  if SQL%NOTFOUND then
      insert into calculo (
        cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
        dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item, tipo_planilla )
      values (
        asi_codtra, usp_sigre_rrhh.is_cnc_bonif_tri, adi_fec_proceso, ln_horas_trabaj, ln_horas_trabaj,
        ln_dias, ln_imp_soles, ln_imp_dolar, asi_origen, '1', 1, asi_tipo_planilla ) ;
  end if;


end usp_rh_cal_fijo_tripulante ;
/
