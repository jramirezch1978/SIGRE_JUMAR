create or replace procedure USP_RH_HIST_DISTRIB_CNTBL(
       asi_origen       in origen.cod_origen%TYPE,
       asi_tipo_trabaj  in tipo_trabajador.tipo_trabajador%TYPE,
       ani_year         in number,
       ani_mes          in number,
       asi_usr          in usuario.cod_usr%TYPE
) is
  ln_count number;
begin
  select count(*)
    into ln_count
    FROM distribucion_cntble t
   where t.cod_origen = asi_origen
     and t.tipo_trabajador = asi_tipo_trabaj
     and to_number(to_char(t.Fec_Calculo,'yyyy')) = ani_year
     and (to_number(to_char(t.Fec_Calculo,'mm')) = ani_mes or ani_mes = -1);

  if ln_count = 0 then
     RAISE_APPLICATION_ERROR(-20000, 'No se ha procesado la distribución contable para enviar al historico');
  end if;

  delete historico_distrib_cntble t
  where cod_origen = asi_origen
    and t.tipo_trabajador = asi_tipo_trabaj
    and to_number(to_char(t.Fec_Calculo,'yyyy')) = ani_year
    and (to_number(to_char(t.Fec_Calculo,'mm'))  = ani_mes or ani_mes = -1);

  insert into historico_distrib_cntble(
         cod_trabajador, cencos, fec_movimiento, cod_labor, und, nro_horas, fec_calculo, centro_benef, tipo_trabajador, cod_origen, cod_usr)
  select cod_trabajador, cencos, fec_movimiento, cod_labor, und, nro_horas, fec_calculo, centro_benef, tipo_trabajador, cod_origen, asi_usr
       FROM distribucion_cntble t
   where t.cod_origen = asi_origen
     and t.tipo_trabajador = asi_tipo_trabaj
     and to_number(to_char(t.Fec_Calculo,'yyyy')) = ani_year
     and (to_number(to_char(t.Fec_Calculo,'mm'))  = ani_mes or ani_mes = -1);

  commit;
end USP_RH_HIST_DISTRIB_CNTBL;
/
