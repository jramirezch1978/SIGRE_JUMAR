create or replace procedure usp_rh_fondo_retiro_orig (
  asi_tipo_trabajador in char, 
  asi_cod_origen in char, 
  asi_fec_proceso in string

) is
   cursor lc_trabajador is
      select m.cod_trabajador
         from maestro m
         where m.cod_origen = asi_cod_origen
            and m.tipo_trabajador = asi_tipo_trabajador
            and m.flag_cal_plnlla = '1' 
            and m.flag_estado = '1' 
            and m.situa_trabaj = 'S' ;
begin
   for rs_trab in lc_trabajador loop
      usp_rh_fondo_retiro_trab(asi_fec_proceso, rs_trab.cod_trabajador);
   end loop;

end usp_rh_fondo_retiro_orig ;
/
