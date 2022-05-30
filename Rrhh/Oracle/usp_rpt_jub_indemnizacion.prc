create or replace procedure usp_rpt_jub_indemnizacion is

ln_orden               number(3) ;
ls_codigo              sldo_deuda_jubilado.cod_jubilado%type ;
ln_secuencia           sldo_deuda_jubilado.sec_herederos%type ;
ld_fecha_proceso       sldo_deuda_jubilado.fec_actual%type ;
ls_flag_estado         sldo_deuda_jubilado.flag_estado%type ;

ln_capital             sldo_deuda_jubilado.imp_acum_interes%type ;
ln_interes             sldo_deuda_jubilado.imp_acum_interes%type ;
ln_adel_capital        sldo_deuda_jubilado.imp_acum_interes%type ;
ln_adel_interes        sldo_deuda_jubilado.imp_acum_interes%type ;
ln_saldo_capital       sldo_deuda_jubilado.imp_acum_interes%type ;
ln_saldo_interes       sldo_deuda_jubilado.imp_acum_interes%type ;

ls_cod_jubilado        mov_variable_jubilado.cod_jubilado%type ;
ln_nro_secuencia       mov_variable_jubilado.nro_secuencial%type ;

ls_nombres             varchar2(40) ;
ld_fec_proceso         date ;
ld_fecha_cese          date ;

ln_indem_01            number(13,2) ;
ln_indem_02            number(13,2) ;
ln_indem_03            number(13,2) ;
ln_indem_04            number(13,2) ;
ln_indem_05            number(13,2) ;
ln_indem_06            number(13,2) ;
ln_indem_07            number(13,2) ;
ln_indem_08            number(13,2) ;

--  Cursor para seleccion de jubilados
cursor c_movimiento is 
  Select mvj.cod_jubilado, mvj.nro_secuencial
  from mov_variable_jubilado mvj
  where mvj.flag_estado = '1' 
  order by mvj.cod_jubilado, mvj.nro_secuencial ;

--  Cursor para hallar saldos por capital e interes
cursor c_saldos is 
  Select sdj.cod_jubilado, sdj.sec_herederos, sdj.concep,
         sdj.fec_actual, sdj.flag_estado, sdj.imp_original,
         sdj.imp_acum_interes, sdj.imp_acum_adel_capital,
         sdj.imp_acum_adel_interes, sdj.imp_sldo_capital,
         sdj.imp_sldo_interes
  from sldo_deuda_jubilado sdj
  where sdj.cod_jubilado = ls_cod_jubilado and
        sdj.sec_herederos = ln_nro_secuencia and
        sdj.fec_actual  = ld_fec_proceso and
        sdj.flag_estado = '1' 
  order by sdj.fec_actual, sdj.cod_jubilado, sdj.sec_herederos,
           sdj.concep ;

begin

delete from tt_rpt_jub_indemnizacion ;

--  Selecciona fecha de proceso
Select c.fec_proceso
  into ld_fec_proceso
  from control c ;
  
ln_orden := 0 ;  

For rc_mov in c_movimiento Loop

  ls_cod_jubilado  := rc_mov.cod_jubilado ;
  ln_nro_secuencia := rc_mov.nro_secuencial ;

  Select rtrim(hj.apel_paterno)||' '||rtrim(hj.apel_materno)||' '||
         nvl(rtrim(hj.nombre1),' ')||' '||nvl(rtrim(hj.nombre2),' ')
    into ls_nombres
    from herederos_jubilados hj
    where hj.cod_jubilado  = ls_cod_jubilado and
          hj.sec_herederos = ln_nro_secuencia ;
  ls_nombres := nvl(ls_nombres,' ') ;

  Select m.fec_cese
    into ld_fecha_cese
    from maestro m
    where m.cod_trabajador = ls_cod_jubilado ;
  ld_fecha_cese := nvl(ld_fecha_cese,ld_fec_proceso) ;

  ln_indem_01 := 0 ;  ln_indem_02 := 0 ;  ln_indem_03 := 0 ;
  ln_indem_04 := 0 ;  ln_indem_05 := 0 ;  ln_indem_06 := 0 ;
  ln_indem_07 := 0 ;  ln_indem_08 := 0 ;

  For rc_sal in c_saldos Loop

    ln_capital       := rc_sal.imp_original ;
    ln_interes       := rc_sal.imp_acum_interes ;
    ln_adel_capital  := rc_sal.imp_acum_adel_capital ;
    ln_adel_interes  := rc_sal.imp_acum_adel_interes ;
    ln_saldo_capital := rc_sal.imp_sldo_capital ;
    ln_saldo_interes := rc_sal.imp_sldo_interes ;
    
    ln_capital       := nvl(ln_capital,0) ;
    ln_interes       := nvl(ln_interes,0) ;
    ln_adel_capital  := nvl(ln_adel_capital,0) ;
    ln_adel_interes  := nvl(ln_adel_interes,0) ;
    ln_saldo_capital := nvl(ln_saldo_capital,0) ;
    ln_saldo_interes := nvl(ln_saldo_interes,0) ;
    
    ln_indem_01 := ln_indem_01 + ln_capital ;
    ln_indem_02 := ln_indem_02 + ln_interes ;
    ln_indem_04 := ln_indem_04 + ln_adel_interes ;
    ln_indem_05 := ln_indem_05 + ln_adel_capital ;
    ln_indem_06 := ln_indem_06 + ln_saldo_capital ;
    ln_indem_07 := ln_indem_07 + ln_saldo_interes ;

  End loop ;
                      
  ln_indem_01 := nvl(ln_indem_01,0) ;
  ln_indem_02 := nvl(ln_indem_02,0) ;
  ln_indem_04 := nvl(ln_indem_04,0) ;
  ln_indem_05 := nvl(ln_indem_05,0) ;
  ln_indem_06 := nvl(ln_indem_06,0) ;
  ln_indem_07 := nvl(ln_indem_07,0) ;
  
  ln_indem_03 := ln_indem_01 + ln_indem_02 ;
  ln_indem_08 := ln_indem_06 + ln_indem_07 ;
  
  --  Insertar los Registro en la tabla tt_rpt_jub_indemnizacion
  If ln_indem_08 > 0 then

    ln_orden := ln_orden + 1 ;
    Insert into tt_rpt_jub_indemnizacion
      (orden, codigo, secuencia, nombres, fecha_cese, 
       indem_01, indem_02, indem_03, indem_04,
       indem_05, indem_06, indem_07, indem_08,
       fecha_proceso)
    Values
      (ln_orden, ls_cod_jubilado, ln_nro_secuencia, ls_nombres, ld_fecha_cese,
       ln_indem_01, ln_indem_02, ln_indem_03, ln_indem_04,
       ln_indem_05, ln_indem_06, ln_indem_07, ln_indem_08,
       ld_fec_proceso ) ;

  End if ;
     
End loop ;
                     
End usp_rpt_jub_indemnizacion ;
/
