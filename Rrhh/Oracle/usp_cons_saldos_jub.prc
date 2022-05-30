create or replace procedure usp_cons_saldos_jub
  ( ad_fec_proceso  in date ) is

ls_cod_jubilado        mov_variable_jubilado.cod_jubilado%type ;
ln_nro_secuencia       mov_variable_jubilado.nro_secuencial%type ;
ls_concepto            sldo_deuda_jubilado.concep%type ;
ls_flag_estado         sldo_deuda_jubilado.flag_estado%type ;
ln_saldo_capital       sldo_deuda_jubilado.imp_sldo_capital%type ;
ln_saldo_interes       sldo_deuda_jubilado.imp_sldo_interes%type ;

ln_capital_interes     sldo_deuda_jubilado.imp_sldo_interes%type ;
ls_nombres             varchar2(35) ;
ls_descripcion         varchar2(35) ;

--  Cursor para seleccion de jubilados
cursor c_movimiento is 
  Select mvj.cod_jubilado, mvj.nro_secuencial
  from mov_variable_jubilado mvj
  where mvj.flag_estado = '1' 
  order by mvj.cod_jubilado, mvj.nro_secuencial ;

--  Cursor para hallar saldos por capital e interes
cursor c_saldos is 
  Select sdj.cod_jubilado, sdj.sec_herederos, sdj.concep,
         sdj.fec_actual, sdj.flag_estado, sdj.imp_sldo_capital,
         sdj.imp_sldo_interes
  from sldo_deuda_jubilado sdj
  where sdj.cod_jubilado = ls_cod_jubilado and
        sdj.sec_herederos = ln_nro_secuencia and
        sdj.fec_actual  = ad_fec_proceso and
        sdj.flag_estado = '1' 
  order by sdj.fec_actual, sdj.cod_jubilado, sdj.sec_herederos,
           sdj.concep ;

begin

delete from tt_cons_jub_saldos ;

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
  ln_capital_interes := 0 ;

  For rc_sal in c_saldos Loop  

    ls_concepto      := rc_sal.concep ;
    ln_saldo_capital := rc_sal.imp_sldo_capital ;
    ln_saldo_interes := rc_sal.imp_sldo_interes ;
    ln_saldo_capital := nvl(ln_saldo_capital,0) ;
    ln_saldo_interes := nvl(ln_saldo_interes,0) ;
  
    ln_capital_interes := ln_saldo_capital + ln_saldo_interes ;

    --  Insertar los Registro en la tabla tt_cons_jub_saldos
    If ln_capital_interes <> 0 then
      Select c.desc_breve
        into ls_descripcion
        from concepto c
        where c.concep = ls_concepto ;

      Insert into tt_cons_jub_saldos
        (codigo, secuencia, nombres, 
         concepto, descripcion, importe)
      Values
        (ls_cod_jubilado, ln_nro_secuencia, ls_nombres,
         ls_concepto, ls_descripcion, ln_capital_interes) ;
    End if ;

  End loop ;
     
End loop ;
                     
End usp_cons_saldos_jub ;
/
