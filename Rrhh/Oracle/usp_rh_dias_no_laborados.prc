create or replace procedure usp_rh_dias_no_laborados(
       asi_tipo_trabaj      in tipo_trabajador.tipo_trabajador%TYPE,
       adi_Fecha1           in date,
       adi_fecha2           in date
) is
  ld_fecha          date;
  ln_dias           number;
  lb_continue       boolean;
  ln_count          number;
  ls_tipo_emp       rrhhparam.tipo_trab_empleado%TYPE;
  ls_tipo_obr       rrhhparam.tipo_trab_obrero%TYPE;
  ls_tipo_des       rrhhparam.tipo_trab_destajo%TYPE;
  
  cursor c_datos is
    select m.cod_trabajador, m.fec_ingreso, m.fec_cese, m.tipo_trabajador, m.cod_origen
      from maestro m
     where m.tipo_trabajador = asi_tipo_trabaj
       and m.flag_estado     = '1';
begin
  --Limpio la tabla temporal
  delete tt_rh_dias_no_laborados;
  
  --Proceso para la inasistencia
  select rh.tipo_trab_empleado, rh.tipo_trab_obrero, rh.tipo_trab_destajo
    into ls_tipo_emp, ls_tipo_obr, ls_tipo_des
    from rrhhparam rh
   where reckey = '1';  

  ln_dias := adi_Fecha2 - adi_fecha1 + 1;
  for lc_reg in c_datos loop
      lb_continue := false;
      if lc_reg.fec_ingreso > adi_fecha2 then lb_continue := true; end if;
      
      if lc_reg.fec_cese is not null then
         if lc_reg.fec_cese < adi_fecha1 then lb_continue := true; end if;
      end if;
      
      if lb_continue = false then
         FOR ln_dia IN 0..ln_dias - 1 LOOP
             ld_fecha := adi_fecha1 + ln_dia;
             if usf_rh_is_dia_descanso(asi_tipo_trabaj, ld_fecha) = false or 
                usf_rh_is_dia_feriado(lc_reg.cod_origen, ld_fecha) = false then
                
                select count(*)
                  into ln_count
                  from asistencia_ht580 t
                 where t.codigo = lc_reg.cod_trabajador
                   and t.fec_movimiento = ld_fecha;
                 
                if ln_count = 0 then
                   --Ha faltado asi que simplemente lo agrego
                   insert into tt_rh_dias_no_laborados(cod_trabajador, fecha)
                   values(lc_reg.cod_trabajador, ld_fecha);
                end if;
                
             end if;
         end loop;
      end if;
  end loop;
  commit;
end usp_rh_dias_no_laborados;
/
