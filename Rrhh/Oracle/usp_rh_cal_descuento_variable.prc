create or replace procedure usp_rh_cal_descuento_variable (
       asi_codtra           in maestro.cod_trabajador%TYPE, 
       adi_fec_proceso      in date, 
       ani_tipcam           in number,
       asi_origen           in origen.cod_origen%TYPE,
       asi_tipo_planilla    in calculo.tipo_planilla%TYPE
) is

ln_imp_soles        calculo.imp_soles%TYPE ;
ln_imp_dolar        calculo.imp_dolar%TYPE ;
ld_fec_ini          gan_desct_variable.fec_movim%TYPE;
ld_fec_fin          gan_desct_variable.fec_movim%TYPE;
ls_tipo_trabajador  maestro.tipo_trabajador%TYPE;

--  Lectura de conceptos de descuentos variables
cursor c_ganancias_variables is
  select distinct gdv.concep
    from gan_desct_variable gdv
   where gdv.cod_trabajador = asi_codtra 
     and substr(gdv.concep,1,1) = '2' 
     and trunc(gdv.fec_movim) between trunc(ld_fec_ini) and trunc(ld_fec_fin)
     and gdv.tipo_planilla      = asi_tipo_planilla;


begin

  --  ********************************************************
  --  ***   ADICIONA DESCUENTOS VARIABLES POR TRABAJADOR   ***
  --  ********************************************************
  select tipo_trabajador
    into ls_tipo_trabajador
    from maestro m
   where m.cod_trabajador = asi_codtra;

  select r.fec_inicio, r.fec_final
    into ld_fec_ini, ld_fec_fin
    from rrhh_param_org r
   where r.origen          = asi_origen
     and r.fec_proceso     = trunc(adi_fec_proceso)
     and r.tipo_trabajador = ls_tipo_trabajador
     and r.tipo_planilla   = asi_tipo_planilla;

  for rc_gv in c_ganancias_variables loop
    
      --  Sumatoria de conceptos de descuentos
      select NVL(sum(nvl(gdv.imp_var,0)),0)
        into ln_imp_soles
        from gan_desct_variable gdv
       where gdv.cod_trabajador = asi_codtra 
         and gdv.concep         = rc_gv.concep 
         and gdv.tipo_planilla = asi_tipo_planilla
         and trunc(gdv.fec_movim) between trunc(ld_fec_ini) and trunc(ld_fec_fin);

      ln_imp_dolar := ln_imp_soles / ani_tipcam ;
      
      update calculo
         set imp_soles        = imp_soles + ln_imp_soles ,
             imp_dolar        = imp_dolar + ln_imp_dolar ,
             flag_replicacion = '1'
       where cod_trabajador = asi_codtra 
         and concep         = rc_gv.concep 
         and tipo_planilla  = asi_tipo_planilla;
          
      if SQL%NOTFOUND then
         insert into calculo (
                cod_trabajador, concep, fec_proceso, horas_trabaj, horas_pag,
                dias_trabaj, imp_soles, imp_dolar, cod_origen, flag_replicacion, item,
                tipo_planilla )
         values (
                asi_codtra, rc_gv.concep, adi_fec_proceso, 0, 0,
                0, ln_imp_soles, ln_imp_dolar, asi_origen, '0', 1, asi_tipo_planilla ) ;
      end if ;

  end loop ;

end usp_rh_cal_descuento_variable ;
/
