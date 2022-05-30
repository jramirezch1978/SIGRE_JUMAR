create or replace procedure usp_rh_fondo_retiro_relac (
  asi_fec_proceso in string

) is
   cursor lc_trabajador is
      select m.cod_trabajador
         from maestro m
         where m.flag_cal_plnlla = '1' 
            and m.flag_estado = '1' 
            and m.situa_trabaj = 'S' ;
begin
   for rs_trab in lc_trabajador loop
      usp_rh_fondo_retiro_trab(asi_fec_proceso, rs_trab.cod_trabajador);
   end loop;

end usp_rh_fondo_retiro_relac;
/
