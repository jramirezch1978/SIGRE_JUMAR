create or replace procedure usp_rh_ret_aprte_origen (
   asi_ano in string,
   asi_cod_origen in string,
   asi_tipo_trabajador in string
)is
   cursor lc_trabajadores is
      select m.cod_trabajador
         from maestro m
         where m.flag_estado = '1'
            and m.flag_cal_plnlla = '1'
            and m.cod_origen = asi_cod_origen
            and m.tipo_trabajador = asi_tipo_trabajador;
   ls_fecha varchar2(20);

   ls_concep_snp char(4);
   ls_concep_afp_jubilacion char(4);
   ls_concep_afp_invalidez char(4);
   ls_concep_afp_comision char(4);
   ls_concep_seguro_agrario char(4);
   ls_concep_sctr_ipss char(4);
   ls_concep_sctr_onp char(4);
   
begin
delete from tt_rh_retencion_importe ;


select gc.concepto_gen 
   into ls_concep_snp
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.snp from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_afp_jubilacion
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.afp_jubilacion from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_afp_invalidez
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.afp_invalidez from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_afp_comision
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.afp_comision from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_seguro_agrario
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.concep_seguro_agrario from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_sctr_ipss
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.concep_sctr_ipss from rrhhparam_cconcep rc where rc.reckey = '1');

select gc.concepto_gen 
   into ls_concep_sctr_onp
   from grupo_calculo gc 
   where gc.grupo_calculo = (select rc.concep_sctr_onp from rrhhparam_cconcep rc where rc.reckey = '1');
   
   for rs_tab in lc_trabajadores loop
      usp_rh_ret_aprte(rs_tab.cod_trabajador, asi_ano, ls_concep_snp, ls_concep_afp_jubilacion, ls_concep_afp_invalidez, ls_concep_afp_comision, ls_concep_seguro_agrario, ls_concep_sctr_ipss, ls_concep_sctr_onp);
   end loop;

end usp_rh_ret_aprte_origen;
/
