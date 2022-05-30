create or replace procedure usp_rh_dias_no_laborados_rtps(
       ani_year         in number,
       ani_mes          in number,
       asi_origen       in varchar2
) is
  ld_fecha1         date;
  ld_Fecha2         date;
  ld_fecha          date;
  ln_dias           number;
  lb_continue       boolean;
  ln_count          number;
  ls_tipo_emp       rrhhparam.tipo_trab_empleado%TYPE;
  ls_tipo_obr       rrhhparam.tipo_trab_obrero%TYPE;
  ls_tipo_des       rrhhparam.tipo_trab_destajo%TYPE;
  
  cursor c_datos is
    select distinct *
    from (
      select distinct m.cod_trabajador, m.fec_ingreso, m.fec_cese, m.tipo_trabajador, m.cod_origen
        from maestro m,
             calculo c
       where m.cod_trabajador = c.cod_trabajador
         and to_char(c.fec_proceso, 'yyyymm') = trim(to_char(ani_year, '0000')) || trim(to_char(ani_mes, '00'))
         and instr(asi_origen, m.cod_origen) > 0
         and m.flag_estado = '1'
      union
      select distinct m.cod_trabajador, m.fec_ingreso, m.fec_cese, m.tipo_trabajador, m.cod_origen
        from maestro m,
             historico_calculo hc
       where m.cod_trabajador = hc.cod_trabajador
         and to_char(hc.fec_calc_plan, 'yyyymm') = trim(to_char(ani_year, '0000')) || trim(to_char(ani_mes, '00'))
         and instr(asi_origen, m.cod_origen) > 0
         and m.flag_estado = '1'
     );  
begin
  --Limpio la tabla temporal
  delete tt_rh_dias_no_laborados;
  
  --Proceso para la inasistencia
  select rh.tipo_trab_empleado, rh.tipo_trab_obrero, rh.tipo_trab_destajo
    into ls_tipo_emp, ls_tipo_obr, ls_tipo_des
    from rrhhparam rh
   where reckey = '1';  
  
  ld_fecha1 := to_date('01/' || trim(to_char(ani_mes)) || '/' || trim(to_char(ani_year, '0000')), 'dd/mm/yyyy');
  ld_fecha2 := last_day(ld_fecha1);
   
  ln_dias :=  ld_Fecha2 - ld_fecha1 + 1;
  
  for lc_reg in c_datos loop
      lb_continue := false;
      if lc_reg.fec_ingreso > ld_fecha2 then lb_continue := true; end if;
      
      if lc_reg.fec_cese is not null then
         if lc_reg.fec_cese < ld_fecha1 then lb_continue := true; end if;
      end if;
      
      if lb_continue = false then
         FOR ln_dia IN 0..ln_dias - 1 LOOP
             ld_fecha := ld_fecha1 + ln_dia;
             if usf_rh_is_dia_descanso(lc_reg.tipo_trabajador, ld_fecha) = false or 
                usf_rh_is_dia_feriado(lc_reg.cod_origen, ld_fecha) = false then
                
                if lc_reg.tipo_trabajador not in (ls_tipo_obr, ls_tipo_des) then
                   select count(*)
                     into ln_count
                     from asistencia_ht580 t
                    where t.codigo = lc_reg.cod_trabajador
                      and t.fec_movimiento = ld_fecha;
                elsif lc_reg.tipo_trabajador = ls_tipo_obr then
                   select count(distinct fecha)
                     into ln_count
                     from pd_jornal_campo t
                    where t.cod_trabajador = lc_reg.cod_trabajador
                      and trunc(t.fecha)   = ld_fecha;
                elsif lc_reg.tipo_trabajador = ls_tipo_des then
                   select count(distinct a.fec_parte)
                     into ln_count
                     from tg_pd_destajo a,
                          tg_pd_destajo_det b
                    where a.nro_parte      = b.nro_parte
                      and b.cod_trabajador = lc_reg.cod_trabajador
                      and trunc(a.fec_parte)   = ld_fecha;
                end if;
                 
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
end usp_rh_dias_no_laborados_rtps;
/
